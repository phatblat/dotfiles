# Special "local" pod install for KP Mobile.
function pil
    LOCAL=1 bundle exec pod install $argv
end
