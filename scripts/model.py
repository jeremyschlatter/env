# {"deps": ["fzf"]} #nix
# flake8: noqa: E501

"""
LLM Model Browser

Quick reference tool for looking up LLM model names across providers.
Uses cached results for instant display, updates in background.

Usage:
  ./model-browser.py          # Browse models
  ./model-browser.py list     # Print all models (for piping to grep/rg)
  ./model-browser.py keys     # Manage API keys
  ./model-browser.py help     # Show help

Requirements:
- Python 3.6+
- fzf (install with: brew install fzf)
"""

import json
import os
import sys
import subprocess
import urllib.request
import urllib.error
from pathlib import Path
from datetime import datetime, timezone
import getpass
import concurrent.futures
from typing import Dict, List, Optional, Any

# Configuration
CACHE_DIR = Path.home() / ".cache" / "llm-model-browser"
KEYS_CACHE_PATH = CACHE_DIR / "keys.json"

KEY_CONFIGS = {
    "openai": {
        "env_var": "OPENAI_API_KEY",
        "description": "OpenAI API Key",
        "optional": False,
    },
    "anthropic": {
        "env_var": "ANTHROPIC_API_KEY",
        "description": "Anthropic API Key",
        "optional": False,
    },
    "google": {
        "env_var": ["GOOGLE_API_KEY", "GEMINI_API_KEY"],
        "description": "Google/Gemini API Key",
        "optional": False,
    },
    "xai": {
        "env_var": "XAI_API_KEY",
        "description": "xAI API Key",
        "optional": False,
    },
    "openrouter": {
        "env_var": "OPENROUTER_API_KEY",
        "description": "OpenRouter API Key",
        "optional": True,
    },
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


# Read keys cache
def read_keys_cache() -> Dict[str, str]:
    try:
        with open(KEYS_CACHE_PATH, "r") as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return {}


# Write keys cache
def write_keys_cache(keys: Dict[str, str]):
    ensure_cache_dir()
    with open(KEYS_CACHE_PATH, "w") as f:
        json.dump(keys, f, indent=2)
    # Set permissions to user-only (0600)
    os.chmod(KEYS_CACHE_PATH, 0o600)


# Get API key for a provider
def get_api_key(provider: str) -> Optional[str]:
    config = KEY_CONFIGS.get(provider)
    if not config:
        return None

    # Check cache first
    keys_cache = read_keys_cache()
    if provider in keys_cache:
        return keys_cache[provider]

    # Check environment variables
    env_vars = config["env_var"]
    if isinstance(env_vars, str):
        env_vars = [env_vars]

    for env_var in env_vars:
        value = os.environ.get(env_var)
        if value:
            return value

    return None


# Manage API keys
def manage_keys():
    print("API Key Management\n")
    print("This will prompt you to enter API keys for each provider.")
    print("Your input will be hidden for security.")
    print("Press Enter to skip a provider or to keep an existing key.")
    print(f"Keys will be stored in: {KEYS_CACHE_PATH}")
    print("")

    keys_cache = read_keys_cache()
    new_keys = keys_cache.copy()

    for provider, config in KEY_CONFIGS.items():
        current_key = get_api_key(provider)
        has_key = "✓" if current_key else "✗"
        optional_text = " (optional)" if config["optional"] else ""

        print(f"\n{has_key} {config['description']}{optional_text}")
        if current_key:
            masked = current_key[:8] + "..." + current_key[-4:]
            print(f"  Current: {masked}")

        try:
            answer = getpass.getpass("  Enter key (or press Enter to skip): ")

            if answer:
                new_keys[provider] = answer
                print("  ✓ Updated")
            elif not current_key and not config["optional"]:
                print("  ⚠ Warning: This key is required for the provider to work")
        except KeyboardInterrupt:
            print("\n\nAborted.")
            sys.exit(0)

    write_keys_cache(new_keys)
    print("\n✓ Keys saved!")
    print(f"  Location: {KEYS_CACHE_PATH}")
    print("  Permissions: User read/write only (0600)")
    print('\nYou can now run "./model-browser.py" to browse models.')


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

    if not api_key:
        raise Exception("No API key available")

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
        api_key = get_api_key(provider)
        if not api_key:
            key_config = KEY_CONFIGS.get(provider)
            if key_config and not key_config["optional"]:
                return {
                    "provider": provider,
                    "success": False,
                    "error": "No API key configured",
                }
            return {
                "provider": provider,
                "success": False,
                "error": "Skipped (optional)",
            }

        models = fetch_models(provider, config)
        write_cache(provider, models)
        return {"provider": provider, "success": True, "count": len(models)}
    except Exception as e:
        return {"provider": provider, "success": False, "error": str(e)}


# Get all cached models
def get_all_cached_models() -> List[str]:
    all_models = []

    for provider in KEY_CONFIGS.keys():
        cache = read_cache(provider)
        if cache and "models" in cache:
            for model in cache["models"]:
                all_models.append(f"{provider}/{model}")

    return all_models


# Get cache timestamps
def get_cache_timestamps() -> Dict[str, datetime]:
    timestamps = {}

    for provider in KEY_CONFIGS.keys():
        cache = read_cache(provider)
        if cache and "timestamp" in cache:
            timestamps[provider] = datetime.fromisoformat(cache["timestamp"])

    return timestamps


# Update all caches in parallel
def update_all_caches() -> List[Dict[str, Any]]:
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

    if subcommand == "keys":
        manage_keys()
        return

    if subcommand == "list":
        ensure_cache_dir()
        update_all_caches()
        for model in get_all_cached_models():
            print(model)
        return

    if subcommand in ["help", "--help", "-h"]:
        print("LLM Model Browser - Quick reference for LLM model names\n")
        print("Usage:")
        print("  ./model-browser.py          Browse models with fzf")
        print("  ./model-browser.py list     Print all models (one per line)")
        print("  ./model-browser.py keys     Manage API keys")
        print("  ./model-browser.py help     Show this help\n")
        print("Keys are read from:")
        print(f"  1. Cache file: {KEYS_CACHE_PATH}")
        print("  2. Environment variables (fallback)")
        print("\nSupported providers: OpenAI, Anthropic, Google, xAI, OpenRouter")
        return

    if subcommand:
        print(f"Unknown subcommand: {subcommand}", file=sys.stderr)
        print('Run "./model-browser.py help" for usage information.', file=sys.stderr)
        sys.exit(1)

    ensure_cache_dir()

    # Get cached models immediately
    models = get_all_cached_models()

    if not models:
        print("No cached models found. Fetching from APIs...", file=sys.stderr)
        print(
            '(Run "./model-browser.py keys" to set up API keys if needed)\n',
            file=sys.stderr,
        )
        results = update_all_caches()

        # Check results
        successful = [r for r in results if r["success"]]
        if not successful:
            print("\nFailed to fetch models from any provider.", file=sys.stderr)
            print(
                'Run "./model-browser.py keys" to set up your API keys.',
                file=sys.stderr,
            )
            sys.exit(1)

        models = get_all_cached_models()

    # Start background update in a thread
    with concurrent.futures.ThreadPoolExecutor(max_workers=1) as executor:
        update_future = executor.submit(update_all_caches)

        # Pipe to fzf
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

        # Wait for background updates to complete
        update_future.result()

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
