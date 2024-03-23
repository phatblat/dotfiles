#
# bindings.fish
# https://brettterpstra.com/2019/11/11/fish-further-exploration/#bindings
#

# ⌥,
# repeats last token on the command line
bind \ez __re_extension

# ⌥z
# remove extension from word under/before cursor
bind \e, __prev_token
