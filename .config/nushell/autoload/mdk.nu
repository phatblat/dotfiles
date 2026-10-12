# mdk - Quick nav to MDK
export def --env mdk [platform: string = ""] {
    let base = ($env.HOME | path join "dev" "mdk")
    let target = if ($platform == "i") or ($platform == "ios") {
        ($base | path join "ios")
    } else if ($platform == "a") or ($platform == "android") {
        ($base | path join "android")
    } else {
        $base
    }
    cd $target
}
