# {"deps": ["fzf"]} #nix
# flake8: noqa: E501

"""
LLM Model Browser

Quick reference tool for looking up LLM model names across providers.

Usage:
  ./model-browser.py          # Browse models
  ./model-browser.py list     # Print all models (for piping to grep/rg)
  ./model-browser.py help     # Show help

Requirements:
- Python 3.6+
- fzf (install with: brew install fzf)
"""

import json
import sys
import subprocess
import urllib.request
import urllib.error
from pathlib import Path
from datetime import datetime, timezone
import concurrent.futures
from typing import Dict, List, Optional, Any

# Configuration
CACHE_DIR = Path.home() / ".cache" / "llm-model-browser"

keys = {
    "openai": "op://Private/Openai/API keys/default",
    "anthropic": "op://Guy Intern/Anthropic API key/key",
    "google": "op://Private/Gemini API Keys/default",
    "xai": "op://Employee/LLM API keys/Keys/xAI - palisade team",
    "openrouter": "op://Private/cvwcuhinwlmid5st3chafx7adq/openrouter",
}

class Provider:
    def __init__(self, name: str, url: str, headers_fn, parse_fn):
        self.name = name
        self.url = url
        self.headers_fn = headers_fn
        self.parse_fn = parse_fn


def create_providers():
    return {
        "openai": Provider(
            name="OpenAI",
            url="https://api.openai.com/v1/models",
            headers_fn=lambda key: {"Authorization": f"Bearer {key}"},
            parse_fn=lambda data: [m["id"] for m in data["data"]],
        ),
        "anthropic": Provider(
            name="Anthropic",
            url="https://api.anthropic.com/v1/models",
            headers_fn=lambda key: {
                "x-api-key": key,
                "anthropic-version": "2023-06-01",
            },
            parse_fn=lambda data: [m["id"] for m in data.get("data", []) if "id" in m],
        ),
        "google": Provider(
            name="Google",
            url="https://generativelanguage.googleapis.com/v1beta/models",
            headers_fn=lambda key: {},
            parse_fn=lambda data: [
                m["name"].replace("models/", "")
                for m in data.get("models", [])
                if "name" in m
            ],
        ),
        "xai": Provider(
            name="xAI",
            url="https://api.x.ai/v1/models",
            headers_fn=lambda key: {"Authorization": f"Bearer {key}"},
            parse_fn=lambda data: [m["id"] for m in data["data"]],
        ),
        "openrouter": Provider(
            name="OpenRouter",
            url="https://openrouter.ai/api/v1/models",
            headers_fn=lambda key: {"Authorization": f"Bearer {key}"},
            parse_fn=lambda data: [m["id"] for m in data["data"]],
        ),
    }


# Ensure cache directory exists
def ensure_cache_dir():
    CACHE_DIR.mkdir(parents=True, exist_ok=True)


# Get API key for a provider
def get_api_key(provider: str) -> str:
    result = subprocess.run(
        ["opcli", "read", keys[provider]],
        capture_output=True,
        text=True,
        check=True,
    )
    return result.stdout.strip()


# Get cache file path for a provider
def get_cache_path(provider: str) -> Path:
    return CACHE_DIR / f"{provider}.json"


# Read cache for a provider
def read_cache(provider: str) -> Optional[Dict[str, Any]]:
    try:
        with open(get_cache_path(provider), "r") as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return None


# Write cache atomically
def write_cache(provider: str, models: List[str]):
    cache_path = get_cache_path(provider)
    temp_path = cache_path.with_suffix(".tmp")

    data = {
        "models": models,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }

    with open(temp_path, "w") as f:
        json.dump(data, f, indent=2)

    temp_path.replace(cache_path)


# Fetch models from API
def fetch_models(provider: str, config: Provider) -> List[str]:
    api_key = get_api_key(provider)

    # Special handling for Google API (key in URL)
    if provider == "google":
        url = f"{config.url}?key={api_key}"
    else:
        url = config.url

    headers = config.headers_fn(api_key)

    req = urllib.request.Request(url, headers=headers)

    try:
        with urllib.request.urlopen(req, timeout=10) as response:
            data = json.loads(response.read())
            return config.parse_fn(data)
    except urllib.error.HTTPError as e:
        error_body = e.read().decode("utf-8", errors="ignore")
        raise Exception(f"HTTP {e.code}: {error_body[:200]}")
    except Exception as e:
        raise Exception(f"Request failed: {str(e)}")


# Update cache for a provider
def update_provider_cache(provider: str, config: Provider) -> Dict[str, Any]:
    try:
        models = fetch_models(provider, config)
        write_cache(provider, models)
        return {"provider": provider, "success": True, "count": len(models)}
    except Exception as e:
        return {"provider": provider, "success": False, "error": str(e)}


