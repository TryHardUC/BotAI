# BotAI

This repository contains an interpreter script for running bots in the UCZone environment. The script is written in Lua and demonstrates how to load modules, attach a UI toggle and lazily start the standard bot implementation.

## Usage

1. Copy `interpreter.lua` into your cheat's `scripts` directory.
2. Start the game with the UCZone cheat. Use the `Enable AI-Bot` checkbox from the UI to activate the bot during a match.
3. The interpreter logs module loads and bot activity using `adapter.log` while forwarding `Init` and `Think` calls to `bot_generic`.

Refer to the [UCZone API documentation](https://uczone.gitbook.io/api-v2.0) for details on available functions and how to implement your own bots.
