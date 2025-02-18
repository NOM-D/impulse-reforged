util.AddNetworkString("impulseInvClear")
util.AddNetworkString("impulseInvClearRestricted")
util.AddNetworkString("impulseInvContainerClose")
util.AddNetworkString("impulseInvContainerCodeReply")
util.AddNetworkString("impulseInvContainerCodeTry")
util.AddNetworkString("impulseInvContainerDoMove")
util.AddNetworkString("impulseInvContainerDoSetCode")
util.AddNetworkString("impulseInvContainerOpen")
util.AddNetworkString("impulseInvContainerRemovePadlock")
util.AddNetworkString("impulseInvContainerSetCode")
util.AddNetworkString("impulseInvContainerUpdate")
util.AddNetworkString("impulseInvDoDrop")
util.AddNetworkString("impulseInvDoEquip")
util.AddNetworkString("impulseInvDoMove")
util.AddNetworkString("impulseInvDoMoveMass")
util.AddNetworkString("impulseInvDoSearch")
util.AddNetworkString("impulseInvDoSearchConfiscate")
util.AddNetworkString("impulseInvDoUse")
util.AddNetworkString("impulseInvGive")
util.AddNetworkString("impulseInvGiveSilent")
util.AddNetworkString("impulseInvMove")
util.AddNetworkString("impulseInvRemove")
util.AddNetworkString("impulseInvStorageOpen")
util.AddNetworkString("impulseInvUpdateData")
util.AddNetworkString("impulseInvUpdateEquip")
util.AddNetworkString("impulseInvUpdateStorage")


net.Receive("impulseInvDoEquip", function(len, ply)
    if not ply.impulseBeenInventorySetup or (ply.nextInvEquip or 0) > CurTime() then return end
    ply.nextInvEquip = CurTime() + 0.1

    if not ply:Alive() or ply:GetNetVar(NET_IS_INCOGNITO, false) then return end

    local canUse = hook.Run("CanUseInventory", ply)

    if canUse != nil and canUse == false then return end

    local itemID = net.ReadUInt(16)
    local equipState = net.ReadBool()

    local hasItem, item = ply:HasInventoryItemSpecific(itemID)

    if hasItem then
        ply:SetInventoryItemEquipped(itemID, equipState or false)
    end
end)

net.Receive("impulseInvDoDrop", function(len, ply)
    if not ply.impulseBeenInventorySetup or (ply.nextInvDrop or 0) > CurTime() then return end
    ply.nextInvDrop = CurTime() + 0.1

    if not ply:Alive() or ply:GetNetVar(NET_IS_INCOGNITO, false) then return end

    local canUse = hook.Run("CanUseInventory", ply)

    if canUse != nil and canUse == false then return end

    local itemID = net.ReadUInt(16)

    local hasItem, item = ply:HasInventoryItemSpecific(itemID)
    impulse.Logs:Debug("Item ID is %s, hasItem = %s", itemID, hasItem)

    if hasItem then
        ply:DropInventoryItem(itemID)
        hook.Run("PlayerDropItem", ply, item, itemID)
    end
end)

net.Receive("impulseInvDoUse", function(len, ply)
    if not ply.impulseBeenInventorySetup or (ply.nextInvUse or 0) > CurTime() then return end
    ply.nextInvUse = CurTime() + 0.1

    if not ply:Alive() or ply:GetNetVar(NET_IS_INCOGNITO, false) then return end

    local canUse = hook.Run("CanUseInventory", ply)

    if canUse != nil and canUse == false then return end

    local itemID = net.ReadUInt(16)

    local hasItem, item = ply:HasInventoryItemSpecific(itemID)

    if hasItem then
        ply:UseInventoryItem(itemID)
    end
end)

net.Receive("impulseInvDoSearchConfiscate", function(len, ply)
    if not ply:IsCP() then return end
    if (ply.nextInvConf or 0) > CurTime() then return end
    ply.nextInfConf = CurTime() + 0.1

    local targ = ply.impulseInventorySearching
    if not IsValid(targ) or not ply:CanArrest(targ) then return end

    local count = net.ReadUInt(8) or 0

    if count > 0 then
        for i = 1, count do
            local netid = net.ReadUInt(10)
            local item = impulse.Inventory.Items[netid]

            if not item then continue end

            if item.Illegal and targ:HasInventoryItem(item.UniqueID) then
                targ:TakeInventoryItemClass(item.UniqueID, 1)

                hook.Run("PlayerConfiscateItem", ply, targ, item.UniqueID)
            end
        end

        ply:Notify("You have confiscated " .. count .. " items.")
        targ:Notify("The search has been completed and " .. count .. " items have been confiscated.")
    else
        targ:Notify("The search has been completed.")
    end

    ply.impulseInventorySearching = nil
    targ:Freeze(false)
end)

