---@class impulse.Derma.impulseInventory : DFrame
local PANEL = {}

function PANEL:Init()
    self:SetSize(ScrW() / 1.5, ScrH() * .7)
    self:Center()
    self:CenterHorizontal()
    self:SetTitle("")
    self:ShowCloseButton(false)
    self:SetDraggable(false)
    --self:MakePopup()
    self:MoveToFront()
    self:Hide() -- Hide by default so we can show it later manually

    local w, h = self:GetSize()

    self.infoName = vgui.Create("DLabel", self)
    self.infoName:SetPos(15, 40)
    self.infoName:SetFont("Impulse-Elements24-Shadow")
    self.infoName:SizeToContents()

    if self.infoName:GetWide() > 245 then
        self.infoName:SetFont("Impulse-Elements19-Shadow")
    end

    local plyTeam = LocalPlayer():Team()
    self.infoTeam = vgui.Create("DLabel", self)
    self.infoTeam:SetPos(15, 64)
    self.infoTeam:SetFont("Impulse-Elements19-Shadow")
    self.infoTeam:SetColor(team.GetColor(plyTeam))
    self.infoTeam:SizeToContents()

    self.infoClassRank = vgui.Create("DLabel", self)
    self.infoClassRank:SetPos(15, 80)
    self.infoClassRank:SetFont("Impulse-Elements19-Shadow")

    self.modelPreview = vgui.Create("impulseModelPanel", self)
    self.modelPreview:SetPos(0, 80)
    self.modelPreview:SetSize(270, h * .75)
    self.modelPreview:MoveToBack()
    self.modelPreview:SetCursor("arrow")

    self.modelPreview:SetFOV((324 / ScrH()) * 100)

    function self.modelPreview:LayoutEntity(ent)
        ent:SetAngles(Angle(-1, 45, 0))
        ent:SetPos(Vector(0, 0, 2.5))
        self:RunAnimation()

        if (! self.setup) then
            for k, v in pairs(LocalPlayer():GetBodyGroups()) do
                ent:SetBodygroup(v.id, LocalPlayer():GetBodygroup(v.id))
            end

            for k, v in pairs(LocalPlayer():GetMaterials()) do
                local mat = LocalPlayer():GetSubMaterial(k - 1)
                if (mat != v) then
                    ent:SetSubMaterial(k - 1, mat)
                end
            end

            hook.Run("SetupInventoryModel", self, ent)

            self.setup = true
        end
    end

    self:SetupItems(w, h)
end

---Reload all dynamic data in the inventory
function PANEL:Reload()
    self:SetupPlayerInfo()
    self:SetupItems()
end

---Reload the player's details
function PANEL:SetupPlayerInfo()
    local client = LocalPlayer()
    local model = client:GetModel()
    local skin = client:GetSkin()
    local className = LocalPlayer():GetTeamClassName()
    local plyTeam = LocalPlayer():Team()

    self.infoName:SetText(client:Nick())
    self.infoName:SizeToContents()

    self.infoTeam:SetText(team.GetName(plyTeam))
    self.infoTeam:SetColor(team.GetColor(plyTeam))
    self.infoTeam:SizeToContents()

    self.modelPreview:SetModel(model, skin)

    impulse.Logs:Debug("Setting up player info for %s, className is %s", client:Nick(), className)
    if (className != "Default") then // TODO: Fix className always being Default
        self.infoClassRank:Show()
        self.infoClassRank:SetText(className)
        self.infoClassRank:SetColor(team.GetColor(plyTeam))
        self.infoClassRank:SizeToContents()
    else
        self.infoClassRank:Hide()
    end
end

