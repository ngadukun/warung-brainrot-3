# Warung Brainrot

[![roblox-brainrot-01 bounty](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/ngadukun/warung-brainrot-3/rank.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/ngadukun/warung-brainrot-3/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

**Rebut, kumpul, kaya — di pasar malam paling absurd sedunia.**

Warung Brainrot is a 3D Indonesian night-market brainrot tycoon for Roblox.
Absurd food-themed characters ride a conveyor belt through a neon night
market; you buy them, they walk home to your base and earn money every
second — while everyone else tries to steal them back.

## How it plays

1. You spawn at the market with **$150**. Brainrots ride the central
   conveyor — walk up and press **E** to buy one.
2. Your brainrot walks to a free pad on your coloured base (blue, red,
   yellow or green) and earns **$/second**; the board over your base shows
   your live income.
3. **Steal**: hold E on a brainrot in someone else's *unlocked* base, carry
   it home on your head, and it deposits itself on your base. Defend with
   **Kunci Base** (20 s lock, 60 s cooldown, button or the **L** key).
4. Every ~100 s an event hits the market, alternating:
   - **Hujan Krupuk** — a cracker storm sweeps the map; anyone caught
     outside a base is washed back to spawn and drops what they carry.
   - **Lampu Disko** — 30 s of double income while the lampion lights and
     the fog cycle through disco colours.
5. **Rebirth** at $25,000 total earned: cash and brainrots reset for a
   permanent, stacking +50% income multiplier. Extra base slots (up to 10)
   cost more each time.

## The cast

12 characters climb a rarity ladder from Common to Secret — Krupuk Terbang
($2/s), Es Teh Manis, Klepon Gemas, Gorengan Sakti, Kopi Tubruk Titan,
Nasi Padang Raksasa, Becak Terbang, Komodo Berkepala Dua, Garuda Emas,
Rendang Dewa, Kujang Petir and the Secret Tung-Tung Sahur ($1,500/s).
Mutations rolled at spawn raise income and change the look: **Gold** 8%
(×2), **Diamond** 3% (×5) and **Rainbow** 0.5% (×10, colour-cycling).

Every character is built from plain Roblox parts — no external assets — in
a market with an entrance arch, eight named food stalls, lampion string
lights, street lamps, umbrella tents and a moonlit sky.

## Layout

- `src/server/` — one module per job: `Config` (all tuning), `PlayerState`
  (the only state store), `BrainrotFactory`, `WorldBuilder`,
  `ConveyorService`, `EconomyService`, `BaseService`, `StealService`,
  `EventService`, `RebirthService`, `TourHelper`, and the `Main` bootstrap.
  All purchases, steals, locks and rebirths are validated server-side.
- `src/client/` — `Game.client` wires the remotes; `Hud` builds the whole
  interface (cash/income top bar, action buttons, event chip and banner,
  toasts) and only ever displays server snapshots.
- `default.project.json` — the Rojo project (server, client, and the
  `ReplicatedStorage/Remotes` RemoteEvents).
- `TOUR.json` — reviewer tour: `TourHelper` stages the mutation showcase
  and both events behind the screenshots.

## Screenshots

`screenshots/` holds four captures of the running game: the cover (the
WARUNG BRAINROT arch, conveyor and a stocked base), a conveyor close-up
with a Diamond brainrot and its Buy prompt, a filled base with its income
ticking, and the Hujan Krupuk wave arriving. The first is also the place's
thumbnail on Roblox.

## Build and hand in

```sh
rojo build default.project.json --output game.rbxl
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
```

`main.ts` copies the place, sources, screenshots and `PLAY.json` out and
writes the `dossier.json` summary with the vendored make.fun library.
