# Powerline for Vim and terminal prompt. Powerline is a Python plugin installed
# by PIP, but it has some additional setup steps. Also, there's a separate
# project for powerline shell prompts.
#
# - https://github.com/powerline/powerline
# - https://powerline.readthedocs.io/en/latest/
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
    set -l powerline_config ~/.config/powerline
    createdirs $vim_dev

    # Powerline plugin (powerline-status)
    set -l python_packages /usr/local/lib/python2.7/site-packages
    set -l config_path $python_packages/powerline/config_files

    if not test -d $powerline_config
        echo "Copying $config_path -> $powerline_config"
        cp -R $config_path $powerline_config
    end

    # Powerline Fonts
    # - https://github.com/powerline/fonts
    echo "Installing Powerline Fonts"
    set -l fonts_dir $vim_dev/powerline-fonts
    clone_or_pull $fonts_dir git@github.com:powerline/fonts.git
    eval $fonts_dir/install.sh

    # Powerline Shell
    # - https://github.com/banga/powerline-shell
    set -l ps_dir           $vim_dev/powerline-shell
    set -l powerline_shell  git@github.com:banga/powerline-shell.git
    set -l fork             git@github.com:phatblat/powerline-shell.git # custom
    clone_or_pull $ps_dir $fork custom

    # Generate the powerline-shell.py based on config.py
    pushd $ps_dir
    ./install.py
    popd
end
