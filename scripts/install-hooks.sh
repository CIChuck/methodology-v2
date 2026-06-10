#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -eu

repo_root="$(git rev-parse --show-toplevel)"
hook_path="$repo_root/.git/hooks/pre-commit"

cat > "$hook_path" <<'HOOK'
#!/usr/bin/env bash
set -eu

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

if [ -x scripts/methodology-guard.sh ]; then
  scripts/methodology-guard.sh --staged
else
  ./scripts/check-methodology.sh
fi
HOOK

chmod +x "$hook_path"

printf 'Installed GenDev pre-commit hook: %s\n' "$hook_path"
