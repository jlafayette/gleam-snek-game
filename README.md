# snek

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
gleam shell # Run an Erlang shell
gleam run -m lustre/dev start
```

## TODO Ideas

- Place exit in wall, and have it visible from the start, and then open
  [x] expand board 20 px (1/2 size) in all directions, do the offsets to make
      this work
  [x] add a wall indicator around border
  [ ] add a door indicator where exit is
  [ ] add a door open indicator where exit is
  [ ] create arrow svg element (rotate based on exit dir)
  [ ] light up arrow in green when exit is open
  
- Timer when exit is opened start
- When timer runs out, die
- Sounds!
- When timer runs out, start spawning other snakes... start with spawn
  points away from exit, then moving towards exit area
- Telegraph spawn points with little doors or red markers
- Level end transition
- Add more levels (at least 10)
- Win screen
- High score screen
- Logging
- Better snake graphics (simple head/tail)
- Score numbers when eating +1
- Score multipliers (spawn when exit opens for added risk/reward)
- Local coop

