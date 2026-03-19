local UnitIsPlayer = UnitIsPlayer
local UnitClass = UnitClass
local UnitExists = UnitExists
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local GetNamePlateForUnit = C_NamePlate.GetNamePlateForUnit
local InCombatLockdown = InCombatLockdown

local prevFrame, prevUnit, prevHealthBar
local prevR, prevG, prevB

local function ClearHighlight()
    if prevHealthBar and prevR then
        prevHealthBar:SetStatusBarColor(prevR, prevG, prevB)
    end

    if prevFrame then
        local uf = prevFrame.UnitFrame
        if uf and uf.__WMT_scaled and uf.__WMT_originalScale then
            if not InCombatLockdown() then
                uf:SetScale(uf.__WMT_originalScale)
            end
            uf.__WMT_scaled = nil
        end
    end

    prevFrame, prevUnit, prevHealthBar = nil, nil, nil
    prevR, prevG, prevB = nil, nil, nil
end

local function GetTargetColor(unit)
    if UnitIsPlayer(unit) then
        local class = select(2, UnitClass(unit))
        local color = class and RAID_CLASS_COLORS[class]
        if color then
            return color.r, color.g, color.b
        end
    end
    return 0, 0.8, 0.8
end

local function SetColorIfDifferent(bar, r, g, b)
    local cr, cg, cb = bar:GetStatusBarColor()
    if cr ~= r or cg ~= g or cb ~= b then
        bar:SetStatusBarColor(r, g, b)
    end
end

local function HighlightPlate(plate)
    if not plate then
        return
    end
    if prevFrame == plate then
        return
    end

    local uf = plate.UnitFrame
    if not uf or not uf.unit then
        return
    end

    ClearHighlight()

    prevFrame = plate
    prevUnit = uf.unit

    if not uf.__WMT_originalScale then
        uf.__WMT_originalScale = uf:GetScale()
    end

    if not uf.__WMT_scaled and not InCombatLockdown() then
        uf:SetScale(uf.__WMT_originalScale * 1.25)
        uf.__WMT_scaled = true
    end

    local healthBar = uf.healthBar
    if healthBar then
        prevHealthBar = healthBar
        prevR, prevG, prevB = healthBar:GetStatusBarColor()

        local r, g, b = GetTargetColor(prevUnit)
        SetColorIfDifferent(healthBar, r, g, b)
    end
end

local function UpdateHighlight()
    if not UnitExists("target") then
        ClearHighlight()
        return
    end

    local plate = GetNamePlateForUnit("target")
    if plate then
        HighlightPlate(plate)
    else
        ClearHighlight()
    end
end

local f = CreateFrame("Frame")

f:RegisterEvent("PLAYER_TARGET_CHANGED")
f:RegisterEvent("NAME_PLATE_UNIT_ADDED")
f:RegisterEvent("NAME_PLATE_UNIT_REMOVED")

f:SetScript(
    "OnEvent",
    function(_, event, unit)
        if event == "PLAYER_TARGET_CHANGED" then
            UpdateHighlight()
        elseif event == "NAME_PLATE_UNIT_ADDED" then
            if unit == "target" then
                UpdateHighlight()
            end
        elseif event == "NAME_PLATE_UNIT_REMOVED" then
            if prevUnit and unit == prevUnit then
                ClearHighlight()
            end
        end
    end
)


hooksecurefunc(
    "CompactUnitFrame_UpdateHealth",
    function(frame)
        if not prevUnit then
            return
        end
        if not frame or frame.unit ~= prevUnit then
            return
        end

        local healthBar = frame.healthBar
        if not healthBar then
            return
        end

        local r, g, b = GetTargetColor(prevUnit)
        SetColorIfDifferent(healthBar, r, g, b)
    end
)

-- initial
UpdateHighlight()
