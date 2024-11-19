#
# bindings.fish
# https://brettterpstra.com/2019/11/11/fish-further-exploration/#bindings
#

# ⌃r
# fuzzy reverse isearch through command history
fzf --reverse -i --border history

# ⌥,
# repeats last token on the command line
bind \ez __re_extension

# ⌥z
# remove extension from word under/before cursor
bind \e, __prev_token
