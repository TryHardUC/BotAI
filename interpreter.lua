-- Interpreter script for UCZone bots
---@diagnostic disable: undefined-global
local script = {}
local BOT = nil
local botStarted = false

-- 0) Logging helper
local function logLoad(msg)
    print("[LOAD] " .. msg)
end

-- 1) Override require and dofile to log loaded modules
local orig_require = require
require = function(name)
    logLoad(string.format("require -> %q", name))
    return orig_require(name)
end

local orig_dofile = dofile
dofile = function(path)
    logLoad(string.format("dofile  -> %q", path))
    return orig_dofile(path)
end

-- 2) Setup search paths for modules and bots
local cheatDir = Engine.GetCheatDirectory():gsub("\\", "/")
local root = cheatDir .. "/scripts"
package.path = table.concat({
    root .. "/modules/?.lua",
    root .. "/modules/?/init.lua",
    root .. "/bots/?.lua",
    root .. "/bots/?/?.lua",
    package.path
}, ";")

-- 3) Load shims, adapter and UI
require("modules.shims")
local adapter = require("modules.adapter_mod")
local oldLogLoad = logLoad
logLoad = function(msg)
    print("[LOAD] " .. msg)
    adapter.log("[LOAD] " .. msg)
end

adapter.log("Interpreter: shims and adapter loaded")
local UI = require("modules.ui_mod")
adapter.log("Interpreter: UI loaded")

-- 4) Lazy-load bot with proxy wrapper
local function loadBot()
    if BOT then
        adapter.log("loadBot: BOT already loaded")
        return
    end

    if not Heroes.GetLocal() then
        adapter.log("loadBot: local hero not ready")
        return
    end

    adapter.log("loadBot: requiring 'bot_generic'")
    local ok, mod = pcall(require, "bot_generic")
    if not ok then
        adapter.log("loadBot: require failed: " .. tostring(mod))
        return
    end
    if type(mod) ~= "table" then
        adapter.log("loadBot: bot_generic returned not a table: " .. tostring(mod))
        return
    end

    local function wrapBOT(botImpl)
        local hero = Heroes.GetLocal()
        local proxy = {}
        setmetatable(proxy, {
            __index = function(_, key)
                if type(botImpl[key]) == "function" then
                    return function(_, ...)
                        return botImpl(hero, ...)
                    end
                end
                if key == "GetTeam" then
                    return function()
                        return Entity.GetTeamNum(hero)
                    end
                end
                if key == "GetAbilityInSlot" then
                    return function(_, slot)
                        return NPC.GetAbility(hero, slot)
                    end
                end
                if key == "GetAbilityByName" then
                    return function(_, name)
                        for i = 0, 15 do
                            local a = NPC.GetAbility(hero, i)
                            if a and Ability.GetName(a) == name then
                                return a
                            end
                        end
                        return nil
                    end
                end
                return botImpl[key]
            end,
            __newindex = function(_, k, v)
                botImpl[k] = v
            end
        })
        return proxy
    end

    BOT = wrapBOT(mod)
    adapter.log("loadBot: bot_generic loaded")
end

-- 5) Toggle "Enable AI-Bot" using UI
adapter.log("Interpreter: setting UI.Enable callback")
UI.Enable:SetCallback(function(self)
    local state = self:Get() and "ON" or "OFF"
    adapter.log("UI.Enable toggled: " .. state)
    if not self:Get() and BOT and botStarted then
        pcall(BOT.EndGame)
        botStarted = false
        BOT = nil
    end
end, true)
adapter.log("Interpreter: callback set")

-- 6) Main OnUpdate logic
function script.OnUpdate()
    adapter.log("OnUpdate called")
    if not UI.Enable:Get() then
        adapter.log("OnUpdate: UI disabled")
        return
    end

    local state = GameRules and GameRules:State_Get()
    adapter.log("OnUpdate: GameRules " .. tostring(state))
    if state ~= DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
        return
    end

    loadBot()
    if not BOT then
        return
    end

    if not botStarted then
        adapter.log("OnUpdate: calling BOT.Init()")
        pcall(BOT.Init)
        botStarted = true
    else
        adapter.log("OnUpdate: BOT.Init already called")
    end

    adapter.log("OnUpdate: calling BOT.Think()")
    pcall(BOT.Think)
end

-- 7) Register OnUpdate every frame
Event.AddListener("OnUpdate", function()
    local ok, err = pcall(script.OnUpdate)
    if not ok then
        adapter.log("OnUpdate CRASH: " .. tostring(err))
    end
end)

adapter.log("Interpreter: initialization complete")
return script