net.Receive("impulseInvDoMove", function(len, ply)
    if (ply.nextInvMove or 0) > CurTime() then return end
    ply.nextInvMove = CurTime() + 0.1

    if not ply.currentStorage or not IsValid(ply.currentStorage) then return end
    if ply.currentStorage:GetPos():DistToSqr(ply:GetPos()) > (100 ^ 2) then return end
    if ply:IsCP() then return end
    if ply:GetNetVar(NET_IS_INCOGNITO, false) or not ply:Alive() then return end

    local canUse = hook.Run("CanUseInventory", ply)

    if canUse != nil and canUse == false then return end

    if not ply.currentStorage:CanPlayerUse(ply) then return end

    local itemid = net.ReadUInt(16)
    local from = net.ReadUInt(4)
    local to = 1

    if from != 1 and from != 2 then return end

    if from == 1 then
        to = 2
    end

    if to == 2 and (ply.impulseNextStorage or 0) > CurTime() then
        ply.nextInvMove = CurTime() + 0.1
        return ply:Notify("Because you were recently in combat you must wait " ..
            string.NiceTime(ply.impulseNextStorage - CurTime()) .. " before depositing items into your storage.")
    end

    local hasItem, item = ply:HasInventoryItemSpecific(itemid, from)

    if not hasItem then return end

    if ply.currentStorage:GetClass() == "impulse_storage_public" then
        local item = impulse.Inventory.Items[impulse.Inventory:ClassToNetID(item.class)]

        if not item then return end

        if item.Illegal then
            return ply:Notify("You may not access or store illegal items at public storage lockers.")
        end
    end

    if item.restricted then
        return ply:Notify("You cannot store a restricted item.")
    end

    if from == 2 and ! ply:CanHoldItem(item.class) then
        return ply:Notify("Item is too heavy to hold.")
    end

    if from == 1 and ! ply:CanHoldItemStorage(item.class) then
        return ply:Notify("Item is too heavy to store.")
    end

    local canStore = hook.Run("CanStoreItem", ply, ply.currentStorage, item.class, from)

    if canStore != nil and canStore == false then return end

    ply:MoveInventoryItem(itemid, from, to)
end)

net.Receive("impulseInvDoMoveMass", function(len, ply)
    if (ply.nextInvMove or 0) > CurTime() then return end
    ply.nextInvMove = CurTime() + 0.1

    if not ply.currentStorage or not IsValid(ply.currentStorage) then return end
    if ply.currentStorage:GetPos():DistToSqr(ply:GetPos()) > (100 ^ 2) then return end
    if ply:IsCP() then return end
    if ply:GetNetVar(NET_IS_INCOGNITO, false) or not ply:Alive() then return end

    local canUse = hook.Run("CanUseInventory", ply)

    if canUse != nil and canUse == false then return end

    if not ply.currentStorage:CanPlayerUse(ply) then return end

    local classid = net.ReadUInt(10)
    local amount = net.ReadUInt(8)
    local from = net.ReadUInt(4)
    local to = 1

    if from != 1 and from != 2 then return end

    if from == 1 then
        to = 2
    end

    amount = math.Clamp(amount, 0, 9999)

    if to == 2 and (ply.impulseNextStorage or 0) > CurTime() then
        ply.nextInvMove = CurTime() + 0.1
        return ply:Notify("Because you were recently in combat you must wait " ..
            string.NiceTime(ply.impulseNextStorage - CurTime()) .. " before depositing items into your storage.")
    end

    if not impulse.Inventory.Items[classid] then return end

    local item = impulse.Inventory.Items[classid]
    local class = item.UniqueID
    local hasItem

    if from == 1 then
        hasItem = ply:HasInventoryItem(class, amount)
    else
        hasItem = ply:HasInventoryItemStorage(class, amount)
    end

    if not hasItem then return end

    if ply.currentStorage:GetClass() == "impulse_storage_public" then
        if item.Illegal then
            return ply:Notify("You may not access or store illegal items at public storage lockers.")
        end
    end

    local runs = 0
    for v, k in pairs(ply:GetInventory(from)) do
        runs = runs + 1

        if k.class == class then -- id pls
            if k.restricted then -- get out
                return ply:Notify("You cannot store a restricted item.")
            end
        end

        if runs >= amount then -- youve passed :D
            break
        end
    end

    if from == 2 and ! ply:CanHoldItem(class, amount) then
        return ply:Notify("Items are too heavy to hold.")
    end

    if from == 1 and ! ply:CanHoldItemStorage(class, amount) then
        return ply:Notify("Items are too heavy to store.")
    end

    local canStore = hook.Run("CanStoreItem", ply, ply.currentStorage, class, from)

    if canStore != nil and canStore == false then return end

    ply:MoveInventoryItemMass(class, from, to, amount)
end)
