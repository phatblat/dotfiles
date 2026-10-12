# xstart - Starts nginx
const xstatus_nu = path self xstatus.nu
source $xstatus_nu
export def --wrapped xstart [...args] {
    ^sudo nginx ...$args
    xstatus
}
