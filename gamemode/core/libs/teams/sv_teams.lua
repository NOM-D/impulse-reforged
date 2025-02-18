---@class Player
local PLAYER = FindMetaTable("Player")

PLAYER.OldSetTeam = PLAYER.OldSetTeam or PLAYER.SetTeam

function PLAYER:SetTeam(teamID)
    local selfTable = self:GetTable()

    local teamData = impulse.Teams.Stored[teamID]
    if (! teamData) then
        impulse.Logs:Debug(self:Nick() .. " tried to join invalid team " .. teamID)
        return false, "Invalid team ID!"
    end

    local teamPlayers = team.NumPlayers(teamID)
    if (teamData.max and teamPlayers >= teamData.max) then
        impulse.Logs:Debug(self:Nick() .. " tried to join team " .. teamID .. " but it was full")
        return false, "You cannot join this team as it is full!"
    end

    local teamModel = isfunction(teamData.model) and teamData.model(self) or teamData.model
    impulse.Logs:Debug("TeamData is setting " ..
    self:Nick() .. " model to " .. (teamModel or selfTable.impulseDefaultModel))
    self:SetModel(teamModel or selfTable.impulseDefaultModel)
    self:SetSkin(teamData.skin or selfTable.impulseDefaultSkin)

    if (teamData.bodygroups) then
        self:ResetBodygroups()
        for v, bodygroupData in pairs(teamData.bodygroups) do
            impulse.Logs:Debug("TeamData is setting bodygroup to " ..
            bodygroupData[1] .. " with subGroup " .. bodygroupData[2])
            self:SetBodygroup(bodygroupData[1],
                (bodygroupData[2] or math.random(0, self:GetBodygroupCount(bodygroupData[1]))))
        end
    end

    self:ResetSubMaterials()
    impulse.Logs:Debug("Reset sub materials")

    if (self:HasBrokenLegs()) then
        self:FixLegs()
        impulse.Logs:Debug("Fixed legs")
    end

    if (self:IsCP() or teamData.cp) then
        self:RemoveAllAmmo()
        impulse.Logs:Debug("Removed all ammo")
    end

    self:UnEquipInventory()
    self:ClearRestrictedInventory()
    self:StripWeapons()
    impulse.Logs:Debug("Stripped weapons and inventory")

    if (teamData.loadoutAdd) then
        for k, v in pairs(teamData.loadoutAdd) do
            self:Give(v)
            impulse.Logs:Debug("Gave weapon: " .. v)
        end
    end

    if (teamData.itemsAdd) then
        for k, v in pairs(teamData.itemsAdd) do
            for i = 1, (v.amount or 1) do
                self:GiveItem(v.class, 1, true)
                impulse.Logs:Debug("Gave item: " .. v.class)
            end
        end
    end

    if (teamData.runSpeed) then
        self:SetRunSpeed(teamData.runSpeed)
    else
        self:SetRunSpeed(impulse.Config.JogSpeed)
    end
    impulse.Logs:Debug("Set run speed to: " .. self:GetRunSpeed())

    selfTable.DoorGroups = teamData.doorGroup or {}

    if (self:Team() != teamID) then
        hook.Run("OnPlayerChangedTeam", self, self:Team(), teamID)
        impulse.Logs:Debug("Player changed team from " .. self:Team() .. " to " .. teamID)
    end

    self:SetNetVar(NET_TEAM_CLASS, nil)
    self:SetNetVar(NET_TEAM_RANK, nil)
    impulse.Logs:Debug("Set class and rank to nil")

    self:OldSetTeam(teamID)
    impulse.Logs:Debug("OldSetTeam to " .. teamID)

    if (teamData.spawns) then
        impulse.Logs:Debug("TeamData is setting player position to random spawn")
        self:SetPos(teamData.spawns[math.random(1, #teamData.spawns)])
    end

    if (teamData.onBecome) then
        impulse.Logs:Debug("TeamData is running onBecome")
        teamData.onBecome(self)
    end

    return true
end

function PLAYER:SetTeamClass(classID, skipLoadout)
    impulse.Logs:Debug("Setting " .. self:Nick() .. " team class to " .. classID)
    local teamData = impulse.Teams:FindTeam(self:Team())
    local teamModel = teamData.model
    if not teamData then
        impulse.Logs:Error("Player does not have a valid team selected!")
        return false
    end

    if (teamModel and isfunction(teamModel)) then
        teamModel = teamModel(self)
    end

    local classData = teamData.classes[classID]
    if classData.onBecome then
        classData.onBecome(self)
    end

    if classData.model then
        impulse.Logs:Debug("ClassData is setting model to " .. classData.model)
        self:SetModel(classData.model)
    else
        local fallback = teamModel or self.impulseDefaultModel
        impulse.Logs:Debug("teamData fallback is setting model to " .. (fallback or "nil"))
        self:SetModel(fallback)
    end

    self:SetupHands()

    if classData.skin then
        self:SetSkin(classData.skin)
    else
        self:SetSkin(teamData.skin or self.impulseDefaultSkin)
    end

    self:ResetBodygroups()

    --- First set class/division bodygroups
    if classData.bodygroups then
        for bodyGroupId, subGroupid in pairs(classData.bodygroups) do
            impulse.Logs:Debug("ClassData is setting bodygroup " .. bodyGroupId .. " to subGroup " .. subGroupid)
            self:SetBodygroup(bodyGroupId, subGroupid or math.random(0, self:GetBodygroupCount(bodygroupData[1])))
        end
        --- If there are no class bodygroups, set team bodygroups instead
    elseif teamData.bodygroups then
        for bodygroupId, subBodyGroup in pairs(teamData.bodygroups) do
            impulse.Logs:Debug("TeamData is setting bodygroup " .. bodyGroupId .. " to subGroup " .. subGroupid)
            self:SetBodygroup(bodygroupId, subBodyGroup or math.random(0, self:GetBodygroupCount(bodygroupData[1])))
        end
    end

    if not skipLoadout then
        if (self:HasBrokenLegs()) then
            self:FixLegs()
        end

        self:StripWeapons()

        if classData.loadoutAdd then
            for v, weapon in pairs(classData.loadoutAdd) do
                self:Give(weapon)
            end
        else
            for v, weapon in pairs(teamData.loadoutAdd) do
                self:Give(weapon)
            end
        end

        self:ClearRestrictedInventory()

        if classData.itemsAdd then
            for v, item in pairs(classData.itemsAdd) do
                for i = 1, (item.amount or 1) do
                    self:GiveItem(item.class, 1, true)
                end
            end
        end
    end

    if classData.armour then
        self:SetArmor(classData.armour)
        self.MaxArmour = classData.armour
    else
        self:SetArmor(0)
        self.MaxArmour = nil
    end

    if classData.doorGroup then
        self.DoorGroups = classData.doorGroup
    else
        self.DoorGroups = teamData.doorGroup or {}
    end

    self:SetNetVar(NET_TEAM_CLASS, classID)

    hook.Run("PlayerChangeClass", self, classID, classData.name)

    return true
end

function PLAYER:SetTeamRank(rankID)
    local teamData = impulse.Teams:FindTeam(self:Team())
    local classData = teamData.classes[self:GetTeamClass()]
    local rankData = teamData.ranks[rankID]

    if (! teamData) then
        self:Notify("Player does not have a valid team selected!")
        return false
    end
    if ! (classData) then
        self:Notify("Player does not have a valid class selected!")
        return false
    end

    if rankData.onBecome then
        rankData.onBecome(self)
    end

    if rankData.model then
        impulse.Logs:Debug("RankData is setting model to " .. rankData.model)
        self:SetModel(rankData.model)
    else
        if classData.model and self:GetModel() != classData.model then
            impulse.Logs:Debug("ClassData is setting model to " .. classData.model)
            self:SetModel(classData.model)
        end
    end

    self:SetupHands()

    if rankData.skin then
        impulse.Logs:Debug("RankData is setting skin to " .. rankData.skin)
        self:SetSkin(rankData.skin)
    end

    if rankData.bodygroupOverrides then
        local isClassSpecific = nil
        local classId = self:GetTeamClass()

        self:ResetBodygroups()
        for index, bodygroupData in pairs(rankData.bodygroupOverrides) do
            if isClassSpecific == nil then
                isClassSpecific = type(bodygroupData) == "table"
            end

            if isClassSpecific then
                if index != classId then continue end
                for bodygroup, subBodygroup in pairs(bodygroupData) do
                    impulse.Logs:Debug("RankData is setting class-specific bodygroup to " ..
                    bodygroup .. " with subGroup " .. subBodygroup)
                    self:SetBodygroup(bodygroup, subBodygroup)
                end
            else
                impulse.Logs:Debug("RankData is setting bodygroup to " .. bodygroup .. " with subGroup " .. subBodygroup)
                self:SetBodygroup(index, (bodygroupData or math.random(0, self:GetBodygroupCount(bodygroupData[1]))))
            end
        end
    end

    if rankData.subMaterial and ! classData.noSubMats then
        for v, k in pairs(rankData.subMaterial) do
            self:SetSubMaterial(v - 1, k)

            self.SetSubMats = self.SetSubMats or {}
            self.SetSubMats[v] = true
        end
    elseif self.SetSubMats then
        self:ResetSubMaterials()
    end

    if (self:HasBrokenLegs()) then
        self:FixLegs()
    end

    self:StripWeapons()

    if rankData.loadoutAdd then
        for v, weapon in pairs(rankData.loadoutAdd) do
            self:Give(weapon)
            impulse.Logs:Debug("rankData gave weapon: " .. weapon)
        end
    else
        for v, weapon in pairs(teamData.loadoutAdd) do
            self:Give(weapon)
            impulse.Logs:Debug("teamData gave weapon: " .. weapon)
        end

        if classData and classData.loadoutAdd then
            for v, weapon in pairs(classData.loadoutAdd) do
                self:Give(weapon)
                impulse.Logs:Debug("classData gave weapon: " .. weapon)
            end
        end

        if rankData.loadoutAdd then
            for v, weapon in pairs(rankData.loadoutAdd) do
                self:Give(weapon)
            end
        end
    end

    self:ClearRestrictedInventory()

    if rankData.itemsAdd then
        for v, item in pairs(rankData.itemsAdd) do
            for i = 1, (item.amount or 1) do
                self:GiveItem(item.class, 1, true)
                impulse.Logs:Debug("rankData gave item: " .. item.class)
            end
        end
    else
        if teamData.itemsAdd then
            for v, item in pairs(teamData.itemsAdd) do
                for i = 1, (item.amount or 1) do
                    self:GiveItem(item.class, 1, true)
                    impulse.Logs:Debug("teamData gave item: " .. item.class)
                end
            end
        end

        if classData.itemsAdd then
            for v, item in pairs(classData.itemsAdd) do
                for i = 1, (item.amount or 1) do
                    self:GiveItem(item.class, 1, true)
                    impulse.Logs:Debug("classData gave item: " .. item.class)
                end
            end
        end

        if rankData.itemsAdd then
            for v, item in pairs(rankData.itemsAdd) do
                for i = 1, (item.amount or 1) do
                    self:GiveItem(item.class, 1, true)
                    impulse.Logs:Debug("rankData gave item: " .. item.class)
                end
            end
        end
    end

    if rankData.doorGroup then
        self.DoorGroups = rankData.doorGroup
    else
        if classData.doorGroup then
            self.DoorGroups = classData.doorGroup
        else
            self.DoorGroups = teamData.doorGroup or {}
        end
    end

    self:SetNetVar(NET_TEAM_RANK, rankID)

    hook.Run("PlayerChangeRank", self, rankID, rankData.name)

    return true
end
