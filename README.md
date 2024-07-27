# snek

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
gleam shell # Run an Erlang shell
gleam run -m lustre/dev start
```

## TODO Ideas

- Minor polish
  - draw edge wall on top of snake (except for exiting state)

- Wall spawn
  - Walls shouldn't be able to go through the snake - allowing containing a patch
    as a strategy
  - Wall spawn happens after the player move, so moving into a spawn-in-1 is allowed
    and will block it as long as the snake body is in that square
  - Pick random spot along wall (weighted towards edges away from exit)
  - Spawn based on distance (accounting for walls)

- Snek Control
  - Allow more flexibility in control input timing for jog and u-turn
    (jog is going 1 side then back to current direction)

- Level end transition
  - Add a game state for Exiting
  - Have custom logic for advancing in this state (faster ticks, no player control)
  - Transition trigger when player has fully exited
  - Improve visuals and sound for exit sequence to stress players out more
  
- Add more levels (at least 10)

- Win screen
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

