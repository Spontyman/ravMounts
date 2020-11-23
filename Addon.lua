---
-- Ravenous Mounts
--   Chooses the best Mount for the job, with no configuration or set-up; it's
--   all based on your Mount Journal Favorites. Includes any and all available
--   Ground, Flying, Swimming, Vendor, Passenger, and Special Zone Mounts!
-- Author: waldenp0nd
-- License: Public Domain
-- https://github.com/waldenp0nd/ravMounts
-- https://www.wowinterface.com/downloads/info24005-RavenousMounts.html
-- https://www.curseforge.com/wow/addons/ravmounts
---
local _, ravMounts = ...
ravMounts.name = "Ravenous Mounts"
ravMounts.version = "2.1.3"

-- DEFAULTS
-- These are only applied when the AddOn is first loaded.
-- From there values are loaded from RAV_ values stored in your WTF folder.
local defaults = {
    COMMAND =               "ravm",
    LOCALE =                "enUS",
    AUTO_VENDOR_MOUNTS =    true,
    AUTO_PASSENGER_MOUNTS = true,
    AUTO_SWIMMING_MOUNTS =  true,
    AUTO_FLEX_MOUNTS =      true,
    AUTO_CLONE =            true
}

local faction, _ = UnitFactionGroup("player")

-- Special formatting for messages
local function prettyPrint(message, full)
    if full == false then
        message = message .. ":"
    end
    local prefix = "\124cff9eb8c9" .. ravMounts.name .. " v" .. ravMounts.version .. (full and " " or ":\124r ")
    DEFAULT_CHAT_FRAME:AddMessage(prefix .. message)
end

