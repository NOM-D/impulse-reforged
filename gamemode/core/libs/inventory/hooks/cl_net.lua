net.Receive("impulseInvGive", function()
    local netid = net.ReadUInt(16)
    local itemID = net.ReadUInt(16)
    local strid = net.ReadUInt(4)
    local restricted = net.ReadBool()

    if not impulse.Inventory.Data[0][strid] then
        impulse.Inventory.Data[0][strid] = {}
    end

    impulse.Inventory.Data[0][strid][itemID] = {
        equipped = false,
        restricted = restricted,
        id = netid
    }
end)

net.Receive("impulseInvMove", function()
    local itemID = net.ReadUInt(16)
    local newitemID = net.ReadUInt(16)
    local from = net.ReadUInt(4)
    local to = net.ReadUInt(4)
    local netid

    local take = impulse.Inventory.Data[0][from][itemID]

    netid = take.id

    impulse.Inventory.Data[0][from][itemID] = nil
    impulse.Inventory.Data[0][to][newitemID] = {
        id = netid
    }

    if impulse_storage and IsValid(impulse_storage) then
        local invScroll = impulse_storage.invScroll:GetVBar():GetScroll()
        local invStorageScroll = impulse_storage.invStorageScroll:GetVBar():GetScroll()

        impulse_storage:SetupItems(invScroll, invStorageScroll)

        if (NEXT_MOVENOISE or 0) < CurTime() then -- to stop ear rape when mass moving items
            LocalPlayer():EmitSound("physics/wood/wood_crate_impact_hard2.wav", nil, nil, 0.5, CHAN_ITEM)
        end

        NEXT_MOVENOISE = CurTime() + 0.1
    end

    if IsValid(impulse_inventory) then
        impulse_inventory:SetupItems()
    end
end)

net.Receive("impulseInvRemove", function()
    local itemID = net.ReadUInt(16)
    local strid = net.ReadUInt(4)
    local item = impulse.Inventory.Data[0][strid][itemID]

    if item then
        impulse.Inventory.Data[0][strid][itemID] = nil
    end

    if IsValid(impulse_inventory) then
        impulse_inventory:SetupItems()
    end
end)

net.Receive("impulseInvClear", function()
    local storagetype = net.ReadUInt(4)

    if impulse.Inventory.Data[0][storagetype] then
        impulse.Inventory.Data[0][storagetype] = {}
    end

    if IsValid(impulse_inventory) then
        impulse_inventory:SetupItems()
    end
end)

net.Receive("impulseInvClearRestricted", function()
    local storagetype = net.ReadUInt(4)

    if impulse.Inventory.Data[0][storagetype] then
        for v, k in pairs(impulse.Inventory.Data[0][storagetype]) do
            if k.restricted then
                impulse.Inventory.Data[0][storagetype][v] = nil
            end
        end
    end

    if IsValid(impulse_inventory) then
        impulse_inventory:SetupItems()
    end
end)

net.Receive("impulseInvUpdateEquip", function()
    local itemID = net.ReadUInt(16)
    local state = net.ReadBool()
    local item = impulse.Inventory.Data[0][INVENTORY_PLAYER][itemID]

    item.equipped = state or false

    impulse_inventory:FindItemPanelByID(itemID).IsEquipped = state or false
end)

net.Receive("impulseInvDoSearch", function()
    local searchee = Entity(net.ReadUInt(8))
    local invSize = net.ReadUInt(16)
    local invCompiled = {}

    if not IsValid(searchee) then return end

    for i = 1, invSize do
        local itemnetid = net.ReadUInt(10)
        local item = impulse.Inventory.Items[itemnetid]

        table.insert(invCompiled, item)
    end


    impulse.Util:MakeWorkbar(5, "Searching...", function()
        if not IsValid(searchee) then return end

        local searchMenu = vgui.Create("impulseSearchMenu")
        searchMenu:SetInv(invCompiled)
        searchMenu:SetPlayer(searchee)
    end, true)
end)

net.Receive("impulseInvStorageOpen", function(len, ply)
    impulse_storage = vgui.Create("impulseInventoryStorage")
end)


net.Receive("impulseInvContainerCodeTry", function()
    Derma_StringRequest("impulse", "Enter container passcode (numerics only):", nil, function(text)
        local code = tonumber(text)

        if code then
            code = math.floor(code)

            if code < 0 then
                return LocalPlayer():Notify("Passcode can not be negative.")
            end

            net.Start("impulseInvContainerCodeReply")
            net.WriteUInt(code, 16)
            net.SendToServer()
        else
            LocalPlayer():Notify("Passcode must only contain numeric characters.")
        end
    end, nil, "Enter")
end)

net.Receive("impulseInvContainerOpen", function()
    local count = net.ReadUInt(8)
    local containerInv = {}

    for i = 1, count do
        local itemid = net.ReadUInt(10)
        local amount = net.ReadUInt(8)

        containerInv[itemid] = { amount = amount }
    end

    if impulse_container and IsValid(impulse_container) then
        impulse_container:Remove()
    end

    impulse_container = vgui.Create("impulseInventoryContainer")
    impulse_container:SetupContainer()
    impulse_container:SetupItems(containerInv)
end)

net.Receive("impulseInvContainerUpdate", function()
    local count = net.ReadUInt(8)
    local containerInv = {}

    for i = 1, count do
        local itemid = net.ReadUInt(10)
        local amount = net.ReadUInt(8)

        containerInv[itemid] = { amount = amount }
    end

    if impulse_container and IsValid(impulse_container) then
        local invScroll = impulse_container.invScroll:GetVBar():GetScroll()
        local invStorageScroll = impulse_container.invStorageScroll:GetVBar():GetScroll()

        impulse_container:SetupItems(containerInv, invScroll, invStorageScroll)
        surface.PlaySound("physics/wood/wood_crate_impact_hard2.wav")
    end
end)

net.Receive("impulseInvContainerSetCode", function()
    Derma_StringRequest("impulse",
        "Enter new container passcode:",
        nil, function(text)
            if not tonumber(text) then
                return LocalPlayer():Notify("Passcode must be a number.")
            end

            local passcode = tonumber(text)
            passcode = math.floor(passcode)

            if passcode < 1000 or passcode > 9999 then
                return LocalPlayer():Notify("Passcode must have 4 digits.")
            end

            net.Start("impulseInvContainerDoSetCode")
            net.WriteUInt(passcode, 16)
            net.SendToServer()
        end, nil, "Set Passcode")
end)
