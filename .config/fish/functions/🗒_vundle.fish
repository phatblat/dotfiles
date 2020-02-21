# https://github.com/VundleVim/Vundle.vim#about
#
# Compatible with Pathogen plugin bundles
# http://lepture.com/en/2012/vundle-vs-pathogen
#
# Sequencing
# - After: brew (python), pip (plugins)
function 🗒_vundle \
    --description='Installs and updates Vundle, plugin manager for Vim.'

    echo "🗒 Vundle"
    echo

    # Source repos
    set -l vim_dev          ~/dev/vim
    set -l vim_autoload     ~/.vim/autoload
    set -l vim_bundle_dir   ~/.vim/bundle

    createdirs $vim_autoload $vim_bundle_dir $vim_dev

    set -l vundle_dir       $vim_bundle_dir/Vundle.vim
    clone_or_pull $vundle_dir git@github.com:VundleVim/Vundle.vim.git

    # Install Vundle plugins
    vim +PluginInstall +qall

    # Install vim-plug plugins
    vim +PluginInstall +qall
end
