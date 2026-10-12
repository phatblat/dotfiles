# dpr - Restart services managed by docker compose
const dpu_nu = path self dpu.nu
source $dpu_nu
export def dpr [] {
    dpd
    dpu
}
