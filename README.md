# snek

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
gleam shell # Run an Erlang shell
gleam run -m lustre/dev start
```

## TODO Ideas

- Don't spawn food at the exit
- When timer runs out, start spawning walls that fill in the whole level.
  start with spawn points away from exit, then moving towards exit area
- Telegraph spawn points with little doors or red markers
- Improve visuals and sound for exit sequence to stress players out more
- Level end transition
- Add more levels (at least 10)
- Win screen
- High score screen
- Tutorial
- Logging
- Better snake graphics (simple head/tail)
- Music
- Score numbers when eating +1
- Score multipliers (spawn when exit opens for added risk/reward)
- Local coop

