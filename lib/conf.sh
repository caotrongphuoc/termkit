#!/usr/bin/env bash
# INI-ish reader and writer for configs/settings.conf.
#
# The caller sets CONF_FILE to the path of the file to operate on
# before calling any function here.
#
# Section and key names are treated as simple identifiers
# (letters, digits, underscore). Values are stored as raw text
# after the '=' up to end of line.

# conf_get <section> <key>
# Prints the value on stdout. Prints nothing if the key is missing.
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
# Writes the key inside the section. Creates the key if the section
# exists but the key does not. Creates both if the section is missing.
# The rest of the file is preserved.
conf_set() {
    local section="$1" key="$2" value="$3"
    local tmp
    tmp=$(mktemp)
    awk -v s="[$section]" -v k="$key" -v v="$value" '
        BEGIN { in_s = 0; done = 0; sec_seen = 0 }
        /^\[.*\]/ {
            # Leaving the target section without writing the key:
            # insert it just before the next section header.
            if (in_s && !done) {
                print k "=" v
                done = 1
            }
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
            # File ended still inside the target section without writing.
            if (in_s && !done) {
                print k "=" v
                done = 1
            }
            # Target section never appeared: append it at the end.
            if (!sec_seen) {
                print ""
                print s
                print k "=" v
            }
        }
    ' "$CONF_FILE" > "$tmp"
    mv "$tmp" "$CONF_FILE"
}

# conf_list_files <dir> <ext>
# Prints basenames (without the extension) of *.<ext> files in <dir>, sorted.
# Prints nothing if the directory has no matching files.
conf_list_files() {
    local dir="$1" ext="$2"
    # Subshell so nullglob does not leak to the caller.
    (
        shopt -s nullglob
        local f
        for f in "$dir"/*."$ext"; do
            f="${f##*/}"
            printf '%s\n' "${f%.$ext}"
        done
    ) | sort
}
