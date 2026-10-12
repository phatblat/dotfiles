# has_space - Return true if the given string contains a space
export def has_space [string?: string] {
    ($string | default "") | str contains " "
}
