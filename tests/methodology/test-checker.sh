#!/usr/bin/env bash
# SPDX-License-Identifier: MIT

set -eu

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"

"$repo_root/scripts/test-checker.sh"

