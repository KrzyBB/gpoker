AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Bot"
ENT.Spawnable = false
ENT.AdminOnly = false
ENT.Category = "Fun + Games"

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "BotName")
    self:NetworkVar("Vector", 0, "ModelColor")

    self:NetworkVarNotify("ModelColor", function(ent,name,old,new)
        self.GetPlayerColor = function() return new end
    end)
end

if SERVER then
    function ENT:Initialize()
        self:PhysicsInit(SOLID_NONE)
        self:SetMoveType(MOVETYPE_NONE)
        self:SetSolid(SOLID_NONE)
    end
else
    function ENT:Initialize()
        self.GetPlayerColor = function() return self:GetModelColor() end
    end

    function ENT:Draw()
        self:DrawModel()
    end
end