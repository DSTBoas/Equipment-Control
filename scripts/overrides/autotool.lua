local InventoryFunctions = require "util/inventoryfunctions"
local CraftFunctions = require "util/craftfunctions"

--------------------------------------------------------------------------
--  DEBUG
--------------------------------------------------------------------------
local DEBUG = true
local function dprint(...)
    if DEBUG then print("[AutoTool]", ...) end
end

--------------------------------------------------------------------------
--  CONFIG
--------------------------------------------------------------------------
local CRAFTING_ALLOWED = GLOBAL.GetModConfigData("AUTO_EQUIP_TOOL", GLOBAL.MOD_EQUIPMENT_CONTROL.MODNAME) == 2
local AUTO_REPEAT_ACTIONS = GLOBAL.GetModConfigData("AUTO_REPEAT_ACTIONS", GLOBAL.MOD_EQUIPMENT_CONTROL.MODNAME)

local CRAFTABLE_TOOLS = {
    CHOP = { "goldenaxe", "axe" },
    MINE = { "goldenpickaxe", "pickaxe" },
}

--------------------------------------------------------------------------
--  Custom Craft Action for display
--------------------------------------------------------------------------
local ModCraftAction = GLOBAL.Action({ priority = 10 })
ModCraftAction.id = "MODCRAFT"
ModCraftAction.str = "Craft"
ModCraftAction.stroverridefn = function(act)
    local itemname = GLOBAL.STRINGS.NAMES[string.upper(act.CRAFT)] or act.CRAFT
    return "Craft " .. itemname
end

--------------------------------------------------------------------------
--  HELPER FUNCTIONS
--------------------------------------------------------------------------
local function ToolTagForTarget(target)
    for act in pairs(CRAFTABLE_TOOLS) do
        if target:HasTag(act .. "_workable") then
            return act
        end
    end
end

local function FindTool(act)
    -- inventory first
    for _, item in pairs(InventoryFunctions:GetPlayerInventory()) do
        if item:HasTag(act .. "_tool") then
            dprint("Found tool in inventory", item.prefab)
            return item, false
        end
    end
    -- craft?
    if CRAFTING_ALLOWED then
        for _, prefab in ipairs(CRAFTABLE_TOOLS[act]) do
            if CraftFunctions:KnowsRecipe(prefab) and CraftFunctions:CanCraft(prefab) then
                dprint("Can craft", prefab)
                return prefab, true
            end
        end
    end
    dprint("No tool available for", act)
end

local WORK_ANIMATIONS = {
    "woodie_chop_pre",
    "woodie_chop_loop",
    "chop_pre",
    "chop_loop",
    "pickaxe_pre",
    "pickaxe_loop",
}

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

