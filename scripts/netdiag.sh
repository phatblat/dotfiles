#!/usr/bin/env bash
# netdiag.sh - correlate ICMP loss across several targets at once, to separate
# Wi-Fi link problems from per-host (ARP / multihoming) problems.
#
# RUN THIS FROM THE MACBOOK (the wireless client).
#
#   ./netdiag.sh                       # gateway + both phatstudio addresses
#   COUNT=300 ./netdiag.sh             # longer capture (default 120s)
#   ./netdiag.sh 10.0.0.1 10.0.0.33    # explicit targets
#
# All targets are pinged concurrently at exactly 1 packet/sec, so icmp_seq N
# lands in the same wall-clock second on every target. That makes the loss
# windows directly comparable.

set -uo pipefail

COUNT=${COUNT:-120}
WRAP=${WRAP:-60}

TARGETS=("$@")
if [ "${#TARGETS[@]}" -eq 0 ]; then
  TARGETS=(10.0.0.1 10.0.0.33 10.0.0.136)
fi

tmp=$(mktemp -d) || exit 1
pids=()
cleanup() {
  for p in "${pids[@]:-}"; do kill "$p" 2>/dev/null; done
}
trap cleanup INT TERM
trap 'rm -rf "$tmp"' EXIT

echo "=== link state at start ==="
awdl=$(ifconfig awdl0 2>/dev/null | sed -n '1p')
case "$awdl" in
  *RUNNING*) echo "awdl0 : UP  <-- AirDrop/Continuity is stealing airtime" ;;
  "")        echo "awdl0 : absent" ;;
  *)         echo "awdl0 : down" ;;
esac
for i in en0 en1; do
  s=$(ifconfig "$i" 2>/dev/null | awk '/status:/{print $2}')
  a=$(ipconfig getifaddr "$i" 2>/dev/null)
  [ -n "$s" ] && echo "$i    : ${s}${a:+  $a}"
done
echo
echo "=== mDNS records for phatstudio.local ==="
timeout 3 dns-sd -G v4 phatstudio.local 2>/dev/null | awk '/phatstudio/{print "  " $6}' | sort -u
echo

printf '=== capturing %ss @ 1 pkt/sec across %s targets ===\n' "$COUNT" "${#TARGETS[@]}"
for t in "${TARGETS[@]}"; do
  ping -c "$COUNT" -i 1 "$t" >"$tmp/out.$t" 2>&1 &
  pids+=("$!")
done
wait

# Received sequence numbers per target.
for t in "${TARGETS[@]}"; do
  grep -o 'icmp_seq=[0-9]*' "$tmp/out.$t" | cut -d= -f2 | sort -n -u >"$tmp/seq.$t"
  awk -v n="$COUNT" '
    {got[$1+0]=1}
    END{ s=""; for(i=0;i<n;i++) s = s (got[i] ? "." : "X"); print s }
  ' "$tmp/seq.$t" >"$tmp/pat.$t"
done

echo
echo "=== loss summary ==="
printf '%-18s %8s  %s\n' TARGET LOSS RTT
for t in "${TARGETS[@]}"; do
  recv=$(wc -l <"$tmp/seq.$t" | tr -d ' ')
  pct=$(awk -v r="$recv" -v n="$COUNT" 'BEGIN{printf "%.1f", (n-r)*100/n}')
  rtt=$(awk -F'= ' '/min\/avg\/max/{split($2,a,"/"); printf "min %s / avg %s / max %s ms", a[1], a[2], a[3]}' "$tmp/out.$t")
  printf '%-18s %7s%%  %s\n' "$t" "$pct" "${rtt:-n/a}"
done

echo
echo "=== timeline  ( . = reply   X = lost ) ==="
for ((off = 0; off < COUNT; off += WRAP)); do
  printf '\n%-18s ' "sec $off"
  for ((c = 0; c < WRAP && off + c < COUNT; c++)); do
    if [ $(((off + c) % 10)) -eq 0 ]; then printf '|'; else printf ' '; fi
  done
  echo
  for t in "${TARGETS[@]}"; do
    printf '%-18s %s\n' "$t" "$(cut -c$((off + 1))-$((off + WRAP)) "$tmp/pat.$t")"
  done
done

# Correlate: was a given second lost everywhere, or only on some targets?
echo
echo "=== verdict ==="
cat "${TARGETS[@]/#/$tmp/pat.}" >"$tmp/all.pat"
awk -v n="$COUNT" -v ntgt="${#TARGETS[@]}" '
  { for (i = 1; i <= n; i++) if (substr($0, i, 1) == "X") lost[i]++ }
  END {
    for (i = 1; i <= n; i++) {
      if (lost[i] == ntgt) all++
      else if (lost[i] > 0) some++
    }
    printf "  seconds lost on ALL targets  : %d\n", all+0
    printf "  seconds lost on SOME targets : %d\n", some+0
    print  ""
    if (all == 0 && some == 0) {
      print "  No loss captured. Re-run longer (COUNT=600) or while the link is misbehaving."
    } else if (all >= some) {
      print "  -> Loss is SHARED across every target, including the gateway."
      print "     The Wi-Fi link itself is dropping. Suspect, in order:"
      print "       1. AWDL (AirDrop/Handoff/Sidecar) hopping the radio off-channel"
      print "       2. Roaming between UniFi APs"
      print "       3. DFS radar event forcing a 5GHz channel change"
      print "       4. Wi-Fi power save / low RSSI"
    } else {
      print "  -> Loss is HOST-SPECIFIC; the gateway stayed reachable."
      print "     The Wi-Fi radio is fine. Suspect the phatstudio dual-NIC setup:"
      print "     10.0.0.33 (en0) and 10.0.0.136 (en21) share one subnet, so ARP"
      print "     for .33 can be answered by either MAC and the switch flaps."
    }
  }
' "$tmp/all.pat"
