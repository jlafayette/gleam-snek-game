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
  - Improve spawning walls so they go quicker, maybe spreading out from existing
    walls? 
  - Walls shouldn't be able to go through the snake - allowing containing a patch
    as a strategy
  - Telegraph spawn points with red markers or countdown numbers
  - Wall spawn happens after the player move, so moving into a spawn-in-1 is allowed
    and will block it as long as the snake body is in that square
  - Spawn based on distance (accounting for walls)

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

