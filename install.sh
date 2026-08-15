#!/usr/bin/env bash
# termkit installer.
# Reads configs/settings.conf and applies terminal customization to bash.

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
CONF_FILE="$SCRIPT_DIR/configs/settings.conf"


# --- INI helpers -------------------------------------------------------------

# conf_get <section> <key> -> prints value (empty if missing).
conf_get()
{
    local section=$1
    local key=$2
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
conf_set()
{
    local section=$1
    local key=$2
    local value=$3
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


# --- config loader -----------------------------------------------------------

# load_settings
# Reads settings.conf into shell variables used by the action functions.
load_settings()
{
    if [ ! -f "$CONF_FILE" ]; then
        echo "settings.conf missing at $CONF_FILE"
        exit 1
    fi

    theme_name=$(conf_get theme name)
    font_name=$(conf_get font name)
    font_install=$(conf_get font install)
    logo_file=$(conf_get logo file)
    logo_enabled=$(conf_get logo enabled)
    aliases_enabled=$(conf_get aliases enabled)
}


# --- actions -----------------------------------------------------------------

show_status()
{
    load_settings
    echo "=== termkit status ==="
    echo " settings file : $CONF_FILE"
    echo " theme         : $theme_name"
    echo " font          : $font_name  (install: $font_install)"
    echo " logo          : $logo_file  (enabled: $logo_enabled)"
    echo " aliases       : $aliases_enabled"
}

reset_settings()
{
    if [ -f "$CONF_FILE" ]; then
        echo "Backup old settings to $CONF_FILE.bak"
        cp "$CONF_FILE" "$CONF_FILE.bak"
    fi

    cat > "$CONF_FILE" <<'EOF'
# termkit state file.
# Edit values below then run: ./install.sh apply

[theme]
name=default

[font]
name=none
install=false

[logo]
enabled=false
file=none

[aliases]
enabled=false
EOF
    echo "Settings reset to defaults at $CONF_FILE"
}

BLOCK_START="# >>> termkit start >>>"
BLOCK_END="# <<< termkit end <<<"

apply_all()
{
    load_settings

    local bashrc="$HOME/.bashrc"
    local backup="$HOME/.bashrc.termkit.bak"

    # Make sure ~/.bashrc exists so we always have a file to append to.
    if [ ! -f "$bashrc" ]; then
        touch "$bashrc"
    fi

    # Keep a one-time backup of the original bashrc.
    if [ ! -f "$backup" ]; then
        cp "$bashrc" "$backup"
        echo "Backup created: $backup"
    fi

    # Verify the referenced files exist before touching bashrc.
    local theme_file="$SCRIPT_DIR/configs/themes/$theme_name.conf"
    if [ ! -f "$theme_file" ]; then
        echo "theme file not found: $theme_file"
        exit 1
    fi

    local logo_path=""
    if [ "$logo_enabled" = "true" ] && [ "$logo_file" != "none" ]; then
        logo_path="$SCRIPT_DIR/configs/logo/$logo_file.txt"
        if [ ! -f "$logo_path" ]; then
            echo "logo file not found: $logo_path"
            exit 1
        fi
    fi

    local aliases_path=""
    if [ "$aliases_enabled" = "true" ]; then
        aliases_path="$SCRIPT_DIR/configs/aliases.sh"
        if [ ! -f "$aliases_path" ]; then
            echo "aliases file not found: $aliases_path"
            exit 1
        fi
    fi

    # Install the font if requested. Safe to re-run.
    if [ "$font_install" = "true" ] && [ "$font_name" != "none" ]; then
        local font_path="$SCRIPT_DIR/configs/fonts/$font_name.ttf"
        if [ ! -f "$font_path" ]; then
            echo "font file not found: $font_path"
            exit 1
        fi
        mkdir -p "$HOME/.local/share/fonts"
        cp -f "$font_path" "$HOME/.local/share/fonts/"
        echo "Installed font: $font_name.ttf"
        if command -v fc-cache >/dev/null 2>&1; then
            fc-cache -f >/dev/null 2>&1
            echo "Refreshed font cache"
        else
            echo "fc-cache not found, skipping cache refresh"
        fi
    fi

    # Strip any existing termkit block so re-apply does not stack duplicates.
    sed -i "\|^${BLOCK_START}\$|,\|^${BLOCK_END}\$|d" "$bashrc"

    # Append the freshly generated block.
    {
        echo "$BLOCK_START"
        echo "# Generated by termkit. Do not edit by hand."
        echo "source \"$theme_file\""
        if [ -n "$logo_path" ]; then
            echo "cat \"$logo_path\""
        fi
        if [ -n "$aliases_path" ]; then
            echo "source \"$aliases_path\""
        fi
        echo "$BLOCK_END"
    } >> "$bashrc"

    echo "Applied. Open a new shell (or run: source ~/.bashrc) to see changes."
}

uninstall_all()
{
    echo "uninstall: not implemented yet, coming in a later step."
}


# --- dispatch ----------------------------------------------------------------

case "$1" in
    apply)
        apply_all
        ;;
    uninstall)
        uninstall_all
        ;;
    status)
        show_status
        ;;
    clean)
        reset_settings
        ;;
    *)
        echo "Usage:"
        echo " $0 apply     : read settings.conf and apply to ~/.bashrc"
        echo " $0 uninstall : remove termkit changes from ~/.bashrc"
        echo " $0 status    : show current settings.conf values"
        echo " $0 clean     : reset settings.conf to defaults (backup kept)"
        ;;
esac