-- Simplify mount summoning syntax
local function mountSummon(list)
    local inCombat = UnitAffectingCombat("player")
    if not inCombat and #list > 0 then
        C_MountJournal.SummonByID(list[random(#list)])
    end
end

-- Check if floating
-- Thanks to DJharris71 (http://www.wowinterface.com/forums/member.php?userid=301959)
local function IsFloating()
    local B, b, _, _, a = "BREATH", GetMirrorTimerInfo(2)
    return (IsSwimming() and (not (b == B) or (b == B and a > -1)))
end

local function IsShapeshifted()
    local _, class, _ = UnitClass("player")
    local shapeshift = GetShapeshiftForm()
    if class == "Druid" and shapeshift then
        return true
    elseif class == "Shaman" and shapeshift then
        return true
    end
    return false
end

-- Get the mount being used by the target or focus (if they're a Player)
-- Thanks to DJharris71 (http://www.wowinterface.com/forums/member.php?userid=301959)
local function GetCloneMount()
    local id = false
    local clone = UnitIsPlayer("target") and "target" or UnitIsPlayer("focus") and "focus" or false
    if clone then
        for buffIndex = 1, 40 do
            for mountIndex = 1, table.maxn(RAV_allMountsByName) do
                if UnitBuff(clone, buffIndex) == RAV_allMountsByName[mountIndex] then
                    id = RAV_allMountsByID[mountIndex]
                    break
                end
            end
            if id then
                break
            end
        end
    end
    return id
end

-- Collect Data and Sort it
function ravMounts.mountListHandler()
    -- Reset the global variables to be populated later
    RAV_flyingMounts = {}
    RAV_groundMounts = {}
    RAV_vendorMounts = {}
    RAV_flyingPassengerMounts = {}
    RAV_groundPassengerMounts = {}
    RAV_swimmingMounts = {}
    RAV_vashjirMounts = {}
    RAV_ahnQirajMounts = {}
    RAV_chauffeurMounts = {}
    RAV_allMountsByName = {}
    RAV_allMountsByID = {}
    RAV_autoVendorMounts = (RAV_autoVendorMounts == nil and defaults.AUTO_VENDOR_MOUNTS or RAV_autoVendorMounts)
    RAV_autoPassengerMounts = (RAV_autoPassengerMounts == nil and defaults.AUTO_PASSENGER_MOUNTS or RAV_autoPassengerMounts)
    RAV_autoSwimmingMounts = (RAV_autoSwimmingMounts == nil and defaults.AUTO_SWIMMING_MOUNTS or RAV_autoSwimmingMounts)
    RAV_autoFlexMounts = (RAV_autoFlexMounts == nil and defaults.AUTO_FLEX_MOUNTS or RAV_autoFlexMounts)
    RAV_autoClone = (RAV_autoClone == nil and defaults.AUTO_CLONE or RAV_autoClone)

    local isFlyingMount, isGroundMount, isVendorMount, isFlyingPassengerMount, isGroundPassengerMount, isSwimmingMount, isVashjirMount, isAhnQirajMount, isChauffeurMount, isFlexMount
    -- Let's start looping over our Mount Journal adding Mounts to their
    -- respective groups
    for mountIndex, mountID in pairs(C_MountJournal.GetMountIDs()) do
        local mountName, spellID, _, _, isUsable, _, isFavorite, _, mountFaction, hiddenOnCharacter, isCollected = C_MountJournal.GetMountInfoByID(mountID)
        local _, _, _, _, mountType = C_MountJournal.GetMountInfoExtraByID(mountID)
        isFlyingMount = (mountType == 247 or mountType == 248)
        isGroundMount = (mountType == 230)
        isSwimmingMount = (mountType == 231 or mountType == 254)
        isVashjirMount = (mountType == 232)
        isAhnQirajMount = (mountType == 241)
        isChauffeurMount = (mountType == 284)
        isVendorMount = (mountID == 280 or mountID == 284 or mountID == 460 or mountID == 1039)
        isFlyingPassengerMount = (mountID == 382 or mountID == 407 or mountID == 455 or mountID == 959 or mountID == 960)
        isGroundPassengerMount = (mountID == 240 or mountID == 254 or mountID == 255 or mountID == 275 or mountID == 286 or mountID == 287 or mountID == 288 or mountID == 289)
        isFlexMount = (mountID == 219 or mountID == 363 or mountID == 376 or mountID == 421 or mountID == 439 or mountID == 451 or mountID == 455 or mountID == 456 or mountID == 457 or mountID == 458 or mountID == 459 or mountID == 468 or mountID == 522 or mountID == 523 or mountID == 532 or mountID == 594 or mountID == 547 or mountID == 593 or mountID == 764 or mountID == 1222)
        if isCollected then
            -- 0 = Horde, 1 = Alliance
            -- Check for mismatch, means not available
            if mountFaction == 0 and faction ~= "Horde" then
                -- skip
            elseif mountFaction == 1 and faction ~= "Alliance" then
                -- skip
            else
                table.insert(RAV_allMountsByName, mountName)
                table.insert(RAV_allMountsByID, mountID)
                if isFlyingMount and isFavorite and not isVendorMount and not isFlyingPassengerMount and not isGroundPassengerMount then
                    if RAV_autoFlexMounts and isFlexMount then
                        table.insert(RAV_groundMounts, mountID)
                    else
                        table.insert(RAV_flyingMounts, mountID)
                    end
                end
                if isGroundMount and isFavorite and not isVendorMount and not isFlyingPassengerMount and not isGroundPassengerMount then
                    table.insert(RAV_groundMounts, mountID)
                end
                if isVendorMount then
                    if RAV_autoVendorMounts then
                        table.insert(RAV_vendorMounts, mountID)
                        if isFavorite then
                            table.insert(RAV_groundMounts, mountID)
                        end
                    elseif not RAV_autoVendorMounts and isFavorite then
                        table.insert(RAV_vendorMounts, mountID)
                    end
                end
                if isFlyingPassengerMount then
                    if RAV_autoPassengerMounts then
                        table.insert(RAV_flyingPassengerMounts, mountID)
                        if isFavorite then
                            table.insert(RAV_flyingMounts, mountID)
                        end
                    elseif not RAV_autoPassengerMounts and isFavorite then
                        table.insert(RAV_flyingPassengerMounts, mountID)
                    end
                end
                if isGroundPassengerMount then
                    if RAV_autoPassengerMounts then
                        table.insert(RAV_groundPassengerMounts, mountID)
                        if isFavorite then
                            table.insert(RAV_groundMounts, mountID)
                        end
                    elseif not RAV_autoPassengerMounts and isFavorite then
                        table.insert(RAV_groundPassengerMounts, mountID)
                    end
                end
                if isSwimmingMount then
                    if RAV_autoSwimmingMounts
                    or not RAV_autoSwimmingMounts and isFavorite then
                        table.insert(RAV_swimmingMounts, mountID)
                    end
                end
                if isChauffeurMount then
                    table.insert(RAV_chauffeurMounts, mountID)
                end
                if isVashjirMount then
                    table.insert(RAV_vashjirMounts, mountID)
                end
                if isAhnQirajMount then
                    table.insert(RAV_ahnQirajMounts, mountID)
                end
            end
        end
    end
end

-- Check a plethora of conditions and choose the appropriate Mount from the
-- Mount Journal, and do nothing if conditions are not met
function ravMounts.mountUpHandler(specificType)
    -- Simplify the appearance of the logic later by casting our checks to
    -- simple variables
    local mounted = IsMounted()
    local inVehicle = UnitInVehicle("player")
    local shapeshifted = IsShapeshifted()
    local flyable = ravMounts.IsFlyableArea()
    local submerged = IsSwimming() and not IsFloating()
    local mapID = C_Map.GetMapInfo(1)
    local inVashjir = (mapID == 610 or mapID == 613 or mapID == 614 or mapID == 615) and true or false
    local inAhnQiraj = (mapID == 717 or mapID == 766) and true or false
    local shiftKey = IsShiftKeyDown()
    local controlKey = IsControlKeyDown()
    local altKey = IsAltKeyDown()
    local haveFlyingMounts = next(RAV_flyingMounts) ~= nil and true or false
    local haveGroundMounts = next(RAV_groundMounts) ~= nil and true or false
    local haveVendorMounts = next(RAV_vendorMounts) ~= nil and true or false
    local haveFlyingPassengerMounts = next(RAV_flyingPassengerMounts) ~= nil and true or false
    local haveGroundPassengerMounts = next(RAV_groundPassengerMounts) ~= nil and true or false
    local haveSwimmingMounts = next(RAV_swimmingMounts) ~= nil and true or false
    local haveVashjirMounts = next(RAV_vashjirMounts) ~= nil and true or false
    local haveAhnQirajMounts = next(RAV_ahnQirajMounts) ~= nil and true or false
    local haveChauffeurMounts = next(RAV_chauffeurMounts) ~= nil and true or false
    local cloneMountID = GetCloneMount()

    -- Specific Mounts
    if (string.match(specificType, "vend") or string.match(specificType, "repair") or string.match(specificType, "trans") or string.match(specificType, "mog")) and haveVendorMounts then
        mountSummon(RAV_vendorMounts)
    elseif (string.match(specificType, "2") or string.match(specificType, "two") or string.match(specificType, "multi") or string.match(specificType, "passenger")) and haveFlyingPassengerMounts and flyable then
        mountSummon(RAV_flyingPassengerMounts)
    elseif string.match(specificType, "fly") and (string.match(specificType, "2") or string.match(specificType, "two") or string.match(specificType, "multi") or string.match(specificType, "passenger")) and haveFlyingPassengerMounts then
        mountSummon(RAV_flyingPassengerMounts)
    elseif (string.match(specificType, "2") or string.match(specificType, "two") or string.match(specificType, "multi") or string.match(specificType, "passenger")) and haveGroundPassengerMounts then
        mountSummon(RAV_groundPassengerMounts)
    elseif string.match(specificType, "swim") and haveSwimmingMounts then
        mountSummon(RAV_swimmingMounts)
    elseif (specificType == "vj" or string.match(specificType, "vash") or string.match(specificType, "jir")) and haveVashjirMounts then
        mountSummon(RAV_vashjirMounts)
    elseif string.match(specificType, "fly") and haveFlyingMounts then
        mountSummon(RAV_flyingMounts)
    elseif (specificType == "aq" or string.match(specificType, "ahn") or string.match(specificType, "qiraj")) and haveAhnQirajMounts then
        mountSummon(RAV_ahnQirajMounts)
    elseif specificType == "ground" and haveGroundMounts then
        mountSummon(RAV_groundMounts)
    elseif specificType == "chauffeur" and haveChauffeurMounts then
        mountSummon(RAV_chauffeurMounts)
    elseif (specificType == "copy" or specificType == "clone" or RAV_autoClone) and cloneMountID then
        C_MountJournal.SummonByID(cloneMountID)
    elseif ((shiftKey and altKey) or (shiftKey and controlKey)) and (mounted or inVehicle) then
        DoEmote(EMOTE171_TOKEN)
    elseif shiftKey and haveVendorMounts then
        mountSummon(RAV_vendorMounts)
    elseif controlKey and flyable and not altKey and haveFlyingPassengerMounts then
        mountSummon(RAV_flyingPassengerMounts)
    elseif controlKey and (not flyable or (flyable and altKey)) and haveGroundPassengerMounts then
        mountSummon(RAV_groundPassengerMounts)
    elseif mounted or inVehicle or shapeshifted then
        Dismount()
        VehicleExit()
        CancelShapeshiftForm()
        UIErrorsFrame:Clear()
    elseif haveFlyingMounts and ((flyable and not submerged and not altKey) or (altKey and not flyable)) then
        mountSummon(RAV_flyingMounts)
    elseif inVashjir and submerged and haveVashjirMounts then
        mountSummon(RAV_vashjirMounts)
    elseif submerged and haveSwimmingMounts then
        mountSummon(RAV_vashjirMounts)
    elseif inAhnQiraj and haveAhnQirajMounts then
        mountSummon(RAV_ahnQirajMounts)
    elseif haveGroundMounts then
        mountSummon(RAV_groundMounts)
    elseif haveChauffeurMounts then
        mountSummon(RAV_chauffeurMounts)
    else
        prettyPrint(ravMounts.locales[ravMounts.locale].notice.nomounts)
    end
end

SLASH_RAVMOUNTS1 = "/ravenousmounts"
SLASH_RAVMOUNTS2 = "/ravmounts"
SLASH_RAVMOUNTS3 = "/ravm"
local function slashHandler(message, editbox)
    local command, argument = strsplit(" ", message)
    if command == "version" or command == "v" then
        prettyPrint(string.format(ravMounts.locales[ravMounts.locale].notice.version, ravMounts.version))
    elseif argument and (command == "s" or string.match(command, "setting") or command == "c" or string.match(command, "config") or string.match(command, "auto") or string.match(command, "tog")) then
        if string.match(argument, "vend") or string.match(argument, "repair") or string.match(argument, "trans") or string.match(argument, "mog") then
            RAV_autoVendorMounts = not RAV_autoVendorMounts
            prettyPrint("\124cffffff66" .. ravMounts.locales[ravMounts.locale].config.vendor .. "\124cffffffff: " .. (RAV_autoVendorMounts and ravMounts.locales[ravMounts.locale].config.auto or ravMounts.locales[ravMounts.locale].config.manual), true)
            if RAV_autoVendorMounts then
                print(ravMounts.locales[ravMounts.locale].automation.vendor[1])
            else
                print(ravMounts.locales[ravMounts.locale].automation.vendor[2])
            end
        elseif string.match(argument, "2") or string.match(argument, "two") or string.match(argument, "multi") or string.match(argument, "passenger") then
            RAV_autoPassengerMounts = not RAV_autoPassengerMounts
            prettyPrint("\124cffffff66" .. ravMounts.locales[ravMounts.locale].config.passenger .. "\124cffffffff: " .. (RAV_autoPassengerMounts and ravMounts.locales[ravMounts.locale].config.auto or ravMounts.locales[ravMounts.locale].config.manual), true)
            if RAV_autoPassengerMounts then
                print(ravMounts.locales[ravMounts.locale].automation.passenger[1])
            else
                print(ravMounts.locales[ravMounts.locale].automation.passenger[2])
            end
        elseif string.match(argument, "swim") then
            RAV_autoSwimmingMounts = not RAV_autoSwimmingMounts
            prettyPrint("\124cffffff66" .. ravMounts.locales[ravMounts.locale].config.swimming .. "\124cffffffff: " .. (RAV_autoSwimmingMounts and ravMounts.locales[ravMounts.locale].config.auto or ravMounts.locales[ravMounts.locale].config.manual), true)
            if RAV_autoSwimmingMounts then
                print(ravMounts.locales[ravMounts.locale].automation.swimming[1])
            else
                print(ravMounts.locales[ravMounts.locale].automation.swimming[2])
            end
        elseif string.match(argument, "flex") then
            RAV_autoFlexMounts = not RAV_autoFlexMounts
            prettyPrint("\124cffffff66" .. ravMounts.locales[ravMounts.locale].config.flex .. "\124cffffffff: " .. (RAV_autoFlexMounts and ravMounts.locales[ravMounts.locale].config.flexboth or ravMounts.locales[ravMounts.locale].config.flexone), true)
            if RAV_autoFlexMounts then
                print(ravMounts.locales[ravMounts.locale].automation.flex[1])
            else
                print(ravMounts.locales[ravMounts.locale].automation.flex[2])
            end
        elseif string.match(argument, "clone") or string.match(argument, "copy") then
            RAV_autoClone = not RAV_autoClone
            prettyPrint("\124cffffff66" .. ravMounts.locales[ravMounts.locale].config.clone .. "\124cffffffff: " .. (RAV_autoClone and ravMounts.locales[ravMounts.locale].config.on or ravMounts.locales[ravMounts.locale].config.off), true)
            if RAV_autoClone then
                print(ravMounts.locales[ravMounts.locale].automation.clone[1])
            else
                print(ravMounts.locales[ravMounts.locale].automation.clone[2])
            end
        else
            print(string.format(ravMounts.locales[ravMounts.locale].automation.missing, defaults.COMMAND))
        end
        ravMounts.mountListHandler()
    elseif command == "s" or string.match(command, "setting") or command == "c" or string.match(command, "config") then
        ravMounts.mountListHandler()
        prettyPrint(ravMounts.locales[ravMounts.locale].notice.config)
        print("\124cffffff66" .. ravMounts.locales[ravMounts.locale].config.vendor .. ":\124r "..(RAV_autoVendorMounts and ravMounts.locales[ravMounts.locale].config.auto or ravMounts.locales[ravMounts.locale].config.manual))
        print("\124cffffff66" .. ravMounts.locales[ravMounts.locale].config.passenger .. ":\124r "..(RAV_autoPassengerMounts and ravMounts.locales[ravMounts.locale].config.auto or ravMounts.locales[ravMounts.locale].config.manual))
        print("\124cffffff66" .. ravMounts.locales[ravMounts.locale].config.swimming .. ":\124r "..(RAV_autoSwimmingMounts and ravMounts.locales[ravMounts.locale].config.auto or ravMounts.locales[ravMounts.locale].config.manual))
        print("\124cffffff66" .. ravMounts.locales[ravMounts.locale].config.flex .. ":\124r "..(RAV_autoFlexMounts and ravMounts.locales[ravMounts.locale].config.flexboth or ravMounts.locales[ravMounts.locale].config.flexone))
        print("\124cffffff66" .. ravMounts.locales[ravMounts.locale].config.clone .. ":\124r "..(RAV_autoClone and ravMounts.locales[ravMounts.locale].config.on or ravMounts.locales[ravMounts.locale].config.off))
        print(string.format(ravMounts.locales[ravMounts.locale].help[3], defaults.COMMAND))
        print(string.format(ravMounts.locales[ravMounts.locale].help[4], defaults.COMMAND, defaults.COMMAND, defaults.COMMAND))
    elseif command == "f" or string.match(command, "forc") or command == "d" or string.match(command, "dat") then
        ravMounts.mountListHandler()
        prettyPrint(ravMounts.locales[ravMounts.locale].notice.force)
        print("\124cffffff66" ..ravMounts.locales[ravMounts.locale].type.total .. " \124r" .. table.maxn(RAV_allMountsByName))
        print("\124cffffff66" ..ravMounts.locales[ravMounts.locale].type.ground .. " \124r" .. table.maxn(RAV_groundMounts))
        print("\124cffffff66" ..ravMounts.locales[ravMounts.locale].type.flying .. " \124r" .. table.maxn(RAV_flyingMounts))
        print("\124cffffff66" ..ravMounts.locales[ravMounts.locale].type.groundpassenger .. " \124r" .. table.maxn(RAV_groundPassengerMounts))
        print("\124cffffff66" ..ravMounts.locales[ravMounts.locale].type.flyingpassenger .. " \124r" .. table.maxn(RAV_flyingPassengerMounts))
        print("\124cffffff66" ..ravMounts.locales[ravMounts.locale].type.vendor .. " \124r" .. table.maxn(RAV_vendorMounts))
        print("\124cffffff66" ..ravMounts.locales[ravMounts.locale].type.swimming .. " \124r" .. table.maxn(RAV_swimmingMounts))
        print("\124cffffff66" ..ravMounts.locales[ravMounts.locale].type.vashjir .. " \124r" .. table.maxn(RAV_vashjirMounts))
        print("\124cffffff66" ..ravMounts.locales[ravMounts.locale].type.ahnqiraj .. " \124r" .. table.maxn(RAV_ahnQirajMounts))
        print("\124cffffff66" ..ravMounts.locales[ravMounts.locale].type.chauffer .. " \124r" .. table.maxn(RAV_chauffeurMounts))
    elseif command == "h" or string.match(command, "hel") then
        prettyPrint(ravMounts.locales[ravMounts.locale].notice.help)
        print(string.format(ravMounts.locales[ravMounts.locale].help[1], defaults.COMMAND))
        print(string.format(ravMounts.locales[ravMounts.locale].help[2], defaults.COMMAND))
        print(string.format(ravMounts.locales[ravMounts.locale].help[3], defaults.COMMAND))
        print(string.format(ravMounts.locales[ravMounts.locale].help[4], defaults.COMMAND, defaults.COMMAND, defaults.COMMAND))
        print(string.format(ravMounts.locales[ravMounts.locale].help[5], defaults.COMMAND))
        print(string.format(ravMounts.locales[ravMounts.locale].help[6], ravMounts.name))
    else
        ravMounts.mountListHandler()
        ravMounts.mountUpHandler(command)
    end
end
SlashCmdList["RAVMOUNTS"] = slashHandler

-- Check Installation and Updates on AddOn Load
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, arg)
    if arg == "ravMounts" then
        if event == "ADDON_LOADED" then
            ravMounts.locale = GetLocale()
            if not ravMounts.locales[ravMounts.locale] then
                ravMounts.locale = defaults.LOCALE
            end
            ravMounts.mountListHandler()
            if not RAV_version then
                prettyPrint(string.format(ravMounts.locales[ravMounts.locale].load.install, ravMounts.name))
            elseif RAV_version ~= ravMounts.version then
                prettyPrint(string.format(ravMounts.locales[ravMounts.locale].load.update, ravMounts.name))
            end
            if not RAV_version or RAV_version ~= ravMounts.version then
                print(string.format(ravMounts.locales[ravMounts.locale].load.both, defaults.COMMAND, ravMounts.name))
            end
            RAV_version = ravMounts.version
        end
    end
end)
