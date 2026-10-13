# BALLERZ · RUN IT

A collectible card game for [Ballerz](https://www.ballerz.com). Open packs, collect all 9,769 Ballerz as cards, build a five-man lineup and play four-quarter games against rival crews. Single-file HTML, no build step, works on desktop and mobile.

**Play:** https://ballerz-nft.github.io/ballerz-run-it/

## The loop

1. **Collect.** Every card is a real Baller with its real DUNK / SHOOT / PLAY / DEF skills, team and appearance traits. Packs come from the daily claim, the Heat meter, wins and milestones.
2. **Build a five.** Three or more from one team gives each of them a team-stack bonus.
3. **Play four quarters.** Each quarter spotlights one skill (all four are visible up front). Send out two players, add their spotlight skill plus chemistry, and outscore the other crew. Anyone who played last quarter is Tired (−5).
4. **Level up.** Every quarter a card plays earns a Rep. 12 Reps = HOLO (+2), 40 Reps = GOLD (+4).
5. **Scrap for Dap**, then spend Dap on a Team Scout Pack to chase a set.

Modes: **The Run** (5 levels that scale to your lineup) and the **Daily Court** (one seeded crew and quarter script for everyone each day, with a shareable result grid).

## Rarity and abilities

Tiers come from overall rating percentiles: Bench, Rotation, Starter, All-Star, Legend (top 1%).

| Body / role | Ability |
| --- | --- |
| Zombie, Bright Zombie | Never gets Tired |
| Alien, Pink Alien, Bright Pink Alien | Plays its best skill in any quarter, at −5 |
| Lizard | +5 when your crew is trailing |
| Stone | +5 in DEF quarters |
| Emoji | Partner gets +3 |
| Devil | +5 when your crew is leading |
| Captain | Partner gets +2 |
| All-Star role | +3 to its own skill |
| MVP | +4 to its own skill |

## Where the data comes from

Stats and traits are read from the public team pages on ballerz.com and embedded in `index.html` (about 400 KB). Pixel art loads by token ID from `ballerz.cloud`. There is no backend: progress lives in the browser's `localStorage`, and the Home screen has a save code to move it between devices.

Refresh the embedded dataset (about 47 requests, one per team page):

```powershell
pwsh tools/update-data.ps1
```

## Not built yet

- **Holder boost.** Connecting a Flow wallet to field a holder's real Ballerz as boosted Franchise cards. Needs the collection's contract identifier and a script query.
- **Leaderboards.** Needs a small backend; today the Daily Court uses shareable result strings.
- **Sound.**

## Files

| File | What it is |
| --- | --- |
| `index.html` | The whole game, with the Baller dataset embedded between `DATA:START` / `DATA:END` |
| `tools/update-data.ps1` | Re-fetches all rosters and rewrites the embedded dataset |
