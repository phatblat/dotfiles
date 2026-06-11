# Dependencies:
#   functions: error-msg masshow
#   builtins:  path join path type is-empty
#   externals: hostname rm ln

# Creates or removes a symlink from a Xcode DerivedData mas debug build into ~/bin, hostname-dispatched
export def maslink [remove?: string] {
    let derived_data = ($env.HOME | path join "Library" "Developer" "Xcode" "DerivedData")

    let hostname = (^hostname | str trim)
    let folder_name = match $hostname {
        "DTO-A017"         => "mas-euqirdsvwusoxnahudunkycvsjgn"
        "protop"           => "mas-euqirdsvwusoxnahudunkycvsjgn"
        "tredecim"         => "mas-crebdnsdmyoxeobfcrozyiypxcpm"
        "tredecim-bigsur"  => "mas-aqgkhlyqitpqytcdqdncgnkvubmq"
        "greymatter"       => "mas-gbyvetvfnsdaiigwwzwjvnbutabs"
        "octodec"          => "mas-aqppolouacncbpdkiaiefddzzlfq"
        _ => {
            error-msg $"This device is not set up for this command. Add the mas folder to the maslink function."
            ^ls $derived_data
            return
        }
    }

    let source = ($derived_data | path join $folder_name "Build" "Products" "Debug" "mas")
    let destination = ($env.HOME | path join "bin" "mas")

    # Delete the symlink if the $remove parameter contains anything
    if ($remove != null and not ($remove | is-empty)) {
        try {
            ^rm $destination
            masshow
        } catch { |err|
            error-msg $"Failed to remove ($destination): ($err.msg)"
        }
        return
    }

    if (($destination | path type) == "symlink") {
        error-msg $"mas is already linked at ($destination)"
        masshow
        return
    }

    ^ln -s $source $destination
    masshow
}
