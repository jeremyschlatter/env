# {"deps": ["_1password-cli", "jq"]} #nix
# Show the structure of a 1Password item without revealing secret values.
# Usage: opcli-describe <item-name> [--account <account>]

set -euo pipefail

item="${1:?Usage: opcli-describe <item-name> [--account <account>]}"
shift

op item get "$item" --format json "$@" | jq '{
  title: .title,
  category: .category,
  vault: .vault.name,
  fields: [.fields[]? | {label, type, id, section: .section.label?}],
  urls: [.urls[]?.href],
}'
