function PLUGIN:PlayerSpawnedNPC(ply, npc)
    npc:SetSpawnEffect(false)
    npc:SetKeyValue("spawnflags", npc:GetSpawnFlags() + SF_NPC_NO_WEAPON_DROP)
end