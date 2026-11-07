# Retire Baseten from the Casper model sync

Priority: Unprioritized

## Problem

Casper no longer uses Baseten as a model provider, but the casper model sync still prices models from Baseten. `scripts/sync-casper-models.sh` fetches the Baseten pricing page through `r.jina.ai` (`BASETEN_PRICING_URL`), parses it in `parse_pricing`, and maps Casper ids to Baseten keys in `baseten_key_for`. A stale or reshaped page fails the whole sync (`die "failed to fetch Baseten pricing page"`), and any Baseten rate can silently differ from what Casper actually charges.

The header comments in the script and in `.omp/profiles/casper/agent/models.yml` still describe the Baseten flow ("per-1M-token costs come from the Baseten pricing page"). The cost entries in `models.yml` that came from it, including `kimi-k3p1-pro` at 2.00 / 10.00 / 0.20, have not been checked against any current source.

## Outcome

The sync script has no Baseten dependency: the scrape, `parse_pricing`, `baseten_key_for`, and `BASETEN_PRICING_URL` are gone, and the header comments in the script and `models.yml` describe where prices really come from. Every priced model in `models.yml` carries a cost with a documented source.

## Notes

- The retired-model entries in the script were already pruned for the four models removed from `models.yml` (`kimi-k2.6`, `kimi-k2.7-code`, `gpt-oss-120b`, `nemotron-3-ultra`). The remaining `baseten_key_for` cases are the ones this item removes.
- `manual_price()` already holds hand-maintained rates from the Casper admin catalog (`ultramarine-1-flash-us`). It is the existing home for prices that have no scrape.
- Pairs with [onboard-fireworks-as-a-casper-pricing-source](onboard-fireworks-as-a-casper-pricing-source.md). Which replacement is chosen decides whether the prices move to `manual_price()` or to a new scrape.
- Origin: review feedback on PR [#582](https://github.com/phatblat/dotfiles/pull/582).
