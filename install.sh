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

    shell_name=$(conf_get shell name)
    # Default to bash when [shell] is missing (backward compat with v0.1 files).
    if [ -z "$shell_name" ]; then
        shell_name="bash"
    fi

    theme_name=$(conf_get theme name)
    font_name=$(conf_get font name)
    font_install=$(conf_get font install)
    logo_file=$(conf_get logo file)
    logo_enabled=$(conf_get logo enabled)
    logo_fastfetch=$(conf_get logo use_fastfetch)
    # Default to false when the field is missing (backward compat with v0.1 files).
    if [ -z "$logo_fastfetch" ]; then
        logo_fastfetch="false"
    fi
    aliases_enabled=$(conf_get aliases enabled)
}


# --- actions -----------------------------------------------------------------

show_status()
{
    load_settings
    echo "=== termkit status ==="
    echo " settings file : $CONF_FILE"
    echo " shell         : $shell_name"
    echo " theme         : $theme_name"
    echo " font          : $font_name  (install: $font_install)"
    echo " logo          : $logo_file  (enabled: $logo_enabled, fastfetch: $logo_fastfetch)"
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
# Comments start with '#'. Values are: key=value under [sections].

[shell]
# name: bash | zsh
name=bash

[theme]
# name: basename of a file in configs/themes/<shell>/
#       bash: matches <name>.bash
#       zsh:  matches <name>.zsh (standalone) or <name>.zsh-theme (oh-my-zsh)
name=default

[font]
# name: basename of a file in configs/fonts/*.ttf, or 'none'
name=none
# install: true = copy the .ttf to ~/.local/share/fonts and refresh cache
install=false

[logo]
# enabled: true = print the logo on shell start
enabled=false
# file: basename of a file in configs/logo/*.txt, or 'none'
file=none
# use_fastfetch: true = print via `fastfetch --logo` (falls back to `cat` if missing)
use_fastfetch=false

[aliases]
# enabled: true = source configs/aliases.sh on shell start
enabled=false
EOF
    echo "Settings reset to defaults at $CONF_FILE"
}

BLOCK_START="# >>> termkit start >>>"
BLOCK_END="# <<< termkit end <<<"

apply_all()
{
    load_settings
    case "$shell_name" in
        bash) apply_bash ;;
        zsh)  apply_zsh ;;
        *)
            echo "unsupported shell: $shell_name (expected: bash or zsh)"
            exit 1
            ;;
    esac
}

apply_bash()
{
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
    local theme_file="$SCRIPT_DIR/configs/themes/bash/$theme_name.bash"
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

    # Decide how to print the logo: fastfetch if requested and available, else cat.
    local logo_cmd=""
    if [ -n "$logo_path" ]; then
        logo_cmd=$(_render_logo_cmd "$logo_path")
    fi

    # Strip any existing termkit block so re-apply does not stack duplicates.
    sed -i "\|^${BLOCK_START}\$|,\|^${BLOCK_END}\$|d" "$bashrc"

    # Append the freshly generated block.
    {
        echo "$BLOCK_START"
        echo "# Generated by termkit. Do not edit by hand."
        echo "source \"$theme_file\""
        if [ -n "$logo_cmd" ]; then
            echo "$logo_cmd"
        fi
        if [ -n "$aliases_path" ]; then
            echo "source \"$aliases_path\""
        fi
        echo "$BLOCK_END"
    } >> "$bashrc"

    echo "Applied. Open a new shell (or run: source ~/.bashrc) to see changes."
}

# _render_logo_cmd <path>
# Prints the shell command that should be embedded in the managed block to
# display the logo. Uses fastfetch when requested and installed, else cat.
_render_logo_cmd()
{
    local path="$1"
    if [ "$logo_fastfetch" = "true" ]; then
        if command -v fastfetch >/dev/null 2>&1; then
            printf 'fastfetch --logo "%s"\n' "$path"
            return
        fi
        echo "WARNING: use_fastfetch=true but fastfetch not found; falling back to cat" >&2
    fi
    printf 'cat "%s"\n' "$path"
}

