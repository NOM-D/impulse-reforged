--- Currency system for impulse
-- @module impulse.Currency

impulse.Currency = impulse.Currency or {}

---@class Player
local PLAYER = FindMetaTable("Player")

--- Returns the player's money
--- @realm shared
--- @return number money The player's money
--- @nodiscard
function PLAYER:GetMoney()
    return tonumber(self:GetLocalVar("money", 0)) --[[@as number]]
end

--- Returns the player's bank money
--- @realm shared
--- @return number bankMoney The player's bank money
--- @nodiscard
function PLAYER:GetBankMoney()
    return tonumber(self:GetLocalVar("bankMoney", 0)) --[[@as number]]
end

--- Returns wether the player has enough money to afford the amount
--- @realm shared
--- @param amount number The amount to check
--- @return boolean canAfford Wether the player can afford the amount
--- @nodiscard
function PLAYER:CanAfford(amount)
    if ( !isnumber(amount) or amount < 0 or amount >= 1 / 0 ) then return false end

    return self:GetMoney() >= amount
end

--- Returns wether the player has enough bank money to afford the amount
--- @realm shared
--- @parameter number canAffordBank The amount to check
--- @return boolean canAffordBank Wether the player can afford the amount
--- @nodiscard
function PLAYER:CanAffordBank(amount)
    if ( !isnumber(amount) or amount < 0 or amount >= 1 / 0 ) then return false end

    return self:GetBankMoney() >= amount
end