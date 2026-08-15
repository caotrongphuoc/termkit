# Default bash theme: plain uncolored prompt.
# Format: user@host:path$
#
# PS1 escape codes used here:
#   \u   current username
#   \h   short hostname
#   \w   full working directory (with ~ for $HOME)
#   \$   '$' for regular user, '#' for root
#
# See `man bash` -> PROMPTING section for the full escape list.
PS1='\u@\h:\w\$ '
