util.AddNetworkString("gpoker_derma_createGame") 
util.AddNetworkString("gpoker_updatePlayers") 
util.AddNetworkString("gpoker_payEntry")
util.AddNetworkString("gpoker_sendDeck") 
util.AddNetworkString("gpoker_derma_bettingActions") 
util.AddNetworkString("gpoker_derma_exchange")
util.AddNetworkString("gpoker_derma_leaveRequest")



net.Receive("gpoker_derma_createGame", function(l, p)
    if !IsValid(p) then return end

    local tr = p:GetEyeTraceNoCursor()
    local pos = tr.HitPos + tr.HitNormal * 10
    local ang = p:EyeAngles()
    ang.p = 0
    ang.y = ang.y + 180

    local options = net.ReadTable()

    local poker = ents.Create("ent_poker_game")
    poker:SetPos(pos)
    poker:SetAngles(ang)
    poker.botsInfo = options.bot.list
    poker:Spawn()
    poker:Activate()

    undo.Create("GPoker Table")
        undo.AddEntity(poker)
        undo.SetPlayer(p)
    undo.Finish()   

    poker:SetGameType(options.game.type)
    poker:SetMaxPlayers(options.game.maxPly)

    poker:SetBetType(options.bet.type)
    poker:SetEntryBet(options.bet.entry)
    poker:SetStartValue(options.bet.start)

    poker:SetBotsPlaceholder(options.bot.placehold)
    poker:SetBots(#options.bot.list)
end)



net.Receive("gpoker_payEntry", function(_, ply)
    local ent = net.ReadEntity()
    local paid = net.ReadBool()

    if !IsValid(ent) then return end

    if paid then
        gPoker.betType[ent:GetBetType()].add(ply, -ent:GetEntryBet(), ent)
        ent.players[ent:getPlayerKey(ply)].ready = true
        sound.Play("mvm/mvm_money_pickup.wav", ent:GetPos())
    else
        ent:removePlayerFromMatch(ply)
    end

    local allReady = true
    for _, v in pairs(ent.players) do
        if !v.ready then allReady = false break end
    end

    if allReady and IsValid(ent) and ent:GetGameState() > 0 then ent:nextState() end
end)



net.Receive("gpoker_derma_bettingActions", function(l, p)
    local s = net.ReadEntity()
    if !IsValid(s) then return end
    if s:GetGameState() < 1 then return end

    local choice = net.ReadUInt(3)
    local val = net.ReadFloat()
    local k = s:getPlayerKey(p)

    if choice == 0 then
        sound.Play("gpoker/check.wav", s:GetPos())
    elseif choice == 1 then
        gPoker.betType[s:GetBetType()].add(p, -val, s)
        s:SetCheck(false)
        s:SetBet(val)
        s.players[k].paidBet = val

        for k,v in pairs(s.players) do
            if not v.fold then
                v.ready = false
            end
        end

        sound.Play("mvm/mvm_money_pickup.wav", s:GetPos())
    elseif choice == 2 then
        gPoker.betType[s:GetBetType()].add(p, -(s:GetBet() - s.players[k].paidBet), s)
        s.players[k].paidBet = s:GetBet()

        sound.Play("mvm/mvm_money_pickup.wav", s:GetPos())
    elseif choice == 3 then
        gPoker.betType[s:GetBetType()].add(p, -val, s)
        s.players[k].paidBet = val

        for k,v in pairs(s.players) do
            if not v.fold then
                v.ready = false
            end
        end

        s:SetBet(val)

        sound.Play("mvm/mvm_money_pickup.wav", s:GetPos())
    elseif choice == 4 then
        s.players[k].fold = true
    end

    s.players[k].ready = true

    s:updatePlayersTable()

    timer.Simple(0.2, function()
        if !IsValid(s) then return end
        
        s:proceed() 
    end)
end)



net.Receive("gpoker_derma_exchange", function(l,p)
    local s = net.ReadEntity()
    local cards = net.ReadTable()

    if !IsValid(s) then return end

    local plyKey = s:getPlayerKey(p)
    local selectCards = {}

    for k,v in ipairs(cards) do
        if v then selectCards[#selectCards + 1] = k end 
    end

    if !table.IsEmpty(selectCards) then
        local oldCards = {}

        for k,v in pairs(selectCards) do
            oldCards[s.decks[plyKey][v].suit] = s.decks[plyKey][v].rank

            s:dealSingularCard(plyKey, v)
        end

        for k,v in pairs(oldCards) do
            s.deck[k][v] = true
        end

        net.Start("gpoker_sendDeck")
            net.WriteEntity(s)
            net.WriteTable(s.decks[s:getPlayerKey(p)])
        net.Send(Entity(s.players[s:getPlayerKey(p)].ind))

        sound.Play("gpoker/cardthrow.wav", s:GetPos())
    end

    s.players[plyKey].ready = true

    s:updatePlayersTable()
    s:proceed()
end)



net.Receive("gpoker_derma_leaveRequest", function(l, ply)
    local poker = net.ReadEntity()
    poker:removePlayerFromMatch(ply)
end)



hook.Add("CanProperty", "gpoker_blockSkinChange", function(ply, property, ent)
    if ent:GetClass() == "ent_poker_card" then return false end
end)

hook.Add("PlayerDisconnected", "gpoker_playerDisconnected", function(ply)
    local ent = gPoker.getTableFromPlayer(ply)

    if IsValid(ent) then
        ent:removePlayerFromMatch(ply)
    end
end)

hook.Add("CanExitVehicle", "gpoker_disableSeatExitting", function(veh, ply)
    if veh:GetVehicleClass() == "Chair_Office2" and IsValid(veh:GetParent()) and veh:GetParent():GetClass() == "ent_poker_game" then return false else return true end
end)

hook.Add("EntityTakeDamage", "gpoker_nullifyPlayerDamage", function(attacked, dmgInfo)
    local attacker = dmgInfo:GetAttacker()

    if (attacked:IsPlayer() and attacked:InVehicle() and IsValid(attacked:GetVehicle():GetParent()) and attacked:GetVehicle():GetParent():GetClass() == "ent_poker_game") or (attacker:IsPlayer() and attacker:InVehicle() and IsValid(attacker:GetVehicle():GetParent()) and attacker:GetVehicle():GetParent():GetClass() == "ent_poker_game") then
        dmgInfo:SetDamage(0)
    end
end)

hook.Add("CanPlayerSuicide", "gpoker_disableKillBind", function(ply)
    if ply:InVehicle() and IsValid(ply:GetVehicle():GetParent()) and ply:GetVehicle():GetParent():GetClass() == "ent_poker_game" then
        return false 
    end
end)

hook.Add("CanPlayerEnterVehicle", "gpoker_disallowSittingOnBotSeats", function(ply, veh, role)
    if !table.IsEmpty(veh:GetChildren()) then
        for k,v in pairs(veh:GetChildren()) do
            if v:GetClass() == "ent_poker_bot" then return false end
        end
    end
    return true
end)