#!/usr/bin/env bash
# termkit installer entry point.
# v0.1 flow: show a menu, save picks to configs/settings.conf, then apply.

set -euo pipefail

# Resolve the repo root so the script works from any cwd.
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ----- library sourcing -------------------------------------------------------
# shellcheck source=lib/conf.sh
# shellcheck source=lib/menu.sh
# shellcheck source=lib/apply.sh

# ----- main -------------------------------------------------------------------
main() {
    # Ensure folders that ship empty still exist at runtime.
    mkdir -p "$REPO_ROOT/configs/fonts"

    # Menu loop and apply call go here in Part 5 / Part 6.
    echo "termkit: not implemented yet"
}

main "$@"