apply_zsh()
{
    local zshrc="$HOME/.zshrc"
    local backup="$HOME/.zshrc.termkit.bak"

    if [ ! -f "$zshrc" ]; then
        touch "$zshrc"
    fi

    if [ ! -f "$backup" ]; then
        cp "$zshrc" "$backup"
        echo "Backup created: $backup"
    fi

    # Locate the theme. Prefer standalone (.zsh); fall back to oh-my-zsh (.zsh-theme).
    local theme_file=""
    local is_omz_theme=0
    if [ -f "$SCRIPT_DIR/configs/themes/zsh/$theme_name.zsh" ]; then
        theme_file="$SCRIPT_DIR/configs/themes/zsh/$theme_name.zsh"
    elif [ -f "$SCRIPT_DIR/configs/themes/zsh/$theme_name.zsh-theme" ]; then
        theme_file="$SCRIPT_DIR/configs/themes/zsh/$theme_name.zsh-theme"
        is_omz_theme=1
    else
        echo "zsh theme not found: configs/themes/zsh/$theme_name.zsh or .zsh-theme"
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

    # Install the font if requested (same mechanism as bash).
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

    # For oh-my-zsh themes: copy into custom themes and remind the user.
    # We do NOT set ZSH_THEME automatically because it must be set BEFORE
    # 'source $ZSH/oh-my-zsh.sh' in ~/.zshrc, and our block sits at the end.
    if [ "$is_omz_theme" = "1" ]; then
        if [ -d "$HOME/.oh-my-zsh" ]; then
            local omz_custom="$HOME/.oh-my-zsh/custom/themes"
            mkdir -p "$omz_custom"
            cp -f "$theme_file" "$omz_custom/$theme_name.zsh-theme"
            echo "Installed oh-my-zsh theme: $omz_custom/$theme_name.zsh-theme"
            echo "NOTE: edit ~/.zshrc and set ZSH_THEME=\"$theme_name\" BEFORE the oh-my-zsh source line."
        else
            echo "WARNING: ~/.oh-my-zsh not found. Install oh-my-zsh first, then re-run apply."
        fi
    fi

    local logo_cmd=""
    if [ -n "$logo_path" ]; then
        logo_cmd=$(_render_logo_cmd "$logo_path")
    fi

    # Strip any existing termkit block, then append a fresh one.
    sed -i "\|^${BLOCK_START}\$|,\|^${BLOCK_END}\$|d" "$zshrc"
    {
        echo "$BLOCK_START"
        echo "# Generated by termkit. Do not edit by hand."
        # Standalone themes get sourced here. Oh-my-zsh themes are loaded
        # via ZSH_THEME earlier in ~/.zshrc, so we do not source them here.
        if [ "$is_omz_theme" = "0" ]; then
            echo "source \"$theme_file\""
        fi
        if [ -n "$logo_cmd" ]; then
            echo "$logo_cmd"
        fi
        if [ -n "$aliases_path" ]; then
            echo "source \"$aliases_path\""
        fi
        echo "$BLOCK_END"
    } >> "$zshrc"

    echo "Applied. Open a new terminal to see changes."
    echo "  (if your login shell is still bash, run 'zsh' — 'source ~/.zshrc' from bash will fail because oh-my-zsh refuses to load under bash)"
}

uninstall_all()
{
    local bashrc="$HOME/.bashrc"
    local zshrc="$HOME/.zshrc"
    local backup_bash="$HOME/.bashrc.termkit.bak"
    local backup_zsh="$HOME/.zshrc.termkit.bak"
    local fonts_dir="$HOME/.local/share/fonts"
    local omz_themes="$HOME/.oh-my-zsh/custom/themes"
    local removed_any=0

    # Strip the managed block from ~/.bashrc if present.
    if [ -f "$bashrc" ] && grep -q "^${BLOCK_START}\$" "$bashrc" 2>/dev/null; then
        sed -i "\|^${BLOCK_START}\$|,\|^${BLOCK_END}\$|d" "$bashrc"
        echo "Removed termkit block from $bashrc"
        removed_any=1
    fi

    # Strip the managed block from ~/.zshrc if present.
    if [ -f "$zshrc" ] && grep -q "^${BLOCK_START}\$" "$zshrc" 2>/dev/null; then
        sed -i "\|^${BLOCK_START}\$|,\|^${BLOCK_END}\$|d" "$zshrc"
        echo "Removed termkit block from $zshrc"
        removed_any=1
    fi

    # Remove any font under ~/.local/share/fonts whose basename matches
    # a file we ship in configs/fonts. We do not touch fonts from elsewhere.
    if [ -d "$fonts_dir" ]; then
        local removed_font=0 name
        local -a shipped_fonts=()
        mapfile -t shipped_fonts < <(
            cd "$SCRIPT_DIR/configs/fonts" 2>/dev/null || exit
            shopt -s nullglob
            for f in *.ttf; do printf '%s\n' "$f"; done
        )
        for name in "${shipped_fonts[@]}"; do
            if [ -f "$fonts_dir/$name" ]; then
                rm -f "$fonts_dir/$name"
                echo "Removed font: $fonts_dir/$name"
                removed_font=1
                removed_any=1
            fi
        done
        if [ "$removed_font" -eq 1 ] && command -v fc-cache >/dev/null 2>&1; then
            fc-cache -f >/dev/null 2>&1
            echo "Refreshed font cache"
        fi
    fi

    # Remove any oh-my-zsh custom theme whose basename matches a .zsh-theme
    # we ship in configs/themes/zsh. Themes from elsewhere are left alone.
    if [ -d "$omz_themes" ]; then
        local name
        local -a shipped_omz=()
        mapfile -t shipped_omz < <(
            cd "$SCRIPT_DIR/configs/themes/zsh" 2>/dev/null || exit
            shopt -s nullglob
            for f in *.zsh-theme; do printf '%s\n' "$f"; done
        )
        for name in "${shipped_omz[@]}"; do
            if [ -f "$omz_themes/$name" ]; then
                rm -f "$omz_themes/$name"
                echo "Removed oh-my-zsh theme: $omz_themes/$name"
                removed_any=1
            fi
        done
    fi

    if [ "$removed_any" -eq 1 ]; then
        echo "Uninstall complete."
        [ -f "$backup_bash" ] && echo "  bashrc backup kept at: $backup_bash"
        [ -f "$backup_zsh"  ] && echo "  zshrc backup kept at:  $backup_zsh"
    else
        echo "Nothing to uninstall."
    fi
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
