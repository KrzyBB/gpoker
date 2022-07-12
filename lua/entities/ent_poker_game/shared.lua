//Basics//

ENT.Type        = "anim"
ENT.PrintName   = "GPoker Table"
ENT.Spawnable   = true
ENT.Category    = "Fun + Games"
ENT.Base        = "base_gmodentity"

//Poker info//

ENT.intermission = 5

ENT.potModel = {
    [0] = {mdl = Model("models/items/currencypack_small.mdl"), val = 100},
    [1] = {mdl = Model("models/items/currencypack_medium.mdl"), val = 1000},
    [2] = {mdl = Model("models/items/currencypack_large.mdl"), val = 100000}
}

ENT.communityDeck = {}
ENT.players = {}

//Functions//

//Returns the key of the player's table, or nil if the player is not in-game
function ENT:getPlayerKey(p)
    for k,v in pairs(self.players) do
        if v.ind and Entity(v.ind) == p then return k end
    end

    return nil
end



//Returns the amount of ACTUAL PLAYERS
function ENT:getPlayersAmount()
    local count = 0

    for k,v in pairs(self.players) do
        if !v.bot then count = count + 1 end
    end

    return count
end



//Returns the amount of BOTS
function ENT:getBotsAmount()
    local count = 0

    for k,v in pairs(self.players) do
        if v.bot then count = count + 1 end
    end

    return count
end



