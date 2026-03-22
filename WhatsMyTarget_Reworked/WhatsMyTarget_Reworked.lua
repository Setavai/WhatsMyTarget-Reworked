local prevPlate = {
    frame = nil,
    unit = nil,
    healthBar = nil,
    healthBarR = nil,
    healthBarG = nil,
    healthBarB = nil,
    scale = nil
}

local function IsDisabledContext()
    local inInstance, instanceType = IsInInstance()

    if inInstance and instanceType == "raid" then
        return true
    end

    if IsInRaid() then
        return true
    end

    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        return true
    end

    return false
end

local function ClearHighlight()
    if prevPlate.healthBar and prevPlate.healthBarR then
        prevPlate.healthBar:SetStatusBarColor(prevPlate.healthBarR, prevPlate.healthBarG, prevPlate.healthBarB)
    end
    if prevPlate.frame and prevPlate.frame.UnitFrame then
        local uf = prevPlate.frame.UnitFrame
        if uf.__WMT_scaled and uf.__WMT_originalScale then
            uf:SetScale(uf.__WMT_originalScale)
            uf.__WMT_scaled = nil
            uf.__WMT_originalScale = nil
        end
    end
    prevPlate.frame = nil
    prevPlate.unit = nil
    prevPlate.healthBar = nil
    prevPlate.healthBarR = nil
    prevPlate.healthBarG = nil
    prevPlate.healthBarB = nil
    prevPlate.scale = nil
end

local function HighlightPlate(plate)
    if IsDisabledContext() then
        ClearHighlight()
        return
    end

    if not plate or not plate.UnitFrame then
        return
    end

    if UnitIsPlayer("target") then
        ClearHighlight()
        return
    end

    ClearHighlight()

    prevPlate.frame = plate
    prevPlate.unit = plate.UnitFrame.unit

    local uf = plate.UnitFrame
    if not uf.__WMT_originalScale then
        uf.__WMT_originalScale = uf:GetScale()
    end
    if not uf.__WMT_scaled then
        uf:SetScale(uf.__WMT_originalScale * 1.25)
        uf.__WMT_scaled = true
    else
        uf:SetScale(uf.__WMT_originalScale * 1.25)
    end
    prevPlate.scale = uf.__WMT_originalScale

    if uf.healthBar then
        prevPlate.healthBar = uf.healthBar
        prevPlate.healthBarR, prevPlate.healthBarG, prevPlate.healthBarB = prevPlate.healthBar:GetStatusBarColor()
        prevPlate.healthBar:SetStatusBarColor(0, 0.8, 0.8)
    end
end

local function UpdateHighlight()
    if IsDisabledContext() then
        ClearHighlight()
        return
    end

    local plate = C_NamePlate.GetNamePlateForUnit("target")
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
f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
f:SetScript("OnEvent", function(_, event, arg1)
    if IsDisabledContext() then
        ClearHighlight()
        return
    end

    if event == "PLAYER_TARGET_CHANGED" or event == "ZONE_CHANGED_NEW_AREA" then
        UpdateHighlight()
    elseif event == "NAME_PLATE_UNIT_ADDED" then
        if UnitIsUnit(arg1, "target") then
            local plate = C_NamePlate.GetNamePlateForUnit("target")
            if plate then
                HighlightPlate(plate)
            end
        end
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        if prevPlate.unit and prevPlate.unit == arg1 then
            ClearHighlight()
        end
    end
end)

hooksecurefunc("CompactUnitFrame_UpdateHealthColor", function(frame)
    if IsDisabledContext() then
        return
    end

    if frame and frame.unit and UnitIsUnit(frame.unit, "target") then
        if UnitIsPlayer("target") then
            return
        end

        local plate = C_NamePlate.GetNamePlateForUnit("target")
        if plate and plate.UnitFrame and plate.UnitFrame.healthBar then
            plate.UnitFrame.healthBar:SetStatusBarColor(0, 0.8, 0.8)
        end
    end
end)

UpdateHighlight()