function PANEL:SetupItems()
    local w, h = self:GetSize()

    if self.tabs and IsValid(self.tabs) then
        self.tabs:Remove()
    end

    local s = 270

    self.tabs = vgui.Create("DPropertySheet", self)
    self.tabs:SetPos(s, 40)
    self.tabs:SetSize(w - s, h - 42)
    self.tabs.tabScroller:DockMargin(-1, 0, -1, 0)
    self.tabs.tabScroller:SetOverlap(0)

    function self.tabs:Paint()
        return true
    end

    if self.invScroll and IsValid(self.invScroll) then
        self.invScroll:Remove()
    end

    self.invScroll = vgui.Create("DScrollPanel", self.tabs)
    self.invScroll:SetPos(0, 0)
    self.invScroll:SetSize(w - math.Clamp(s, 100, 270), h - 42)

    self.items = {}
    self.itemsPanels = {}

    local weight = 0
    local localInv = table.Copy(impulse.Inventory.Data[0][INVENTORY_PLAYER]) or {}

    if localInv and table.Count(localInv) > 0 then
        for v, k in pairs(localInv) do
            local itemData = impulse.Inventory.Items[k.id]
            if not itemData then continue end

            local otherItem = self.items[k.id]
            local itemX = itemData

            if itemX.CanStack and otherItem then
                otherItem.Count = (otherItem.Count or 1) + 1
            else
                local item = self.invScroll:Add("impulseInventoryItem")
                item:Dock(TOP)
                item:DockMargin(0, 0, 15, 5)
                item:SetItem(k, w)
                item.InvID = v
                item.InvPanel = self
                self.items[k.id] = item
                self.itemsPanels[v] = item
            end

            weight = weight + (itemX.Weight or 0)
        end
    else
        self.empty = self.invScroll:Add("DLabel", self)
        self.empty:SetContentAlignment(5)
        self.empty:Dock(TOP)
        self.empty:SetText("Empty")
        self.empty:SetFont("Impulse-Elements19-Shadow")
    end

    self.invWeight = weight

    self.tabs:AddSheet("Inventory", self.invScroll)

    self:SetupSkills(w, h)
end

local bodyCol = Color(50, 50, 50, 210)
function PANEL:SetupSkills(w, h)
    self.skillScroll = vgui.Create("DScrollPanel", self.tabs)
    self.skillScroll:SetPos(0, 0)
    self.skillScroll:SetSize(w - 270, h - 42)

    for v, k in pairs(impulse.Skills.Skills) do
        local skillBg = self.skillScroll:Add("DPanel")
        skillBg:SetTall(80)
        skillBg:Dock(TOP)
        skillBg:DockMargin(0, 0, 15, 5)
        skillBg.Skill = v

        local level = LocalPlayer():GetSkillLevel(v)
        local xp = LocalPlayer():GetSkillXP(v)

        function skillBg:Paint(w, h)
            surface.SetDrawColor(bodyCol)
            surface.DrawRect(0, 0, w, h)

            local skill = self.Skill
            local skillName = impulse.Skills.GetNiceName(skill)

            draw.DrawText(skillName .. " - Level " .. level, "Impulse-Elements22-Shadow", 5, 3, color_white,
                TEXT_ALIGN_LEFT)
            draw.DrawText("Total skill: " .. xp .. "XP", "Impulse-Elements16-Shadow", w - 5, 7, color_white,
                TEXT_ALIGN_RIGHT)

            return true
        end

        local lastXp = impulse.Skills.GetLevelXPRequirement(level - 1)
        local nextXp = impulse.Skills.GetLevelXPRequirement(level)
        local perc = (xp - lastXp) / (nextXp - lastXp)

        local bar = vgui.Create("DProgress", skillBg)
        bar:SetPos(20, 30)
        bar:SetSize(self.skillScroll:GetWide() - 73, 40)

        if level == 10 then
            bar:SetFraction(1)
            bar.BarCol = Color(218, 165, 32)
        else
            bar:SetFraction(perc)
        end

        function bar:PaintOver(w, h)
            if level != 10 then
                draw.DrawText(math.Round(perc * 100, 1) .. "% to next level", "Impulse-Elements18-Shadow", w / 2, 10,
                    color_white, TEXT_ALIGN_CENTER)
            else
                draw.DrawText("Mastered", "Impulse-Elements18-Shadow", w / 2, 10, color_white, TEXT_ALIGN_CENTER)
            end

            draw.DrawText(lastXp .. "XP", "Impulse-Elements16-Shadow", 10, 10, color_white)
            draw.DrawText(nextXp .. "XP", "Impulse-Elements16-Shadow", w - 10, 10, color_white, TEXT_ALIGN_RIGHT)
        end
    end

    self.tabs:AddSheet("Skills", self.skillScroll)
end

function PANEL:FindItemPanelByID(id)
    return self.itemsPanels[id]
end

local grey = Color(209, 209, 209)
function PANEL:PaintOver(w, h)
    draw.SimpleText(self.invWeight .. "kg/" .. impulse.Config.InventoryMaxWeight .. "kg", "Impulse-Elements18-Shadow",
        w - 18, 40, grey, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
end

vgui.Register("impulseInventory", PANEL, "DFrame")
