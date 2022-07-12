surface.CreateFont("gpoker_header", {
    font = "Arial",
	extended = false,
	size = 24,
	weight = 1000,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = true,
	additive = false,
	outline = false,
})

surface.CreateFont("gpoker_text", {
    font = "Arial",
	extended = false,
	size = 16,
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = true,
	additive = false,
	outline = false,
})

surface.CreateFont("gpoker_bold", {
    font = "Arial",
	extended = false,
	size = 16,
	weight = 800,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = true,
	additive = false,
	outline = false,
})



net.Receive("gpoker_derma_createGame", function()
    local winW, winH = 384, 216
    local win = vgui.Create("DFrame")
    win:SetSize(winW, winH)
    win:Center()
    win:SetTitle("Select Game Settings")
    win:SetDraggable(false)
    win:MakePopup()


    //The left twix//


    local left = vgui.Create("DPanel", win)
    left:SetSize(win:GetWide() * 0.25 - 15)
    left:Dock(LEFT)

    local optionsMenu = vgui.Create("DCategoryList", left)
    optionsMenu:Dock(FILL)
    optionsMenu:DockMargin(2, 2, 2, 2)

    local options = optionsMenu:Add("Settings")

    local gameOption = options:Add("Game")
    local betOption = options:Add("Betting")
    local botOption = options:Add("Bots")

    local createButton = vgui.Create("DButton", left)
    createButton:Dock(BOTTOM)
    createButton:DockMargin(2, 2, 2, 2)
    createButton:SetText("Create")
    createButton:SetTall(createButton:GetWide())


    //The right twix//


    local right = vgui.Create("DPanel", win)
    right:SetSize(win:GetWide() - left:GetWide() - 15)
    right:Dock(RIGHT)

    //Game

    local gamePanel = vgui.Create("DPanel", right)
    gamePanel:Dock(FILL)

    local gameSelectText = vgui.Create("DLabel", gamePanel)
    gameSelectText:SetColor(color_black)
    gameSelectText:SetText("Game Type")
    gameSelectText:Dock(TOP)
    gameSelectText:DockMargin(10,0,10,0)

    local gameSelect = vgui.Create("DComboBox", gamePanel)
    gameSelect:Dock(TOP)
    gameSelect:DockMargin(10,0,10,0)
    for i = 0, #gPoker.gameType do
        gameSelect:AddChoice(gPoker.gameType[i].name, i, i == 0)
    end

    local maxPlyText = vgui.Create("DLabel", gamePanel)
    maxPlyText:Dock(TOP)
    maxPlyText:DockMargin(10,10,10,0)
    maxPlyText:SetTextColor(color_black)
    maxPlyText:SetText("Maximum amount of players")

    local maxPly = vgui.Create("DNumberWang", gamePanel)
    maxPly:Dock(TOP)
    maxPly:DockMargin(10,0,10,0)
    maxPly:SetMinMax(2, 8)
    maxPly:SetValue(4)

    //Betting

    local betPanel = vgui.Create("DPanel", right)
    betPanel:Dock(FILL)
    betPanel:Hide()

    local betText = vgui.Create("DLabel", betPanel)
    betText:Dock(TOP)
    betText:DockMargin(10,0,10,0)
    betText:SetTextColor(color_black)
    betText:SetText("Bet Type")

    local betSelect = vgui.Create("DComboBox", betPanel)
    betSelect:Dock(TOP)
    betSelect:DockMargin(10,0,10,0)
    for i = 0, #gPoker.betType do
        betSelect:AddChoice(gPoker.betType[i].name, i, i == 0)
    end

    local entryFee = vgui.Create("DNumSlider", betPanel)
    entryFee:Dock(TOP)
    entryFee:DockMargin(10,10,10,0)
    entryFee:SetText("Entry Fee")
    entryFee:SetDark(true)
    entryFee:SetDecimals(0)

    local startValue = vgui.Create("DNumSlider", betPanel)
    startValue:Dock(TOP)
    startValue:DockMargin(10,10,10,0)
    startValue:SetText("Starting Value")
    startValue:SetDark(true)
    startValue:SetDecimals(0)
    startValue:SetMinMax(gPoker.betType[betSelect:GetOptionData(betSelect:GetSelectedID()) or 0].setMinMax.min, gPoker.betType[betSelect:GetOptionData(betSelect:GetSelectedID()) or 0].setMinMax.max)
    startValue:SetValue(startValue:GetMax()/10)

    if !gPoker.betType[betSelect:GetOptionData(betSelect:GetSelectedID())].canSet then startValue:Hide() end

    entryFee:SetMinMax(0, gPoker.betType[betSelect:GetOptionData(betSelect:GetSelectedID())].feeMinMax.max(startValue))
    if entryFee:GetMax() < 0 then entryFee:SetMax(0) end
    entryFee:SetValue(entryFee:GetMax() / 10)

    startValue.OnValueChanged = function()
        entryFee:SetMax(startValue:GetValue())
        if entryFee:GetValue() > startValue:GetValue() then entryFee:SetValue(startValue:GetValue()) end
    end

    betSelect.OnSelect = function()
        startValue:SetMinMax(gPoker.betType[betSelect:GetOptionData(betSelect:GetSelectedID())].setMinMax.min, gPoker.betType[betSelect:GetOptionData(betSelect:GetSelectedID())].setMinMax.max)

        if gPoker.betType[betSelect:GetOptionData(betSelect:GetSelectedID())].canSet then 
            startValue:Show() 
        else startValue:Hide() end

        entryFee:SetMinMax(gPoker.betType[betSelect:GetOptionData(betSelect:GetSelectedID())].feeMinMax.min, gPoker.betType[betSelect:GetOptionData(betSelect:GetSelectedID())].feeMinMax.max(startValue))
        if entryFee:GetValue() > entryFee:GetMax() then entryFee:SetValue(entryFee:GetMax()) end
    end

    //Bots

    local botPanel = vgui.Create("DPanel", right)
    botPanel:Dock(FILL)
    botPanel:Hide()

    local placeholder = vgui.Create("DCheckBoxLabel", botPanel)
    placeholder:Dock(TOP)
    placeholder:DockMargin(10,2,10,0)
    placeholder:SetText("Placeholders")
    placeholder:SetTextColor(color_black)
    placeholder:SetTooltip("When table is full, any player trying to join will take random bot's place")

    local botsList = vgui.Create("DListView", botPanel)
    botsList:Dock(TOP)
    botsList:DockMargin(10,10,10,0)
    botsList:SetTall(125)
    botsList:AddColumn("Name", 1)
    botsList:AddColumn("Model", 2)
    botsList:AddColumn("Color", 3)
    
    local botAdd = vgui.Create("DButton", botPanel)
    botAdd:Dock(LEFT)
    botAdd:DockMargin(10,10,2,2)
    botAdd:SetText("Add")

    local botRemove = vgui.Create("DButton", botPanel)
    botRemove:Dock(LEFT)
    botRemove:DockMargin(2,10,2,2)
    botRemove:SetText("Remove")
    botRemove:SetEnabled(false)

    local botEdit = vgui.Create("DButton", botPanel)
    botEdit:Dock(LEFT)
    botEdit:DockMargin(2,10,2,2)
    botEdit:SetText("Edit")
    botEdit:SetEnabled(false)

    local bots = {}

    botAdd.DoClick = function()
        if #botsList:GetLines() >= math.Clamp(maxPly:GetValue(), maxPly:GetMin(), maxPly:GetMax()) then return end

        local index = #bots + 1

        bots[index] = {
            name = table.Random(gPoker.bots.names),
            mdl = table.Random(player_manager.AllValidModels()),
            clr = Color(math.random(0,255), math.random(0,255), math.random(0,255))
        }

        local idk = botsList:AddLine(bots[index].name, bots[index].mdl, bots[index].clr)
        idk.OnSelect = function()
            botRemove:SetEnabled(true)
            botEdit:SetEnabled(true)
        end
    end

    maxPly.OnValueChanged = function()
        if #bots > maxPly:GetValue() then
            for i = #bots, 1, -1 do
                if i == maxPly:GetValue() then break end

                table.remove(bots, i)
                botsList:RemoveLine(i)
            end
        end
    end

    botRemove.DoClick = function()
        local selected = botsList:GetSelected()

        for k,v in pairs(selected) do
            botsList:RemoveLine(v:GetID())
            table.remove(bots, v:GetID())
        end

        
        botRemove:SetEnabled(false)
        botEdit:SetEnabled(false)
    end

    botEdit.DoClick = function()
        local selected, selectedPanel = botsList:GetSelectedLine()

        local editWin = vgui.Create("DFrame")
        editWin:SetSize(winW * 1.3, winH * 1.75)
        editWin:Center()
        editWin:SetTitle("Edit Bot")
        editWin:MakePopup()

        local left = vgui.Create("DPanel", editWin)
        left:Dock(LEFT)
        left:SetWide(editWin:GetWide()/3 * 2 - 15)

        local labelName = vgui.Create("DLabel", left)
        labelName:Dock(TOP)
        labelName:DockMargin(10,2,10,0)
        labelName:SetText("Name")
        labelName:SetTextColor(color_black)

        local editName = vgui.Create("DTextEntry", left)
        editName:Dock(TOP)
        editName:DockMargin(10,0,10,0)
        editName:SetText(bots[selected].name)

        local clrLabel = vgui.Create("DLabel", left)
        clrLabel:Dock(TOP)
        clrLabel:DockMargin(10,10,10,0)
        clrLabel:SetText("Color")
        clrLabel:SetTextColor(color_black)

        local editClr = vgui.Create("DColorMixer", left)
        editClr:Dock(TOP)
        editClr:DockMargin(10,0,10,0)
        editClr:SetColor(bots[selected].clr)

        local finish = vgui.Create("DButton", left)
        finish:Dock(BOTTOM)
        finish:DockMargin(100,10,100,2)
        finish:SetText("Edit")



        local right = vgui.Create("DPanel", editWin)
        right:Dock(RIGHT)
        right:SetWide(editWin:GetWide() - left:GetWide() - 15)

        local goddamnmodel = bots[selected].mdl

        local preview = vgui.Create("DModelPanel", right)
        preview:Dock(TOP)
        preview:SetTall(preview:GetWide() * 2)
        preview.updateSelf = function()
            preview:SetModel(goddamnmodel)

            local bone = preview.Entity:LookupBone("ValveBiped.Bip01_Head1")
            if bone then
                local eyepos = preview.Entity:GetBonePosition(bone)
                preview:SetLookAt(eyepos)
                preview:SetCamPos(eyepos - Vector(-15, 0, 0))
                preview.Entity:SetEyeTarget(eyepos - Vector(-15, 0, 0))
            end
            function preview.Entity:GetPlayerColor() return editClr:GetVector() end
        end
        preview.LayoutEntity = function() return end
        preview.updateSelf()

        local scroll = vgui.Create("DScrollPanel", right)
        scroll:Dock(FILL)

        local theList = vgui.Create("DIconLayout", scroll)
        theList:Dock(FILL)
        theList:DockMargin(2,0,0,0)

        for name, model in SortedPairs(player_manager.AllValidModels()) do
            local icon = vgui.Create("SpawnIcon", theList)
			icon:SetModel(model)
			icon:SetSize(50, 50)
			icon:SetTooltip(name)
            icon.mdl = model
            icon.DoClick = function()
                goddamnmodel = icon.mdl
                preview.updateSelf()
            end
        end

        finish.DoClick = function()
            bots[selected].name = editName:GetValue()
            bots[selected].mdl = goddamnmodel
            bots[selected].clr = editClr:GetColor()

            selectedPanel:SetColumnText(1, bots[selected].name)
            selectedPanel:SetColumnText(2, bots[selected].mdl)
            selectedPanel:SetColumnText(3, Color(bots[selected].clr.r, bots[selected].clr.g, bots[selected].clr.b))

            editWin:Remove()
        end
    end


    //Option clicky clicky//


    gameOption.DoClick = function()
        gamePanel:Show()
        betPanel:Hide()
        botPanel:Hide()
    end

    betOption.DoClick = function()
        gamePanel:Hide()
        betPanel:Show()
        botPanel:Hide()
    end

    botOption.DoClick = function()
        gamePanel:Hide()
        betPanel:Hide()
        botPanel:Show()
    end



    createButton.DoClick = function()
        local options = {
            game = {
                type    = gameSelect:GetOptionData(gameSelect:GetSelectedID()) or 0,
                maxPly  = math.Clamp(maxPly:GetValue(), 2, 8) 
            },
            bet = {
                type = betSelect:GetOptionData(betSelect:GetSelectedID()) or 0,
                entry = math.floor(entryFee:GetValue()),
                start = math.floor(startValue:GetValue()) or 0
            },
            bot = {
                placehold = placeholder:GetChecked(),
                list = bots
            }
        }

        net.Start("gpoker_derma_createGame")
            net.WriteTable(options)
        net.SendToServer()

        win:Remove()
    end
end)



