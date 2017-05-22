# Installs and updates Vundle, plugin manager for Vim.
# https://github.com/VundleVim/Vundle.vim#about
#
# Compatible with Pathogen plugin bundles
# http://lepture.com/en/2012/vundle-vs-pathogen
#
# Sequencing
# - After: brew (python), pip (plugins)
function 🗒__vundle
    echo "🗒  Vundle"
    echo

    set -l vim_dev          ~/dev/vim
    set -l vim_autoload     ~/.vim/autoload
    set -l vim_bundle_dir   ~/.vim/bundle

    createdirs $vim_autoload $vim_bundle_dir $vim_dev

    set -l vundle_dir       $vim_bundle_dir/Vundle.vim
    clone_or_pull $vundle_dir git@github.com:VundleVim/Vundle.vim.git

    pushd $vim_bundle_dir/YouCompleteMe
    and ./install.py --clang-completer
    and popd

    # Vim-plug
    set -l plug_dir         $vim_dev/vim-plug
    set -l plug_autoload    $vim_autoload/plug.vim
    clone_or_pull $plug_dir git@github.com:junegunn/vim-plug.git

    # Symlink the plug.vim file into the autoload dir
    if not test -L $plug_autoload
        ln -sfv $plug_dir/plug.vim $plug_autoload
    end

    # Install plugins
    vim +PluginInstall +qall
end
