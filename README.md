# BotAI

This repository contains a small Lua interpreter demonstrating how to interact
with the [UCZone API](https://uczone.gitbook.io/api-v2.0) that is included in the
environment. The interpreter parses a minimal DSL and forwards commands to the
API, launching the standard bot before executing the rest of the script.

## Usage

1. Prepare a script file with commands. See `example_script.dota` for a basic example.
2. Run the interpreter with Lua:

```bash
lua dota_interpreter.lua example_script.dota
```

Supported commands:

- `start_bot` — launch the standard bot provided by the API.
- `move_to X Y` — move your hero to coordinates `X`, `Y`.
- `attack TARGET` — attack a given target.
- `wait SECONDS` — pause execution for a given time.
- `say MESSAGE` — send a chat message.

The script is a minimal demonstration. Consult the official UCZone
documentation for full details of available functions.
