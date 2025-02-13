
--#region dependencies

local UpvalueHacker = GLOBAL.require("tools/upvaluehacker")
local tablecopy = GLOBAL.require("tools/tablecopy")
-- local stacktrace = GLOBAL.require("tools/stacktrace")

--#endregion

--#region Config

---@param config string
local function GetKeyFromConfig(config)
    local key = GetModConfigData(config)
    return key and (type(key) == "number" and key or GLOBAL[key])
end

---@type integer
local NIGHTVISION_TOGGLE_KEY = GetKeyFromConfig("NIGHTVISION_TOGGLE_KEY") or false

---@type boolean
local NIGHTVISION_NOTIFY_ENABLE = GetModConfigData("NIGHTVISION_NOTIFY_ENABLE") or true

---@type number
local VISION_BLENDTIME = GetModConfigData("VISION_BLENDTIME") or (1/60)

---@type boolean
local NIGHTVISION_DARKNESS_ACTION_ENABLE = GetModConfigData("NIGHTVISION_DARKNESS_ACTION_ENABLE") or true

---@type boolean
local NIGHTVISION_DARKNESS_ALERT_ENABLE = GetModConfigData("NIGHTVISION_DARKNESS_ALERT_ENABLE") or true

---@type number
local NIGHTVISION_DARKNESS_ALERT_TRESHOLD = GetModConfigData("NIGHTVISION_DARKNESS_ALERT_TRESHOLD") or 0.1

---@type number
local NIGHTVISION_DARKNESS_ALERT_FREQUENCY = GetModConfigData("NIGHTVISION_DARKNESS_ALERT_FREQUENCY") or 0.1

---@type 0|1|2|3
local NIGHTVISION_COLORCUBES_PATCH_MODE = GetModConfigData("NIGHTVISION_COLORCUBES_PATCH_MODE") or 1

---@type 0|1|2|3
local GHOSTVISION_COLORCUBES_PATCH_MODE = GetModConfigData("GHOSTVISION_COLORCUBES_PATCH_MODE") or 1

---@type number|false
local NIGHTVISION_STRENGTH = GetModConfigData("NIGHTVISION_STRENGTH") or false

--#endregion

---@type boolean
local nightvision_active = false

---@return boolean
local function InGame()
    --[[
        Part of this was recommended by "Tony",
        Can be found in the steam workshop mod's comments
        This is used to fix a crash
            when using the night vision toggle key outside of a game

        Thanks
    ]]

    if not GLOBAL.ThePlayer then
        return false
    end

    if not GLOBAL.ThePlayer.HUD then
        return false
    end

    if GLOBAL.ThePlayer.HUD:HasInputFocus() then
        return false
    end

    local screen = GLOBAL.TheFrontEnd:GetActiveScreen() and GLOBAL.TheFrontEnd:GetActiveScreen().name or ""
    if screen:find("HUD") == nil then
        return false
    end

    return true

end

---@return boolean
local function PlayerIsGhost(player)
    -- dont ask
    return player:HasTag("playerghost") == true
end

---@return boolean
local function PlayerHasMoggles(player)
    -- dont ask
    return player.replica.inventory:EquipHasTag("nightvision") == true
end

local nightvision_phasefn = {
    blendtime = VISION_BLENDTIME,
    events = {
    },
    fn = nil,
}

local function ResetVision(player)
    -- print("ROCKOU ResetVision")
    if GHOSTVISION_COLORCUBES_PATCH_MODE == 0 and NIGHTVISION_COLORCUBES_PATCH_MODE == 0 then
        return
    end

    local playervision = player.components.playervision

    local old_forcenightvision = playervision.forcenightvision
    local old_nightvision = playervision.nightvision
    local old_ghostvision = playervision.ghostvision

    if nightvision_active then
        -- override default filters
        -- only ghost and night vision
        -- will not override nightmare filter from caves

        if GHOSTVISION_COLORCUBES_PATCH_MODE >= 1 then
            playervision.ghostvision = false
        end
        if NIGHTVISION_COLORCUBES_PATCH_MODE >= 1 then
            playervision.forcenightvision = false
            playervision.nightvision = false
        end
        
    end

    playervision:UpdateCCTable()
    player:PushEvent("ccoverrides", playervision.currentcctable)
    player:PushEvent("ccphasefn", nightvision_phasefn)

    playervision.forcenightvision = old_forcenightvision
    playervision.nightvision = old_nightvision
    playervision.ghostvision = old_ghostvision