function ENT:SetupDataTables()
    //Configurables
    self:NetworkVar("Int", 0, "GameType")
    self:NetworkVar("Int", 1, "MaxPlayers")
    self:NetworkVar("Int", 2, "BetType")
    self:NetworkVar("Float", 0, "EntryBet")
    self:NetworkVar("Float", 1, "StartValue")
    self:NetworkVar("Bool", 0, "BotsPlaceholder")
    self:NetworkVar("Int", 3, "Bots")

    //Match important stuff
    self:NetworkVar("Int", 4, "GameState")
    self:NetworkVar("Float", 2, "Pot")
    self:NetworkVar("Float", 3, "Bet")
    self:NetworkVar("Bool", 1, "Check")

    //Players related stuff
    self:NetworkVar("Int", 5, "Dealer")
    self:NetworkVar("Int", 6, "Turn")
    self:NetworkVar("Int", 7, "Winner")

    self:NetworkVarNotify("GameState", function(ent,name,old,new)
        //The intermission timer before/between rounds
        if new == 0 then
            timer.Create("gpoker_intermission" .. self:EntIndex(), self.intermission, 1, function()
                if SERVER and IsValid(self) and #self.players > 1 then 
                    self:SetGameState(1)
                    gPoker.gameType[self:GetGameType()].states[1].func(self) 
                end
            end)
        elseif old == 0 and new == -1 then
            timer.Remove("gpoker_intermission" .. self:EntIndex())
        end

        if CLIENT then
            //Creation of dealer token and setting deck to pot
            if old < 1 and new > 0 then
                if IsValid(self.deckPot) then
                    self.deckPot:SetModel(gPoker.betType[self:GetBetType()].models[1].mdl)
                    self.deckPot:SetModelScale(gPoker.betType[self:GetBetType()].models[1].scale)
                end
                if self.dealer == NULL then
                    self.dealer = ClientsideModel("models/gpoker/dealerchip.mdl", RENDERGROUP_BOTH)
                    self.dealer:SetParent(self)
                    self.dealer:SetLocalPos(Vector(0,0,0))
                end
            //Removing dealer token and reverting the deck back to normal
            elseif old > 0 and new < 1 then
                if IsValid(self.dealer) then
                    self.dealer:Remove()
                    self.dealer = NULL
                end
                if IsValid(self.deckPot) then
                    self.deckPot:SetModel("models/cards/stack.mdl")
                    self.deckPot:SetModelScale(1.75)
                end
                self.localDeck = {}
                self.communityDeck = {}
            end
        end
    end)

    if CLIENT then
        //Updating pot model
        self:NetworkVarNotify("Pot", function(ent, name, old, new)
            for i = 1, #gPoker.betType[self:GetBetType()].models do
                if new < gPoker.betType[self:GetBetType()].models[i].val and IsValid(self.deckPot) then 
                    self.deckPot:SetModel(gPoker.betType[self:GetBetType()].models[i].mdl)
                    self.deckPot:SetModelScale(gPoker.betType[self:GetBetType()].models[i].scale)
                    break
                end
            end
        end)

        //Updating position of dealer token
        self:NetworkVarNotify("Dealer", function(ent, name, old, new)
            if IsValid(self.dealer) then
                local startAngPos = 0
                local startAng = 0
                local radius = 30

                local ang = startAngPos - (360 / #self.players) * (new - 1) + 15
                ang = math.rad(ang)
                
                local x = math.cos(ang) * radius
                local y = math.sin(ang) * radius

                self.dealer:SetLocalPos(Vector(x, y, 38.5))
                self.dealer:SetLocalAngles(Angle(0, startAng - (360 / #self.players) * (new - 1), 0))
            end
        end)
    end

    if SERVER then
        self:NetworkVarNotify("Bots", function(ent,name,old,new)
            self:updateBots(self.botsInfo)
        end)

        self:NetworkVarNotify("Turn", function(ent, name, old, new)
            if self:GetGameState() > 0 and new != 0 then
                local ply = Entity(self.players[new].ind)

                if !IsValid(ply) then self:nextTurn() return end

                if gPoker.gameType[self:GetGameType()].states[self:GetGameState()].drawing then
                    if self.players[new].bot then self:simulateBotExchange(new) return end

                    net.Start("gpoker_derma_exchange")
                        net.WriteEntity(self)
                    net.Send(ply)
                else
                    if self.players[new].bot then self:simulateBotAction(new) return end

                    net.Start("gpoker_derma_bettingActions", false)
                        net.WriteEntity(self)
                        net.WriteBool(self:GetCheck())
                        net.WriteFloat(self:GetBet())
                    net.Send(ply)
                end
            end
        end)
    end
end



//Returns strength (ex. straight) and value (ex. ace high)
function ENT:getDeckValue(deck)
    local strength = 0
    local value = 0

    local ranks = {}
    local suits = {}

    local high = nil
    local pair = {}
    local threeKind = nil
    local fourKind = nil
    local straight = nil
    local flush = nil

    for i = 0, 12 do
        ranks[i] = 0
        if i >= 0 and i <= 3 then suits[i] = 0 end
    end

    for k,v in pairs(deck) do
        ranks[v.rank] = ranks[v.rank] + 1
        suits[v.suit] = suits[v.suit] + 1
    end

    //Four, three kinds and pairs
    for i = 12, 0, -1 do
        if ranks[i] == 4 then
            fourKind = i
        elseif ranks[i] == 3 then
            threeKind = i
        elseif ranks[i] == 2 then
            pair[#pair + 1] = i
        end

        if high == nil and ranks[i] > 0 then high = i end
    end

    //Straight and flush
    if #deck >= 5 then
        //Flush
        for k,v in pairs(suits) do
            if v >= 5 then flush = k break end
        end

        //Straight
        local sequence = 0

        for i = 0, 12 do
            if ranks[i] > 0 then
                sequence = sequence + 1
                if sequence >= 5 then straight = i end
            else sequence = 0 end
        end
    end



    //Getting strength and values
    if flush != nil and straight != nil and straight == 12 then --Royal Flush
        strength = 9
        value = flush
    elseif flush != nil and straight != nil then --Straight Flush
        strength = 8
        value = straight + flush * 0.1
    elseif fourKind != nil then --Four of a Kind
        strength = 7
        value = fourKind
    elseif threeKind != nil and #pair > 0 then --Full House
        strength = 6
        value = threeKind + pair[1] * 0.01
    elseif flush != nil then --Flush
        strength = 5
        value = high
    elseif straight != nil then --Straight
        strength = 4
        value = straight
    elseif threeKind != nil then --Three of a kind
        strength = 3
        value = threeKind
    elseif #pair >= 2 then
        strength = 2
        value = pair[1] + pair[2] * 0.01
    elseif #pair == 1 then
        strength = 1
        value = pair[1]
    else
        strength = 0
        value = high
    end

    return strength, value
end