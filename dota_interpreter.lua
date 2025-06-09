-- Simple interpreter for UCZone API in Lua
-- Assumes the API is already available in the environment as module 'uczone'
-- The interpreter also starts the standard bot via the API

local api
local ok, mod = pcall(require, 'uczone')
if ok then
    api = mod
else
    io.stderr:write('Could not load uczone module: ' .. tostring(mod) .. "\n")
    api = {}
end

-- command handlers
local commands = {}

function commands.start_bot()
    if api.start_bot then
        api.start_bot()
    else
        print('start_bot called (api.start_bot not implemented)')
    end
end

function commands.move_to(x, y)
    if api.move_to then
        api.move_to{ x = tonumber(x), y = tonumber(y) }
    else
        print(string.format('move_to %s %s', x, y))
    end
end

function commands.attack(target)
    if api.attack then
        api.attack{ target = target }
    else
        print('attack ' .. target)
    end
end

function commands.wait(sec)
    os.execute('sleep ' .. tonumber(sec))
end

function commands.say(...)
    local msg = table.concat({...}, ' ')
    if api.say then
        api.say{ message = msg }
    else
        print('say ' .. msg)
    end
end

local function run_script(path)
    for line in io.lines(path) do
        local parts = {}
        for word in string.gmatch(line, '%S+') do
            table.insert(parts, word)
        end
        local cmd = parts[1]
        if cmd and not cmd:match('^#') and commands[cmd] then
            table.remove(parts, 1)
            commands[cmd](table.unpack(parts))
        end
    end
end

local script = arg[1]
if not script then
    print('Usage: lua dota_interpreter.lua <script_file>')
    os.exit(1)
end
run_script(script)