end

local function ToggleNightVision()
    if not InGame() then return end

    if  GLOBAL.ThePlayer == nil or
        GLOBAL.ThePlayer.components == nil or
        GLOBAL.ThePlayer.components.playervision == nil
    then return end

    local player = GLOBAL.ThePlayer
    local playervision = GLOBAL.ThePlayer.components.playervision

    nightvision_active = not nightvision_active

    --#region disable or enable actions

    if NIGHTVISION_DARKNESS_ACTION_ENABLE then
        -- playervision.nightvision = nightvision_active
        playervision.forcenightvision = nightvision_active
    end

    --#endregion

    --#region basic nightvision

    -- must be before ambientlighting override
    -- because ambientlighting listens to nightvision events to set the visual ambientlighting
    player:PushEvent("nightvision", nightvision_active)

    --#endregion

    --#region night vision brightness

    if NIGHTVISION_STRENGTH ~= false then
        local overrideVisualColor = Point(NIGHTVISION_STRENGTH, NIGHTVISION_STRENGTH, NIGHTVISION_STRENGTH)
        GLOBAL.TheWorld:PushEvent("overridevisualambientlighting", nightvision_active and overrideVisualColor or nil)
        if not nightvision_active then
            -- breaks lightwatcher and darkness alert if used wrong
            GLOBAL.TheWorld:PushEvent("overrideambientlighting", nil)
        end
    end

    --#endregion

    --#region re-establish normal vision if we disable
    
    ResetVision(player)

    --#endregion

    --#region tell nightvision status

    if NIGHTVISION_NOTIFY_ENABLE then
        GLOBAL.ThePlayer.components.talker:Say("Night Vision: "..tostring(nightvision_active))
    end

    --#endregion

    -- GLOBAL.ThePlayer.components.talker:Say(
    --     "ToggleNightVision\n"..
    --     "Night Vision: "..tostring(nightvision_active).."\n"..
    --     "PlayerIsGhost: "..tostring(PlayerIsGhost(player)).."\n"..
    --     "PlayerHasMoggles: "..tostring(PlayerHasMoggles(player)).."\n"..
    --     "ghostvision: "..tostring(playervision.ghostvision).."\n"..
    --     "nightvision: "..tostring(playervision.nightvision).."\n"..
    --     "forcenightvision: "..tostring(playervision.forcenightvision))

end

-- detect when the toggle key is pressed
GLOBAL.TheInput:AddKeyUpHandler(NIGHTVISION_TOGGLE_KEY, ToggleNightVision)

--#region Darkness Alert

---@type number
local NIGHTVISION_DARKNESS_ALERT_SCALE_MODIFIER = 0.75
---@type integer
local NIGHTVISION_DARKNESS_ALERT_SCALE_ITERATIONS = 8
---@type integer
local NIGHTVISION_DARKNESS_ALERT_ACTIVE_COUNT_MAX = 2

