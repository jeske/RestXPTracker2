-- Initialize Local Database
RestXP_DB = RestXP_DB or {}

-- Update Character Info Function
local function updateCurrentCharacterInfo()
    local charName = UnitName("player")
    local realmName = GetRealmName()
    local level = UnitLevel("player")
    local xp = UnitXP("player")
    local maxXP = UnitXPMax("player")
    local restXP = GetXPExhaustion() or 0
    local isResting = IsResting()
    local logoutTime = time()

    RestXP_DB[realmName] = RestXP_DB[realmName] or {}
    if level == MAX_PLAYER_LEVEL then
	RestXP_DB[realmName][charName] = nil
        return
    end

    RestXP_DB[realmName][charName] = {
        xp = xp,
        maxXP = maxXP,
        restXP = restXP,
        logoutTime = logoutTime,
        isResting = isResting
    }
end


-- Create Event Frame and Register Events
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_XP_UPDATE")
frame:RegisterEvent("PLAYER_ALIVE")
frame:RegisterEvent("PLAYER_UPDATE_RESTING")
frame:RegisterEvent("PLAYER_LEAVING_WORLD")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_XP_UPDATE" or event == "PLAYER_ALIVE" or event == "PLAYER_UPDATE_RESTING" then
        updateCurrentCharacterInfo()
    end
end)


-- Slash Command Handler
SLASH_RESTXP1 = "/restxp"
SlashCmdList["RESTXP"] = function(msg)
    updateCurrentCharacterInfo()

    local sortedRealms = {}
    for realm in pairs(RestXP_DB) do
        table.insert(sortedRealms, realm)
    end
    table.sort(sortedRealms)

    for _, realm in ipairs(sortedRealms) do
        local sortedChars = {}
        for char in pairs(RestXP_DB[realm]) do
            table.insert(sortedChars, char)
        end
        table.sort(sortedChars)

        for _, char in ipairs(sortedChars) do
	    local data = RestXP_DB[realm][char]

	    local EIGHT_HOURS = 60 * 60 * 8
	    local restedXP_LimitRatio = 1.5
            local elapsedTime = (char == currentCharName and realm == currentRealmName) and 0 or time() - data.logoutTime
            local restXPIncrement = data.isResting and (data.maxXP * 0.05) or (data.maxXP * 0.0125)
            local estimatedRestXP = data.restXP + (elapsedTime / EIGHT_HOURS) * restXPIncrement
            local restXPPercent = math.min(100, (estimatedRestXP / (data.maxXP * restedXP_LimitRatio)) * 100)

	    print(string.format("%s-%s: %.0f%%", char, realm, restXPPercent))
        end
    end
end
