local InventoryFunctions = require "util/inventoryfunctions"
local CraftFunctions = require "util/craftfunctions"

local CRAFTING_ALLOWED = GetModConfigData("AUTO_EQUIP_TOOL", MOD_EQUIPMENT_CONTROL.MODNAME) == 2
local AUTO_REPEAT_ACTIONS = GetModConfigData("AUTO_REPEAT_ACTIONS", MOD_EQUIPMENT_CONTROL.MODNAME)

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

-- Create a custom action for crafting display
local ModCraftAction = Action({ priority = 10 })
ModCraftAction.id = "MODCRAFT"
ModCraftAction.str = "Craft"

local function Init()
    local player = ThePlayer
    if not player then return end
    
    local PlayerActionPicker = player.components.playeractionpicker
    local PlayerController = player.components.playercontroller
    if not PlayerActionPicker or not PlayerController then return end
    
    -- Store pending action info
    local pendingAction = nil
    local workTarget = nil -- Track what we're currently working on
    
    -- Override mouse action picking
    local _DoGetMouseActions = PlayerActionPicker.DoGetMouseActions
    function PlayerActionPicker:DoGetMouseActions(...)
        local lmb, rmb = _DoGetMouseActions(self, ...)
        
        -- Only override if no active item and current action is replaceable
        if not InventoryFunctions:GetActiveItem() and 
           not InventoryFunctions:IsHeavyLifting() and
           (not lmb or lmb.action == ACTIONS.WALKTO or lmb.action == ACTIONS.LOOKAT) then
            
            local target = TheInput:GetWorldEntityUnderMouse()
            if target and CanEntitySeeTarget(self.inst, target) then
                local toolAction = GetToolAction(target)
                if toolAction then
                    local tool, needsCraft = FindTool(toolAction)
                    if tool then
                        if needsCraft then
                            -- For crafting, use our custom action
                            lmb = BufferedAction(self.inst, target, ModCraftAction)
                            lmb.CRAFT = tool
                            lmb.DOACTION = ACTIONS[toolAction]
                            -- Override the string function to show "Craft [item]"
                            lmb.GetActionString = function()
                                local itemname = STRINGS.NAMES[string.upper(tool)] or tool
                                return "Craft " .. itemname
                            end
                        else
                            -- For equipping, use the actual tool action
                            lmb = BufferedAction(self.inst, target, ACTIONS[toolAction], tool)
                            lmb.AUTOEQUIP = tool
                        end
                    end
                end
            end
        end
        
        return lmb, rmb
    end
    
    -- Handle our custom actions
    local _OnLeftClick = PlayerController.OnLeftClick
    function PlayerController:OnLeftClick(down)
        if down then
            -- Clear work target when clicking something new
            workTarget = nil
            
            local act = self:GetLeftMouseAction()
            if act then
                -- Track work targets
                if act.action == ACTIONS.CHOP or act.action == ACTIONS.MINE then
                    workTarget = act.target
                end
                
                if act.AUTOEQUIP then
                    -- Store action info for after equip
                    pendingAction = {
                        target = act.target,
                        action = act.action,
                        tool = act.invobject
                    }
                    -- Equip the tool
                    InventoryFunctions:Equip(act.invobject)
                    return
                elseif act.CRAFT then
                    -- Store action info for after craft
                    pendingAction = {
                        target = act.target,
                        action = act.DOACTION,
                        crafting = act.CRAFT
                    }
                    -- Clear buffered action and craft
                    if player.sg then
                        player:ClearBufferedAction()
                    end
                    CraftFunctions:Craft(act.CRAFT)
                    return
                end
            end
        end
        
        _OnLeftClick(self, down)
    end
    
    -- Function to perform the pending action
    local function PerformPendingAction(item)
        if pendingAction and pendingAction.target and pendingAction.target:IsValid() then
            local target = pendingAction.target
            local action = pendingAction.action
            local position = target:GetPosition()
            
            -- Set work target for auto-repeat
            if action == ACTIONS.CHOP or action == ACTIONS.MINE then
                workTarget = target
            end
            
            pendingAction = nil
            
            -- Send the action to server
            player:DoTaskInTime(FRAMES * 2, function()
                if target and target:IsValid() and action then
                    if player.components.locomotor == nil then
                        SendRPCToServer(
                            RPC.LeftClick,
                            action.code,
                            position.x,
                            position.z,
                            target
                        )
                    else
                        local act = BufferedAction(player, target, action, item)
                        act.preview_cb = function()
                            SendRPCToServer(
                                RPC.LeftClick,
                                action.code,
                                position.x,
                                position.z,
                                target
                            )
                        end
                        player.components.locomotor:PreviewAction(act, true)
                    end
                end
            end)
        end
    end
    
    -- Listen for equip event to perform the pending action
    player:ListenForEvent("equip", function(inst, data)
        if pendingAction and data and data.item then
            -- Check if this is the tool we were waiting for
            if (pendingAction.tool and data.item == pendingAction.tool) or
               (pendingAction.crafting and data.item.prefab == pendingAction.crafting) then
                PerformPendingAction(data.item)
            end
        end
    end)
    
    -- Add auto-repeat functionality
    if AUTO_REPEAT_ACTIONS then
        -- Override OnControl to detect when player cancels
        local _OnControl = PlayerController.OnControl
        function PlayerController:OnControl(control, down)
            -- Clear work target on any movement or action
            if down and (control == CONTROL_MOVE_UP or control == CONTROL_MOVE_DOWN or 
                        control == CONTROL_MOVE_LEFT or control == CONTROL_MOVE_RIGHT or
                        control == CONTROL_PRIMARY or control == CONTROL_SECONDARY) then
                workTarget = nil
            end
            return _OnControl(self, control, down)
        end
        
        -- Check if we should repeat work action
        local function ShouldRepeatWork()
            if not workTarget or not workTarget:IsValid() then
                return false
            end
            
            -- Only repeat if we're still near the target
            local dist = player:GetDistanceSqToInst(workTarget)
            if dist > 16 then -- 4 units squared
                workTarget = nil
                return false
            end
            
            -- Only repeat if target still needs work
            if not (workTarget:HasTag("CHOP_workable") or workTarget:HasTag("MINE_workable")) then
                workTarget = nil
                return false
            end
            
            return true
        end
        
        if TheWorld.ismastersim then
            -- Server-side: modify IsAnyOfControlsPressed
            local _IsAnyOfControlsPressed = PlayerController.IsAnyOfControlsPressed
            function PlayerController:IsAnyOfControlsPressed(...)
                if IsInWorkAnimation(self.inst) and ShouldRepeatWork() then
                    for _, control in ipairs({...}) do
                        if control == CONTROL_ACTION then
                            return true
                        end
                    end
                end
                return _IsAnyOfControlsPressed(self, ...)
            end
        else
            -- Client-side: trigger action in OnUpdate
            local _OnUpdate = PlayerController.OnUpdate
            function PlayerController:OnUpdate(...)
                if IsInWorkAnimation(self.inst) and ShouldRepeatWork() then
                    -- Only repeat work actions on the same target
                    local act = self:GetActionButtonAction()
                    if act and act.target == workTarget and 
                       (act.action == ACTIONS.CHOP or act.action == ACTIONS.MINE) then
                        self:OnControl(CONTROL_ACTION, true)
                    end
                end
                _OnUpdate(self, ...)
            end
        end
    end
end

return Init