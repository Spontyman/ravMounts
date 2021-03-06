local _, ns = ...
local L = {}
ns.L = L

setmetatable(L, { __index = function(t, k)
    local v = tostring(k)
    t[k] = v
    return v
end })

local CM = C_Map

-- Automatic
local mapIDs = ns.data.mapIDs
L.AhnQiraj = CM.GetMapInfo(mapIDs.ahnqiraj[#mapIDs.ahnqiraj]).name
L.Vashjir = CM.GetMapInfo(mapIDs.vashjir[#mapIDs.vashjir]).name
L.Maw = CM.GetMapInfo(mapIDs.maw[#mapIDs.maw]).name

-- Default (English)
L.Modifier = "Modifier"
L.Version = "%s is the current version." -- ns.version
L.Install = "Thanks for installing |cff%1$sv%2$s|r!" -- ns.color, ns.version
L.Update = "Thanks for updating to |cff%1$sv%2$s|r!" -- ns.color, ns.version
L.Support1 = "This Addon creates and maintains a macro called |r%s|cffffffff for you under |rGeneral Macros|cffffffff." -- ns.name
L.Support2 = "Check out the Addon on |rGitHub|cffffffff, |rWoWInterface|cffffffff, or |rCurse|cffffffff for more info and support!"
L.Support3 = "You can also get help directly from the author on Discord: |r%s|cffffffff" -- ns.discord
L.NoMounts = "Unfortunately, you don't have any mounts that can be called at this time!"
L.NoMacroSpace = "Unfortunately, you don't have enough global macro space for the macro to be created!"
L.Force = "Mount Journal data collected, sorted, and ready to go!"
L.Ground = "Ground"
L.Passenger = "Passenger"
L.PassengerGround = L.Passenger .. " (" .. L.Ground .. ")"
L.PassengerFlying = L.Passenger .. " (" .. _G.BATTLE_PET_NAME_3 .. ")"
L.Cloneable = "Cloneable"
L.Macro = "Automatically create/maintain macro"
L.MacroTooltip = "When enabled, a macro called |cffffffff%s|r will be automatically created and managed for you under |cffffffffGeneral Macros|r." -- ns.name
L.FavoritesHeading = "Types which use Favorites:"
L.MountsTooltip = "When enabled, only %s marked as favorites will be summoned." -- type
L.DataHeading = "Collected Data:"

-- Check locale and assign appropriate
local CURRENT_LOCALE = GetLocale()

-- German
if CURRENT_LOCALE == "deDE" then return end

-- Spanish
if CURRENT_LOCALE == "esES" then return end

-- Latin-American Spanish
if CURRENT_LOCALE == "esMX" then return end

-- French
if CURRENT_LOCALE == "frFR" then return end

-- Italian
if CURRENT_LOCALE == "itIT" then return end

-- Brazilian Portuguese
if CURRENT_LOCALE == "ptBR" then return end

-- Russian
if CURRENT_LOCALE == "ruRU" then return end

-- Korean
if CURRENT_LOCALE == "koKR" then return end

-- Simplified Chinese
if CURRENT_LOCALE == "zhCN" then return end

-- Traditional Chinese
if CURRENT_LOCALE == "zhTW" then return end

-- Swedish
if CURRENT_LOCALE == "svSE" then return end
