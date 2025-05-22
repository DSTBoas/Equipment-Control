local InventoryFunctions = require "util/inventoryfunctions"
local CraftFunctions = require "util/craftfunctions"

local CRAFTING_ALLOWED = GetModConfigData("AUTO_EQUIP_TOOL", GLOBAL.MOD_EQUIPMENT_CONTROL.MODNAME) == 2
local AUTO_REPEAT_ACTIONS = GetModConfigData("AUTO_REPEAT_ACTIONS", GLOBAL.MOD_EQUIPMENT_CONTROL.MODNAME)

local CRAFTABLE_TOOLS = {
    CHOP = { "goldenaxe", "axe" },
    MINE = { "goldenpickaxe", "pickaxe" },
}

local WORK_ANIMATIONS = {
    "woodie_chop_pre",
    "woodie_chop_loop",
    "chop_pre",
    "chop_loop",
    "pickaxe_pre",
    "pickaxe_loop",
}

-- Create a custom action for crafting display
local ModCraftAction = GLOBAL.Action({ priority = 10 })
ModCraftAction.id = "MODCRAFT"
ModCraftAction.str = "Craft"
ModCraftAction.stroverridefn = function(act)
    local itemname = GLOBAL.STRINGS.NAMES[string.upper(act.CRAFT)] or act.CRAFT
    return "Craft " .. itemname
end

local function GetToolAction(target)
    for action in pairs(CRAFTABLE_TOOLS) do
        if target:HasTag(action .. "_workable") then
            return action
        end
    end
end

local function FindTool(action)
    -- Check inventory first
    for _, item in pairs(InventoryFunctions:GetPlayerInventory()) do
        if item:HasTag(action .. "_tool") then
            return item, false
        end
    end
    
    -- Check if we can craft
    if CRAFTING_ALLOWED then
        for _, prefab in ipairs(CRAFTABLE_TOOLS[action]) do
            if CraftFunctions:KnowsRecipe(prefab) and CraftFunctions:CanCraft(prefab) then
                return prefab, true
            end
        end
    end
end

local function IsInWorkAnimation(inst)
    if not inst.AnimState then return false end
    
    for _, anim in ipairs(WORK_ANIMATIONS) do
        if inst.AnimState:IsCurrentAnimation(anim) then
            return true
        end
    end
    
    -- Special case for beaver form
    if inst:HasTag("beaver") and not inst:HasTag("attack") and 
       inst.AnimState:IsCurrentAnimation("atk") then
        return true
    end
    
    return false
end

-- Add post construct for PlayerActionPicker
AddClassPostConstruct("components/playeractionpicker", function(self)
    if self.inst ~= GLOBAL.ThePlayer then
        return
    end
    
    local _DoGetMouseActions = self.DoGetMouseActions
    function self:DoGetMouseActions(...)
        local lmb, rmb = _DoGetMouseActions(self, ...)
        
        -- Only override if no active item and current action is replaceable
        if not InventoryFunctions:GetActiveItem() and 
           not InventoryFunctions:IsHeavyLifting() and
           (not lmb or lmb.action == GLOBAL.ACTIONS.WALKTO or lmb.action == GLOBAL.ACTIONS.LOOKAT) then
            
            local target = GLOBAL.TheInput:GetWorldEntityUnderMouse()
            if target and GLOBAL.CanEntitySeeTarget(self.inst, target) then
                local toolAction = GetToolAction(target)
                if toolAction then
                    local tool, needsCraft = FindTool(toolAction)
                    if tool then
                        if needsCraft then
                            -- For crafting, use our custom action
                            lmb = GLOBAL.BufferedAction(self.inst, target, ModCraftAction)
                            lmb.CRAFT = tool
                            lmb.DOACTION = GLOBAL.ACTIONS[toolAction]
                        else
                            -- For equipping, use the actual tool action
                            lmb = GLOBAL.BufferedAction(self.inst, target, GLOBAL.ACTIONS[toolAction], tool)
                            lmb.AUTOEQUIP = tool
                        end
                    end
                end
            end
        end
        
        return lmb, rmb
    end
end)