--------------------------------------------------------------------------
--  Override DoGetMouseActions
--------------------------------------------------------------------------
AddClassPostConstruct("components/playeractionpicker", function(self)
    if self.inst ~= GLOBAL.ThePlayer then
        return
    end
    
    local _DoGetMouseActions = self.DoGetMouseActions
    function self:DoGetMouseActions(position, target, ...)
        local lmb, rmb = _DoGetMouseActions(self, position, target, ...)
        
        -- Get the actual target under mouse if not provided
        if not target then
            target = GLOBAL.TheInput:GetWorldEntityUnderMouse()
        end
        
        dprint("Original actions:", lmb and lmb.action.id, rmb and rmb.action.id, "Target:", target and target.prefab)
        
        -- Only override if no active item and current action is replaceable
        if not InventoryFunctions:GetActiveItem() and 
           not InventoryFunctions:IsHeavyLifting() and
           lmb and (lmb.action == GLOBAL.ACTIONS.WALKTO or lmb.action == GLOBAL.ACTIONS.LOOKAT) then
            
            if target and GLOBAL.CanEntitySeeTarget(self.inst, target) then
                local toolAction = ToolTagForTarget(target)
                if toolAction then
                    dprint("Found workable target:", target.prefab, "needs", toolAction)
                    local tool, needsCraft = FindTool(toolAction)
                    if tool then
                        if needsCraft then
                            -- For crafting, create our custom craft action
                            dprint("Setting up craft for", tool)
                            lmb = GLOBAL.BufferedAction(self.inst, target, ModCraftAction)
                            lmb.CRAFT = tool
                            lmb.DOACTION = GLOBAL.ACTIONS[toolAction]
                        else
                            -- For equipping, create proper work action
                            dprint("Setting up auto-equip for", tool.prefab)
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

--------------------------------------------------------------------------
--  Handle the custom actions
--------------------------------------------------------------------------
AddClassPostConstruct("components/playercontroller", function(self)
    if self.inst ~= GLOBAL.ThePlayer then
        return
    end
    
    -- Store state for pending actions and work tracking
    self.autotool_pendingAction = nil
    self.autotool_workTarget = nil
    
    local _OnLeftClick = self.OnLeftClick
    function self:OnLeftClick(down)
        if down then
            -- Clear work target when clicking something new
            self.autotool_workTarget = nil
            
            local act = self:GetLeftMouseAction()
            
            if act then
                dprint("OnLeftClick - Action:", act.action.id, "CRAFT:", act.CRAFT, "AUTOEQUIP:", act.AUTOEQUIP and act.AUTOEQUIP.prefab)
                
                -- Track work targets for manual actions
                if act.action == GLOBAL.ACTIONS.CHOP or act.action == GLOBAL.ACTIONS.MINE then
                    self.autotool_workTarget = act.target
                    dprint("Set work target:", act.target and act.target.prefab)
                end
                
                if act.AUTOEQUIP then
                    dprint("Click: Auto-equipping", act.AUTOEQUIP.prefab)
                    -- Store action info for after equip
                    self.autotool_pendingAction = {
                        target = act.target,
                        action = act.action,
                        tool = act.invobject
                    }
                    -- Equip the tool
                    InventoryFunctions:Equip(act.AUTOEQUIP)
                    return
                elseif act.action == ModCraftAction and act.CRAFT then
                    dprint("Click: Crafting", act.CRAFT)
                    -- Store action info for after craft
                    self.autotool_pendingAction = {
                        target = act.target,
                        action = act.DOACTION,
                        crafting = act.CRAFT
                    }
                    -- Clear buffered action and craft
                    if self.inst.sg then self.inst:ClearBufferedAction() end
                    CraftFunctions:Craft(act.CRAFT)
                    return
                end
            end
        end
        return _OnLeftClick(self, down)
    end
    
    -- Set up the equip event listener to perform pending action
    self.inst:ListenForEvent("equip", function(inst, data)
        if self.autotool_pendingAction and data and data.item then
            local pendingAction = self.autotool_pendingAction
            
            -- Check if this is the tool we were waiting for
            local isCorrectTool = (pendingAction.tool and data.item == pendingAction.tool) or
                                 (pendingAction.crafting and data.item.prefab == pendingAction.crafting)
            
            dprint("Equip event - item:", data.item.prefab, "isCorrectTool:", isCorrectTool)
            
            if isCorrectTool then
                local target = pendingAction.target
                local action = pendingAction.action
                
                dprint("Equipped", data.item.prefab, "- performing pending action on", target and target.prefab)
                
                -- Set work target for auto-repeat
                if action == GLOBAL.ACTIONS.CHOP or action == GLOBAL.ACTIONS.MINE then
                    self.autotool_workTarget = target
                end
                
                -- Clear pending action
                self.autotool_pendingAction = nil
                
                -- Perform action immediately
                if target and target:IsValid() and action then
                    dprint("Executing pending action", action.id, "on", target.prefab)
                    local position = target:GetPosition()
                    local act = GLOBAL.BufferedAction(inst, target, action, data.item)
                    
                    -- Use the same RPC method as a regular click
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
                else
                    dprint("Pending action failed - target invalid or action missing")
                end
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
                dprint("Cleared work target due to control:", control)
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

dprint("AutoTool loaded (debug mode =", DEBUG, ")")