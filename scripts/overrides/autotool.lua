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
    
    -- Store state for pending actions
    self.autotool_pendingAction = nil
    
    local _OnLeftClick = self.OnLeftClick
    function self:OnLeftClick(down)
        if down then
            local act = self:GetLeftMouseAction()
            
            if act then
                dprint("OnLeftClick - Action:", act.action.id, "CRAFT:", act.CRAFT, "AUTOEQUIP:", act.AUTOEQUIP and act.AUTOEQUIP.prefab)
                
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
                
                -- Clear pending action
                self.autotool_pendingAction = nil
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
end)

dprint("AutoTool loaded (debug mode =", DEBUG, ")")