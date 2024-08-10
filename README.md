# snek

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
gleam shell # Run an Erlang shell
gleam run -m lustre/dev start
```

## TODO Ideas

- Wall spawn
  - Pick random spot along wall (weighted towards edges away from exit)
  - Spawn based on distance from exit (accounting for walls)
  - * Play warning sound with new spawn point goes visible
  - * Play sound when wall spawns (thunk + rocks rattle)
  - * Add ticking clock sound or something that indicates the incoming walls.
    Play this after the exit opens but slightly before the first walls spawn.
    Maybe right when the first numbers appear and start ticking down.

- Add more levels (at least 10)

- Win screen
- You Died screen should be different than GameOver/Restart screen
- High score screen
- Tutorial
- Logging
- Better snake graphics (simple head/tail)

- Player stats at game-end screen (requires server and DB)

- Music
- Score numbers when eating +1
- Score multipliers (spawn when exit opens for added risk/reward)

Expansion
- More levels
- Local coop
- Add tips
  - On death or maybe at the start of the game, add tips that go over rules or
    strategies

