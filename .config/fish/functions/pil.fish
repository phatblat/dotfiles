# Special "local" pod install for KP Mobile.
# @see pul
function pil
    LOCAL=1 bundle exec "pod install $argv"
end