-- spawn a single darkness alert on an entity
local function SpawnDarknessAlert(parent)

    if not parent then return end

    local inst = GLOBAL.CreateEntity()

    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst:AddTag("CLASSIFIED")
    inst:AddTag("NOCLICK")
    inst:AddTag("placer")

    inst.AnimState:SetBank("winona_battery_placement")
    inst.AnimState:SetBuild("winona_battery_placement")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetLightOverride(1)
    inst.AnimState:SetOrientation(GLOBAL.ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(GLOBAL.LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(1)
    inst.AnimState:SetScale(0, 0)
    inst.AnimState:SetAddColour(1,0,0,0)
    inst.entity:SetParent(parent.entity)

    for i=0, NIGHTVISION_DARKNESS_ALERT_SCALE_ITERATIONS do
        inst:DoTaskInTime(GLOBAL.FRAMES*i, function(inst)
            local size = i/NIGHTVISION_DARKNESS_ALERT_SCALE_ITERATIONS * NIGHTVISION_DARKNESS_ALERT_SCALE_MODIFIER
            inst.AnimState:SetScale(size, size)
        end)
        -- plus one to leave a frame between both sets of iterations
        inst:DoTaskInTime(GLOBAL.FRAMES*(NIGHTVISION_DARKNESS_ALERT_SCALE_ITERATIONS+i+1), function(inst)
            local size = (NIGHTVISION_DARKNESS_ALERT_SCALE_ITERATIONS-i)/NIGHTVISION_DARKNESS_ALERT_SCALE_ITERATIONS * NIGHTVISION_DARKNESS_ALERT_SCALE_MODIFIER
            inst.AnimState:SetScale(size, size)
        end)
    end

    -- time for both iterations
    -- plus one to leave a frame between both sets of iterations
    -- plus one to leave a frame between the end of the last iteration and its deletion
    inst:DoTaskInTime(GLOBAL.FRAMES*(NIGHTVISION_DARKNESS_ALERT_SCALE_ITERATIONS*2+1+1), function(inst)
        inst:Remove()
    end)

end

local function TrySpawnDarknessAlert(inst)

    -- if inst.LightWatcher then
    --     GLOBAL.ThePlayer.components.talker:Say("TrySpawnDarknessAlert\nLightValue: ".. inst.LightWatcher:GetLightValue())
    -- end

    local time_until_next_attempt = NIGHTVISION_DARKNESS_ALERT_FREQUENCY
    
    if inst.LightWatcher and inst.LightWatcher:GetLightValue() < NIGHTVISION_DARKNESS_ALERT_TRESHOLD and nightvision_active then
        -- this should allow it to be slightly more responsive with low framerate
        local time_between_alerts = (GLOBAL.FRAMES*(NIGHTVISION_DARKNESS_ALERT_SCALE_ITERATIONS*2+1))/NIGHTVISION_DARKNESS_ALERT_ACTIVE_COUNT_MAX
        time_until_next_attempt = math.max(time_between_alerts, NIGHTVISION_DARKNESS_ALERT_FREQUENCY)
        
        SpawnDarknessAlert(inst)
    end

    inst:DoTaskInTime(time_until_next_attempt, TrySpawnDarknessAlert)

end

local function OnPlayerPostInit_DarknessAlert(inst)
    if NIGHTVISION_DARKNESS_ALERT_ENABLE then
        -- inst:DoPeriodicTask(DARKNESS_ALERT_REFRESH_TIME, TrySpawnDarknessAlert)
        inst:DoTaskInTime(0.25, TrySpawnDarknessAlert)
    end
end

--#endregion

--#region listen to external updates to patch around player vision

-- check to change color cubes depending on night vision status and if we have a mole hat or ghost vision

local function PushResetVision(inst)
    -- print("ROCKOU PushResetVision")
    -- print(stacktrace())
    inst:DoTaskInTime(0, ResetVision)
end

local function OnPlayerPostInit_ResetVision(inst)
    if NIGHTVISION_COLORCUBES_PATCH_MODE == 1 or GHOSTVISION_COLORCUBES_PATCH_MODE == 1 then
        inst:ListenForEvent("equip", PushResetVision) -- client only moggle
        inst:ListenForEvent("unequip", PushResetVision) -- client only moggle
        inst:ListenForEvent("inventoryclosed", PushResetVision) -- client only moggle death??

        inst:ListenForEvent("changearea", PushResetVision) -- cave nightmare cycle
        inst:ListenForEvent("phasechange", PushResetVision) -- day cycle phase change

        -- death and revive
        if inst.player_classified ~= nil then
            inst.player_classified:ListenForEvent("isghostmodedirty", function (inst)
                -- print("ROCKOU Event isghostmodedirty")
                PushResetVision(inst._parent)
            end)
        end
    end
end

--#endregion

function OnPlayerPostInit(inst)
    -- print("ROCKOU OnPlayerPostInit")

    if inst ~= GLOBAL.ThePlayer then return end

    OnPlayerPostInit_ResetVision(inst)

    OnPlayerPostInit_DarknessAlert(inst)

end

if NIGHTVISION_DARKNESS_ALERT_ENABLE == true or NIGHTVISION_COLORCUBES_PATCH_MODE == 1 or GHOSTVISION_COLORCUBES_PATCH_MODE == 1 then

    AddPlayerPostInit(function(inst)
        -- print("ROCKOU AddPlayerPostInit")
        inst:DoTaskInTime(1/60, OnPlayerPostInit)
    end)

end

--#region moggles vision patch / delete

if NIGHTVISION_COLORCUBES_PATCH_MODE == 2 or GHOSTVISION_COLORCUBES_PATCH_MODE == 2 then

    AddComponentPostInit("playervision", function (self)

        local oldUpdateCCTable = self.UpdateCCTable
        local newUpdateCCTable = function (self)
            -- print("ROCKOU newUpdateCCTable")
            -- print(stacktrace())

            local old_forcenightvision = self.forcenightvision
            local old_nightvision = self.nightvision
            local old_ghostvision = self.ghostvision

            if NIGHTVISION_COLORCUBES_PATCH_MODE >= 2 then
                self.forcenightvision = false
                self.nightvision = false
            end
            if GHOSTVISION_COLORCUBES_PATCH_MODE >= 2 then
                self.ghostvision = false
            end

            oldUpdateCCTable(self)
            self.inst:PushEvent("ccoverrides", self.currentcctable)
            self.inst:PushEvent("ccphasefn", nightvision_phasefn)
        
            self.forcenightvision = old_forcenightvision
            self.nightvision = old_nightvision
            self.ghostvision = old_ghostvision

        end
        self.UpdateCCTable = newUpdateCCTable

    end)

end

if NIGHTVISION_COLORCUBES_PATCH_MODE == 3 or GHOSTVISION_COLORCUBES_PATCH_MODE == 3 then

    AddClassPostConstruct("components/playervision", function (self)
        -- luckily basically everything in playervision is public except for some constants
        -- this gives us easy access to those privates
        if NIGHTVISION_COLORCUBES_PATCH_MODE == 3 then
            UpvalueHacker.SetUpvalue(self.UpdateCCTable, nil, "NIGHTVISION_COLOURCUBES")
        end
        if GHOSTVISION_COLORCUBES_PATCH_MODE == 3 then
            UpvalueHacker.SetUpvalue(self.UpdateCCTable, nil, "GHOSTVISION_COLOURCUBES")
        end
    end)

end

--#endregion

--#region brightness

if NIGHTVISION_STRENGTH ~= false then

    local function GetColorsFromRGB(rgb)
        return {
            PHASE_COLOURS =
            {
                default =
                {
                    day = { colour = rgb, time = 0 },
                    dusk = { colour = rgb, time = 0 },
                    night = { colour = rgb, time = 0 },
                },
            },
        
            FULL_MOON_COLOUR = { colour = rgb, time = 0 },
            CAVE_COLOUR = { colour = rgb, time = 0 },
        }
    end

    AddClassPostConstruct("components/ambientlighting", function(self)
        -- print("ROCKOU_ AddClassPostConstruct(\"components/ambientlighting\", function(self)")

        -- local realcolor = UpvalueHacker.GetUpvalue(self.OnUpdate, "_realcolour")

        local overridecolor = UpvalueHacker.GetUpvalue(self.OnUpdate, "_overridecolour")

        local computeTargetColor = UpvalueHacker.GetUpvalue(self.OnUpdate, "DoUpdateFlash", "ComputeTargetColour")
        local pushCurrentColour = UpvalueHacker.GetUpvalue(self.OnUpdate, "PushCurrentColour")
        local normalColors = tablecopy(overridecolor.currentcolourset)

        -- print("ROCKOU_", realcolor, overridecolor, computeTargetColor, pushCurrentColour, normalColors)

        local OverrideVisualAmbiantLighting = function(inst, newVisualColor)
            -- print("ROCKOU_ function(newVisualColor)", inst, newVisualColor)
            overridecolor.currentcolourset = newVisualColor ~= nil and GetColorsFromRGB(newVisualColor) or normalColors

            computeTargetColor(overridecolor, 0)

            pushCurrentColour()
        end
        GLOBAL.TheWorld:ListenForEvent("overridevisualambientlighting", OverrideVisualAmbiantLighting)

    end)

end

--#endregion