# Get all cached models
def get_all_cached_models() -> List[str]:
    all_models = []

    for provider in keys.keys():
        cache = read_cache(provider)
        if cache and "models" in cache:
            for model in cache["models"]:
                all_models.append(f"{provider}/{model}")

    return all_models


# Get cache timestamps
def get_cache_timestamps() -> Dict[str, datetime]:
    timestamps = {}

    for provider in keys.keys():
        cache = read_cache(provider)
        if cache and "timestamp" in cache:
            timestamps[provider] = datetime.fromisoformat(cache["timestamp"])

    return timestamps


# Update all caches in parallel
def update_all_caches() -> List[Dict[str, Any]]:
    # Warm up opcli auth so parallel reads don't trample each other's TouchID prompts.
    get_api_key(next(iter(keys)))

    providers = create_providers()

    with concurrent.futures.ThreadPoolExecutor(max_workers=5) as executor:
        futures = {
            executor.submit(update_provider_cache, name, config): name
            for name, config in providers.items()
        }

        results = []
        for future in concurrent.futures.as_completed(futures):
            results.append(future.result())

        return results


# Pipe models to fzf
def pipe_to_fzf(models: List[str]) -> Optional[str]:
    try:
        process = subprocess.Popen(
            [
                "fzf",
                "--prompt=Model> ",
                "--height=40%",
                "--layout=reverse",
                "--border",
                "--info=inline",
            ],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )

        stdout, stderr = process.communicate(input="\n".join(models).encode("utf-8"))

        # If user selected something (exit code 0), return the selection
        if process.returncode == 0:
            return stdout.decode("utf-8").strip()

        # User cancelled or error occurred
        return None
    except FileNotFoundError:
        raise FileNotFoundError("fzf not found")


# Copy text to clipboard (macOS)
def copy_to_clipboard(text: str) -> bool:
    try:
        process = subprocess.Popen(
            ["pbcopy"],
            stdin=subprocess.PIPE,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        process.communicate(input=text.encode("utf-8"))
        return process.returncode == 0
    except FileNotFoundError:
        return False


# Format time ago
def time_ago(dt: datetime) -> str:
    seconds = (datetime.now(timezone.utc) - dt).total_seconds()

    if seconds < 60:
        return f"{int(seconds)}s ago"
    elif seconds < 3600:
        return f"{int(seconds / 60)}m ago"
    elif seconds < 86400:
        return f"{int(seconds / 3600)}h ago"
    else:
        return f"{int(seconds / 86400)}d ago"


# Main function
def main():
    # Check for subcommand
    subcommand = sys.argv[1] if len(sys.argv) > 1 else None

    if subcommand == "list":
        ensure_cache_dir()
        results = update_all_caches()
        failures = [r for r in results if not r["success"]]
        if failures:
            print("Failed to update models:", file=sys.stderr)
            for r in failures:
                print(f"  {r['provider']}: {r['error']}", file=sys.stderr)
            sys.exit(1)
        for model in get_all_cached_models():
            print(model)
        return

    if subcommand in ["help", "--help", "-h"]:
        print("LLM Model Browser - Quick reference for LLM model names\n")
        print("Usage:")
        print("  ./model-browser.py          Browse models with fzf")
        print("  ./model-browser.py list     Print all models (one per line)")
        print("  ./model-browser.py help     Show this help\n")
        print("Supported providers: OpenAI, Anthropic, Google, xAI, OpenRouter")
        return

    if subcommand:
        print(f"Unknown subcommand: {subcommand}", file=sys.stderr)
        print('Run "./model-browser.py help" for usage information.', file=sys.stderr)
        sys.exit(1)

    ensure_cache_dir()

    results = update_all_caches()
    failures = [r for r in results if not r["success"]]
    if failures:
        print("Failed to update models:", file=sys.stderr)
        for r in failures:
            print(f"  {r['provider']}: {r['error']}", file=sys.stderr)
        sys.exit(1)

    models = get_all_cached_models()

    try:
        selected = pipe_to_fzf(models)
    except FileNotFoundError:
        print(
            "\nError: fzf not found. Install with: brew install fzf",
            file=sys.stderr,
        )
        sys.exit(1)
    except Exception as e:
        print(f"\nError: {e}", file=sys.stderr)
        sys.exit(1)

    # If user selected a model, print and copy to clipboard
    if selected:
        print(f"\n{selected}")

        if copy_to_clipboard(selected):
            print("✓ Copied to clipboard", file=sys.stderr)
        else:
            print(
                "⚠ Failed to copy to clipboard (pbcopy not available)", file=sys.stderr
            )

    # Show cache status
    timestamps = get_cache_timestamps()
    print("\nCache last updated:", file=sys.stderr)
    for provider, timestamp in timestamps.items():
        print(f"  {provider}: {time_ago(timestamp)}", file=sys.stderr)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nAborted.", file=sys.stderr)
        sys.exit(0)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
