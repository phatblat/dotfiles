# Onboard Fireworks as a Casper pricing source

Priority: Unprioritized

## Problem

Fireworks is believed to be the only external model host Casper still uses, but the casper model sync knows nothing about it. `scripts/sync-casper-models.sh` takes prices only from Baseten, a hand-kept `manual_price()` table, and the `free_model()` list. Models served through Fireworks therefore get a zero cost or a stale hand-entered one, and the casper profile's spend tracking reads wrong for them.

Which Casper models Fireworks serves, and what it charges for each, has not been established. The claim that Fireworks is the only external host is the user's recollection and is not confirmed anywhere in this repo.

## Outcome

Each Casper model that Fireworks serves gets a cost in `.omp/profiles/casper/agent/models.yml` from a documented Fireworks rate, and a model-id-to-Fireworks mapping lives in the sync script. A sync run reproduces those costs without hand edits, or the script states that they are hand-maintained and where the rates come from.

## Notes

- First step: confirm that Fireworks is the only external host, and list which Casper ids it serves, from the Casper admin catalog at `https://casper.ditto.live/catalog`.
- Open question: whether Fireworks publishes a pricing page or API stable enough to scrape. If not, `manual_price()` is the right home and this item reduces to a one-time rate entry plus a comment naming the source and date.
- Cached-input rates matter: `models.yml` costs carry all four fields (`input`, `output`, `cacheRead`, `cacheWrite`), and omitted ones keep the discovered zero value.
- Pairs with [retire-baseten-from-casper-model-sync](retire-baseten-from-casper-model-sync.md). They can land in either order, but the Baseten removal should not leave models unpriced.
- Origin: review feedback on PR [#582](https://github.com/phatblat/dotfiles/pull/582).
