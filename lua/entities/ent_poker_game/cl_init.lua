include("shared.lua")

ENT.localDeck = {}
ENT.deckPot = NULL
ENT.dealer = NULL



//Functions//

function ENT:Draw()
    self:DrawModel()

    if IsValid(self.deckPot) then
        if self:GetGameState() > -1 then
            local ang = EyeAngles()
            ang.p = 0 
            ang.r = 0

            ang:RotateAroundAxis(ang:Up(), -90)
            ang:RotateAroundAxis(ang:Forward(), 90)

            local text = ""
            if self:GetGameState() == 0 and timer.Exists("gpoker_intermission" .. self:EntIndex()) then 
                text = math.floor(timer.TimeLeft("gpoker_intermission" .. self:EntIndex())) + 1
            else
                text = self:GetPot() .. gPoker.betType[self:GetBetType()].fix
            end

            cam.Start3D2D(self.deckPot:GetPos() + self.deckPot:GetUp() * 15, ang, 0.2)
                draw.SimpleText(text, "gpoker_header", 0, 0, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            cam.End3D2D()
        end

        self.deckPot:SetLocalAngles(Angle(0,CurTime() % 360 * 10,0))
        self.deckPot:SetLocalPos(Vector(0,0,math.sin(CurTime() * 3) + 39))
    end

    for k,v in pairs(self.players) do
        local ent = Entity(v.ind)
        if self:GetPos():Distance(LocalPlayer():GetPos()) <= 256 and self:getPlayerKey(ent) then
            local ang = EyeAngles()
            ang.p = 0
            ang.r = 0
        
            ang:RotateAroundAxis(ang:Up(), -90)
            ang:RotateAroundAxis(ang:Forward(), 90)
        
            local mult = 15
            if !ent:IsPlayer() then mult = 45 end
        
            local pos = ent:EyePos() + ent:GetUp() * mult
        
            cam.Start3D2D(pos, ang, 0.15)
                surface.SetFont("gpoker_header")
        
                local key = self:getPlayerKey(ent)
                local margin = 5
                local nick
                if ent:IsPlayer() then nick = ent:Nick() else nick = "[BOT] " .. ent:GetBotName() end
                local fontW, fontH = surface.GetTextSize(nick)
                local bgW, bgH = math.Clamp(fontW, 85, 1000) + margin * 2, fontH + margin * 2
        
                local bgClr = Color(37,37,37, 225)
                local txtClr = Color(255,255,255,255)
                local outClr = Color(71,133,198,255)
                local stateClr = txtClr
        
                surface.SetFont("gpoker_text")
                local state = ""
                local btmTxtH = 0
        
                if self:GetGameState() > 0  then
                    if self.players[key].strength != nil then
                        state = gPoker.strength[self.players[key].strength]
                    elseif self.players[key].fold then
                        state = "Fold"
                        stateClr = Color(225,225,225,255)
                    else
                        state = gPoker.betType[self:GetBetType()].get(ent) .. gPoker.betType[self:GetBetType()].fix
                    end
                
                    local _, btmTxtH = surface.GetTextSize(state)
                    bgH = btmTxtH + bgH
                end
            
            
                //Change opacity
                if (self:GetWinner() > 0 and self:GetWinner() ~= key) or (self:GetGameState() > 0 and self:GetGameState() < #gPoker.gameType[self:GetGameType()].states and self:GetTurn() ~= key)  then
                    local m = 0.4
                
                    bgClr = Color(bgClr.r, bgClr.g, bgClr.b, bgClr.a * m)
                    txtClr = Color(txtClr.r, txtClr.g, txtClr.b, txtClr.a * m)
                    stateClr = Color(stateClr.r, stateClr.g, stateClr.b, stateClr.a * m)
                    outClr = Color(outClr.r, outClr.g, outClr.b, outClr.a * m)
                end
            
                if self:GetGameState() == #gPoker.gameType[self:GetGameType()].states and self:GetWinner() == key then stateClr = Color(241,241,75) end
            
                draw.NoTexture()
                surface.SetDrawColor(bgClr:Unpack())
                surface.DrawRect(0 - bgW/2, 0 - bgH/2, bgW, bgH)
            
                surface.SetDrawColor(outClr:Unpack())
                surface.DrawOutlinedRect(0 - bgW/2, 0 - bgH/2, bgW, bgH, 2)
            
                draw.SimpleText(nick, "gpoker_header", 0, 0 - bgH/2 + margin, txtClr, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
                draw.SimpleText(state, "gpoker_text", 0, 0 - bgH/2 + margin + fontH + btmTxtH/2, stateClr, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
            cam.End3D2D()
        end
    end
end



function ENT:Initialize()
    self.deckPot = ClientsideModel("models/cards/stack.mdl", RENDERGROUP_BOTH)
    self.deckPot:SetParent(self)
    self.deckPot:SetModelScale(1.75)
    self.deckPot:SetLocalPos(Vector(0,0,38.5))
    self.deckPot:SetLocalAngles(Angle(0,0,0))

    hook.Add("HUDPaint", "gpoker_hudPaint" .. self:EntIndex(), function()
        //HUD
        if !IsValid(self) then return end

        if self:BeingLookedAtByLocalPlayer() and self:GetPos():Distance(LocalPlayer():GetPos()) < 128 and self:GetGameState() < 1 then
            if !self:getPlayerKey(LocalPlayer()) then
                surface.SetFont("gpoker_bold")
                local plyHeader = "Players: "
                local startHeader = "Starting Value: "
                local entryHeader = "Entry Fee: "
        
                local plyW, _ = surface.GetTextSize(plyHeader)
                local startW, _ = surface.GetTextSize(startHeader)
                local entryW, _ = surface.GetTextSize(entryHeader)
        
                local x, y = ScrW() / 2, ScrH() / 2
                local bW, bH = 250, 125
                local pad = 5
                local _, fontH = surface.GetTextSize("W")
        
                surface.SetDrawColor(37,37,37, 225)
                surface.DrawRect(x - bW / 2, y - bH / 2, bW, bH)
                surface.SetDrawColor(71,133,198)
                surface.DrawOutlinedRect(x - bW / 2, y - bH / 2, bW, bH, 2)
        
                draw.SimpleText(gPoker.gameType[self:GetGameType()].name, "gpoker_header", x, y - bH / 2 + pad, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
                draw.SimpleText(plyHeader, "gpoker_bold", x - bW / 2 + pad, y - bH / 2 + fontH + pad + 15, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText("(" .. #self.players .. "/" .. self:GetMaxPlayers() .. ")", "gpoker_text", x - bW / 2 + pad + plyW, y - bH / 2 + fontH + pad + 15, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText(entryHeader, "gpoker_bold", x - bW / 2 + pad, y - bH / 2 + fontH * 2 + pad + 15, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText(self:GetEntryBet() .. gPoker.betType[self:GetBetType()].fix, "gpoker_text", x - bW / 2 + pad + entryW, y - bH / 2 + fontH * 2 + pad + 15, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                if gPoker.betType[self:GetBetType()].canSet then
                    draw.SimpleText(startHeader, "gpoker_bold", x - bW / 2 + pad, y - bH / 2 + fontH * 3 + pad + 15, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    draw.SimpleText(self:GetStartValue() .. gPoker.betType[self:GetBetType()].fix, "gpoker_text", x - bW / 2 + pad + startW, y - bH / 2 + fontH * 3 + pad + 15, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end

                local canJoin = true
                for k,v in pairs(ents.FindByClass("ent_poker_game")) do
                    if v:getPlayerKey(LocalPlayer()) then canJoin = false break end
                end
            
                local text = "Press [" .. string.upper(input.LookupBinding("+use")) .. "] to join."
                if !canJoin then text = "Cannot join - already in a match." end
                if #self.players >= self:GetMaxPlayers() then text = "Cannot join - match full" end
                draw.SimpleText(text, "gpoker_bold", x, y + bH / 2 - pad, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
            end
        end

        if self.players[self:getPlayerKey(LocalPlayer())] then
            local width = 245
            local height = 108

            //Cards
            if self:GetGameState() > 0 then
                surface.SetDrawColor(Color(37,37,37, 225))
                surface.DrawRect(ScrW()/2 - width/2, ScrH() - height + 2, width, height)

                surface.SetDrawColor(Color(71,133,198))
                surface.DrawOutlinedRect(ScrW()/2 - width/2, ScrH() - height + 2, width, height, 2)

                if #self.localDeck > 0 then
                    for i = 1, #self.localDeck do
                        local suit = self.localDeck[i].suit
                        local rank = self.localDeck[i].rank
                        local cardW, cardH
                        cardW = 100
                        cardH = 150
                        local deckCenter = ScrW()/2 - cardW / 2

                        draw.RoundedBox(6, deckCenter   -   (cardW * (0.25 / math.Clamp(#self.localDeck - 3, 1.5, 10) )) * (#self.localDeck - 1)   +   (cardW * (0.5 / math.Clamp(#self.localDeck - 3, 1.5, 10) )) * (i-1) - 2.5, ScrH() - cardH * 0.8 - 2.5 * (i-1), cardW, cardH, Color(0,0,0,127))

                        surface.SetDrawColor(255,255,255,255)
                        surface.SetMaterial(gPoker.cards[suit][rank])
                        surface.DrawTexturedRect(deckCenter   -   (cardW * (0.25 / math.Clamp(#self.localDeck - 3, 1.5, 10) )) * (#self.localDeck - 1)   +   (cardW * (0.5 / math.Clamp(#self.localDeck - 3, 1.5, 10) )) * (i-1), ScrH() - cardH * 0.8 - 2.5 * (i-1), cardW, cardH)
                    end
                end

                //Community cards below our cards, if there are any
                if #self.communityDeck > 0 then
                    for i = 1, #self.communityDeck do
                        local suit = self.communityDeck[i].suit
                        local rank = self.communityDeck[i].rank
                        local cardW, cardH = 100, 150
                        local deckCenter = ScrW()/2 - cardW / 2

                        draw.RoundedBox(6, deckCenter   -   (cardW * (0.25 / math.Clamp(#self.communityDeck - 3, 1.5, 10) )) * (#self.communityDeck - 1)   +   (cardW * (0.5 / math.Clamp(#self.communityDeck - 3, 1.5, 10) )) * (i-1) - 2.5, ScrH() - cardH * 0.5 - 2.5 * (i-1), cardW, cardH, Color(0,0,0,127))

                        surface.SetDrawColor(255,255,255,255)
                        surface.SetMaterial(gPoker.cards[suit][rank])
                        surface.DrawTexturedRect(deckCenter   -   (cardW * (0.25 / math.Clamp(#self.communityDeck - 3, 1.5, 10) )) * (#self.communityDeck - 1)   +   (cardW * (0.5 / math.Clamp(#self.communityDeck - 3, 1.5, 10) )) * (i-1), ScrH() - cardH * 0.5 - 2.5 * (i-1), cardW, cardH)
                    end
                end



                local sideW, sideH = 100, height

                surface.SetDrawColor(Color(37,37,37, 225))
                surface.DrawRect(ScrW()/2 + width/2, ScrH() - height + 2, sideW, sideH)

                surface.SetDrawColor(Color(71,133,198))
                surface.DrawOutlinedRect(ScrW()/2 + width/2, ScrH() - height + 2, sideW, sideH, 2)


                surface.SetFont("gpoker_header")
                local money, bet, pot = gPoker.betType[self:GetBetType()].name .. ": ", "Bet: ", "Pot: "
                local moneyW, headH = surface.GetTextSize(money)

                surface.DrawOutlinedRect(ScrW()/2 + width/2, ScrH() - height + 2, sideW, 5 + headH, 2)

                surface.SetFont("gpoker_bold")
                local betW, boldH = surface.GetTextSize(bet)
                local potW, _ = surface.GetTextSize(pot)
                local outset = 12


                draw.SimpleText(gPoker.betType[self:GetBetType()].get(LocalPlayer()) .. gPoker.betType[self:GetBetType()].fix, "gpoker_header", ScrW()/2 + width/2 + sideW/2, ScrH() - height + outset + 5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

                draw.SimpleText(bet, "gpoker_bold", ScrW()/2 + width/2 + 5, ScrH() - height + outset + headH + 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText(self:GetBet() .. gPoker.betType[self:GetBetType()].fix, "gpoker_text", ScrW()/2 + width/2 + 5 + betW, ScrH() - height + outset + headH + 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

                draw.SimpleText(pot, "gpoker_bold", ScrW()/2 + width/2 + 5, ScrH() - height + outset + headH + boldH + 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText(self:GetPot() .. gPoker.betType[self:GetBetType()].fix, "gpoker_text", ScrW()/2 + width/2 + 5 + potW, ScrH() - height + outset + headH + boldH + 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

                -- draw.SimpleText(string.FormattedTime(CurTime() - self.matchStartTime, "%02i:%02i"), "gpoker_bold", ScrW()/2 + width/2 + sideW/2, ScrH() - 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
            end



            //Info
            local upW, upH = 300, 50

            surface.SetDrawColor(37,37,37, 225)
            surface.DrawRect(ScrW()/2 - upW/2, -2, upW, upH)

            surface.SetDrawColor(71,133,198)
            surface.DrawOutlinedRect(ScrW()/2 - upW/2, -2, upW, upH, 2)

            surface.SetFont("gpoker_header")

            local state
            if self:GetGameState() > 0 then
                if isfunction(gPoker.gameType[self:GetGameType()].states[self:GetGameState()].text) then
                    state =gPoker.gameType[self:GetGameType()].states[self:GetGameState()].text(self)
                else
                    state = gPoker.gameType[self:GetGameType()].states[self:GetGameState()].text
                end
            elseif self:GetGameState() == 0 then
                state = "Intermission"
            else
                state = "Waiting for players"
            end

            draw.SimpleText(gPoker.gameType[self:GetGameType()].name, "gpoker_header", ScrW()/2, 15, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText(state, "gpoker_text", ScrW()/2, 30, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end)
end



function ENT:OnRemove()
    if IsValid(self.deckPot) then self.deckPot:Remove() end
    if IsValid(self.dealer) then self.dealer:Remove() end

    hook.Remove("HUDPaint", "gpoker_hudPaint" .. self:EntIndex())
end



function ENT:openEntryFeeDerma()
    local w, h = 300, 150

    local win = vgui.Create("DFrame")
    win:SetTitle("Pay the entry fee")
    win:SetSize(w, h)
    win:Center()
    win:SetVisible(true)
    win:SetDraggable(false)
    win:ShowCloseButton(false)
    win.Paint = function(self, w, h)
        local outSize = 2
        local outset = 20

        surface.SetDrawColor(Color(37,37,37, 225))
        surface.DrawRect(0, outset, w, h-outset)

        surface.SetDrawColor(Color(71,133,198))
        surface.DrawRect(0, 0, w, outset)
        surface.DrawOutlinedRect(0, outset, w, h - outset, outSize)
    end
    win:SetPopupStayAtBack(true)
    win:MakePopup()




    local pay = vgui.Create("DButton", win)
    pay:SetSize(w/2, h - 20)
    pay:SetPos(2, 20)
    pay:SetFont("gpoker_header")
    pay:SetTextColor(color_white)
    pay:SetText("Pay ante")
    pay.Paint = function(self, w, h)
        if self:IsHovered() then
            surface.SetDrawColor(Color(71,133,198))
        else
            surface.SetDrawColor(Color(37,37,37))
        end
        surface.DrawRect(0,0,w,h)

        surface.SetDrawColor(Color(71,133,198))
        surface.DrawOutlinedRect(0,0,w,h,buttonOutline)
    end
    pay.DoClick = function()
        net.Start("gpoker_payEntry", false)
            net.WriteEntity(self)
            net.WriteBool(true)
        net.SendToServer()
        win:Close()
    end

    local payVal = vgui.Create("DLabel", pay)
    payVal:SetFont("gpoker_bold")
    payVal:SetTextColor(color_white)
    payVal:SetText("(" .. self:GetEntryBet() .. gPoker.betType[self:GetBetType()].fix .. ")")
    surface.SetFont("gpoker_bold")
    local textW, _ = surface.GetTextSize("(" .. self:GetEntryBet() .. gPoker.betType[self:GetBetType()].fix .. ")")
    
    payVal:SetPos(pay:GetWide()/2 - textW/2, pay:GetTall()/2 + 10)



    local leave = vgui.Create("DButton", win)
    leave:SetSize(w/2, h - 20)
    leave:SetPos(w/2, 20)
    leave:SetFont("gpoker_header")
    leave:SetTextColor(color_white)
    leave:SetText("Leave")
    leave.Paint = function(self, w, h)
        if self:IsHovered() then
            surface.SetDrawColor(Color(71,133,198))
        else
            surface.SetDrawColor(Color(37,37,37))
        end
        surface.DrawRect(0,0,w,h)

        surface.SetDrawColor(Color(71,133,198))
        surface.DrawOutlinedRect(0,0,w,h,buttonOutline)
    end
    leave.DoClick = function()
        net.Start("gpoker_payEntry", false)
            net.WriteEntity(self)
            net.WriteBool(false)
        net.SendToServer()
        win:Close()
    end
end



function ENT:openBettingDerma(check)
    local w, h = 300, 150

    local win = vgui.Create("DFrame")
    win:SetTitle("")
    win:SetSize(w, h)
    win:Center()
    win:SetVisible(true)
    win:SetDraggable(false)
    win:ShowCloseButton(true)
    win.Paint = function(self, w, h)
        local outSize = 2
        local outset = 20

        surface.SetDrawColor(Color(37,37,37, 225))
        surface.DrawRect(0, outset, w, h-outset)

        surface.SetDrawColor(Color(71,133,198))
        surface.DrawRect(0, 0, w, outset)
        surface.DrawOutlinedRect(0, outset, w, h - outset, outSize)
    end
    win.Close = function()
        self:openLeaveRequest()
        win:Remove()
    end
    win:SetPopupStayAtBack(true)
    win:MakePopup()




    local buttonOutline = 2

    if check then
        local check = vgui.Create("DButton", win)
        check:SetSize(w/2, h - 20)
        check:SetPos(2, 20)
        check:SetFont("gpoker_header")
        check:SetTextColor(color_white)
        check:SetText("Check")
        check.Paint = function(self, w, h)
            if self:IsHovered() then
                surface.SetDrawColor(Color(71,133,198))
            else
                surface.SetDrawColor(Color(37,37,37))
            end
            surface.DrawRect(0,0,w,h)
    
            surface.SetDrawColor(Color(71,133,198))
            surface.DrawOutlinedRect(0,0,w,h,buttonOutline)
        end
        check.DoClick = function()
            net.Start("gpoker_derma_bettingActions", false)
                net.WriteEntity(self)
                net.WriteUInt(0, 3)
            net.SendToServer()
            win:Remove()
        end

        local bet = vgui.Create("DButton", win)
        local clr = color_white
        local canBet = gPoker.betType[self:GetBetType()].get(LocalPlayer()) > self:GetBet()

        if !canBet then clr = Color(155,155,155) end

        bet:SetSize(w/2 - 4, h - 20)
        bet:SetPos(w/2 + 2, 20)
        bet:SetFont("gpoker_header")
        bet:SetTextColor(clr)
        bet:SetText("Bet")
        bet.Paint = function(self, w, h)
            if !canBet then
                surface.SetDrawColor(Color(30,30,30))
            elseif self:IsHovered() then
                surface.SetDrawColor(Color(71,133,198))
            else
                surface.SetDrawColor(Color(37,37,37))
            end
            surface.DrawRect(0,0,w,h)
    
            surface.SetDrawColor(Color(71,133,198))
            surface.DrawOutlinedRect(0,0,w,h,buttonOutline)
        end
        bet.DoClick = function()
            if !canBet then return end

            local betAmount = vgui.Create("DNumSlider", win)
            betAmount:SetDecimals(0)
            betAmount:SetPos(10, 0)
            betAmount:CenterVertical()
            betAmount:SetSize(w-(h-20)/2, 25)
            betAmount:SetMin(self:GetBet())
            betAmount:SetMax(gPoker.betType[self:GetBetType()].get(LocalPlayer()))
            betAmount:SetValue(betAmount:GetMin())

            local betButton = vgui.Create("DButton", win)
            betButton:SetSize((h-20)/2,(h-20)/2)
            betButton:SetPos(w - (h-20)/2,20)
            betButton:SetFont("gpoker_header")
            betButton:SetTextColor(color_white)
            betButton:SetText("Bet")
            betButton.Paint = function(self, w, h)
                if self:IsHovered() then
                    surface.SetDrawColor(Color(71,133,198))
                else
                    surface.SetDrawColor(Color(37,37,37))
                end
                surface.DrawRect(0,0,w,h)
        
                surface.SetDrawColor(Color(71,133,198))
                surface.DrawOutlinedRect(0,0,w,h,buttonOutline)
            end
            betButton.DoClick = function()
                local val = math.floor(betAmount:GetValue())

                net.Start("gpoker_derma_bettingActions", false)
                    net.WriteEntity(self)
                    net.WriteUInt(1, 3)
                    net.WriteFloat(val)
                net.SendToServer()
                win:Remove()
            end

            local backButton = vgui.Create("DButton", win)
            backButton:SetSize((h-20)/2,(h-20)/2)
            backButton:SetPos(w - (h-20)/2, 20 + (h-20)/2)
            backButton:SetFont("gpoker_header")
            backButton:SetTextColor(color_white)
            backButton:SetText("Back")
            backButton.Paint = function(self, w, h)
                if self:IsHovered() then
                    surface.SetDrawColor(Color(71,133,198))
                else
                    surface.SetDrawColor(Color(37,37,37))
                end
                surface.DrawRect(0,0,w,h)
        
                surface.SetDrawColor(Color(71,133,198))
                surface.DrawOutlinedRect(0,0,w,h,buttonOutline)
            end
            backButton.DoClick = function()
                bet:Show()
                check:Show()
                betAmount:Remove()
                betButton:Remove()
                backButton:Remove()
            end

            bet:Hide()
            check:Hide()
        end
    else
        local call = vgui.Create("DButton", win)
        call:SetSize(w/3,h-20)
        call:SetPos(2, 20)
        call:SetFont("gpoker_header")
        call:SetTextColor(color_white)
        call:SetText("Call")
        call.Paint = function(self, w, h)
            if self:IsHovered() then
                surface.SetDrawColor(Color(71,133,198))
            else
                surface.SetDrawColor(Color(37,37,37))
            end
            surface.DrawRect(0,0,w,h)
    
            surface.SetDrawColor(Color(71,133,198))
            surface.DrawOutlinedRect(0,0,w,h,buttonOutline)
        end
        call.DoClick = function()
            net.Start("gpoker_derma_bettingActions", false)
                net.WriteEntity(self)
                net.WriteUInt(2, 3)
            net.SendToServer()
            win:Remove()
        end

        local callVal = vgui.Create("DLabel", call)
        callVal:SetFont("gpoker_bold")
        callVal:SetTextColor(color_white)
        callVal:SetText("(" .. self:GetBet() - self.players[self:getPlayerKey(LocalPlayer())].paidBet .. gPoker.betType[self:GetBetType()].fix .. ")")
        surface.SetFont("gpoker_bold")
        local textW, _ = surface.GetTextSize("(" .. self:GetBet() - self.players[self:getPlayerKey(LocalPlayer())].paidBet .. gPoker.betType[self:GetBetType()].fix .. ")")
        
        callVal:SetPos(call:GetWide()/2 - textW/2, call:GetTall()/2 + 10)


        local fold = vgui.Create("DButton", win)
        fold:SetSize(w/3,h-20)
        fold:SetPos(w/3, 20)
        fold:SetFont("gpoker_header")
        fold:SetTextColor(color_white)
        fold:SetText("Fold")
        fold.Paint = function(self, w, h)
            if self:IsHovered() then
                surface.SetDrawColor(Color(71,133,198))
            else
                surface.SetDrawColor(Color(37,37,37))
            end
            surface.DrawRect(0,0,w,h)
    
            surface.SetDrawColor(Color(71,133,198))
            surface.DrawOutlinedRect(0,0,w,h,buttonOutline)
        end
        fold.DoClick = function()
            net.Start("gpoker_derma_bettingActions", false)
                net.WriteEntity(self)
                net.WriteUInt(4, 3)
            net.SendToServer()
            win:Remove()
        end


        local curBet = self:GetBet()

        local raise = vgui.Create("DButton", win)
        local canRaise = gPoker.betType[self:GetBetType()].get(LocalPlayer()) > curBet + 1
        local clr = color_white

        if !canRaise then clr = Color(155,155,155) end

        raise:SetSize(w/3,h-20)
        raise:SetPos(w/3*2 - 2, 20)
        raise:SetFont("gpoker_header")
        raise:SetTextColor(clr)
        raise:SetText("Raise")
        raise.Paint = function(self, w, h)
            if !canRaise then
                surface.SetDrawColor(Color(30,30,30))
            elseif self:IsHovered() then
                surface.SetDrawColor(Color(71,133,198))
            else
                surface.SetDrawColor(Color(37,37,37))
            end
            surface.DrawRect(0,0,w,h)
    
            surface.SetDrawColor(Color(71,133,198))
            surface.DrawOutlinedRect(0,0,w,h,buttonOutline)
        end
        raise.DoClick = function()
            if !canRaise then return end

            local raiseAmount = vgui.Create("DNumSlider", win)
            raiseAmount:SetDecimals(0)
            raiseAmount:SetPos(10, 0)
            raiseAmount:CenterVertical()
            raiseAmount:SetSize(w-(h-20)/2, 25)
            raiseAmount:SetMin(self:GetBet() + 1)
            raiseAmount:SetMax(gPoker.betType[self:GetBetType()].get(LocalPlayer()))
            raiseAmount:SetValue(self:GetBet() + 1)

            local raiseButton = vgui.Create("DButton", win)
            raiseButton:SetSize((h-20)/2,(h-20)/2)
            raiseButton:SetPos(w - (h-20)/2,20)
            raiseButton:SetFont("gpoker_header")
            raiseButton:SetTextColor(color_white)
            raiseButton:SetText("Raise")
            raiseButton.Paint = function(self, w, h)
                if self:IsHovered() then
                    surface.SetDrawColor(Color(71,133,198))
                else
                    surface.SetDrawColor(Color(37,37,37))
                end
                surface.DrawRect(0,0,w,h)
        
                surface.SetDrawColor(Color(71,133,198))
                surface.DrawOutlinedRect(0,0,w,h,buttonOutline)
            end
            raiseButton.DoClick = function()
                local val = math.floor(raiseAmount:GetValue())

                net.Start("gpoker_derma_bettingActions", false)
                    net.WriteEntity(self)
                    net.WriteUInt(1, 3)
                    net.WriteFloat(val)
                net.SendToServer()
                win:Remove()
            end

            local backButton = vgui.Create("DButton", win)
            backButton:SetSize((h-20)/2,(h-20)/2)
            backButton:SetPos(w - (h-20)/2, 20 + (h-20)/2)
            backButton:SetFont("gpoker_header")
            backButton:SetTextColor(color_white)
            backButton:SetText("Back")
            backButton.Paint = function(self, w, h)
                if self:IsHovered() then
                    surface.SetDrawColor(Color(71,133,198))
                else
                    surface.SetDrawColor(Color(37,37,37))
                end
                surface.DrawRect(0,0,w,h)
        
                surface.SetDrawColor(Color(71,133,198))
                surface.DrawOutlinedRect(0,0,w,h,buttonOutline)
            end
            backButton.DoClick = function()
                raise:Show()
                call:Show()
                fold:Show()
                raiseAmount:Remove()
                raiseButton:Remove()
                backButton:Remove()
            end

            raise:Hide()
            call:Hide()
            fold:Hide()
        end
    end
end



function ENT:openExchangeDerma()
    local cardW, cardH = 125, 0
    cardH = cardW * 1.5
    local w, h = (gPoker.gameType[self:GetGameType()].cardNum * (cardW * 0.3) + (cardW - cardW * 0.3)) + 20, 150

    local win = vgui.Create("DFrame")
    win:SetTitle("")
    win:SetSize(w, h)
    win:Center()
    win:SetVisible(true)
    win:ShowCloseButton(true)
    win:SetDraggable(false)
    win.Close = function()
        self:openLeaveRequest()
        win:Remove()
    end
    win.Paint = function(self, w, h)
        local outSize = 2
        local outset = 20

        surface.SetDrawColor(Color(37,37,37, 225))
        surface.DrawRect(0, outset, w, h-outset)

        surface.SetDrawColor(Color(71,133,198))
        surface.DrawRect(0, 0, w, outset)
        surface.DrawOutlinedRect(0, outset, w, h - outset, outSize)
    end
    win:SetPopupStayAtBack(true)
    win:MakePopup()


    local cards = {}
    local mark = {}
    local pos = {}

    surface.SetFont("gpoker_text")

    for k,v in pairs(self.localDeck) do
        mark[k] = false
        cards[k] = vgui.Create("DImageButton", win)
        cards[k]:SetSize(cardW, cardH)
        pos[k] = (k - 1) * (cardW * 0.3) + 10
        cards[k]:SetPos(pos[k], h/2 - (cardH/2 * 0.3) - 2.5 * (k - 1))
        cards[k]:SetMaterial(gPoker.cards[v.suit][v.rank])

        cards[k].DoClick = function()
            mark[k] = !mark[k]
            if mark[k] then 
                cards[k]:SetPos(pos[k], h/2 - (cardH/2 * 0.3) - 2.5 * (k - 1) - 10) 
            else 
                cards[k]:SetPos(pos[k], h/2 - (cardH/2 * 0.3) - 2.5 * (k - 1)) 
            end
        end

        cards[k].PaintOver = function()
            if mark[k] then
                draw.RoundedBox(5, 0, 0, cardW,cardH, Color(0,123,255,125))
            end
        end
    end

    local cover = vgui.Create("DPanel", win)
    cover:SetSize(w, h * 0.4)
    cover:SetPos(0, h * 0.6)
    cover.Paint = function()

        surface.SetDrawColor(Color(37,37,37))
        surface.DrawRect(0,0,w,h*0.4)

        surface.SetDrawColor(Color(71,133,198))
        surface.DrawOutlinedRect(0,0,w,h*0.4,2)
    end

    local button = vgui.Create("DButton", win)
    button:SetPos(0, h * 0.6)
    button:SetSize(w,h * 0.4)
    button:SetFont("gpoker_header")
    button:SetTextColor(color_white)
    button:SetText("Exchange")
    button.Paint = function(self, w, h)
        if self:IsHovered() then
            surface.SetDrawColor(Color(71,133,198))
        else
            surface.SetDrawColor(Color(37,37,37))
        end
        surface.DrawRect(0,0,w,h)

        surface.SetDrawColor(Color(71,133,198))
        surface.DrawOutlinedRect(0,0,w,h,2)
    end
    button.DoClick = function()
        net.Start("gpoker_derma_exchange", false)
            net.WriteEntity(self)
            net.WriteTable(mark)
        net.SendToServer()
        win:Remove()
    end
end



function ENT:openLeaveRequest()
    local w, h = 200, 120
    local win = vgui.Create("DFrame")
    win:SetSize(w,h)
    win:Center()
    win:SetTitle("Do you want to leave the match?")
    win:SetDraggable(false)
    win:ShowCloseButton(false)
    win.Paint = function(self, w, h)
        local outSize = 2
        local outset = 20

        surface.SetDrawColor(Color(37,37,37))
        surface.DrawRect(0, outset, w, h-outset)

        surface.SetDrawColor(Color(71,133,198))
        surface.DrawRect(0, 0, w, outset)
        surface.DrawOutlinedRect(0, outset, w, h - outset, outSize)

        surface.DrawOutlinedRect(0, outset, w/3, h - outset, outSize)
    end
    win:SetPopupStayAtBack(true)
    win:MakePopup()

    local y = vgui.Create("DButton", win)
    y:SetFont("gpoker_header")
    y:SetTextColor(color_white)
    y:SetText("Leave")
    y:SetSize(100,100)
    y:SetPos(0,20)
    y.Paint = function(self, w, h)
        if self:IsHovered() then
            surface.SetDrawColor(Color(71,133,198))
        else
            surface.SetDrawColor(Color(37,37,37))
        end
        surface.DrawRect(0,0,w,h)

        local buttonOutline = 2
        surface.SetDrawColor(Color(71,133,198))
        surface.DrawOutlinedRect(0,0,w,h,buttonOutline)
    end
    y.DoClick = function()
        win:Close()

        if !IsValid(self) then return end
        
        net.Start("gpoker_derma_leaveRequest")
            net.WriteEntity(self)
        net.SendToServer()
    end

    local n = vgui.Create("DButton", win)
    n:SetFont("gpoker_header")
    n:SetTextColor(color_white)
    n:SetText("Cancel")
    n:SetSize(100,100)
    n:SetPos(100,20)
    n.Paint = function(self, w, h)
        if self:IsHovered() then
            surface.SetDrawColor(Color(71,133,198))
        else
            surface.SetDrawColor(Color(37,37,37))
        end
        surface.DrawRect(0,0,w,h)

        local buttonOutline = 2
        surface.SetDrawColor(Color(71,133,198))
        surface.DrawOutlinedRect(0,0,w,h,buttonOutline)
    end
    n.DoClick = function()
        if self:GetTurn() == self:getPlayerKey(LocalPlayer()) then 
            if gPoker.gameType[self:GetGameType()].states[self:GetGameState()].drawing then
                self:openExchangeDerma()
            else
                self:openBettingDerma(self:GetCheck())
            end
        end
        win:Close()
    end
end