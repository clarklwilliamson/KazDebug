local KazGUI = LibStub("KazGUILib-1.0")
local C = KazGUI.Colors
local K = KazGUI.Constants

local MONO = "Fonts\\ARIALN.TTF"  -- narrow font for code input/output

local frame, inputBox, outputBox, inputScroll, outputScroll

-- Restyle a UIPanelScrollFrameTemplate scrollbar to match KazGUI style
local function StyleScrollBar(scrollFrame, scrollName)
	local scrollBar = scrollFrame.ScrollBar or _G[scrollName .. "ScrollBar"]
	if not scrollBar then return end

	scrollBar:SetWidth(K.SCROLLBAR_WIDTH)

	-- Hide arrows
	local upBtn = scrollBar.ScrollUpButton or _G[scrollName .. "ScrollBarScrollUpButton"]
	local downBtn = scrollBar.ScrollDownButton or _G[scrollName .. "ScrollBarScrollDownButton"]
	if upBtn then upBtn:SetSize(1, 1); upBtn:SetAlpha(0); upBtn:EnableMouse(false) end
	if downBtn then downBtn:SetSize(1, 1); downBtn:SetAlpha(0); downBtn:EnableMouse(false) end

	-- Track
	local track = scrollBar:CreateTexture(nil, "BACKGROUND")
	track:SetAllPoints()
	track:SetColorTexture(unpack(C.scrollTrack))

	-- Thumb
	local thumb = scrollBar.ThumbTexture or scrollBar:GetThumbTexture()
	if thumb then
		thumb:SetColorTexture(unpack(C.scrollThumb))
		thumb:SetSize(K.SCROLLBAR_WIDTH, 40)
		scrollBar:HookScript("OnEnter", function()
			thumb:SetColorTexture(unpack(C.scrollThumbHover))
		end)
		scrollBar:HookScript("OnLeave", function()
			thumb:SetColorTexture(unpack(C.scrollThumb))
		end)
	end
end

print("|cffc8aa64KazDebug|r loaded — /kd to open")

