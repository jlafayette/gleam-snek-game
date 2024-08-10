# snek

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
gleam shell # Run an Erlang shell
gleam run -m lustre/dev start
```

## Build

```sh
gleam run -m lustre/dev build app
```

## TODO Ideas

- Deploy to github pages
- Add more levels (at least 10)
- Win screen
- High score screen
- You Died screen should be different than GameOver/Restart screen
- Logging
- Player stats at game-end screen (requires server and DB)

- Sound
  - Add pan based on x position

- Player Control
  - When tick happens and player would die, launch a new tick event with small
    grace-period delay so the player has a chance to save it
    (to do this, don't use interval for ticks, have the next tick spawned at the
     end of the tick update)

- Tutorial

- Wall spawn
  - Pick random spot along wall (weighted towards edges away from exit)
  - Spawn based on distance from exit (accounting for walls)
  - Add ticking clock sound or something that indicates the incoming walls.
    Play this after the exit opens but slightly before the first walls spawn.
    Maybe right when the first numbers appear and start ticking down.

Expansion
- Better snake graphics (simple head/tail)
- More levels
- Local coop
- Add tips
  - On death or maybe at the start of the game, add tips that go over rules or
    strategies
- Music
- Score numbers when eating +1
- Score multipliers (spawn when exit opens for added risk/reward)

