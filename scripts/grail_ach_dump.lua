-- Grail Achievement Data Dump for Midnight (Quel'Thalas)
-- Run in KazDebug (/kd) then copy output
-- Walks achievement categories to find Midnight quest achievements,
-- outputs in Grail's G[questID] = {zoneMapID, 500000+achID} format

local BASE = 500000 -- Grail.mapAreaBaseAchievement

-- Midnight zone mapIDs (from Grail)
local MIDNIGHT_ZONES = {
    [2393] = "Silvermoon City",
    [2395] = "Eversong Woods",
    [2536] = "Atal'Aman",
    [2437] = "Zul'Aman",
    [2413] = "Harandar",
    [2405] = "Voidstorm",
    [2444] = "Slayer's Rise",
    [2537] = "Quel'Thalas (continent)",
}

-- Criteria type constants
local CRITERIA_TYPE_QUEST = 27  -- complete specific quest
local CRITERIA_TYPE_ACH = 8    -- sub-achievement

-- Collect all categories
local cats = GetCategoryList()
print("=== SCANNING " .. #cats .. " ACHIEVEMENT CATEGORIES ===")

-- Find Midnight-related categories
local midnightCats = {}
for _, catID in ipairs(cats) do
    local name, parentID = GetCategoryInfo(catID)
    if name then
        local lname = name:lower()
        if lname:find("midnight") or lname:find("quel'thalas") or lname:find("quelth")
           or lname:find("silvermoon") or lname:find("eversong") or lname:find("zul'aman")
           or lname:find("harandar") or lname:find("voidstorm") or lname:find("atal'aman") then
            midnightCats[catID] = name
            print("  Found category: " .. catID .. " = " .. name .. " (parent: " .. tostring(parentID) .. ")")
        end
        -- Also check parent chains — "Quests" subcategories for Midnight
        if parentID and parentID > 0 then
            local parentName = GetCategoryInfo(parentID)
            if parentName then
                local lpn = parentName:lower()
                if lpn:find("midnight") or lpn:find("quel'thalas") then
                    midnightCats[catID] = name .. " (under " .. parentName .. ")"
                    print("  Found sub-category: " .. catID .. " = " .. name .. " under " .. parentName)
                end
            end
        end
    end
end

-- Also scan the Quests > Midnight category specifically
-- Walk all categories to find "Quests" parent, then Midnight under it
local questsCatID = nil
for _, catID in ipairs(cats) do
    local name, parentID = GetCategoryInfo(catID)
    if name == "Quests" and (parentID == -1 or parentID == 0) then
        questsCatID = catID
        break
    end
end

if questsCatID then
    print("\nQuests root category: " .. questsCatID)
    for _, catID in ipairs(cats) do
        local name, parentID = GetCategoryInfo(catID)
        if parentID == questsCatID then
            print("  Quests sub: " .. catID .. " = " .. tostring(name))
            -- Check for Midnight expansion sub-categories
            for _, subCatID in ipairs(cats) do
                local subName, subParent = GetCategoryInfo(subCatID)
                if subParent == catID then
                    local ln = (subName or ""):lower()
                    if ln:find("midnight") or ln:find("quel") or ln:find("silvermoon")
                       or ln:find("eversong") or ln:find("zul") or ln:find("harandar")
                       or ln:find("voidstorm") or ln:find("atal") then
                        midnightCats[subCatID] = subName
                        print("    >> MIDNIGHT: " .. subCatID .. " = " .. subName)
                    end
                end
            end
        end
    end
end

-- Also look for Exploration > Midnight
local exploreCatID = nil
for _, catID in ipairs(cats) do
    local name, parentID = GetCategoryInfo(catID)
    if name == "Exploration" and (parentID == -1 or parentID == 0) then
        exploreCatID = catID
        break
    end
end

if exploreCatID then
    print("\nExploration root category: " .. exploreCatID)
    for _, catID in ipairs(cats) do
        local name, parentID = GetCategoryInfo(catID)
        if parentID == exploreCatID then
            local ln = (name or ""):lower()
            if ln:find("midnight") or ln:find("quel") then
                midnightCats[catID] = name
                print("  >> MIDNIGHT EXPLORE: " .. catID .. " = " .. name)
            end
        end
    end
end

print("\n=== MIDNIGHT CATEGORIES FOUND: " .. (function() local n=0; for _ in pairs(midnightCats) do n=n+1 end; return n end)() .. " ===")

-- Now dump all achievements in these categories
local questToAch = {} -- questID -> { achIDs }
local achInfo = {}     -- achID -> { name, categoryName, isLoremaster }
local subAchs = {}     -- achID -> { subAchIDs } for meta-achievements

print("\n=== ACHIEVEMENT DETAILS ===")
for catID, catName in pairs(midnightCats) do
    local numAch = GetCategoryNumAchievements(catID)
    print("\n-- Category: " .. catName .. " (" .. catID .. ") — " .. numAch .. " achievements")

    for i = 1, numAch do
        local achID, achName, points, completed, month, day, year, desc, flags, icon, rewardText, isGuild, wasEarnedByMe = GetAchievementInfo(catID, i)
        if achID then
            local numCriteria = GetAchievementNumCriteria(achID)
            local isLoremaster = desc and (desc:lower():find("complete") and desc:lower():find("quest")) or false
            achInfo[achID] = { name = achName, cat = catName, criteria = numCriteria, desc = desc, isLoremaster = isLoremaster }

            print(string.format("  [%d] %s (%d criteria) — %s", achID, achName, numCriteria, desc or ""))

            for j = 1, numCriteria do
                local critName, critType, critCompleted, quantity, reqQuantity, charName, critFlags, assetID, quantityString = GetAchievementCriteriaInfo(achID, j)
                if critType == CRITERIA_TYPE_QUEST and assetID and assetID > 0 then
                    -- Quest-based criteria
                    if not questToAch[assetID] then questToAch[assetID] = {} end
                    if not tContains(questToAch[assetID], achID) then
                        tinsert(questToAch[assetID], achID)
                    end
                elseif critType == CRITERIA_TYPE_ACH and assetID and assetID > 0 then
                    -- Sub-achievement criteria (meta-achievement)
                    if not subAchs[achID] then subAchs[achID] = {} end
                    tinsert(subAchs[achID], assetID)
                    print(string.format("    sub-ach: %d (%s)", assetID, critName or "?"))
                end

                if critType == CRITERIA_TYPE_QUEST then
                    print(string.format("    quest: %d (%s)", assetID or 0, critName or "?"))
                end
            end
        end
    end
end

-- Build reverse: for meta-achievements, walk sub-achievements for their quests too
print("\n=== RESOLVING META-ACHIEVEMENTS ===")
for metaAchID, subs in pairs(subAchs) do
    print("Meta: " .. metaAchID .. " (" .. (achInfo[metaAchID] and achInfo[metaAchID].name or "?") .. ")")
    for _, subAchID in ipairs(subs) do
        local numCrit = GetAchievementNumCriteria(subAchID)
        local subName = select(2, GetAchievementInfo(subAchID))
        print("  Sub " .. subAchID .. " (" .. (subName or "?") .. ") — " .. numCrit .. " criteria")
        for j = 1, numCrit do
            local critName, critType, _, _, _, _, _, assetID = GetAchievementCriteriaInfo(subAchID, j)
            if critType == CRITERIA_TYPE_QUEST and assetID and assetID > 0 then
                if not questToAch[assetID] then questToAch[assetID] = {} end
                -- Map quest to BOTH the sub-achievement and meta-achievement
                if not tContains(questToAch[assetID], subAchID) then
                    tinsert(questToAch[assetID], subAchID)
                end
            end
        end
    end
end

-- Output Grail G[] format
-- We need the zone mapID for each quest. Use 2537 (Quel'Thalas continent) as default
-- since we can't easily determine sub-zone from achievement data alone
local DEFAULT_ZONE = 2537

print("\n\n========================================")
print("=== GRAIL G[] FORMAT OUTPUT ===")
print("========================================")
print("-- Midnight achievement quest mappings")
print("-- G[questID] = {zoneMapID, 500000+achID, ...}")
print("-- Zone: " .. DEFAULT_ZONE .. " (Quel'Thalas)")
print("")

-- Sort by questID for clean output
local sortedQuests = {}
for qid in pairs(questToAch) do
    tinsert(sortedQuests, qid)
end
table.sort(sortedQuests)

for _, qid in ipairs(sortedQuests) do
    local achs = questToAch[qid]
    local parts = { tostring(DEFAULT_ZONE) }
    for _, achID in ipairs(achs) do
        tinsert(parts, tostring(BASE + achID))
    end
    print("G[" .. qid .. "]={" .. table.concat(parts, ",") .. "}")
end

print("\n\n========================================")
print("=== ACHIEVEMENT ID LISTS (for loremasterAchievements / extraAchievements) ===")
print("========================================")

-- Separate loremaster vs extra based on description heuristics
local loremaster = {}
local extra = {}

for achID, info in pairs(achInfo) do
    local desc = (info.desc or ""):lower()
    -- Loremaster achievements typically say "Complete X quests in ZONE"
    -- or are the zone-specific completion achievements
    if desc:find("loremaster") or (desc:find("complete") and desc:find("quest") and not desc:find("daily")) then
        tinsert(loremaster, achID)
    else
        tinsert(extra, achID)
    end
    print(string.format("  %d: %s — %s [%s]", achID, info.name, info.desc or "", info.cat))
end

table.sort(loremaster)
table.sort(extra)

print("\n-- Loremaster candidates (paste into loremasterAchievements[mapQuelThalas]):")
print("{ " .. table.concat(loremaster, ", ") .. " }")

print("\n-- Extra candidates (paste into extraAchievements[mapQuelThalas]):")
print("{ " .. table.concat(extra, ", ") .. " }")

-- Also dump achievementsToZoneMapping entries if we can detect zones
print("\n\n========================================")
print("=== ACHIEVEMENT TO ZONE MAPPING ===")
print("========================================")
print("-- Add to achievementsToZoneMapping table")
print("-- (all mapped to 2537/Quel'Thalas for now — refine per sub-zone later)")
local allAchs = {}
for achID in pairs(achInfo) do tinsert(allAchs, achID) end
table.sort(allAchs)
for _, achID in ipairs(allAchs) do
    print(string.format("  [%d] = %d, -- %s", BASE + achID, DEFAULT_ZONE, achInfo[achID].name))
end

local questCount = 0
for _ in pairs(questToAch) do questCount = questCount + 1 end
print("\n=== DONE: " .. questCount .. " quests across " .. #allAchs .. " achievements ===")
