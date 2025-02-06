--- Currency system for impulse
--- @module impulse.Currency
impulse.Currency = impulse.Currency or {}

--- Spawns money at a position
--- @realm server
--- @param pos Vector Position to spawn the money at
--- @param amount number Amount of money to spawn
--- @param dropper Player? Player who dropped the money
--- @return Entity The money entity
function impulse.Currency:SpawnMoney(pos, amount, dropper)
    local note = ents.Create("impulse_money")
    note:SetMoney(amount)
    note:SetPos(pos)
    note.Dropper = dropper or nil
    note:Spawn()

    return note
end

--- Wipes everyone's money
--- @realm server
--- @return nil
function impulse.Currency:WipeMoney()
    local query = mysql:Update("impulse_players")
    query:Update("money", 0)
    query:Execute()

    for k, v in player.Iterator() do
        v:SetMoney(0)
    end
end

--- Wipes everyone's bank money
--- @realm server
--- @return nil
function impulse.Currency:WipeBankMoney()
    local query = mysql:Update("impulse_players")
    query:Update("bankmoney", 0)
    query:Execute()

    for k, v in player.Iterator() do
        v:SetBankMoney(0)
    end
end

--- Wipes everyone's money and bank money
--- @realm server
function impulse.Currency:WipeAll()
    self:WipeMoney()
    self:WipeBankMoney()
end

---@class Player
local PLAYER = FindMetaTable("Player")

--- Set's the amount of money a player has
--- @realm server
--- @param amount number The amount of money to set for the player
--- @param bNoSave boolean? If true, the money will not be saved to the database
--- @return number The new amount of money the player has received
function PLAYER:SetMoney(amount, bNoSave)
    if ( !self.impulseBeenSetup ) then return end

    if ( !bNoSave ) then
        local query = mysql:Update("impulse_players")
        query:Update("money", amount)
        query:Where("steamid", self:SteamID64())
        query:Execute()
    end

    self:SetLocalVar("money", amount)

    return amount
end

--- Set's the amount of bank money a player has
--- @param amount number The amount of bank money to set for the player
--- @param bNoSave boolean? If true, the bank money will not be saved to the database (optional)
--- @return number The new amount of bank money the player has received
function PLAYER:SetBankMoney(amount, bNoSave)
    if not self.impulseBeenSetup then return end

    if not bNoSave then
        local query = mysql:Update("impulse_players")
        query:Update("bankmoney", amount)
        query:Where("steamid", self:SteamID64())
        query:Execute()
    end

    self:SetLocalVar("bankmoney", amount)

    return amount
end

--- Gives the player the amount of money
--- @param amount number Amount of money to give to the player
--- @return number The new amount of money the player has after addition
function PLAYER:AddMoney(amount)
    return self:SetMoney(self:GetMoney() + amount)
end

--- Takes the amount of money from the player
--- @param amount number Amount of money to take from the player
--- @return number The new amount of money the player has after deduction
function PLAYER:TakeMoney(amount)
    return self:SetMoney(self:GetMoney() - amount)
end

--- Gives the player the amount of bank money
--- @param amount number Amount of bank money to give to the player
--- @return number The new amount of bank money the player has after addition
function PLAYER:AddBankMoney(amount)
    return self:SetBankMoney(self:GetBankMoney() + amount)
end

--- Takes the amount of bank money from the player
--- @param amount number Amount of bank money to take from the player
--- @return number The new amount of bank money the player has after deduction
function PLAYER:TakeBankMoney(amount)
    return self:SetBankMoney(self:GetBankMoney() - amount)
end