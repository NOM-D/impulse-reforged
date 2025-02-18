local databaseSaveTimerId = "impulse.data.save"
if timer.Exists(databaseSaveTimerId) then
    timer.Remove(databaseSaveTimerId)
end

timer.Create(databaseSaveTimerId,
    impulse.Config.SaveIntervalSec || 120, 0, function()
        for _, ply in player.Iterator() do
            ply:SaveData()
        end
    end)
