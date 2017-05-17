# Powerline for Vim and terminal prompt. Powerline is a Python plugin installed
# by PIP, but it has some additional setup steps. Also, there's a separate
# project for powerline shell prompts.
#
# - https://github.com/powerline/powerline
# - https://powerline.readthedocs.io/en/latest/
# - https://github.com/banga/powerline-shell
# - https://github.com/powerline/fonts
# - https://computers.tutsplus.com/tutorials/getting-spiffy-with-powerline--cms-20740#highlighter_632634

# function fish_prompt
#     <path/to/powerline-shell.py> $status --shell bare ^/dev/null
# end
#
# Sequencing
# - After: brew (python), pip (powerline-status)
function ▶️__powerline
    echo "▶️  Powerline"
    echo

    set -l vim_dev          ~/dev/vim

    # Powerline Shell
    set -l ps_dir           $vim_dev/powerline-shell
    set -l powerline_shell  git@github.com:banga/powerline-shell.git
    set -l fork             git@github.com:phatblat/powerline-shell.git # custom
    clone_or_pull $ps_dir $fork custom

    # Generate the powerline-shell.py based on config.py
    pushd $ps_dir
    ./install.py
    popd

    # Powerline Fonts
    echo "Installing Powerline Fonts"
    set -l fonts_dir $vim_dev/powerline-fonts
    clone_or_pull $fonts_dir git@github.com:powerline/fonts.git
    eval $fonts_dir/install.sh
end
