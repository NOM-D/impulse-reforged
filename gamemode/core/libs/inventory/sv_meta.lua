---@realm server

---@class Player : PLAYER
local PLAYER = FindMetaTable("Player")

---Load the player's inventory items from the database
---@param self Player
---@param callback fun(result: impulse.DataModels.InventoryItem[]): impulse.DataModels.InventoryItem[]
---@return impulse.DataModels.InventoryItem[]?
function PLAYER:LoadInventoryItemsFromDatabase(callback)
    local query = mysql:Select("impulse_inventory")
    query:Select("id")
    query:Select("uniqueid")
    query:Select("ownerid")
    query:Select("storagetype")
    query:Where("ownerid", self.impulseID)

    if (callback) then
        ---@param result impulse.DataModels.InventoryItem[]
        query:Callback(function(result)
            if (! IsValid(self)) then
                impulse.Logs:Error("Player is not valid when trying to load inventory items from database.")
                return
            end

            if (istable(result)) then
                callback(result)
            else
                callback({})
            end
        end)
    end
    query:Execute()
end
