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

- Food
  - Adjust spawns so that a certain number of food on board is prioritized
    (otherwise best strategy is to wait around for a long time eating nothing
     before the exit opens to let food build up)
  - Retry spawning in late game when most of the board is snek body or walls
    so spawn rate is comparible to earlier.  There should be reward for hanging
    out at the very end of the game

- Wall spawn
  - Pick random spot along wall (weighted towards edges away from exit)
  - Spawn based on distance (accounting for walls)
  - Play warning sound with new spawn point goes visible
  - Play sound when wall spawns

- Snek Control
  - Allow more flexibility in control input timing for jog and u-turn
    (jog is going 1 side then back to current direction)

- Level end transition
  - Add a game state for Exiting
  - Have custom logic for advancing in this state (faster ticks, no player control)
  - Transition trigger when player has fully exited
  - Improve visuals and sound for exit sequence to stress players out more

- Add tips
  - On death or maybe at the start of the game, add tips that go over rules or
    strategies
  
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

