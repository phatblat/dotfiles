function brew_core \
    --description 'Quick nav to homebrew-core dir'

    if is_arm
        pushd (brew_home)/Library/Taps/homebrew/homebrew-core/Formula
    else
        pushd (brew_home)/Homebrew/Library/Taps/homebrew/homebrew-core/Formula
    end
end
