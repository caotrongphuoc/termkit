# Minimal bash prompt: cyan user, green host, blue path.
# ANSI 8-color palette: 30 black 31 red 32 green 33 yellow 34 blue 35 magenta 36 cyan 37 white.
# TWEAK: swap 36/32/34 for other colors. Wrap non-printing bytes in \[...\].
# For 256-color, see ak.bash.
PS1='\[\e[36m\]\u\[\e[0m\]@\[\e[32m\]\h\[\e[0m\]:\[\e[34m\]\w\[\e[0m\]\$ '
