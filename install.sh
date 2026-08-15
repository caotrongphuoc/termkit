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

apply_all()
{
    load_settings
    echo "apply: not implemented yet, coming in the next step."
    echo "Current settings that would be applied:"
    show_status
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
