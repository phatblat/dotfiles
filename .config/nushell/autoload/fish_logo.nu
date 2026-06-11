# Dependencies:
#   functions: none
#   builtins:  ansi print is-empty
#   externals: none

# Print a colorful ASCII-art Fish shell logo with configurable colors
export def fish_logo [
    outer_color?: string  # Outer color name (default: red)
    medium_color?: string # Medium color name (default: #ff7700, orange)
    inner_color?: string  # Inner color name (default: yellow)
    mouth?: string        # Mouth character (default: [)
    eye?: string          # Eye character (default: O)
    --help (-h)           # Show usage
] {
    let usage = "Usage: fish_logo <outer_color> <medium_color> <inner_color> <mouth> <eye>
See ansi --list for available colors."

    if $help {
        print $usage
        return
    }

    let oc = if ($outer_color == null or ($outer_color | is-empty)) { "red" } else { $outer_color }
    let mc = if ($medium_color == null or ($medium_color | is-empty)) { "#ff7700" } else { $medium_color }
    let ic = if ($inner_color == null or ($inner_color | is-empty)) { "yellow" } else { $inner_color }
    let mo = if ($mouth == null or ($mouth | is-empty)) { "[" } else { $mouth }
    let ey = if ($eye == null or ($eye | is-empty)) { "O" } else { $eye }

    # ansi color escape sequences
    let o = (ansi $oc)
    let m = (ansi $mc)
    let i = (ansi $ic)
    let n = (ansi reset)

    # Literal parens in the art are escaped as \( and \) in nu string interpolation
    print $"                 ($o)___
  ___======____=($m)-($i)-($m)-=($o)\)
/T            \\_($i)--=($m)==($o)\)
($mo) \\ ($m)\(($i)($ey)($m)\)   ($o)\\~    \\_($i)-=($m)=($o)\)
 \\      / \)J($m)~~    ($o)\\\\($i)-=($o)\)
  \\\\___/  \)JJ($m)~($i)~~   ($o)\\)
   \\_____/JJJ($m)~~($i)~~    ($o)\\\\
   ($m)/ ($o)\\  ($i), \\\\($o)J($m)~~~($i)~~     ($m)\\\\
  \(-($i)\\\)($o)\\=($m)|($i)\\\\\\\\\\\\\\\\($m)~~($i)~~       ($m)L_($i)_
  ($m)\(($o)\\\\($m)\\\)  \(($i)\\\\($m)\\\\\)($o)_           ($i)\\==($m)__
   ($o)\\V    ($m)\\\\\\\\($o)\) ==($m)=_____   ($i)\\\\\\\\\\\\\\\\($m)\\\\\\\\
          ($o)\\V\)     \\_\) ($m)\\\\\\\\($i)\\\\\\\\JJ\\\\($m)J\\)
                      ($o)/($m)J($i)\\\\($m)J($o)T\\\\($m)JJJ($o)J\)
                      \(J($m)JJ($o)| \\UUU\)
                       \(UU\)($n)"
}
