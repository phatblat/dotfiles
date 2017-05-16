# Installs and updates Vundle, plugin manager for Vim.
# https://github.com/VundleVim/Vundle.vim#about
#
# Sequencing
# - After: brew (installed with node)
function 🗒__vundle
    echo "🗒  Vundle"
    echo

    set -l vim_bundle_dir ~/.vim/bundle
    set -l vundle_dir $vim_bundle_dir/Vundle.vim

    if not test -e $vundle_dir
        git clone git@github.com:VundleVim/Vundle.vim.git $vundle_dir
    else
        pushd $vundle_dir
        git pull
        popd
    end

    vim +PluginInstall +qall

    pushd $vim_bundle_dir/YouCompleteMe
    and ./install.py --clang-completer
    and popd
end
