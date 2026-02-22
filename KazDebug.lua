local FONT = "Fonts\\FRIZQT__.TTF"
local MONO = "Fonts\\ARIALN.TTF"

local frame, inputBox, outputBox, inputScroll, outputScroll

local BACKDROP = {
    bgFile = "Interface\\BUTTONS\\WHITE8X8",
    edgeFile = "Interface\\BUTTONS\\WHITE8X8",
    edgeSize = 1,
}

print("|cffc8aa64KazDebug|r loaded — /kd to open")

local function BuildFrame()
    frame = CreateFrame("Frame", "KazDebugFrame", UIParent, "BackdropTemplate")
    frame:SetSize(700, 500)
    frame:SetPoint("CENTER")
    frame:SetBackdrop(BACKDROP)
    frame:SetBackdropColor(18/255, 18/255, 18/255, 0.96)
    frame:SetBackdropBorderColor(90/255, 80/255, 65/255, 1)
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:SetResizable(true)
    frame:SetResizeBounds(400, 300, 1200, 800)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()

    table.insert(UISpecialFrames, "KazDebugFrame")

    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY")
    title:SetFont(FONT, 13, "")
    title:SetPoint("TOPLEFT", 10, -8)
    title:SetText("KazDebug")
    title:SetTextColor(200/255, 170/255, 100/255)

    -- Close button
    local closeBtn = CreateFrame("Button", nil, frame)
    closeBtn:SetSize(20, 20)
    closeBtn:SetPoint("TOPRIGHT", -4, -4)
    local closeLbl = closeBtn:CreateFontString(nil, "OVERLAY")
    closeLbl:SetFont(FONT, 14, "")
    closeLbl:SetPoint("CENTER")
    closeLbl:SetText("x")
    closeLbl:SetTextColor(140/255, 130/255, 115/255)
    closeBtn:SetScript("OnEnter", function() closeLbl:SetTextColor(220/255, 100/255, 100/255) end)
    closeBtn:SetScript("OnLeave", function() closeLbl:SetTextColor(140/255, 130/255, 115/255) end)
    closeBtn:SetScript("OnClick", function() frame:Hide() end)

    -- Clear button
    local clearBtn = CreateFrame("Button", nil, frame, "BackdropTemplate")
    clearBtn:SetSize(50, 20)
    clearBtn:SetPoint("TOPRIGHT", closeBtn, "TOPLEFT", -4, 0)
    clearBtn:SetBackdrop(BACKDROP)
    clearBtn:SetBackdropColor(30/255, 30/255, 30/255, 0.8)
    clearBtn:SetBackdropBorderColor(70/255, 65/255, 55/255)
    local clearLbl = clearBtn:CreateFontString(nil, "OVERLAY")
    clearLbl:SetFont(FONT, 10, "")
    clearLbl:SetPoint("CENTER")
    clearLbl:SetText("Clear")
    clearLbl:SetTextColor(150/255, 140/255, 120/255)
    clearBtn:SetScript("OnEnter", function()
        clearLbl:SetTextColor(220/255, 200/255, 160/255)
        clearBtn:SetBackdropBorderColor(200/255, 170/255, 100/255)
    end)
    clearBtn:SetScript("OnLeave", function()
        clearLbl:SetTextColor(150/255, 140/255, 120/255)
        clearBtn:SetBackdropBorderColor(70/255, 65/255, 55/255)
    end)
    clearBtn:SetScript("OnClick", function()
        inputBox:SetText("")
        outputBox:SetText("")
        inputBox:SetFocus()
    end)

    -- Input label
    local inputLabel = frame:CreateFontString(nil, "OVERLAY")
    inputLabel:SetFont(FONT, 10, "")
    inputLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -30)
    inputLabel:SetText("Input (Lua)")
    inputLabel:SetTextColor(130/255, 125/255, 115/255)

    -- Run button
    local runBtn = CreateFrame("Button", nil, frame, "BackdropTemplate")
    runBtn:SetSize(50, 20)
    runBtn:SetPoint("LEFT", inputLabel, "RIGHT", 8, 0)
    runBtn:SetBackdrop(BACKDROP)
    runBtn:SetBackdropColor(30/255, 30/255, 30/255, 0.8)
    runBtn:SetBackdropBorderColor(70/255, 65/255, 55/255)
    local runLbl = runBtn:CreateFontString(nil, "OVERLAY")
    runLbl:SetFont(FONT, 10, "")
    runLbl:SetPoint("CENTER")
    runLbl:SetText("Run")
    runLbl:SetTextColor(0.3, 0.9, 0.3)
    runBtn:SetScript("OnEnter", function()
        runLbl:SetTextColor(0.5, 1, 0.5)
        runBtn:SetBackdropBorderColor(0.3, 0.9, 0.3)
    end)
    runBtn:SetScript("OnLeave", function()
        runLbl:SetTextColor(0.3, 0.9, 0.3)
        runBtn:SetBackdropBorderColor(70/255, 65/255, 55/255)
    end)

    -- Ctrl+Enter hint
    local hintText = frame:CreateFontString(nil, "OVERLAY")
    hintText:SetFont(FONT, 9, "")
    hintText:SetPoint("LEFT", runBtn, "RIGHT", 8, 0)
    hintText:SetText("Ctrl+Enter to run")
    hintText:SetTextColor(90/255, 85/255, 75/255)

    -- Input scroll frame (top half)
    inputScroll = CreateFrame("ScrollFrame", "KazDebugInputScroll", frame, "UIPanelScrollFrameTemplate")
    inputScroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -48)
    inputScroll:SetPoint("RIGHT", frame, "RIGHT", -28, 0)
    inputScroll:SetHeight(1) -- set dynamically

    inputBox = CreateFrame("EditBox", "KazDebugInputBox", inputScroll)
    inputBox:SetMultiLine(true)
    inputBox:SetAutoFocus(false)
    inputBox:SetFont(MONO, 12, "")
    inputBox:SetTextColor(220/255, 215/255, 200/255)
    inputBox:SetWidth(inputScroll:GetWidth())
    inputBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    inputScroll:SetScrollChild(inputBox)

    -- Click anywhere in scroll area → focus the EditBox (AMR pattern)
    inputScroll:SetScript("OnMouseUp", function(self)
        inputBox:SetFocus()
        inputBox:SetCursorPosition(inputBox:GetNumLetters())
    end)

    -- Input background
    local inputBg = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    inputBg:SetPoint("TOPLEFT", inputScroll, "TOPLEFT", -4, 4)
    inputBg:SetPoint("BOTTOMRIGHT", inputScroll, "BOTTOMRIGHT", 20, -4)
    inputBg:SetBackdrop(BACKDROP)
    inputBg:SetBackdropColor(10/255, 10/255, 10/255, 0.6)
    inputBg:SetBackdropBorderColor(70/255, 65/255, 55/255)
    inputBg:SetFrameLevel(frame:GetFrameLevel() + 1)
    inputScroll:SetFrameLevel(inputBg:GetFrameLevel() + 1)

    -- Output label
    local outputLabel = frame:CreateFontString(nil, "OVERLAY")
    outputLabel:SetFont(FONT, 10, "")
    outputLabel:SetText("Output")
    outputLabel:SetTextColor(130/255, 125/255, 115/255)

    -- Copy hint next to output label
    local copyHint = frame:CreateFontString(nil, "OVERLAY")
    copyHint:SetFont(FONT, 9, "")
    copyHint:SetText("Click to select all, Ctrl+C to copy")
    copyHint:SetTextColor(90/255, 85/255, 75/255)

    -- Output scroll frame (bottom half)
    outputScroll = CreateFrame("ScrollFrame", "KazDebugOutputScroll", frame, "UIPanelScrollFrameTemplate")
    outputScroll:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 8, 8)
    outputScroll:SetPoint("RIGHT", frame, "RIGHT", -28, 0)
    outputScroll:SetHeight(1) -- set dynamically

    outputBox = CreateFrame("EditBox", "KazDebugOutputBox", outputScroll)
    outputBox:SetMultiLine(true)
    outputBox:SetAutoFocus(false)
    outputBox:SetFont(MONO, 12, "")
    outputBox:SetTextColor(180/255, 180/255, 180/255)
    outputBox:SetWidth(outputScroll:GetWidth())
    outputBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    outputScroll:SetScrollChild(outputBox)

    -- Output: select all on focus for easy Ctrl+C
    outputBox:SetScript("OnEditFocusGained", function(self)
        self:HighlightText()
    end)

    -- Click anywhere in output scroll area → focus + select all
    outputScroll:SetScript("OnMouseUp", function(self)
        outputBox:SetFocus()
        outputBox:HighlightText()
    end)

    -- Output background
    local outputBg = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    outputBg:SetPoint("TOPLEFT", outputScroll, "TOPLEFT", -4, 4)
    outputBg:SetPoint("BOTTOMRIGHT", outputScroll, "BOTTOMRIGHT", 20, -4)
    outputBg:SetBackdrop(BACKDROP)
    outputBg:SetBackdropColor(10/255, 10/255, 10/255, 0.6)
    outputBg:SetBackdropBorderColor(70/255, 65/255, 55/255)
    outputBg:SetFrameLevel(frame:GetFrameLevel() + 1)
    outputScroll:SetFrameLevel(outputBg:GetFrameLevel() + 1)

    -- Dynamic layout: split frame 50/50 with labels between
    frame:SetScript("OnSizeChanged", function(self, w, h)
        local usable = h - 48 - 8 - 18  -- top chrome + bottom pad + output label
        local half = math.floor(usable / 2) - 4
        inputScroll:SetHeight(half)
        outputScroll:SetHeight(half)

        outputLabel:ClearAllPoints()
        outputLabel:SetPoint("TOPLEFT", inputBg, "BOTTOMLEFT", 4, -4)

        copyHint:ClearAllPoints()
        copyHint:SetPoint("LEFT", outputLabel, "RIGHT", 8, 0)

        outputScroll:ClearAllPoints()
        outputScroll:SetPoint("TOPLEFT", outputLabel, "BOTTOMLEFT", -4, -2)
        outputScroll:SetPoint("RIGHT", frame, "RIGHT", -28, 0)
        outputScroll:SetHeight(half)

        inputBox:SetWidth(math.max(100, w - 48))
        outputBox:SetWidth(math.max(100, w - 48))
    end)

    -- Resize grip
    local grip = CreateFrame("Button", nil, frame)
    grip:SetSize(16, 16)
    grip:SetPoint("BOTTOMRIGHT", -2, 2)
    grip:SetFrameLevel(frame:GetFrameLevel() + 20)
    local gripTex = grip:CreateTexture(nil, "OVERLAY")
    gripTex:SetSize(16, 16)
    gripTex:SetPoint("CENTER")
    gripTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    gripTex:SetVertexColor(120/255, 110/255, 90/255)
    grip:SetScript("OnEnter", function() gripTex:SetVertexColor(200/255, 180/255, 140/255) end)
    grip:SetScript("OnLeave", function() gripTex:SetVertexColor(120/255, 110/255, 90/255) end)
    grip:SetScript("OnMouseDown", function() frame:StartSizing("BOTTOMRIGHT") end)
    grip:SetScript("OnMouseUp", function() frame:StopMovingOrSizing() end)

    -- Run logic
    local function RunCode()
        local code = inputBox:GetText()
        if not code or strtrim(code) == "" then return end

        -- Capture print output
        local output = {}
        local oldPrint = print
        print = function(...)
            local parts = {}
            for i = 1, select("#", ...) do
                parts[i] = tostring(select(i, ...))
            end
            table.insert(output, table.concat(parts, "\t"))
        end

        -- Try as expression first (return value), then as statements
        local fn, err = loadstring("return " .. code)
        if not fn then
            fn, err = loadstring(code)
        end

        if not fn then
            print = oldPrint
            outputBox:SetText("|cffff6666Error:|r " .. tostring(err))
            return
        end

        local ok, result = pcall(fn)
        print = oldPrint

        local lines = {}

        -- Add captured print output
        for _, line in ipairs(output) do
            table.insert(lines, line)
        end

        -- Add return value if any
        if ok then
            if result ~= nil then
                table.insert(lines, tostring(result))
            end
            if #lines == 0 then
                table.insert(lines, "(no output)")
            end
        else
            table.insert(lines, "|cffff6666Error:|r " .. tostring(result))
        end

        outputBox:SetText(table.concat(lines, "\n"))
    end

    runBtn:SetScript("OnClick", RunCode)

    -- Ctrl+Enter runs code from input box
    inputBox:SetScript("OnKeyDown", function(self, key)
        if key == "ENTER" and IsControlKeyDown() then
            RunCode()
        end
    end)

    -- Force initial layout
    C_Timer.After(0, function()
        if frame:IsShown() then
            local w, h = frame:GetSize()
            frame:GetScript("OnSizeChanged")(frame, w, h)
        end
    end)
end

-- Slash command
SLASH_KAZDEBUG1 = "/kd"
SLASH_KAZDEBUG2 = "/kazdebug"
SlashCmdList["KAZDEBUG"] = function()
    if not frame then
        BuildFrame()
    end
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
        -- Trigger layout
        local w, h = frame:GetSize()
        frame:GetScript("OnSizeChanged")(frame, w, h)
        inputBox:SetFocus()
    end
end
