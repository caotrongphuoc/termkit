#!/usr/bin/env bash
# INI-ish reader and writer for configs/settings.conf.
# Filled in during Part 3.

# ----- public API (to be implemented) -----------------------------------------
# conf_get <section> <key>              -> prints value
# conf_set <section> <key> <value>      -> updates the file in place
# conf_list_files <dir> <ext>           -> prints file basenames in <dir> with <ext>
