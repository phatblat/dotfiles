# rustup environment for tcsh
if ( $?PATH ) then
    if ( "$PATH" !~ *$HOME/.cargo/bin* ) then
        setenv PATH "$HOME/.cargo/bin:$PATH"
    endif
else
    setenv PATH "$HOME/.cargo/bin"
endif
