impulse.Doors = impulse.Doors or {}
impulse.Doors.Data = impulse.Doors.Data or {}

local logs = impulse.Logs
local eMeta = FindMetaTable("Entity")
local fileName = "impulse-reforged/doors/" .. game.GetMap()

file.CreateDir("impulse-reforged/doors")

function impulse.Doors:Save()
    local doors = {}

    for v, k in ents.Iterator() do
        if k:IsDoor() and k:CreatedByMap() then
            if k:GetNetVar(NET_IS_DOOR_BUYABLE, true) == false then
                doors[k:MapCreationID()] = {
                    name = k:GetNetVar(NET_DOOR_NAME, nil),
                    group = k:GetNetVar(NET_DOOR_GROUP, nil),
                    pos = k:GetPos(),
                    buyable = k:GetNetVar(NET_IS_DOOR_BUYABLE, false)
                }
            end
        end
    end

    logs:Debug("Saving doors to impulse-reforged/doors/" .. game.GetMap() .. ".json | Doors saved: " .. #doors)
    file.Write(fileName .. ".json", util.TableToJSON(doors))
end

function impulse.Doors:Load()
    impulse.Doors.Data = {}

    if file.Exists(fileName .. ".json", "DATA") then
        local mapDoorData = util.JSONToTable(file.Read(fileName .. ".json", "DATA"))
        local posBuffer = {}
        local posFinds = {}

        -- use position hashes so we dont take several seconds
        for doorID, doorData in pairs(mapDoorData) do
            if not doorData.pos then continue end

            posBuffer[doorData.pos.x .. "|" .. doorData.pos.y .. "|" .. doorData.pos.z] = doorID
        end

        -- try to find every door via the pos value (update safeish)
        for v, k in ents.Iterator() do
            local p = k.GetPos(k)
            local found = posBuffer[p.x .. "|" .. p.y .. "|" .. p.z]

            if found and k:IsDoor() then
                local doorEnt = k
                local doorData = mapDoorData[found]
                local doorIndex = doorEnt:EntIndex()
                posFinds[doorIndex] = true

                if doorData.name then doorEnt:SetNetVar(NET_DOOR_NAME, doorData.name) end
                if doorData.group then doorEnt:SetNetVar(NET_DOOR_GROUP, doorData.group) end
                if doorData.buyable != nil then doorEnt:SetNetVar(NET_IS_DOOR_BUYABLE, false) end
            end
        end

        -- and doors we couldnt get by pos, we'll fallback to hammerID's (less update safe) (old method)
        for doorID, doorData in pairs(mapDoorData) do
            local doorEnt = ents.GetMapCreatedEntity(doorID)

            if IsValid(doorEnt) and doorEnt:IsDoor() then
                local doorIndex = doorEnt:EntIndex()

                if posFinds[doorIndex] then
                    continue
                end

                if doorData.name then doorEnt:SetNetVar(NET_DOOR_NAME, doorData.name) end
                if doorData.group then doorEnt:SetNetVar(NET_DOOR_GROUP, doorData.group) end
                if doorData.buyable != nil then doorEnt:SetNetVar(NET_IS_DOOR_BUYABLE, false) end

                logs:Warning("Added door by HammerID value because it could not be found via pos. Door index: " ..
                    doorIndex .. ". Please investigate.")
            end
        end

        posBuffer = nil
        posFinds = nil
    end

    hook.Run("DoorsSetup")
end

function eMeta:DoorLock()
    self:Fire("lock", "", 0)
end

function eMeta:DoorUnlock()
    self:Fire("unlock", "", 0)
    if self:GetClass() == "func_door" then
        self:Fire("open")
    end
end

function eMeta:GetDoorMaster()
    return self.MasterUser
end

--- @class Player
local PLAYER = FindMetaTable("Player")

function PLAYER:SetDoorMaster(door)
    local owners = { self:EntIndex() }

    door:SetNetVar(NET_DOOR_OWNERS, owners)
    door.MasterUser = self

    self.impulseOwnedDoors = self.impulseOwnedDoors or {}
    self.impulseOwnedDoors[door] = true
end

function PLAYER:RemoveDoorMaster(door, noUnlock)
    local owners = door:GetNetVar(NET_DOOR_OWNERS)
    door:SetNetVar(NET_DOOR_OWNERS, nil)
    door.MasterUser = nil

    for v, k in pairs(owners) do
        local owner = Entity(k)

        if IsValid(owner) and owner:IsPlayer() then
            owner.impulseOwnedDoors[door] = nil
        end
    end

    if not noUnlock then
        door:DoorUnlock()
    end
end

function PLAYER:SetDoorUser(door)
    local doorOwners = door:GetNetVar(NET_DOOR_OWNERS)

    if not doorOwners then return end

    table.insert(doorOwners, self:EntIndex())
    door:SetNetVar(NET_DOOR_OWNERS, doorOwners)

    self.impulseOwnedDoors = self.impulseOwnedDoors or {}
    self.impulseOwnedDoors[door] = true
end

function PLAYER:RemoveDoorUser(door)
    local doorOwners = door:GetNetVar(NET_DOOR_OWNERS)

    if not doorOwners then return end

    table.RemoveByValue(doorOwners, self:EntIndex())
    door:SetNetVar(NET_DOOR_OWNERS, doorOwners)

    self.impulseOwnedDoors = self.impulseOwnedDoors or {}
    self.impulseOwnedDoors[door] = nil
end

concommand.Add("impulse_door_sethidden", function(ply, cmd, args)
    if (IsValid(ply) and ! ply:IsSuperAdmin()) then return end

    local trace = {}
    trace.start = ply:EyePos()
    trace.endpos = trace.start + ply:GetAimVector() * 200
    trace.filter = ply

    local traceEnt = util.TraceLine(trace).Entity

    if IsValid(traceEnt) and traceEnt:IsDoor() then
        if args[1] == "1" then
            traceEnt:SetNetVar(NET_IS_DOOR_BUYABLE, false)
        else
            traceEnt:SetNetVar(NET_IS_DOOR_BUYABLE, nil)
        end
        traceEnt:SetNetVar(NET_DOOR_GROUP, nil)
        traceEnt:SetNetVar(NET_DOOR_NAME, nil)
        traceEnt:SetNetVar(NET_DOOR_OWNERS, nil)

        ply:Notify("Door " .. traceEnt:EntIndex() .. " show = " .. args[1])

        impulse.Doors:Save()
    end
end)

concommand.Add("impulse_door_setgroup", function(ply, cmd, args)
    if (IsValid(ply) and ! ply:IsSuperAdmin()) then return end

    local trace = {}
    trace.start = ply:EyePos()
    trace.endpos = trace.start + ply:GetAimVector() * 200
    trace.filter = ply

    local traceEnt = util.TraceLine(trace).Entity

    if IsValid(traceEnt) and traceEnt:IsDoor() then
        traceEnt:SetNetVar(NET_IS_DOOR_BUYABLE, false)
        traceEnt:SetNetVar(NET_DOOR_GROUP, tonumber(args[1]))
        traceEnt:SetNetVar(NET_DOOR_NAME, nil)
        traceEnt:SetNetVar(NET_DOOR_OWNERS, nil)

        ply:Notify("Door " .. traceEnt:EntIndex() .. " group = " .. args[1])

        impulse.Doors:Save()
    end
end)

concommand.Add("impulse_door_removegroup", function(ply, cmd, args)
    if (IsValid(ply) and ! ply:IsSuperAdmin()) then return end

    local trace = {}
    trace.start = ply:EyePos()
    trace.endpos = trace.start + ply:GetAimVector() * 200
    trace.filter = ply

    local traceEnt = util.TraceLine(trace).Entity
    if (IsValid(traceEnt) and traceEnt:IsDoor()) then
        traceEnt:SetNetVar(NET_IS_DOOR_BUYABLE, nil)
        traceEnt:SetNetVar(NET_DOOR_GROUP, nil)
        traceEnt:SetNetVar(NET_DOOR_NAME, nil)
        traceEnt:SetNetVar(NET_DOOR_OWNERS, nil)

        ply:Notify("Door " .. traceEnt:EntIndex() .. " group = nil")

        impulse.Doors:Save()
    end
end)