-- Add post construct for PlayerController
AddClassPostConstruct("components/playercontroller", function(self)
    if self.inst ~= GLOBAL.ThePlayer then
        return
    end
    
    -- Store state
    self.autotool_workTarget = nil
    self.autotool_pendingAction = nil
    
    -- Override OnLeftClick
    local _OnLeftClick = self.OnLeftClick
    function self:OnLeftClick(down)
        if down then
            -- Clear work target when clicking something new
            self.autotool_workTarget = nil
            
            local act = self:GetLeftMouseAction()
            if act then
                -- Track work targets
                if act.action == GLOBAL.ACTIONS.CHOP or act.action == GLOBAL.ACTIONS.MINE then
                    self.autotool_workTarget = act.target
                end
                
                if act.AUTOEQUIP then
                    -- Store action info for after equip
                    self.autotool_pendingAction = {
                        target = act.target,
                        action = act.action,
                        tool = act.invobject
                    }
                    -- Equip the tool
                    InventoryFunctions:Equip(act.invobject)
                    return
                elseif act.CRAFT then
                    -- Store action info for after craft
                    self.autotool_pendingAction = {
                        target = act.target,
                        action = act.DOACTION,
                        crafting = act.CRAFT
                    }
                    -- Clear buffered action and craft
                    if self.inst.sg then
                        self.inst:ClearBufferedAction()
                    end
                    CraftFunctions:Craft(act.CRAFT)
                    return
                end
            end
        end
        
        _OnLeftClick(self, down)
    end
    
    -- Set up the equip event listener
    self.inst:ListenForEvent("equip", function(inst, data)
        if self.autotool_pendingAction and data and data.item then
            local pendingAction = self.autotool_pendingAction
            
            -- Check if this is the tool we were waiting for
            local isCorrectTool = (pendingAction.tool and data.item == pendingAction.tool) or
                                 (pendingAction.crafting and data.item.prefab == pendingAction.crafting)
            
            if isCorrectTool then
                local target = pendingAction.target
                local action = pendingAction.action
                
                -- Clear pending action
                self.autotool_pendingAction = nil
                
                -- Set work target for auto-repeat
                if action == GLOBAL.ACTIONS.CHOP or action == GLOBAL.ACTIONS.MINE then
                    self.autotool_workTarget = target
                end
                
                -- Perform action after delay
                inst:DoTaskInTime(GLOBAL.FRAMES * 4, function()
                    if target and target:IsValid() and action then
                        local position = target:GetPosition()
                        local act = GLOBAL.BufferedAction(inst, target, action, data.item)
                        
                        if self.locomotor == nil then
                            GLOBAL.SendRPCToServer(
                                GLOBAL.RPC.LeftClick,
                                action.code,
                                position.x,
                                position.z,
                                target
                            )
                        else
                            act.preview_cb = function()
                                GLOBAL.SendRPCToServer(
                                    GLOBAL.RPC.LeftClick,
                                    action.code,
                                    position.x,
                                    position.z,
                                    target
                                )
                            end
                            self:DoAction(act)
                        end
                    end
                end)
            end
        end
    end)
    
    -- Auto-repeat functionality
    if AUTO_REPEAT_ACTIONS then
        -- Override OnControl to detect when player cancels
        local _OnControl = self.OnControl
        function self:OnControl(control, down)
            -- Clear work target on any movement or action
            if down and (control == GLOBAL.CONTROL_MOVE_UP or control == GLOBAL.CONTROL_MOVE_DOWN or 
                        control == GLOBAL.CONTROL_MOVE_LEFT or control == GLOBAL.CONTROL_MOVE_RIGHT or
                        control == GLOBAL.CONTROL_PRIMARY or control == GLOBAL.CONTROL_SECONDARY) then
                self.autotool_workTarget = nil
            end
            return _OnControl(self, control, down)
        end
        
        -- Check if we should repeat work action
        local function ShouldRepeatWork()
            if not self.autotool_workTarget or not self.autotool_workTarget:IsValid() then
                return false
            end
            
            -- Only repeat if we're still near the target
            local dist = self.inst:GetDistanceSqToInst(self.autotool_workTarget)
            if dist > 16 then -- 4 units squared
                self.autotool_workTarget = nil
                return false
            end
            
            -- Only repeat if target still needs work
            if not (self.autotool_workTarget:HasTag("CHOP_workable") or self.autotool_workTarget:HasTag("MINE_workable")) then
                self.autotool_workTarget = nil
                return false
            end
            
            return true
        end
        
        if GLOBAL.TheWorld.ismastersim then
            -- Server-side: modify IsAnyOfControlsPressed
            local _IsAnyOfControlsPressed = self.IsAnyOfControlsPressed
            function self:IsAnyOfControlsPressed(...)
                if IsInWorkAnimation(self.inst) and ShouldRepeatWork() then
                    for _, control in ipairs({...}) do
                        if control == GLOBAL.CONTROL_ACTION then
                            return true
                        end
                    end
                end
                return _IsAnyOfControlsPressed(self, ...)
            end
        else
            -- Client-side: trigger action in OnUpdate
            local _OnUpdate = self.OnUpdate
            function self:OnUpdate(...)
                if IsInWorkAnimation(self.inst) and ShouldRepeatWork() then
                    -- Only repeat work actions on the same target
                    local act = self:GetActionButtonAction()
                    if act and act.target == self.autotool_workTarget and 
                       (act.action == GLOBAL.ACTIONS.CHOP or act.action == GLOBAL.ACTIONS.MINE) then
                        self:OnControl(GLOBAL.CONTROL_ACTION, true)
                    end
                end
                _OnUpdate(self, ...)
            end
        end
    end
end)