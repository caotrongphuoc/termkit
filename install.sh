#!/usr/bin/env bash
# termkit installer. Reads configs/settings.conf and applies to bash or zsh.

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
CONF_FILE="$SCRIPT_DIR/configs/settings.conf"


# --- INI helpers -------------------------------------------------------------

# conf_get <section> <key> — print value, or empty if missing.
conf_get()
{
    local section=$1 key=$2
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

# conf_set <section> <key> <value> — update in place, create if missing.
conf_set()
{
    local section=$1 key=$2 value=$3
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

# _get <section> <key> <default> — conf_get with a fallback if empty.
_get()
{
    local v
    v=$(conf_get "$1" "$2")
    echo "${v:-$3}"
}


# --- config loader -----------------------------------------------------------

# load_settings — read settings.conf into shell variables.
load_settings()
{
    if [ ! -f "$CONF_FILE" ]; then
        echo "settings.conf missing at $CONF_FILE"
        exit 1
    fi

    shell_name=$(_get shell name bash)
    zsh_plugins=$(conf_get zsh plugins)
    theme_name=$(conf_get theme name)
    font_name=$(conf_get font name)
    font_install=$(conf_get font install)
    logo_file=$(conf_get logo file)
    logo_enabled=$(conf_get logo enabled)
    logo_fastfetch=$(_get logo use_fastfetch false)
    fastfetch_config=$(_get fastfetch config none)
    aliases_enabled=$(conf_get aliases enabled)
}


# --- actions -----------------------------------------------------------------

show_status()
{
    load_settings
    echo "=== termkit status ==="
    echo " settings file : $CONF_FILE"
    echo " shell         : $shell_name"
    [ "$shell_name" = "zsh" ] && echo " zsh plugins   : ${zsh_plugins:-(none)}"
    echo " theme         : $theme_name"
    echo " font          : $font_name  (install: $font_install)"
    echo " logo          : $logo_file  (enabled: $logo_enabled, fastfetch: $logo_fastfetch)"
    echo " fastfetch cfg : $fastfetch_config"
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

[zsh]
# plugins: space-separated list of oh-my-zsh plugin names, or empty.
#          When non-empty and shell=zsh, apply patches the plugins=(...)
#          line in ~/.zshrc before the oh-my-zsh source line.
#          Example: plugins=git zsh-syntax-highlighting zsh-autosuggestions
plugins=

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

[fastfetch]
# config: basename of a file in configs/fastfetch/*.jsonc, or 'none'
#         When set, apply overwrites ~/.config/fastfetch/config.jsonc with it.
config=none

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
        *) echo "unsupported shell: $shell_name (expected: bash or zsh)"; exit 1 ;;
    esac
}

apply_bash()
{
    local bashrc="$HOME/.bashrc"
    local backup="$HOME/.bashrc.termkit.bak"

    [ -f "$bashrc" ] || touch "$bashrc"
    if [ ! -f "$backup" ]; then
        cp "$bashrc" "$backup"
        echo "Backup created: $backup"
    fi

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

    _install_font
    _apply_fastfetch_config

    local logo_cmd=""
    [ -n "$logo_path" ] && logo_cmd=$(_render_logo_cmd "$logo_path")

    _strip_managed_block "$bashrc"
    _write_managed_block "$bashrc" "source \"$theme_file\""

    echo "Applied. Open a new shell (or run: source ~/.bashrc) to see changes."
}

# --- helpers -----------------------------------------------------------------

# _install_font — copy .ttf to ~/.local/share/fonts + fc-cache. No-op unless install=true.
_install_font()
{
    [ "$font_install" != "true" ] && return
    [ "$font_name" = "none" ] && return

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
}

# _fix_omz_perms — chmod g-w,o-w on oh-my-zsh dirs to silence compaudit. Idempotent.
_fix_omz_perms()
{
    [ -d "$HOME/.oh-my-zsh" ] || return

    local d fixed=0
    for d in \
        "$HOME/.oh-my-zsh" \
        "$HOME/.oh-my-zsh/custom" \
        "$HOME/.oh-my-zsh/custom/themes" \
        "$HOME/.oh-my-zsh/cache/completions" \
        "$HOME/.oh-my-zsh/custom/plugins"/*/; do
        [ -d "$d" ] || continue
        # -perm /022 = group-write or other-write bit set.
        if find "$d" -maxdepth 0 -perm /022 -print 2>/dev/null | grep -q .; then
            chmod g-w,o-w "$d" 2>/dev/null && fixed=$((fixed + 1))
        fi
    done
    [ "$fixed" -gt 0 ] && echo "Tightened $fixed oh-my-zsh dir(s) to silence compaudit"
}

# _strip_managed_block <file> — remove the block from BLOCK_START to BLOCK_END.
_strip_managed_block()
{
    sed -i "\|^${BLOCK_START}\$|,\|^${BLOCK_END}\$|d" "$1"
}

# _write_managed_block <file> <theme_line> — append managed block. Pass empty
# theme_line for oh-my-zsh themes (loaded via ZSH_THEME, not sourced here).
# Reads $logo_cmd and $aliases_path from the caller.
_write_managed_block()
{
    local file=$1 theme_line=$2
    {
        echo "$BLOCK_START"
        echo "# Generated by termkit. Do not edit by hand."
        [ -n "$theme_line" ] && echo "$theme_line"
        [ -n "$logo_cmd" ] && echo "$logo_cmd"
        [ -n "$aliases_path" ] && echo "source \"$aliases_path\""
        echo "$BLOCK_END"
    } >> "$file"
}

# _patch_zshrc_line <new_line> <match_regex> <label>
# Replace matching line in ~/.zshrc, or insert before oh-my-zsh source line. Warn if neither.
_patch_zshrc_line()
{
    local new=$1 pattern=$2 label=$3
    local zshrc="$HOME/.zshrc"
    local tmp
    tmp=$(mktemp)

    if grep -q "$pattern" "$zshrc"; then
        awk -v new="$new" -v pat="$pattern" '$0 ~ pat { print new; next } { print }' "$zshrc" > "$tmp" && mv "$tmp" "$zshrc"
        echo "Updated $label to '$new' in $zshrc"
    elif grep -qF "source \$ZSH/oh-my-zsh.sh" "$zshrc"; then
        awk -v new="$new" '/^source \$ZSH\/oh-my-zsh.sh/ && !ins { print new; ins=1 } { print }' "$zshrc" > "$tmp" && mv "$tmp" "$zshrc"
        echo "Inserted '$new' before oh-my-zsh source line in $zshrc"
    else
        rm -f "$tmp"
        echo "WARNING: no $label line or oh-my-zsh source in $zshrc. Add manually: $new"
    fi
}

# _apply_fastfetch_config — overwrite ~/.config/fastfetch/config.jsonc. No-op if config=none.
_apply_fastfetch_config()
{
    [ "$fastfetch_config" = "none" ] && return
    local src="$SCRIPT_DIR/configs/fastfetch/$fastfetch_config.jsonc"
    if [ ! -f "$src" ]; then
        echo "fastfetch config not found: $src"
        exit 1
    fi
    mkdir -p "$HOME/.config/fastfetch"
    cp -f "$src" "$HOME/.config/fastfetch/config.jsonc"
    echo "Installed fastfetch config: $HOME/.config/fastfetch/config.jsonc"
}

# _render_logo_cmd <path> — print the shell line to display the logo (fastfetch or cat).
_render_logo_cmd()
{
    local path=$1
    if [ "$logo_fastfetch" = "true" ]; then
        if command -v fastfetch >/dev/null 2>&1; then
            printf 'fastfetch --logo "%s"\n' "$path"
            return
        fi
        echo "WARNING: use_fastfetch=true but fastfetch not found; falling back to cat" >&2
    fi
    printf 'cat "%s"\n' "$path"
}

# --- apply_zsh ---------------------------------------------------------------

apply_zsh()
{
    local zshrc="$HOME/.zshrc"
    local backup="$HOME/.zshrc.termkit.bak"

    [ -f "$zshrc" ] || touch "$zshrc"
    if [ ! -f "$backup" ]; then
        cp "$zshrc" "$backup"
        echo "Backup created: $backup"
    fi

    # Prefer standalone .zsh; fall back to .zsh-theme (oh-my-zsh).
    local theme_file="" is_omz_theme=0
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

    _install_font

    # oh-my-zsh themes: copy + patch ZSH_THEME (must be set before oh-my-zsh source line).
    if [ "$is_omz_theme" = "1" ]; then
        if [ -d "$HOME/.oh-my-zsh" ]; then
            local omz_custom="$HOME/.oh-my-zsh/custom/themes"
            mkdir -p "$omz_custom"
            cp -f "$theme_file" "$omz_custom/$theme_name.zsh-theme"
            echo "Installed oh-my-zsh theme: $omz_custom/$theme_name.zsh-theme"
            _patch_zshrc_line "ZSH_THEME=\"$theme_name\"" '^ZSH_THEME=' "ZSH_THEME"
        else
            echo "WARNING: ~/.oh-my-zsh not found. Install oh-my-zsh first, then re-run apply."
        fi
    fi

    [ -n "$zsh_plugins" ] && _patch_zshrc_line "plugins=($zsh_plugins)" '^plugins=' "plugins"

    _apply_fastfetch_config

    local logo_cmd=""
    [ -n "$logo_path" ] && logo_cmd=$(_render_logo_cmd "$logo_path")

    # Standalone .zsh gets sourced in the block; oh-my-zsh themes load via ZSH_THEME.
    local theme_line=""
    [ "$is_omz_theme" = "0" ] && theme_line="source \"$theme_file\""

    _strip_managed_block "$zshrc"
    _write_managed_block "$zshrc" "$theme_line"

    _fix_omz_perms

    echo "Applied. Open a new terminal (or 'exec zsh') to see changes."
}

# --- uninstall ---------------------------------------------------------------

uninstall_all()
{
    local bashrc="$HOME/.bashrc"
    local zshrc="$HOME/.zshrc"
    local backup_bash="$HOME/.bashrc.termkit.bak"
    local backup_zsh="$HOME/.zshrc.termkit.bak"
    local fonts_dir="$HOME/.local/share/fonts"
    local omz_themes="$HOME/.oh-my-zsh/custom/themes"
    local removed_any=0

    if [ -f "$bashrc" ] && grep -q "^${BLOCK_START}\$" "$bashrc" 2>/dev/null; then
        _strip_managed_block "$bashrc"
        echo "Removed termkit block from $bashrc"
        removed_any=1
    fi
    if [ -f "$zshrc" ] && grep -q "^${BLOCK_START}\$" "$zshrc" 2>/dev/null; then
        _strip_managed_block "$zshrc"
        echo "Removed termkit block from $zshrc"
        removed_any=1
    fi

    # Remove fonts whose basename matches a file we ship. Foreign fonts untouched.
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

    # Remove oh-my-zsh custom themes matching shipped basenames. Foreign themes untouched.
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

    # Remove fastfetch config only if content matches a shipped file byte-for-byte.
    local ff_config="$HOME/.config/fastfetch/config.jsonc"
    if [ -f "$ff_config" ] && [ -d "$SCRIPT_DIR/configs/fastfetch" ]; then
        local shipped
        for shipped in "$SCRIPT_DIR/configs/fastfetch"/*.jsonc; do
            [ -e "$shipped" ] || continue
            if cmp -s "$ff_config" "$shipped"; then
                rm -f "$ff_config"
                echo "Removed fastfetch config: $ff_config"
                removed_any=1
                break
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
    apply)     apply_all ;;
    uninstall) uninstall_all ;;
    status)    show_status ;;
    clean)     reset_settings ;;
    *)
        echo "Usage:"
        echo " $0 apply     : read settings.conf and apply to your shell rc"
        echo " $0 uninstall : remove termkit changes from ~/.bashrc and ~/.zshrc"
        echo " $0 status    : show current settings.conf values"
        echo " $0 clean     : reset settings.conf to defaults (backup kept)"
        ;;
esac
