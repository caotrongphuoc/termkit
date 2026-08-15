#!/usr/bin/env bash
# termkit installer.
# Shows a numbered menu, saves picks to configs/settings.conf, then applies.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF_FILE="$REPO_ROOT/configs/settings.conf"

# --- INI helpers -------------------------------------------------------------

# conf_get <section> <key> -> prints value (empty if missing).
conf_get() {
    local section="$1" key="$2"
    awk -v s="[$section]" -v k="$key" '
        $0 == s { in_s = 1; next }
        /^\[.*\]/ { in_s = 0; next }
        in_s && $0 ~ "^" k "=" {
            sub("^" k "=", "")
            print
            exit
        }
    ' "$CONF_FILE"
}

# conf_set <section> <key> <value>
# Updates the key in place. Creates the key or section if missing.
conf_set() {
    local section="$1" key="$2" value="$3"
    local tmp
    tmp=$(mktemp)
    awk -v s="[$section]" -v k="$key" -v v="$value" '
        BEGIN { in_s = 0; done = 0; sec_seen = 0 }
        /^\[.*\]/ {
            if (in_s && !done) { print k "=" v; done = 1 }
            in_s = ($0 == s)
            if (in_s) sec_seen = 1
            print
            next
        }
        in_s && !done && $0 ~ "^" k "=" {
            print k "=" v
            done = 1
            next
        }
        { print }
        END {
            if (in_s && !done) { print k "=" v; done = 1 }
            if (!sec_seen) { print ""; print s; print k "=" v }
        }
    ' "$CONF_FILE" > "$tmp"
    mv "$tmp" "$CONF_FILE"
}

# list_files <dir> <ext> -> prints basenames without extension, sorted.
list_files() {
    local dir="$1" ext="$2"
    (
        shopt -s nullglob
        local f
        for f in "$dir"/*."$ext"; do
            f="${f##*/}"
            printf '%s\n' "${f%.$ext}"
        done
    ) | sort
}

# --- menu helpers ------------------------------------------------------------

# pick_from_list <title> <current> <item...>
# Numbered picker. Prints picked item on stdout. Choice 0 keeps <current>.
pick_from_list() {
    local title="$1" current="$2"
    shift 2
    local items=("$@")
    local n=${#items[@]}
    local i choice

    while true; do
        # UI goes to stderr so $(pick_from_list ...) only captures the picked value.
        {
            clear
            printf '=== %s ===\n' "$title"
            printf 'current: %s\n\n' "$current"
            for i in "${!items[@]}"; do
                printf '  %d) %s\n' "$((i + 1))" "${items[$i]}"
            done
            printf '  0) back (keep %s)\n\n' "$current"
        } >&2
        read -rp 'choice: ' choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 0 ] && [ "$choice" -le "$n" ]; then
            if [ "$choice" -eq 0 ]; then
                printf '%s\n' "$current"
            else
                printf '%s\n' "${items[$((choice - 1))]}"
            fi
            return 0
        fi
        printf 'invalid choice, press Enter to try again' >&2
        read -r
    done
}

# yes_no <prompt> <current_bool> -> prints "true" or "false".
# Empty input keeps <current_bool>.
yes_no() {
    local prompt="$1" current="$2" ans hint
    if [ "$current" = "true" ]; then hint="[Y/n]"; else hint="[y/N]"; fi
    read -rp "$prompt $hint " ans
    case "$ans" in
        y|Y|yes|YES) printf 'true\n' ;;
        n|N|no|NO)   printf 'false\n' ;;
        *)           printf '%s\n' "$current" ;;
    esac
}

# --- submenus ----------------------------------------------------------------

submenu_theme() {
    local current picked
    current=$(conf_get theme name)
    local -a themes=()
    mapfile -t themes < <(list_files "$REPO_ROOT/configs/themes" conf)
    if [ ${#themes[@]} -eq 0 ]; then
        printf 'no themes found in configs/themes/, press Enter\n' >&2
        read -r
        return
    fi
    picked=$(pick_from_list "Pick a theme" "$current" "${themes[@]}")
    conf_set theme name "$picked"
}

submenu_font() {
    local current picked install_now current_install
    current=$(conf_get font name)
    current_install=$(conf_get font install)
    local -a fonts=("none")
    local -a found=()
    mapfile -t found < <(list_files "$REPO_ROOT/configs/fonts" ttf)
    fonts+=("${found[@]}")
    picked=$(pick_from_list "Pick a font" "$current" "${fonts[@]}")
    conf_set font name "$picked"
    if [ "$picked" != "none" ]; then
        install_now=$(yes_no "install this font to ~/.local/share/fonts?" "$current_install")
        conf_set font install "$install_now"
    else
        conf_set font install false
    fi
}

submenu_logo() {
    local current picked enable_now current_enable
    current=$(conf_get logo file)
    current_enable=$(conf_get logo enabled)
    local -a logos=("none")
    local -a found=()
    mapfile -t found < <(list_files "$REPO_ROOT/configs/logo" txt)
    logos+=("${found[@]}")
    picked=$(pick_from_list "Pick a logo" "$current" "${logos[@]}")
    conf_set logo file "$picked"
    if [ "$picked" != "none" ]; then
        enable_now=$(yes_no "print this logo on shell start?" "$current_enable")
        conf_set logo enabled "$enable_now"
    else
        conf_set logo enabled false
    fi
}

submenu_aliases() {
    local current picked
    current=$(conf_get aliases enabled)
    picked=$(yes_no "enable termkit aliases?" "$current")
    conf_set aliases enabled "$picked"
}

# --- apply (implemented in Part 6) ------------------------------------------

apply_all() {
    printf '\napply: not implemented yet, coming in the next step.\n'
    printf 'settings.conf has been saved with your picks.\n'
}

# --- main loop --------------------------------------------------------------

show_summary() {
    printf '=== termkit ===\n'
    printf 'current settings:\n'
    printf '  theme    = %s\n' "$(conf_get theme name)"
    printf '  font     = %s   (install: %s)\n' "$(conf_get font name)" "$(conf_get font install)"
    printf '  logo     = %s   (enabled: %s)\n' "$(conf_get logo file)" "$(conf_get logo enabled)"
    printf '  aliases  = %s\n' "$(conf_get aliases enabled)"
    printf '\n'
}

main_menu() {
    local choice
    while true; do
        clear
        show_summary
        printf '1) Change theme\n'
        printf '2) Change font\n'
        printf '3) Change logo\n'
        printf '4) Toggle aliases\n'
        printf '5) Apply and exit\n'
        printf '6) Quit without applying\n\n'
        read -rp 'choice: ' choice
        case "$choice" in
            1) submenu_theme ;;
            2) submenu_font ;;
            3) submenu_logo ;;
            4) submenu_aliases ;;
            5) apply_all; return 0 ;;
            6) printf 'no changes applied.\n'; return 0 ;;
            *) printf 'invalid choice, press Enter\n' >&2; read -r ;;
        esac
    done
}

main() {
    mkdir -p "$REPO_ROOT/configs/fonts"
    if [ ! -f "$CONF_FILE" ]; then
        printf 'settings.conf missing at %s\n' "$CONF_FILE" >&2
        exit 1
    fi
    main_menu
}

main "$@"
