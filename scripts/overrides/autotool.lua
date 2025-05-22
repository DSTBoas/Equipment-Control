local InventoryFunctions = require "util/inventoryfunctions"
local CraftFunctions = require "util/craftfunctions"

local CRAFTING_ALLOWED = GLOBAL.GetModConfigData("AUTO_EQUIP_TOOL", GLOBAL.MOD_EQUIPMENT_CONTROL.MODNAME) == 2
local AUTO_REPEAT_ACTIONS = GLOBAL.GetModConfigData("AUTO_REPEAT_ACTIONS", GLOBAL.MOD_EQUIPMENT_CONTROL.MODNAME)

local CRAFTABLE_TOOLS = {
    CHOP = {"goldenaxe", "axe"},
    MINE = {"goldenpickaxe", "pickaxe"}
}

local ModCraftAction = GLOBAL.Action({priority = 10})
ModCraftAction.id = "MODCRAFT"
ModCraftAction.str = "Craft"
ModCraftAction.stroverridefn = function(act)
    local itemname = GLOBAL.STRINGS.NAMES[string.upper(act.CRAFT)] or act.CRAFT
    return "Craft " .. itemname
end

local function ToolTagForTarget(target)
    for act in pairs(CRAFTABLE_TOOLS) do
        if target:HasTag(act .. "_workable") then
            return act
        end
    end
end

local function FindTool(act)
    for _, item in pairs(InventoryFunctions:GetPlayerInventory()) do
        if item:HasTag(act .. "_tool") then
            return item, false
        end
    end

    if CRAFTING_ALLOWED then
        for _, prefab in ipairs(CRAFTABLE_TOOLS[act]) do
            if CraftFunctions:KnowsRecipe(prefab) and CraftFunctions:CanCraft(prefab) then
                return prefab, true
            end
        end
    end
end

local WORK_ANIMATIONS = {
    "woodie_chop_pre",
    "woodie_chop_loop",
    "chop_pre",
    "chop_loop",
    "pickaxe_pre",
    "pickaxe_loop"
}

local function IsInWorkAnimation(inst)
    if not inst.AnimState then
        return false
    end

    for _, anim in ipairs(WORK_ANIMATIONS) do
        if inst.AnimState:IsCurrentAnimation(anim) then
            return true
        end
    end

    if inst:HasTag("beaver") and not inst:HasTag("attack") and inst.AnimState:IsCurrentAnimation("atk") then
        return true
    end

    return false
end

AddClassPostConstruct(
    "components/playeractionpicker",
    function(self)
        if self.inst ~= GLOBAL.ThePlayer then
            return
        end

        local _DoGetMouseActions = self.DoGetMouseActions
        function self:DoGetMouseActions(position, target, ...)
            local lmb, rmb = _DoGetMouseActions(self, position, target, ...)

            if not target then
                target = GLOBAL.TheInput:GetWorldEntityUnderMouse()
            end

            if
                not InventoryFunctions:GetActiveItem() and not InventoryFunctions:IsHeavyLifting() and lmb and
                    (lmb.action == GLOBAL.ACTIONS.WALKTO or lmb.action == GLOBAL.ACTIONS.LOOKAT)
             then
                if target and GLOBAL.CanEntitySeeTarget(self.inst, target) then
                    local toolAction = ToolTagForTarget(target)
                    if toolAction then
                        local tool, needsCraft = FindTool(toolAction)
                        if tool then
                            if needsCraft then
                                lmb = GLOBAL.BufferedAction(self.inst, target, ModCraftAction)
                                lmb.CRAFT = tool
                                lmb.DOACTION = GLOBAL.ACTIONS[toolAction]
                            else
                                lmb = GLOBAL.BufferedAction(self.inst, target, GLOBAL.ACTIONS[toolAction], tool)
                                lmb.AUTOEQUIP = tool
                            end
                        end
                    end
                end
            end

            return lmb, rmb
        end
    end
)

AddClassPostConstruct(
    "components/playercontroller",
    function(self)
        if self.inst ~= GLOBAL.ThePlayer then
            return
        end

        self.autotool_pendingAction = nil
        self.autotool_workTarget = nil

        local _OnLeftClick = self.OnLeftClick
        function self:OnLeftClick(down)
            if down then
                self.autotool_workTarget = nil

                local act = self:GetLeftMouseAction()

                if act then
                    if act.action == GLOBAL.ACTIONS.CHOP or act.action == GLOBAL.ACTIONS.MINE then
                        self.autotool_workTarget = act.target
                    end

                    if act.AUTOEQUIP then
                        self.autotool_pendingAction = {
                            target = act.target,
                            action = act.action,
                            tool = act.invobject
                        }
                        InventoryFunctions:Equip(act.AUTOEQUIP)
                        return
                    elseif act.action == ModCraftAction and act.CRAFT then
                        self.autotool_pendingAction = {
                            target = act.target,
                            action = act.DOACTION,
                            crafting = act.CRAFT
                        }
                        if self.inst.sg then
                            self.inst:ClearBufferedAction()
                        end
                        CraftFunctions:Craft(act.CRAFT)
                        return
                    end
                end
            end
            return _OnLeftClick(self, down)
        end

        self.inst:ListenForEvent(
            "equip",
            function(inst, data)
                if self.autotool_pendingAction and data and data.item then
                    local pendingAction = self.autotool_pendingAction

                    local isCorrectTool =
                        (pendingAction.tool and data.item == pendingAction.tool) or
                        (pendingAction.crafting and data.item.prefab == pendingAction.crafting)

                    if isCorrectTool then
                        local target = pendingAction.target
                        local action = pendingAction.action

                        if action == GLOBAL.ACTIONS.CHOP or action == GLOBAL.ACTIONS.MINE then
                            self.autotool_workTarget = target
                        end

                        self.autotool_pendingAction = nil

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
                    end
                end
            end
        )

        if AUTO_REPEAT_ACTIONS then
            local _OnControl = self.OnControl
            function self:OnControl(control, down)
                if
                    down and
                        (control == GLOBAL.CONTROL_MOVE_UP or control == GLOBAL.CONTROL_MOVE_DOWN or
                            control == GLOBAL.CONTROL_MOVE_LEFT or
                            control == GLOBAL.CONTROL_MOVE_RIGHT or
                            control == GLOBAL.CONTROL_PRIMARY or
                            control == GLOBAL.CONTROL_SECONDARY)
                 then
                    self.autotool_workTarget = nil
                end
                return _OnControl(self, control, down)
            end

            local function ShouldRepeatWork()
                if not self.autotool_workTarget or not self.autotool_workTarget:IsValid() then
                    return false
                end

                local dist = self.inst:GetDistanceSqToInst(self.autotool_workTarget)
                if dist > 16 then
                    self.autotool_workTarget = nil
                    return false
                end

                if
                    not (self.autotool_workTarget:HasTag("CHOP_workable") or
                        self.autotool_workTarget:HasTag("MINE_workable"))
                 then
                    self.autotool_workTarget = nil
                    return false
                end

                return true
            end

            if GLOBAL.TheWorld.ismastersim then
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
                local _OnUpdate = self.OnUpdate
                function self:OnUpdate(...)
                    if IsInWorkAnimation(self.inst) and ShouldRepeatWork() then
                        local act = self:GetActionButtonAction()
                        if
                            act and act.target == self.autotool_workTarget and
                                (act.action == GLOBAL.ACTIONS.CHOP or act.action == GLOBAL.ACTIONS.MINE)
                         then
                            self:OnControl(GLOBAL.CONTROL_ACTION, true)
                        end
                    end
                    _OnUpdate(self, ...)
                end
            end
        end
    end
)
