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
    if is_mac
        set -l python_packages /usr/local/lib/python3.7/site-packages
    else
        set -l python_packages /home/linuxbrew/.linuxbrew/lib/python3.7/site-packages
    end
    set -l config_path $python_packages/powerline/config_files

    if not test -d $powerline_config
        echo "Copying $config_path -> $powerline_config"
        cp -R $config_path $powerline_config
    end

    echo "Installing Powerline Fonts"
    if is_mac
        set -l font_dir ~/Library/Fonts/
        createdirs $font_dir

        # Powerline Fonts
        # - https://github.com/powerline/fonts
        set -l fonts_dir $vim_dev/powerline-fonts
        clone_or_pull $fonts_dir git@github.com:powerline/fonts.git
        eval $fonts_dir/install.sh
    else if is_linux
        sudo apt-get install fonts-powerline
    end
end