net.Receive("gpoker_updatePlayers", function()
    local ent = net.ReadEntity()

    if !IsValid(ent) then return end

    ent.players = net.ReadTable()
end)



net.Receive("gpoker_sendDeck", function()
    local ent = net.ReadEntity()
    local community = net.ReadBool()
    local deck = net.ReadTable()

    if community then
        ent.communityDeck = deck
    else
        ent.localDeck = deck
    end
end)



net.Receive("gpoker_payEntry", function()
    local ent = net.ReadEntity()

    if !IsValid(ent) then return else ent:openEntryFeeDerma() end
end)



net.Receive("gpoker_derma_bettingActions", function()
    local ent = net.ReadEntity()

    if !IsValid(ent) then return end
    local check = net.ReadBool()
    local bet = net.ReadFloat()

    ent:openBettingDerma(check, bet)
end)



net.Receive("gpoker_derma_exchange", function()
    local ent = net.ReadEntity()

    if !IsValid(ent) then return end
    ent:openExchangeDerma()
end)



hook.Add("KeyPress", "gpoker_leaveRequest", function(ply, key)
    if key == IN_USE and ply:InVehicle() and ply:GetVehicle():GetVehicleClass() == "Chair_Office2" and IsValid(ply:GetVehicle():GetParent()) and ply:GetVehicle():GetParent():GetClass() == "ent_poker_game" then
        if LocalPlayer() == ply then ply:GetVehicle():GetParent():openLeaveRequest() end
    end
end)