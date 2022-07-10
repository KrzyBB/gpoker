AddCSLuaFile()

ENT.Type        = "anim"
ENT.Base        = "base_gmodentity"
ENT.PrintName   = "Poker Card"
ENT.Spawnable   = false
ENT.AdminOnly   = false
ENT.Category    = "Fun + Games"
ENT.Editable    = false

ENT.tran = {
    ["Suit"] = {
        [0] = "Club",
        [1] = "Diamond",
        [2] = "Heart",
        [3] = "Spade"
    },

    ["Rank"] = {
        [0]     = {name = "Two",    mat = {[0] = {s=4,  m=1},   [1] = {s=7,     m=1},     [2] = {s=6,     m=1},     [3] = {s=5,     m=1}}},    
        [1]     = {name = "Three",  mat = {[0] = {s=8,  m=1},   [1] = {s=11,    m=1},     [2] = {s=10,    m=1},     [3] = {s=9,     m=1}}},
        [2]     = {name = "Four",   mat = {[0] = {s=12, m=1},   [1] = {s=15,    m=1},     [2] = {s=14,    m=1},     [3] = {s=13,    m=1}}},
        [3]     = {name = "Five",   mat = {[0] = {s=16, m=1},   [1] = {s=19,    m=1},     [2] = {s=18,    m=1},     [3] = {s=17,    m=1}}},
        [4]     = {name = "Six",    mat = {[0] = {s=20, m=1},   [1] = {s=23,    m=1},     [2] = {s=22,    m=1},     [3] = {s=21,    m=1}}},
        [5]     = {name = "Seven",  mat = {[0] = {s=24, m=1},   [1] = {s=27,    m=1},     [2] = {s=26,    m=1},     [3] = {s=25,    m=1}}},
        [6]     = {name = "Eight",  mat = {[0] = {s=28, m=1},   [1] = {s=1,     m=2},     [2] = {s=0,     m=2},     [3] = {s=29,    m=1}}},
        [7]     = {name = "Nine",   mat = {[0] = {s=2,  m=2},   [1] = {s=5,     m=2},     [2] = {s=4,     m=2},     [3] = {s=3,     m=2}}},
        [8]     = {name = "Ten",    mat = {[0] = {s=6,  m=2},   [1] = {s=9,     m=2},     [2] = {s=8,     m=2},     [3] = {s=7,     m=2}}},
        [9]     = {name = "Jack",   mat = {[0] = {s=10, m=2},   [1] = {s=13,    m=2},     [2] = {s=12,    m=2},     [3] = {s=11,    m=2}}},
        [10]    = {name = "Queen",  mat = {[0] = {s=14, m=2},   [1] = {s=17,    m=2},     [2] = {s=16,    m=2},     [3] = {s=15,    m=2}}},
        [11]    = {name = "King",   mat = {[0] = {s=18, m=2},   [1] = {s=21,    m=2},     [2] = {s=20,    m=2},     [3] = {s=19,    m=2}}}, 
        [12]    = {name = "Ace",    mat = {[0] = {s=0,  m=1},   [1] = {s=3,     m=1},     [2] = {s=2,     m=1},     [3] = {s=1,     m=1}}}
    }

}



function ENT:SetupDataTables()
    self:NetworkVar("Int", 0, "Suit")
    self:NetworkVar("Int", 1, "Rank")

    if SERVER then
        self:NetworkVarNotify("Suit", function(ent, name, old, new)
            self:SetSkin(self.tran["Rank"][self:GetRank()].mat[new].s)
        
            if self.tran["Rank"][self:GetRank()].mat[new].m != self.tran["Rank"][self:GetRank()].mat[old].m then
                self:SetModel("models/cards/card" .. self.tran["Rank"][self:GetRank()].mat[new].m .. ".mdl")
            end
        end)
    
        self:NetworkVarNotify("Rank", function(ent, name, old, new)
            self:SetSkin(self.tran["Rank"][new].mat[self:GetSuit()].s)
        
            if self.tran["Rank"][new].mat[self:GetSuit()].m != self.tran["Rank"][old].mat[self:GetSuit()].m then
                self:SetModel("models/cards/card" .. self.tran["Rank"][new].mat[self:GetSuit()].m .. ".mdl")
            end
        end)
    end
end

if SERVER then
    function ENT:Initialize()
        self:SetModel("models/cards/card1.mdl")
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetRenderMode(RENDERMODE_TRANSCOLOR)
        self:SetMoveType(MOVETYPE_NONE)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetModelScale(1.75, 0.01)
    end
else
    function ENT:Draw()
        self:DrawModel()
    end
end