local function BuildFrame()
	frame = KazGUI:CreateFrame("KazDebugFrame", 700, 500, {
		title = "KazDebug",
		resizable = true,
		minSize = {400, 300},
	})
	frame:SetResizeBounds(400, 300, 1200, 800)

	-- Clear button (in title bar, left of close)
	local clearBtn = CreateFrame("Button", nil, frame.titleBar, "BackdropTemplate")
	clearBtn:SetSize(50, 20)
	clearBtn:SetPoint("RIGHT", frame.titleBar.closeBtn, "LEFT", -4, 0)
	KazGUI:ApplyBackdrop(clearBtn, "headerBg", "border")
	local clearLbl = KazGUI:CreateText(clearBtn, 10, "ctrlText")
	clearLbl:SetPoint("CENTER")
	clearLbl:SetText("Clear")
	clearBtn:SetScript("OnEnter", function()
		clearLbl:SetTextColor(unpack(C.ctrlHover))
		clearBtn:SetBackdropBorderColor(unpack(C.accentBronze))
	end)
	clearBtn:SetScript("OnLeave", function()
		clearLbl:SetTextColor(unpack(C.ctrlText))
		clearBtn:SetBackdropBorderColor(unpack(C.border))
	end)
	clearBtn:SetScript("OnClick", function()
		inputBox:SetText("")
		outputBox:SetText("")
		inputBox:SetFocus()
	end)

	-- Input label
	local inputLabel = KazGUI:CreateText(frame, K.FONT_SIZE_SMALL, "textHeader")
	inputLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -(K.TITLE_HEIGHT + 4))
	inputLabel:SetText("Input (Lua)")

	-- Run button
	local runBtn = CreateFrame("Button", nil, frame, "BackdropTemplate")
	runBtn:SetSize(50, 20)
	runBtn:SetPoint("LEFT", inputLabel, "RIGHT", 8, 0)
	KazGUI:ApplyBackdrop(runBtn, "headerBg", "border")
	local runLbl = runBtn:CreateFontString(nil, "OVERLAY")
	runLbl:SetFont(K.FONT, 10, "")
	runLbl:SetPoint("CENTER")
	runLbl:SetText("Run")
	runLbl:SetTextColor(0.3, 0.9, 0.3)
	runBtn:SetScript("OnEnter", function()
		runLbl:SetTextColor(0.5, 1, 0.5)
		runBtn:SetBackdropBorderColor(0.3, 0.9, 0.3)
	end)
	runBtn:SetScript("OnLeave", function()
		runLbl:SetTextColor(0.3, 0.9, 0.3)
		runBtn:SetBackdropBorderColor(unpack(C.border))
	end)

	-- Ctrl+Enter hint
	local hintText = frame:CreateFontString(nil, "OVERLAY")
	hintText:SetFont(K.FONT, 9, "")
	hintText:SetPoint("LEFT", runBtn, "RIGHT", 8, 0)
	hintText:SetText("Ctrl+Enter to run")
	hintText:SetTextColor(90/255, 85/255, 75/255)

	-- Input scroll frame (top half)
	inputScroll = CreateFrame("ScrollFrame", "KazDebugInputScroll", frame, "UIPanelScrollFrameTemplate")
	inputScroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -(K.TITLE_HEIGHT + 22))
	inputScroll:SetPoint("RIGHT", frame, "RIGHT", -28, 0)
	inputScroll:SetHeight(1) -- set dynamically

	inputBox = CreateFrame("EditBox", "KazDebugInputBox", inputScroll)
	inputBox:SetMultiLine(true)
	inputBox:SetAutoFocus(false)
	inputBox:SetFont(MONO, 12, "")
	inputBox:SetTextColor(unpack(C.textNormal))
	inputBox:SetWidth(inputScroll:GetWidth())
	inputBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	inputScroll:SetScrollChild(inputBox)
	StyleScrollBar(inputScroll, "KazDebugInputScroll")

	-- Click anywhere in scroll area → focus the EditBox
	inputScroll:SetScript("OnMouseUp", function()
		inputBox:SetFocus()
		inputBox:SetCursorPosition(inputBox:GetNumLetters())
	end)

	-- Input background
	local inputBg = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	inputBg:SetPoint("TOPLEFT", inputScroll, "TOPLEFT", -4, 4)
	inputBg:SetPoint("BOTTOMRIGHT", inputScroll, "BOTTOMRIGHT", 20, -4)
	KazGUI:ApplyBackdrop(inputBg, "bg", "border")
	inputBg:SetBackdropColor(10/255, 10/255, 10/255, 0.6)
	inputBg:SetFrameLevel(frame:GetFrameLevel() + 1)
	inputScroll:SetFrameLevel(inputBg:GetFrameLevel() + 1)

	-- Output label
	local outputLabel = KazGUI:CreateText(frame, K.FONT_SIZE_SMALL, "textHeader")
	outputLabel:SetText("Output")

	-- Copy hint next to output label
	local copyHint = frame:CreateFontString(nil, "OVERLAY")
	copyHint:SetFont(K.FONT, 9, "")
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
	StyleScrollBar(outputScroll, "KazDebugOutputScroll")

	-- Output: select all on focus for easy Ctrl+C
	outputBox:SetScript("OnEditFocusGained", function(self)
		self:HighlightText()
	end)

	-- Click anywhere in output scroll area → focus + select all
	outputScroll:SetScript("OnMouseUp", function()
		outputBox:SetFocus()
		outputBox:HighlightText()
	end)

	-- Output background
	local outputBg = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	outputBg:SetPoint("TOPLEFT", outputScroll, "TOPLEFT", -4, 4)
	outputBg:SetPoint("BOTTOMRIGHT", outputScroll, "BOTTOMRIGHT", 20, -4)
	KazGUI:ApplyBackdrop(outputBg, "bg", "border")
	outputBg:SetBackdropColor(10/255, 10/255, 10/255, 0.6)
	outputBg:SetFrameLevel(frame:GetFrameLevel() + 1)
	outputScroll:SetFrameLevel(outputBg:GetFrameLevel() + 1)

	-- Dynamic layout: split frame 50/50 with labels between
	frame:SetScript("OnSizeChanged", function(self, w, h)
		local usable = h - K.TITLE_HEIGHT - 22 - 8 - 18  -- top chrome + bottom pad + output label
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
SLASH_KAZDEBUG3 = "/kdb"
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
KAZ_COMMANDS["debug"] = { handler = SlashCmdList["KAZDEBUG"], alias = "/kd", desc = "Lua console" }
