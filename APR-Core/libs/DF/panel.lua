
local detailsFramework = _G ["DetailsFramework"]
if (not detailsFramework or not DetailsFrameworkCanLoad) then
	return
end

local _
--lua locals
local rawset = rawset --lua local
local rawget = rawget --lua local
local setmetatable = setmetatable --lua local
local unpack = table.unpack or unpack --lua local
local type = type --lua local
local floor = math.floor --lua local
local loadstring = loadstring --lua local
local CreateFrame = CreateFrame

local IS_WOW_PROJECT_MAINLINE = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
local IS_WOW_PROJECT_NOT_MAINLINE = WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE
local IS_WOW_PROJECT_CLASSIC_ERA = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC

local CastInfo = detailsFramework.CastInfo

local PixelUtil = PixelUtil or DFPixelUtil

local UnitGroupRolesAssigned = detailsFramework.UnitGroupRolesAssigned

local cleanfunction = function() end
local APIFrameFunctions

do
	local metaPrototype = {
		WidgetType = "panel",
		dversion = detailsFramework.dversion,
	}

	--check if there's a metaPrototype already existing
	if (_G[detailsFramework.GlobalWidgetControlNames["panel"]]) then
		--get the already existing metaPrototype
		local oldMetaPrototype = _G[detailsFramework.GlobalWidgetControlNames ["panel"]]
		--check if is older
		if ( (not oldMetaPrototype.dversion) or (oldMetaPrototype.dversion < detailsFramework.dversion) ) then
			--the version is older them the currently loading one
			--copy the new values into the old metatable
			for funcName, _ in pairs(metaPrototype) do
				oldMetaPrototype[funcName] = metaPrototype[funcName]
			end
		end
	else
		--first time loading the framework
		_G[detailsFramework.GlobalWidgetControlNames["panel"]] = metaPrototype
	end
end

local PanelMetaFunctions = _G[detailsFramework.GlobalWidgetControlNames["panel"]]
detailsFramework:Mixin(PanelMetaFunctions, detailsFramework.ScriptHookMixin)

--default options for the frame layout
local default_framelayout_options = {
	amount_per_line = 4,
	start_x = 2,
	start_y = -2,
	is_vertical = false,
	grow_right = true, --on vertical (if not grow next line left)
	grow_down = true, --on horizontal (if not grow next line up)
	anchor_to_child = false, --if true set the point to the previous frame instead of coordinate
	anchor_point = "topleft",
	anchor_relative = "topleft",
	offset_x = 100,
	offset_y = 20,
	width = 0, --if bigger than 0, it will set the value
	height = 0,
	break_if_hidden = true, --stop if encounters a hidden frame
}

--mixin for frame layout
detailsFramework.LayoutFrame = {
	AnchorTo = function(self, anchor, point, x, y)
		if (point == "top") then
			self:ClearAllPoints()
			self:SetPoint("bottom", anchor, "top", x or 0, y or 0)

		elseif (point == "bottom") then
			self:ClearAllPoints()
			self:SetPoint("top", anchor, "bottom", x or 0, y or 0)

		elseif (point == "left") then
			self:ClearAllPoints()
			self:SetPoint("right", anchor, "left", x or 0, y or 0)

		elseif (point == "right") then
			self:ClearAllPoints()
			self:SetPoint("left", anchor, "right", x or 0, y or 0)
		end
	end,

	ArrangeFrames = function(self, frameList, options)
		if (not frameList) then
			frameList = {self:GetChildren()}
		end

		options = options or {}
		detailsFramework.table.deploy(options, default_framelayout_options)

		local breakLine = options.amount_per_line + 1
		local currentX, currentY = options.start_x, options.start_y
		local offsetX, offsetY = options.offset_x, options.offset_y
		local anchorPoint = options.anchor_point
		local anchorAt = options.anchor_relative
		local latestFrame = self
		local firstRowFrame = frameList[1]

		if (options.is_vertical) then
			for i = 1, #frameList do
				local thisFrame =  frameList[i]
				if (options.break_if_hidden and not thisFrame:IsShown()) then
					break
				end
				thisFrame:ClearAllPoints()

				if (options.anchor_to_child) then
					if (i == breakLine) then
						if (options.grow_right) then
							thisFrame:SetPoint("topleft", firstRowFrame, "topright", offsetX, 0)
						else
							thisFrame:SetPoint("topright", firstRowFrame, "topleft", -offsetX, 0)
						end
						firstRowFrame = thisFrame
						latestFrame = thisFrame
						breakLine = breakLine + options.amount_per_line
					else
						thisFrame:SetPoint(anchorPoint, latestFrame, i == 1 and "topleft" or anchorAt, offsetX, i == 1 and 0 or offsetY)
						latestFrame = thisFrame
					end
				else
					if (i == breakLine) then
						if (options.grow_right) then
							currentX = currentX + offsetX
						else
							currentX = currentX - offsetX
						end
						currentY = options.start_y

						firstRowFrame = thisFrame
						breakLine = breakLine + options.amount_per_line
					end

					thisFrame:SetPoint(anchorPoint, self, anchorAt, currentX, currentY)
					currentY = currentY - offsetY
				end
			end

		else
			for i = 1, #frameList do
				local thisFrame =  frameList [i]
				if (options.break_if_hidden and not thisFrame:IsShown()) then
					break
				end
				thisFrame:ClearAllPoints()

				if (options.anchor_to_child) then
					if (i == breakLine) then
						if (options.grow_down) then
							thisFrame:SetPoint("topleft", firstRowFrame, "bottomleft", 0, -offsetY)
						else
							thisFrame:SetPoint("bottomleft", firstRowFrame, "topleft", 0, offsetY)
						end
						firstRowFrame = thisFrame
						latestFrame = thisFrame
						breakLine = breakLine + options.amount_per_line
					else
						thisFrame:SetPoint(anchorPoint, latestFrame, i == 1 and "topleft" or anchorAt, i == 1 and 0 or offsetX, offsetY)
						latestFrame = thisFrame
					end
				else
					if (i == breakLine) then
						if (options.grow_down) then
							currentY = currentY - offsetY
						else
							currentY = currentY + offsetY
						end
						currentX = options.start_x

						firstRowFrame = thisFrame
						breakLine = breakLine + options.amount_per_line
					end

					thisFrame:SetPoint(anchorPoint, self, anchorAt, currentX, currentY)
					currentX = currentX + offsetX
				end
			end
		end
	end
}


------------------------------------------------------------------------------------------------------------
--metatables
	PanelMetaFunctions.__call = function(_table, value)
		--nothing to do
		return true
	end

------------------------------------------------------------------------------------------------------------
--members
	--tooltip
	local gmember_tooltip = function(_object)
		return _object:GetTooltip()
	end
	--shown
	local gmember_shown = function(_object)
		return _object:IsShown()
	end
	--backdrop color
	local gmember_color = function(_object)
		return _object.frame:GetBackdropColor()
	end
	--backdrop table
	local gmember_backdrop = function(_object)
		return _object.frame:GetBackdrop()
	end
	--frame width
	local gmember_width = function(_object)
		return _object.frame:GetWidth()
	end
	--frame height
	local gmember_height = function(_object)
		return _object.frame:GetHeight()
	end
	--locked
	local gmember_locked = function(_object)
		return rawget(_object, "is_locked")
	end

	PanelMetaFunctions.GetMembers = PanelMetaFunctions.GetMembers or {}
	PanelMetaFunctions.GetMembers ["tooltip"] = gmember_tooltip
	PanelMetaFunctions.GetMembers ["shown"] = gmember_shown
	PanelMetaFunctions.GetMembers ["color"] = gmember_color
	PanelMetaFunctions.GetMembers ["backdrop"] = gmember_backdrop
	PanelMetaFunctions.GetMembers ["width"] = gmember_width
	PanelMetaFunctions.GetMembers ["height"] = gmember_height
	PanelMetaFunctions.GetMembers ["locked"] = gmember_locked

	PanelMetaFunctions.__index = function(object, key)
		local func = PanelMetaFunctions.GetMembers[key]
		if (func) then
			return func(object, key)
		end

		local fromMe = rawget(object, key)
		if (fromMe) then
			return fromMe
		end

		return PanelMetaFunctions[key]
	end

	--tooltip
	local smember_tooltip = function(_object, _value)
		return _object:SetTooltip (_value)
	end
	--show
	local smember_show = function(_object, _value)
		if (_value) then
			return _object:Show()
		else
			return _object:Hide()
		end
	end
	--hide
	local smember_hide = function(_object, _value)
		if (not _value) then
			return _object:Show()
		else
			return _object:Hide()
		end
	end
	--backdrop color
	local smember_color = function(_object, _value)
		local _value1, _value2, _value3, _value4 = detailsFramework:ParseColors(_value)
		return _object:SetBackdropColor(_value1, _value2, _value3, _value4)
	end
	--frame width
	local smember_width = function(_object, _value)
		return _object.frame:SetWidth(_value)
	end
	--frame height
	local smember_height = function(_object, _value)
		return _object.frame:SetHeight(_value)
	end

	--locked
	local smember_locked = function(_object, _value)
		if (_value) then
			_object.frame:SetMovable(false)
			return rawset(_object, "is_locked", true)
		else
			_object.frame:SetMovable(true)
			rawset(_object, "is_locked", false)
			return
		end
	end

	--backdrop
	local smember_backdrop = function(_object, _value)
		return _object.frame:SetBackdrop(_value)
	end

	--close with right button
	local smember_right_close = function(_object, _value)
		return rawset(_object, "rightButtonClose", _value)
	end

	PanelMetaFunctions.SetMembers = PanelMetaFunctions.SetMembers or {}
	PanelMetaFunctions.SetMembers["tooltip"] = smember_tooltip
	PanelMetaFunctions.SetMembers["show"] = smember_show
	PanelMetaFunctions.SetMembers["hide"] = smember_hide
	PanelMetaFunctions.SetMembers["color"] = smember_color
	PanelMetaFunctions.SetMembers["backdrop"] = smember_backdrop
	PanelMetaFunctions.SetMembers["width"] = smember_width
	PanelMetaFunctions.SetMembers["height"] = smember_height
	PanelMetaFunctions.SetMembers["locked"] = smember_locked
	PanelMetaFunctions.SetMembers["close_with_right"] = smember_right_close

	PanelMetaFunctions.__newindex = function(_table, _key, _value)
		local func = PanelMetaFunctions.SetMembers [_key]
		if (func) then
			return func (_table, _value)
		else
			return rawset(_table, _key, _value)
		end
	end

------------------------------------------------------------------------------------------------------------
--methods

--right click to close
	function PanelMetaFunctions:CreateRightClickLabel(textType, width, height, showCloseText)
		local text
		width = width or 20
		height = height or 20

		if (showCloseText) then
			text = showCloseText
		else
			if (textType) then
				textType = string.lower(textType)
				if (textType == "short") then
					text = "close window"

				elseif (textType == "medium") then
					text = "close window"

				elseif (textType == "large") then
					text = "close window"
				end
			else
				text = "close window"
			end
		end

		return detailsFramework:NewLabel(self, _, "$parentRightMouseToClose", nil, "|TInterface\\TUTORIALFRAME\\UI-TUTORIAL-FRAME:" .. width .. ":" .. height .. ":0:1:512:512:8:70:328:409|t " .. text)
	end

--show & hide
	function PanelMetaFunctions:Show()
		self.frame:Show()
	end

	function PanelMetaFunctions:Hide()
		self.frame:Hide()
	end

-- setpoint
	function PanelMetaFunctions:SetPoint(v1, v2, v3, v4, v5)
		v1, v2, v3, v4, v5 = detailsFramework:CheckPoints (v1, v2, v3, v4, v5, self)
		if (not v1) then
			print("Invalid parameter for SetPoint")
			return
		end
		return self.widget:SetPoint(v1, v2, v3, v4, v5)
	end

-- sizes
	function PanelMetaFunctions:SetSize(w, h)
		if (w) then
			self.frame:SetWidth(w)
		end
		if (h) then
			self.frame:SetHeight(h)
		end
	end

-- clear
	function PanelMetaFunctions:HideWidgets()
		for widgetName, widgetSelf in pairs(self) do
			if (type(widgetSelf) == "table" and widgetSelf.dframework) then
				widgetSelf:Hide()
			end
		end
	end

-- backdrop
	function PanelMetaFunctions:SetBackdrop(background, edge, tilesize, edgesize, tile, left, right, top, bottom)

		if (type(background) == "boolean" and not background) then
			return self.frame:SetBackdrop(nil)

		elseif (type(background) == "table") then
			self.frame:SetBackdrop(background)

		else
			local currentBackdrop = self.frame:GetBackdrop() or {edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", bgFile="Interface\\DialogFrame\\UI-DialogBox-Background", tile=true, tileSize=16, edgeSize=16, insets={left=1, right=0, top=0, bottom=0}}
			currentBackdrop.bgFile = background or currentBackdrop.bgFile
			currentBackdrop.edgeFile = edgeFile or currentBackdrop.edgeFile
			currentBackdrop.tileSize = tilesize or currentBackdrop.tileSize
			currentBackdrop.edgeSize = edgesize or currentBackdrop.edgeSize
			currentBackdrop.tile = tile or currentBackdrop.tile
			currentBackdrop.insets.left = left or currentBackdrop.insets.left
			currentBackdrop.insets.right = left or currentBackdrop.insets.right
			currentBackdrop.insets.top = left or currentBackdrop.insets.top
			currentBackdrop.insets.bottom = left or currentBackdrop.insets.bottom
			self.frame:SetBackdrop(currentBackdrop)
		end
	end

-- backdropcolor
	function PanelMetaFunctions:SetBackdropColor(color, arg2, arg3, arg4)
		if (arg2) then
			self.frame:SetBackdropColor(color, arg2, arg3, arg4 or 1)
		else
			local _value1, _value2, _value3, _value4 = detailsFramework:ParseColors(color)
			self.frame:SetBackdropColor(_value1, _value2, _value3, _value4)
		end
	end

-- border color
	function PanelMetaFunctions:SetBackdropBorderColor(color, arg2, arg3, arg4)
		if (arg2) then
			return self.frame:SetBackdropBorderColor(color, arg2, arg3, arg4)
		end
		local _value1, _value2, _value3, _value4 = detailsFramework:ParseColors(color)
		self.frame:SetBackdropBorderColor(_value1, _value2, _value3, _value4)
	end

-- tooltip
	function PanelMetaFunctions:SetTooltip (tooltip)
		if (tooltip) then
			return rawset(self, "have_tooltip", tooltip)
		else
			return rawset(self, "have_tooltip", nil)
		end
	end
	function PanelMetaFunctions:GetTooltip()
		return rawget(self, "have_tooltip")
	end

-- frame levels
	function PanelMetaFunctions:GetFrameLevel()
		return self.widget:GetFrameLevel()
	end
	function PanelMetaFunctions:SetFrameLevel(level, frame)
		if (not frame) then
			return self.widget:SetFrameLevel(level)
		else
			local framelevel = frame:GetFrameLevel (frame) + level
			return self.widget:SetFrameLevel(framelevel)
		end
	end

-- frame stratas
	function PanelMetaFunctions:SetFrameStrata()
		return self.widget:GetFrameStrata()
	end
	function PanelMetaFunctions:SetFrameStrata(strata)
		if (type(strata) == "table") then
			self.widget:SetFrameStrata(strata:GetFrameStrata())
		else
			self.widget:SetFrameStrata(strata)
		end
	end

------------------------------------------------------------------------------------------------------------
--scripts

	local OnEnter = function(frame)
		local capsule = frame.MyObject
		local kill = capsule:RunHooksForWidget("OnEnter", frame, capsule)
		if (kill) then
			return
		end

		if (frame.MyObject.have_tooltip) then
			GameCooltip2:Reset()
			GameCooltip2:SetType ("tooltip")
			GameCooltip2:SetColor ("main", "transparent")
			GameCooltip2:AddLine(frame.MyObject.have_tooltip)
			GameCooltip2:SetOwner(frame)
			GameCooltip2:ShowCooltip()
		end
	end

	local OnLeave = function(frame)
		local capsule = frame.MyObject
		local kill = capsule:RunHooksForWidget("OnLeave", frame, capsule)
		if (kill) then
			return
		end

		if (frame.MyObject.have_tooltip) then
			GameCooltip2:ShowMe(false)
		end

	end

	local OnHide = function(frame)
		local capsule = frame.MyObject
		local kill = capsule:RunHooksForWidget("OnHide", frame, capsule)
		if (kill) then
			return
		end
	end

	local OnShow = function(frame)
		local capsule = frame.MyObject
		local kill = capsule:RunHooksForWidget("OnShow", frame, capsule)
		if (kill) then
			return
		end
	end

	local OnMouseDown = function(frame, button)
		local capsule = frame.MyObject
		local kill = capsule:RunHooksForWidget("OnMouseDown", frame, button, capsule)
		if (kill) then
			return
		end

		if (frame.MyObject.container == UIParent) then
			if (not frame.isLocked and frame:IsMovable()) then
				frame.isMoving = true
				frame:StartMoving()
			end

		elseif (not frame.MyObject.container.isLocked and frame.MyObject.container:IsMovable()) then
			if (not frame.isLocked and frame:IsMovable()) then
				frame.MyObject.container.isMoving = true
				frame.MyObject.container:StartMoving()
			end
		end


	end

	local OnMouseUp = function(frame, button)
		local capsule = frame.MyObject
		local kill = capsule:RunHooksForWidget("OnMouseUp", frame, button, capsule)
		if (kill) then
			return
		end

		if (button == "RightButton" and frame.MyObject.rightButtonClose) then
			frame.MyObject:Hide()
		end

		if (frame.MyObject.container == UIParent) then
			if (frame.isMoving) then
				frame:StopMovingOrSizing()
				frame.isMoving = false
			end
		else
			if (frame.MyObject.container.isMoving) then
				frame.MyObject.container:StopMovingOrSizing()
				frame.MyObject.container.isMoving = false
			end
		end
	end

------------------------------------------------------------------------------------------------------------
--object constructor
function detailsFramework:CreatePanel (parent, w, h, backdrop, backdropcolor, bordercolor, member, name)
	return detailsFramework:NewPanel(parent, parent, name, member, w, h, backdrop, backdropcolor, bordercolor)
end

function detailsFramework:NewPanel(parent, container, name, member, w, h, backdrop, backdropcolor, bordercolor)

	if (not name) then
		name = "DetailsFrameworkPanelNumber" .. detailsFramework.PanelCounter
		detailsFramework.PanelCounter = detailsFramework.PanelCounter + 1

	elseif (not parent) then
		parent = UIParent
	end
	if (not container) then
		container = parent
	end

	if (name:find("$parent")) then
		name = name:gsub("$parent", parent:GetName())
	end

	local PanelObject = {type = "panel", dframework = true}

	if (member) then
		parent [member] = PanelObject
	end

	if (parent.dframework) then
		parent = parent.widget
	end
	if (container.dframework) then
		container = container.widget
	end

	--default members:
		--misc
		PanelObject.is_locked = true
		PanelObject.container = container
		PanelObject.rightButtonClose = false

	PanelObject.frame = CreateFrame("frame", name, parent,"BackdropTemplate")
	PanelObject.frame:SetSize(100, 100)
	PanelObject.frame.Gradient = {
					["OnEnter"] = {0.3, 0.3, 0.3, 0.5},
					["OnLeave"] = {0.9, 0.7, 0.7, 1}
	}
	PanelObject.frame:SetBackdrop({bgFile = [[Interface\DialogFrame\UI-DialogBox-Background]], edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 10, tileSize = 64, tile = true})

	PanelObject.widget = PanelObject.frame
	PanelObject.frame.MyObject = PanelObject

	if (not APIFrameFunctions) then
		APIFrameFunctions = {}
		local idx = getmetatable(PanelObject.frame).__index
		for funcName, funcAddress in pairs(idx) do
			if (not PanelMetaFunctions [funcName]) then
				PanelMetaFunctions [funcName] = function(object, ...)
					local x = loadstring ( "return _G['"..object.frame:GetName().."']:"..funcName.."(...)")
					return x (...)
				end
			end
		end
	end

	PanelObject.frame:SetWidth(w or 100)
	PanelObject.frame:SetHeight(h or 100)

	PanelObject.HookList = {
		OnEnter = {},
		OnLeave = {},
		OnHide = {},
		OnShow = {},
		OnMouseDown = {},
		OnMouseUp = {},
	}

	--hooks
		PanelObject.frame:SetScript("OnEnter", OnEnter)
		PanelObject.frame:SetScript("OnLeave", OnLeave)
		PanelObject.frame:SetScript("OnHide", OnHide)
		PanelObject.frame:SetScript("OnShow", OnShow)
		PanelObject.frame:SetScript("OnMouseDown", OnMouseDown)
		PanelObject.frame:SetScript("OnMouseUp", OnMouseUp)

	setmetatable(PanelObject, PanelMetaFunctions)

	if (backdrop) then
		PanelObject:SetBackdrop(backdrop)
	elseif (type(backdrop) == "boolean") then
		PanelObject.frame:SetBackdrop(nil)
	end

	if (backdropcolor) then
		PanelObject:SetBackdropColor(backdropcolor)
	end

	if (bordercolor) then
		PanelObject:SetBackdropBorderColor(bordercolor)
	end

	return PanelObject
end

------------fill panel

local button_on_enter = function(self)
	self.MyObject._icon:SetBlendMode("ADD")
	if (self.MyObject.onenter_func) then
		pcall(self.MyObject.onenter_func, self.MyObject)
	end
end
local button_on_leave = function(self)
	self.MyObject._icon:SetBlendMode("BLEND")
	if (self.MyObject.onleave_func) then
		pcall(self.MyObject.onleave_func, self.MyObject)
	end
end

local add_row = function(self, t, need_update)
	local index = #self.rows+1

	local thisrow = detailsFramework:NewPanel(self, self, "$parentHeader_" .. self._name .. index, nil, 1, 20)
	thisrow.backdrop = {bgFile = [[Interface\Tooltips\UI-Tooltip-Background]]}
	thisrow.color = {.3, .3, .3, .9}
	thisrow.type = t.type
	thisrow.func = t.func
	thisrow.name = t.name
	thisrow.notext = t.notext
	thisrow.icon = t.icon
	thisrow.iconalign = t.iconalign

	thisrow.hidden = t.hidden or false

	thisrow.onenter = t.onenter
	thisrow.onleave = t.onleave

	local text = detailsFramework:NewLabel(thisrow, nil, self._name .. "$parentLabel" .. index, "text")
	text:SetPoint("left", thisrow, "left", 2, 0)
	text:SetText(t.name)

	tinsert(self._raw_rows, t)
	tinsert(self.rows, thisrow)

	if (need_update) then
		self:AlignRows()
	end
end

local align_rows = function(self)

	local rows_shown = 0
	for index, row in ipairs(self.rows) do
		if (not row.hidden) then
			rows_shown = rows_shown + 1
		end
	end

	local cur_width = 1
	local row_width = self._width / max(rows_shown, 0.0001)


	local sindex = 1

	wipe (self._anchors)

	for index, row in ipairs(self.rows) do
		if (not row.hidden) then
			if (self._autowidth) then
				if (self._raw_rows [index].width) then
					row.width = self._raw_rows [index].width
				else
					row.width = row_width
				end
				row:SetPoint("topleft", self, "topleft", cur_width, -1)
				tinsert(self._anchors, cur_width)
				cur_width = cur_width + row_width + 1
			else
				row:SetPoint("topleft", self, "topleft", cur_width, -1)
				row.width = self._raw_rows [index].width
				tinsert(self._anchors, cur_width)
				cur_width = cur_width + self._raw_rows [index].width + 1
			end

			row:Show()

			local rowType = row.type

			if (rowType == "text") then
				for i = 1, #self.scrollframe.lines do
					local line = self.scrollframe.lines [i]
					local text = tremove(line.text_available)
					if (not text) then
						self:CreateRowText (line)
						text = tremove(line.text_available)
					end
					tinsert(line.text_inuse, text)
					text:SetPoint("left", line, "left", self._anchors [#self._anchors], 0)
					text:SetWidth(row.width)

					detailsFramework:SetFontSize(text, row.textsize or 10)
					text:SetJustifyH(row.textalign or "left")
				end
			elseif (rowType == "entry") then
				for i = 1, #self.scrollframe.lines do
					local line = self.scrollframe.lines [i]
					local entry = tremove(line.entry_available)
					if (not entry) then
						self:CreateRowEntry (line)
						entry = tremove(line.entry_available)
					end
					tinsert(line.entry_inuse, entry)
					entry:SetPoint("left", line, "left", self._anchors [#self._anchors], 0)
					if (sindex == rows_shown) then
						entry:SetWidth(row.width - 25)
					else
						entry:SetWidth(row.width)
					end
					entry.func = row.func

					entry.onenter_func = nil
					entry.onleave_func = nil

					if (row.onenter) then
						entry.onenter_func = row.onenter
					end
					if (row.onleave) then
						entry.onleave_func = row.onleave
					end
				end

			elseif (rowType == "checkbox") then
				for i = 1, #self.scrollframe.lines do
					local line = self.scrollframe.lines [i]
					local checkbox = tremove(line.checkbox_available)
					if (not checkbox) then
						self:CreateCheckbox (line)
						checkbox = tremove(line.checkbox_available)
					end

					tinsert(line.checkbox_inuse, checkbox)

					checkbox:SetPoint("left", line, "left", self._anchors [#self._anchors] + ((row.width - 20) / 2), 0)
					if (sindex == rows_shown) then
						checkbox:SetWidth(20)
						--checkbox:SetWidth(row.width - 25)
					else
						checkbox:SetWidth(20)
					end

					checkbox.onenter_func = nil
					checkbox.onleave_func = nil
				end

			elseif (rowType == "button") then
				for i = 1, #self.scrollframe.lines do
					local line = self.scrollframe.lines [i]
					local button = tremove(line.button_available)
					if (not button) then
						self:CreateRowButton (line)
						button = tremove(line.button_available)
					end
					tinsert(line.button_inuse, button)
					button:SetPoint("left", line, "left", self._anchors [#self._anchors], 0)
					if (sindex == rows_shown) then
						button:SetWidth(row.width - 25)
					else
						button:SetWidth(row.width)
					end

					if (row.icon) then
						button._icon.texture = row.icon
						button._icon:ClearAllPoints()
						if (row.iconalign) then
							if (row.iconalign == "center") then
								button._icon:SetPoint("center", button, "center")
							elseif (row.iconalign == "right") then
								button._icon:SetPoint("right", button, "right")
							end
						else
							button._icon:SetPoint("left", button, "left")
						end
					end

					if (row.name and not row.notext) then
						button._text:SetPoint("left", button._icon, "right", 2, 0)
						button._text.text = row.name
					end

					button.onenter_func = nil
					button.onleave_func = nil

					if (row.onenter) then
						button.onenter_func = row.onenter
					end
					if (row.onleave) then
						button.onleave_func = row.onleave
					end

				end
			elseif (rowType == "icon") then
				for i = 1, #self.scrollframe.lines do
					local line = self.scrollframe.lines [i]
					local icon = tremove(line.icon_available)
					if (not icon) then
						self:CreateRowIcon (line)
						icon = tremove(line.icon_available)
					end
					tinsert(line.icon_inuse, icon)
					icon:SetPoint("left", line, "left", self._anchors [#self._anchors] + ( ((row.width or 22) - 22) / 2), 0)
					icon.func = row.func
				end

			elseif (rowType == "texture") then
				for i = 1, #self.scrollframe.lines do
					local line = self.scrollframe.lines [i]
					local texture = tremove(line.texture_available)
					if (not texture) then
						self:CreateRowTexture (line)
						texture = tremove(line.texture_available)
					end
					tinsert(line.texture_inuse, texture)
					texture:SetPoint("left", line, "left", self._anchors [#self._anchors] + ( ((row.width or 22) - 22) / 2), 0)
				end

			end

			sindex = sindex + 1
		else
			row:Hide()
		end
	end

	if (#self.rows > 0) then
		if (self._autowidth) then
			self.rows [#self.rows]:SetWidth(row_width - rows_shown + 1)
		else
			self.rows [#self.rows]:SetWidth(self._raw_rows [rows_shown].width - rows_shown + 1)
		end
	end

	self.showing_amt = rows_shown
end

local update_rows = function(self, updated_rows)

	for i = 1, #updated_rows do
		local t = updated_rows [i]
		local raw = self._raw_rows [i]

		if (not raw) then
			self:AddRow (t)
		else
			raw.name = t.name
			raw.hidden = t.hidden or false
			raw.textsize = t.textsize
			raw.textalign = t.textalign

			local widget = self.rows [i]
			widget.name = t.name
			widget.textsize = t.textsize
			widget.textalign = t.textalign
			widget.hidden = t.hidden or false

			--
			widget.onenter = t.onenter
			widget.onleave = t.onleave
			--

			widget.text:SetText(t.name)
			detailsFramework:SetFontSize(widget.text, raw.textsize or 10)
			widget.text:SetJustifyH(raw.textalign or "left")
		end
	end

	for i = #updated_rows+1, #self._raw_rows do
		local raw = self._raw_rows [i]
		local widget = self.rows [i]
		raw.hidden = true
		widget.hidden = true
	end

	for index, row in ipairs(self.scrollframe.lines) do
		for i = #row.text_inuse, 1, -1 do
			tinsert(row.text_available, tremove(row.text_inuse, i))
		end
		for i = 1, #row.text_available do
			row.text_available[i]:Hide()
		end

		for i = #row.entry_inuse, 1, -1 do
			tinsert(row.entry_available, tremove(row.entry_inuse, i))
		end
		for i = 1, #row.entry_available do
			row.entry_available[i]:Hide()
		end

		for i = #row.button_inuse, 1, -1 do
			tinsert(row.button_available, tremove(row.button_inuse, i))
		end
		for i = 1, #row.button_available do
			row.button_available[i]:Hide()
		end

		for i = #row.checkbox_inuse, 1, -1 do
			tinsert(row.checkbox_available, tremove(row.checkbox_inuse, i))
		end
		for i = 1, #row.checkbox_available do
			row.checkbox_available[i]:Hide()
		end

		for i = #row.icon_inuse, 1, -1 do
			tinsert(row.icon_available, tremove(row.icon_inuse, i))
		end
		for i = 1, #row.icon_available do
			row.icon_available[i]:Hide()
		end

		for i = #row.texture_inuse, 1, -1 do
			tinsert(row.texture_available, tremove(row.texture_inuse, i))
		end
		for i = 1, #row.texture_available do
			row.texture_available[i]:Hide()
		end
	end

	self.current_header = updated_rows

	self:AlignRows()

end

local create_panel_text = function(self, row)
	row.text_total = row.text_total + 1
	local text = detailsFramework:NewLabel(row, nil, self._name .. "$parentLabel" .. row.text_total, "text" .. row.text_total)
	tinsert(row.text_available, text)
end

local create_panel_entry = function(self, row)
	row.entry_total = row.entry_total + 1
	local editbox = detailsFramework:NewTextEntry(row, nil, "$parentEntry" .. row.entry_total, "entry", 120, 20)
	editbox.align = "left"

	editbox:SetHook("OnEnterPressed", function()
		editbox.widget.focuslost = true
		editbox:ClearFocus()
		editbox.func (editbox.index, editbox.text)
		return true
	end)

	editbox:SetHook("OnEnter", function()
		if (editbox.onenter_func) then
			pcall(editbox.onenter_func, editbox)
		end
	end)
	editbox:SetHook("OnLeave", function()
		if (editbox.onleave_func) then
			pcall(editbox.onleave_func, editbox)
		end
	end)

	editbox.editbox.current_bordercolor = {1, 1, 1, 0.1}

	editbox:SetTemplate(detailsFramework:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"))
	editbox:SetBackdropColor(.2, .2, .2, 0.7)

	tinsert(row.entry_available, editbox)
end

local create_panel_checkbox = function(self, row)
	--row.checkbox_available
	row.checkbox_total = row.checkbox_total + 1

	local switch = detailsFramework:NewSwitch (row, nil, "$parentCheckBox" .. row.checkbox_total, nil, 20, 20, nil, nil, false)
	switch:SetAsCheckBox()
	switch:SetTemplate(detailsFramework:GetTemplate("switch", "OPTIONS_CHECKBOX_TEMPLATE"))

	tinsert(row.checkbox_available, switch)
end

local create_panel_button = function(self, row)
	row.button_total = row.button_total + 1
	local button = detailsFramework:NewButton(row, nil, "$parentButton" .. row.button_total, "button" .. row.button_total, 120, 20)

	--create icon and the text
	local icon = detailsFramework:NewImage(button, nil, 20, 20)
	local text = detailsFramework:NewLabel(button)

	button._icon = icon
	button._text = text

	button:SetHook("OnEnter", button_on_enter)
	button:SetHook("OnLeave", button_on_leave)

	tinsert(row.button_available, button)
end

local icon_onclick = function(texture, iconbutton)
	iconbutton._icon.texture = texture
	iconbutton.func (iconbutton.index, texture)
end

local create_panel_icon = function(self, row)
	row.icon_total = row.icon_total + 1
	local iconbutton = detailsFramework:NewButton(row, nil, "$parentIconButton" .. row.icon_total, "iconbutton", 22, 20)

	iconbutton:SetHook("OnEnter", button_on_enter)
	iconbutton:SetHook("OnLeave", button_on_leave)

	iconbutton:SetHook("OnMouseUp", function()
		detailsFramework:IconPick (icon_onclick, true, iconbutton)
		return true
	end)

	local icon = detailsFramework:NewImage(iconbutton, nil, 20, 20, "artwork", nil, "_icon", "$parentIcon" .. row.icon_total)
	iconbutton._icon = icon

	icon:SetPoint("center", iconbutton, "center", 0, 0)

	tinsert(row.icon_available, iconbutton)
end

local create_panel_texture = function(self, row)
	row.texture_total = row.texture_total + 1
	local texture = detailsFramework:NewImage(row, nil, 20, 20, "artwork", nil, "_icon" .. row.texture_total, "$parentIcon" .. row.texture_total)
	tinsert(row.texture_available, texture)
end

local set_fill_function = function(self, func)
	self._fillfunc = func
end
local set_total_function = function(self, func)
	self._totalfunc = func
end
local drop_header_function = function(self)
	wipe (self.rows)
end

local fillpanel_update_size = function(self, elapsed)
	local panel = self.MyObject

	panel._width = panel:GetWidth()
	panel._height = panel:GetHeight()

	panel:UpdateRowAmount()
	if (panel.current_header) then
		update_rows (panel, panel.current_header)
	end
	panel:Refresh()

	self:SetScript("OnUpdate", nil)
end

 -- ~fillpanel
  --alias
function detailsFramework:CreateFillPanel(parent, rows, w, h, total_lines, fill_row, autowidth, options, member, name)
	return detailsFramework:NewFillPanel(parent, rows, name, member, w, h, total_lines, fill_row, autowidth, options)
end

function detailsFramework:NewFillPanel(parent, rows, name, member, w, h, total_lines, fill_row, autowidth, options)
	local panel = detailsFramework:NewPanel(parent, parent, name, member, w, h)
	panel.backdrop = nil

	options = options or {rowheight = 20}
	panel.rows = {}

	panel.AddRow = add_row
	panel.AlignRows = align_rows
	panel.UpdateRows = update_rows
	panel.CreateRowText = create_panel_text
	panel.CreateRowEntry = create_panel_entry
	panel.CreateRowButton = create_panel_button
	panel.CreateCheckbox = create_panel_checkbox
	panel.CreateRowIcon = create_panel_icon
	panel.CreateRowTexture = create_panel_texture
	panel.SetFillFunction = set_fill_function
	panel.SetTotalFunction = set_total_function
	panel.DropHeader = drop_header_function

	panel._name = name
	panel._width = w
	panel._height = h
	panel._raw_rows = {}
	panel._anchors = {}
	panel._fillfunc = fill_row
	panel._totalfunc = total_lines
	panel._autowidth = autowidth

	panel:SetScript("OnSizeChanged", function()
		panel:SetScript("OnUpdate", fillpanel_update_size)
	end)

	for index, t in ipairs(rows) do
		panel.AddRow(panel, t)
	end

	local refresh_fillbox = function(self)
		local offset = FauxScrollFrame_GetOffset(self)
		local filled_lines = panel._totalfunc(panel)

		for index = 1, #self.lines do
			local row = self.lines [index]
			if (index <= filled_lines) then

				local real_index = index + offset
				local results = panel._fillfunc (real_index, panel)

				if (results and results [1]) then
					row:Show()

					local text, entry, button, icon, texture, checkbox = 1, 1, 1, 1, 1, 1

					for index, t in ipairs(panel.rows) do
						if (not t.hidden) then
							if (t.type == "text") then
								local fontstring = row.text_inuse [text]
								text = text + 1
								fontstring:SetText(results [index])
								fontstring.index = real_index
								fontstring:Show()

							elseif (t.type == "entry") then
								local entrywidget = row.entry_inuse [entry]
								entry = entry + 1
								entrywidget.index = real_index

								if (type(results [index]) == "table") then
									entrywidget:SetText(results [index].text)
									entrywidget.id = results [index].id
									entrywidget.data1 = results [index].data1
									entrywidget.data2 = results [index].data2
								else
									entrywidget:SetText(results [index])
								end

								entrywidget:SetCursorPosition(0)

								entrywidget:Show()

							elseif (t.type == "checkbox") then
								local checkboxwidget = row.checkbox_inuse [button]
								checkbox = checkbox + 1
								checkboxwidget.index = real_index
								checkboxwidget:SetValue(results [index])

								local func = function()
									t.func (real_index, index)
									panel:Refresh()
								end
								checkboxwidget.OnSwitch = func

							elseif (t.type == "button") then
								local buttonwidget = row.button_inuse [button]
								button = button + 1
								buttonwidget.index = real_index

								if (type(results [index]) == "table") then
									if (results [index].text) then
										buttonwidget:SetText(results [index].text)
									end

									if (results [index].icon) then
										buttonwidget._icon:SetTexture(results [index].icon)
									end

									if (results [index].func) then
										local func = function()
											t.func (real_index, results [index].value)
											panel:Refresh()
										end
										buttonwidget:SetClickFunction(func)
									else
										local func = function()
											t.func (real_index, index)
											panel:Refresh()
										end
										buttonwidget:SetClickFunction(func)
									end

									buttonwidget.id = results [index].id
									buttonwidget.data1 = results [index].data1
									buttonwidget.data2 = results [index].data2

								else
									local func = function()
										t.func (real_index, index)
										panel:Refresh()
									end
									buttonwidget:SetClickFunction(func)
									buttonwidget:SetText(results [index])
								end

								buttonwidget:Show()

							elseif (t.type == "icon") then
								local iconwidget = row.icon_inuse [icon]
								icon = icon + 1

								iconwidget.line = index
								iconwidget.index = real_index

								if (type(results [index]) == "string") then
									local result = results [index]:gsub(".-%\\", "")
									iconwidget._icon.texture = results [index]
									iconwidget._icon:SetTexCoord(0.1, .9, 0.1, .9)

								elseif (type(results [index]) == "table") then
									iconwidget._icon:SetTexture(results [index].texture)

									local textCoord = results [index].texcoord
									if (textCoord) then
										iconwidget._icon:SetTexCoord(unpack(textCoord))
									else
										iconwidget._icon:SetTexCoord(0.1, .9, 0.1, .9)
									end

									local color = results [index].color
									if (color) then
										local r, g, b, a = detailsFramework:ParseColors(color)
										iconwidget._icon:SetVertexColor(r, g, b, a)
									else
										iconwidget._icon:SetVertexColor(1, 1, 1, 1)
									end
								else
									iconwidget._icon:SetTexture(results [index])
									iconwidget._icon:SetTexCoord(0.1, .9, 0.1, .9)
								end

								iconwidget:Show()

							elseif (t.type == "texture") then
								local texturewidget = row.texture_inuse [texture]
								texture = texture + 1

								texturewidget.line = index
								texturewidget.index = real_index

								if (type(results [index]) == "string") then
									local result = results [index]:gsub(".-%\\", "")
									texturewidget.texture = results [index]

								elseif (type(results [index]) == "table") then
									texturewidget:SetTexture(results [index].texture)

									local textCoord = results [index].texcoord
									if (textCoord) then
										texturewidget:SetTexCoord(unpack(textCoord))
									else
										texturewidget:SetTexCoord(0, 1, 0, 1)
									end

									local color = results [index].color
									if (color) then
										local r, g, b, a = detailsFramework:ParseColors(color)
										texturewidget:SetVertexColor(r, g, b, a)
									else
										texturewidget:SetVertexColor(1, 1, 1, 1)
									end

								else
									texturewidget:SetTexture(results [index])
								end

								texturewidget:Show()
							end
						end
					end

				else
					row:Hide()
				end
			else
				row:Hide()
			end
		end
	end

	function panel:Refresh()
		if (type(panel._totalfunc) == "boolean") then
			--not yet initialized
			return
		end
		local filled_lines = panel._totalfunc (panel)
		local scroll_total_lines = #panel.scrollframe.lines
		local line_height = options.rowheight
		refresh_fillbox (panel.scrollframe)
		FauxScrollFrame_Update (panel.scrollframe, filled_lines, scroll_total_lines, line_height)
		panel.scrollframe:Show()
	end

	local scrollframe = CreateFrame("scrollframe", name .. "Scroll", panel.widget, "FauxScrollFrameTemplate", "BackdropTemplate")
	scrollframe:SetScript("OnVerticalScroll", function(self, offset) FauxScrollFrame_OnVerticalScroll (self, offset, 20, panel.Refresh) end)
	scrollframe:SetPoint("topleft", panel.widget, "topleft", 0, -21)
	scrollframe:SetPoint("topright", panel.widget, "topright", -23, -21)
	scrollframe:SetPoint("bottomleft", panel.widget, "bottomleft")
	scrollframe:SetPoint("bottomright", panel.widget, "bottomright", -23, 0)
	scrollframe:SetSize(w, h)
	panel.scrollframe = scrollframe
	scrollframe.lines = {}

	detailsFramework:ReskinSlider(scrollframe)

	--create lines
	function panel:UpdateRowAmount()
		local size = options.rowheight
		local amount = math.floor(((panel._height-21) / size))

		for i = #scrollframe.lines+1, amount do
			local row = CreateFrame("frame", panel:GetName() .. "Row_" .. i, panel.widget,"BackdropTemplate")
			row:SetSize(1, size)
			row.color = {1, 1, 1, .2}

			row:SetBackdrop({bgFile = [[Interface\Tooltips\UI-Tooltip-Background]]})

			if (i%2 == 0) then
				row:SetBackdropColor(.5, .5, .5, 0.2)
			else
				row:SetBackdropColor(1, 1, 1, 0.00)
			end

			row:SetPoint("topleft", scrollframe, "topleft", 0, (i-1) * size * -1)
			row:SetPoint("topright", scrollframe, "topright", 0, (i-1) * size * -1)
			tinsert(scrollframe.lines, row)

			row.text_available = {}
			row.text_inuse = {}
			row.text_total = 0

			row.entry_available = {}
			row.entry_inuse = {}
			row.entry_total = 0

			row.button_available = {}
			row.button_inuse = {}
			row.button_total = 0

			row.checkbox_available = {}
			row.checkbox_inuse = {}
			row.checkbox_total = 0

			row.icon_available = {}
			row.icon_inuse = {}
			row.icon_total = 0

			row.texture_available = {}
			row.texture_inuse = {}
			row.texture_total = 0
		end
	end
	panel:UpdateRowAmount()

	panel.AlignRows (panel)

	return panel
end


------------color pick
local color_pick_func = function()
	local r, g, b = ColorPickerFrame:GetColorRGB()
	local a = OpacitySliderFrame:GetValue()
	ColorPickerFrame:dcallback (r, g, b, a, ColorPickerFrame.dframe)
end
local color_pick_func_cancel = function()
	ColorPickerFrame:SetColorRGB (unpack(ColorPickerFrame.previousValues))
	local r, g, b = ColorPickerFrame:GetColorRGB()
	local a = OpacitySliderFrame:GetValue()
	ColorPickerFrame:dcallback (r, g, b, a, ColorPickerFrame.dframe)
end

function detailsFramework:ColorPick (frame, r, g, b, alpha, callback)

	ColorPickerFrame:ClearAllPoints()
	ColorPickerFrame:SetPoint("bottomleft", frame, "topright", 0, 0)

	ColorPickerFrame.dcallback = callback
	ColorPickerFrame.dframe = frame

	ColorPickerFrame.func = color_pick_func
	ColorPickerFrame.opacityFunc = color_pick_func
	ColorPickerFrame.cancelFunc = color_pick_func_cancel

	ColorPickerFrame.opacity = alpha
	ColorPickerFrame.hasOpacity = alpha and true

	ColorPickerFrame.previousValues = {r, g, b}
	ColorPickerFrame:SetParent(UIParent)
	ColorPickerFrame:SetFrameStrata("tooltip")
	ColorPickerFrame:SetColorRGB (r, g, b)
	ColorPickerFrame:Show()

end

------------icon pick
function detailsFramework:IconPick (callback, close_when_select, param1, param2)

	if (not detailsFramework.IconPickFrame) then

		local string_lower = string.lower

		detailsFramework.IconPickFrame = CreateFrame("frame", "DetailsFrameworkIconPickFrame", UIParent, "BackdropTemplate")
		tinsert(UISpecialFrames, "DetailsFrameworkIconPickFrame")
		detailsFramework.IconPickFrame:SetFrameStrata("FULLSCREEN")

		detailsFramework.IconPickFrame:SetPoint("center", UIParent, "center")
		detailsFramework.IconPickFrame:SetWidth(416)
		detailsFramework.IconPickFrame:SetHeight(350)
		detailsFramework.IconPickFrame:EnableMouse(true)
		detailsFramework.IconPickFrame:SetMovable(true)

		detailsFramework:CreateTitleBar (detailsFramework.IconPickFrame, "Details! Framework Icon Picker")

		detailsFramework.IconPickFrame:SetBackdrop({edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1, bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true})
		detailsFramework.IconPickFrame:SetBackdropBorderColor(0, 0, 0)
		detailsFramework.IconPickFrame:SetBackdropColor(24/255, 24/255, 24/255, .8)
		detailsFramework.IconPickFrame:SetFrameLevel(5000)

		detailsFramework.IconPickFrame:SetScript("OnMouseDown", function(self)
			if (not self.isMoving) then
				detailsFramework.IconPickFrame:StartMoving()
				self.isMoving = true
			end
		end)

		detailsFramework.IconPickFrame:SetScript("OnMouseUp", function(self)
			if (self.isMoving) then
				detailsFramework.IconPickFrame:StopMovingOrSizing()
				self.isMoving = nil
			end
		end)

		detailsFramework.IconPickFrame.emptyFunction = function() end
		detailsFramework.IconPickFrame.callback = detailsFramework.IconPickFrame.emptyFunction

		detailsFramework.IconPickFrame.preview =  CreateFrame("frame", nil, UIParent, "BackdropTemplate")
		detailsFramework.IconPickFrame.preview:SetFrameStrata("tooltip")
		detailsFramework.IconPickFrame.preview:SetFrameLevel(6001)
		detailsFramework.IconPickFrame.preview:SetSize(76, 76)

		local preview_image_bg = detailsFramework:NewImage(detailsFramework.IconPickFrame.preview, nil, 76, 76)
		preview_image_bg:SetDrawLayer("background", 0)
		preview_image_bg:SetAllPoints(detailsFramework.IconPickFrame.preview)
		preview_image_bg:SetColorTexture(0, 0, 0)

		local preview_image = detailsFramework:NewImage(detailsFramework.IconPickFrame.preview, nil, 76, 76)
		preview_image:SetAllPoints(detailsFramework.IconPickFrame.preview)

		detailsFramework.IconPickFrame.preview.icon = preview_image
		detailsFramework.IconPickFrame.preview:Hide()

		--serach
		detailsFramework.IconPickFrame.searchLabel =  detailsFramework:NewLabel(detailsFramework.IconPickFrame, nil, "$parentSearchBoxLabel", nil, "Search:")
		detailsFramework.IconPickFrame.searchLabel:SetPoint("topleft", detailsFramework.IconPickFrame, "topleft", 12, -36)
		detailsFramework.IconPickFrame.searchLabel:SetTemplate(detailsFramework:GetTemplate("font", "ORANGE_FONT_TEMPLATE"))
		detailsFramework.IconPickFrame.searchLabel.fontsize = 12

		detailsFramework.IconPickFrame.search = detailsFramework:NewTextEntry(detailsFramework.IconPickFrame, nil, "$parentSearchBox", nil, 140, 20)
		detailsFramework.IconPickFrame.search:SetPoint("left", detailsFramework.IconPickFrame.searchLabel, "right", 2, 0)
		detailsFramework.IconPickFrame.search:SetTemplate(detailsFramework:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"))

		detailsFramework.IconPickFrame.search:SetHook("OnTextChanged", function()
			detailsFramework.IconPickFrame.searching = detailsFramework.IconPickFrame.search:GetText()
			if (detailsFramework.IconPickFrame.searching == "") then
				detailsFramework.IconPickFrameScroll:Show()
				detailsFramework.IconPickFrame.searching = nil
				detailsFramework.IconPickFrameScroll.RefreshIcons()
			else
				detailsFramework.IconPickFrameScroll:Hide()
				FauxScrollFrame_SetOffset (detailsFramework.IconPickFrame, 1)
				detailsFramework.IconPickFrame.last_filter_index = 1
				detailsFramework.IconPickFrameScroll.RefreshIcons()
			end
		end)

		--manually enter the icon path
		detailsFramework.IconPickFrame.customIcon = detailsFramework:CreateLabel(detailsFramework.IconPickFrame, "Icon Path:", detailsFramework:GetTemplate("font", "ORANGE_FONT_TEMPLATE"))
		detailsFramework.IconPickFrame.customIcon:SetPoint("bottomleft", detailsFramework.IconPickFrame, "bottomleft", 12, 16)
		detailsFramework.IconPickFrame.customIcon.fontsize = 12

		detailsFramework.IconPickFrame.customIconEntry = detailsFramework:CreateTextEntry(detailsFramework.IconPickFrame, function()end, 200, 20, "CustomIconEntry", _, _, detailsFramework:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"))
		detailsFramework.IconPickFrame.customIconEntry:SetPoint("left", detailsFramework.IconPickFrame.customIcon, "right", 2, 0)

		detailsFramework.IconPickFrame.customIconEntry:SetHook("OnTextChanged", function()
			detailsFramework.IconPickFrame.preview:SetPoint("bottom", detailsFramework.IconPickFrame.customIconEntry.widget, "top", 0, 2)
			detailsFramework.IconPickFrame.preview.icon:SetTexture(detailsFramework.IconPickFrame.customIconEntry:GetText())
			detailsFramework.IconPickFrame.preview:Show()
		end)

		detailsFramework.IconPickFrame.customIconEntry:SetHook("OnEnter", function()
			detailsFramework.IconPickFrame.preview:SetPoint("bottom", detailsFramework.IconPickFrame.customIconEntry.widget, "top", 0, 2)
			detailsFramework.IconPickFrame.preview.icon:SetTexture(detailsFramework.IconPickFrame.customIconEntry:GetText())
			detailsFramework.IconPickFrame.preview:Show()
		end)

		--close button
		local close_button = CreateFrame("button", nil, detailsFramework.IconPickFrame, "UIPanelCloseButton", "BackdropTemplate")
		close_button:SetWidth(32)
		close_button:SetHeight(32)
		close_button:SetPoint("TOPRIGHT", detailsFramework.IconPickFrame, "TOPRIGHT", -8, -7)
		close_button:SetFrameLevel(close_button:GetFrameLevel()+2)
		close_button:SetAlpha(0) --just hide, it is used below

		--accept custom icon button
		local accept_custom_icon = function()
			local path = detailsFramework.IconPickFrame.customIconEntry:GetText()

			detailsFramework:QuickDispatch(detailsFramework.IconPickFrame.callback, path, detailsFramework.IconPickFrame.param1, detailsFramework.IconPickFrame.param2)

			if (detailsFramework.IconPickFrame.click_close) then
				close_button:Click()
			end
		end

		detailsFramework.IconPickFrame.customIconAccept = detailsFramework:CreateButton(detailsFramework.IconPickFrame, accept_custom_icon, 82, 20, "Accept", nil, nil, nil, nil, nil, nil, detailsFramework:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"), detailsFramework:GetTemplate("font", "ORANGE_FONT_TEMPLATE"))
		detailsFramework.IconPickFrame.customIconAccept:SetPoint("left", detailsFramework.IconPickFrame.customIconEntry, "right", 2, 0)

		--fill with icons
		local MACRO_ICON_FILENAMES = {}
		local SPELLNAMES_CACHE = {}

		detailsFramework.IconPickFrame:SetScript("OnShow", function()
			MACRO_ICON_FILENAMES[1] = "INV_MISC_QUESTIONMARK"
			local index = 2

			for i = 1, GetNumSpellTabs() do
				local tab, tabTex, offset, numSpells, _ = GetSpellTabInfo(i)
				offset = offset + 1
				local tabEnd = offset + numSpells

				for j = offset, tabEnd - 1 do
					--to get spell info by slot, you have to pass in a pet argument
					local spellType, ID = GetSpellBookItemInfo(j, "player")
					if (spellType ~= "FLYOUT") then
						MACRO_ICON_FILENAMES [index] = GetSpellBookItemTexture(j, "player") or 0
						SPELLNAMES_CACHE [index] = GetSpellInfo(ID)
						index = index + 1

					elseif (spellType == "FLYOUT") then
						local _, _, numSlots, isKnown = GetFlyoutInfo(ID)
						if (isKnown and numSlots > 0) then
							for k = 1, numSlots do
								local spellID, overrideSpellID, isKnown = GetFlyoutSlotInfo(ID, k)
								if (isKnown) then
									MACRO_ICON_FILENAMES [index] = GetSpellTexture(spellID) or 0
									SPELLNAMES_CACHE [index] = GetSpellInfo(spellID)
									index = index + 1
								end
							end
						end
					end
				end
			end

			GetLooseMacroItemIcons(MACRO_ICON_FILENAMES)
			GetLooseMacroIcons(MACRO_ICON_FILENAMES)
			GetMacroIcons(MACRO_ICON_FILENAMES)
			GetMacroItemIcons(MACRO_ICON_FILENAMES)

			--reset the custom icon text entry
			detailsFramework.IconPickFrame.customIconEntry:SetText("")
			--reset the search text entry
			detailsFramework.IconPickFrame.search:SetText("")
		end)

		detailsFramework.IconPickFrame:SetScript("OnHide", function()
			wipe(MACRO_ICON_FILENAMES)
			wipe(SPELLNAMES_CACHE)
			detailsFramework.IconPickFrame.preview:Hide()
			collectgarbage()
		end)

		detailsFramework.IconPickFrame.buttons = {}

		local onClickFunction = function(self)

			detailsFramework:QuickDispatch(detailsFramework.IconPickFrame.callback, self.icon:GetTexture(), detailsFramework.IconPickFrame.param1, detailsFramework.IconPickFrame.param2)

			if (detailsFramework.IconPickFrame.click_close) then
				close_button:Click()
			end
		end

		local onEnter = function(self)
			detailsFramework.IconPickFrame.preview:SetPoint("bottom", self, "top", 0, 2)
			detailsFramework.IconPickFrame.preview.icon:SetTexture(self.icon:GetTexture())
			detailsFramework.IconPickFrame.preview:Show()
			self.icon:SetBlendMode("ADD")
		end
		local onLeave = function(self)
			detailsFramework.IconPickFrame.preview:Hide()
			self.icon:SetBlendMode("BLEND")
		end

		local backdrop = {bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tile = true, tileSize = 16,
		insets = {left = 0, right = 0, top = 0, bottom = 0}, edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1}

		for _, button in ipairs(detailsFramework.IconPickFrame.buttons) do
			button:SetBackdropBorderColor(0, 0, 0, 1)
		end

		local width = 412
		local height = 248
		local linesAmount = 6
		local lineHeight = 40

		local updateIconScroll = function(self, data, offset, totalLines)
            for i = 1, totalLines do
                local index = i + offset
                local iconsInThisLine = data[index]
				if (iconsInThisLine) then
					local line = self:GetLine(i)
                    for o = 1, #iconsInThisLine do
						local _, _, texture = GetSpellInfo(iconsInThisLine[o])
						if (texture) then
							line.buttons[o].icon:SetTexture(texture)
							line.buttons[o].texture = texture
						else
							line.buttons[o].icon:SetTexture(iconsInThisLine[o])
							line.buttons[o].texture = iconsInThisLine[o]
						end
					end
				end
			end
		end

		local lower = string.lower

		local scroll = detailsFramework:CreateScrollBox(detailsFramework.IconPickFrame, "DetailsFrameworkIconPickFrameScroll", updateIconScroll, {}, width, height, linesAmount, lineHeight)
		detailsFramework:ReskinSlider(scroll)
		scroll:SetPoint("topleft", detailsFramework.IconPickFrame, "topleft", 2, -58)

		function scroll.RefreshIcons()
			--build icon list
			local iconList = {}
			local numMacroIcons = #MACRO_ICON_FILENAMES

			local filter
			if (detailsFramework.IconPickFrame.searching) then
				filter = lower(detailsFramework.IconPickFrame.searching)
			end

			if (filter and filter ~= "") then
				local index
				local currentTable
				for i = 1, #SPELLNAMES_CACHE do
					if (SPELLNAMES_CACHE[i] and SPELLNAMES_CACHE[i]:lower():find(filter)) then
						if (not index) then
							index = 1
							local t = {}
							iconList[#iconList+1] = t
							currentTable = t
						end

						currentTable[index] = SPELLNAMES_CACHE[i]

						index = index + 1
						if (index == 11) then
							index = nil
						end
					end

				end
			else
				for i = 1, #SPELLNAMES_CACHE, 10 do
					local t = {}
					iconList[#iconList+1] = t
					for o = i, i+9 do
						if (SPELLNAMES_CACHE[o]) then
							t[#t+1] = SPELLNAMES_CACHE[o]
						end
					end
				end

				for i = 1, #MACRO_ICON_FILENAMES, 10 do
					local t = {}
					iconList[#iconList+1] = t
					for o = i, i+9 do
						if (MACRO_ICON_FILENAMES[o]) then
							t[#t+1] = MACRO_ICON_FILENAMES[o]
						end
					end
				end
			end

			--set data and refresh
			scroll:SetData(iconList)
			scroll:Refresh()
		end

		--create the lines and button of the scroll box
		for i = 1, linesAmount do
			scroll:CreateLine(function(self, index)
				local line = CreateFrame("button", "$parentLine" .. index, self, "BackdropTemplate")
				line:SetPoint("topleft", self, "topleft", 1, -((index-1)*(lineHeight+1)) - 1)
				line:SetSize(width - 2, lineHeight)
				line:SetBackdrop({bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true})
				line:SetBackdropColor(.2, .2, .2, .5)
				line.buttons = {}

				local lastButton

				for o = 1, 10 do
					local button = CreateFrame("button", "$parentIcon" .. o, line)
					if (not lastButton) then
						button:SetPoint("left", line, "left", 0, 0)
					else
						button:SetPoint("left", lastButton, "right", 1, 0)
					end
					button:SetSize(lineHeight, lineHeight)
					button.icon = button:CreateTexture("$parentIcon", "overlay")
					button.icon:SetAllPoints()
					button.icon:SetTexCoord(.1, .9, .1, .9)
					line.buttons[o] = button

					button:SetScript("OnEnter", onEnter)
					button:SetScript("OnLeave", onLeave)
					button:SetScript("OnClick", onClickFunction)

					lastButton = button
				end

				return line
			end)
		end

		detailsFramework.IconPickFrameScroll = scroll
		detailsFramework.IconPickFrame:Hide()
	end

	detailsFramework.IconPickFrame.param1, detailsFramework.IconPickFrame.param2 = param1, param2
	detailsFramework.IconPickFrame:Show()
	detailsFramework.IconPickFrame.callback = callback or detailsFramework.IconPickFrame.emptyFunction
	detailsFramework.IconPickFrame.click_close = close_when_select
	detailsFramework.IconPickFrameScroll.RefreshIcons()

end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function detailsFramework:ShowPanicWarning (text)
	if (not detailsFramework.PanicWarningWindow) then
		detailsFramework.PanicWarningWindow = CreateFrame("frame", "DetailsFrameworkPanicWarningWindow", UIParent, "BackdropTemplate")
		detailsFramework.PanicWarningWindow:SetHeight(80)
		detailsFramework.PanicWarningWindow:SetBackdrop({bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true})
		detailsFramework.PanicWarningWindow:SetBackdropColor(1, 0, 0, 0.2)
		detailsFramework.PanicWarningWindow:SetPoint("topleft", UIParent, "topleft", 0, -250)
		detailsFramework.PanicWarningWindow:SetPoint("topright", UIParent, "topright", 0, -250)

		detailsFramework.PanicWarningWindow.text = detailsFramework.PanicWarningWindow:CreateFontString(nil, "overlay", "GameFontNormal")
		detailsFramework.PanicWarningWindow.text:SetPoint("center", detailsFramework.PanicWarningWindow, "center")
		detailsFramework.PanicWarningWindow.text:SetTextColor(1, 0.6, 0)
	end

	detailsFramework.PanicWarningWindow.text:SetText(text)
	detailsFramework.PanicWarningWindow:Show()
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


local simple_panel_mouse_down = function(self, button)
	if (button == "RightButton") then
		if (self.IsMoving) then
			self.IsMoving = false
			self:StopMovingOrSizing()
			if (self.db and self.db.position) then
				detailsFramework:SavePositionOnScreen (self)
			end
		end
		if (not self.DontRightClickClose) then
			self:Hide()
		end
		return
	end
	if (not self.IsMoving and not self.IsLocked) then
		self.IsMoving = true
		self:StartMoving()
	end
end
local simple_panel_mouse_up = function(self, button)
	if (self.IsMoving) then
		self.IsMoving = false
		self:StopMovingOrSizing()
		if (self.db and self.db.position) then
			detailsFramework:SavePositionOnScreen (self)
		end
	end
end
local simple_panel_settitle = function(self, title)
	self.Title:SetText(title)
end

local simple_panel_close_click = function(self)
	self:GetParent():GetParent():Hide()
end

local SimplePanel_frame_backdrop = {edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1, bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true}
local SimplePanel_frame_backdrop_color = {0, 0, 0, 0.9}
local SimplePanel_frame_backdrop_border_color = {0, 0, 0, 1}

--with_label was making the frame stay in place while its parent moves
--the slider was anchoring to with_label and here here were anchoring the slider again
---@class df_scalebar : slider
---@field thumb texture
function detailsFramework:CreateScaleBar(frame, config) --~scale
	---@type df_scalebar
	local scaleBar, text = detailsFramework:CreateSlider(frame, 120, 14, 0.6, 1.6, 0.1, config.scale, true, "ScaleBar", nil, "Scale:", detailsFramework:GetTemplate("slider", "OPTIONS_SLIDER_TEMPLATE"), detailsFramework:GetTemplate("font", "ORANGE_FONT_TEMPLATE"))
	scaleBar.thumb:SetWidth(24)
	scaleBar:SetValueStep(0.1)
	scaleBar:SetObeyStepOnDrag(true)
	scaleBar.mouseDown = false
	rawset(scaleBar, "lockdown", true)

	--create a custom editbox to enter the scale from text
	local editbox = CreateFrame("editbox", nil, scaleBar.widget, "BackdropTemplate")
	editbox:SetSize(40, 20)
	editbox:SetJustifyH("center")
	editbox:SetBackdrop({bgFile = [[Interface\ACHIEVEMENTFRAME\UI-GuildAchievement-Parchment-Horizontal-Desaturated]],
	edgeFile = [[Interface\Buttons\WHITE8X8]],
	tile = true, edgeSize = 1, tileSize = 64})
	editbox:SetFontObject("GameFontHighlightSmall")
	editbox:SetBackdropColor(0, 0, 0, 1)

	editbox:SetScript("OnEditFocusGained", function()
	end)

	editbox:SetScript("OnEnterPressed", function()
		editbox:ClearFocus()
		editbox:Hide()
		local text = editbox:GetText()
		local newScale = detailsFramework.TextToFloor(text)

		if (newScale) then
			config.scale = newScale
			scaleBar:SetValue(newScale)
			frame:SetScale(newScale)
			editbox.defaultValue = newScale
		end
	end)

	editbox:SetScript("OnEscapePressed", function()
		editbox:ClearFocus()
		editbox:Hide()
		editbox:SetText(editbox.defaultValue)
	end)

	scaleBar:SetScript("OnMouseDown", function(_, mouseButton)
		if (mouseButton == "RightButton") then
			editbox:Show()
			editbox:SetAllPoints()
			editbox:SetText(config.scale)
			editbox:SetFocus(true)
			editbox.defaultValue = config.scale

		elseif (mouseButton == "LeftButton") then
			scaleBar.mouseDown  = true
		end
	end)

	scaleBar:SetScript("OnMouseUp", function(_, mouseButton)
		if (mouseButton == "LeftButton") then
			scaleBar.mouseDown  = false
			frame:SetScale(config.scale)
			editbox.defaultValue = config.scale
		end
	end)

	text:SetPoint("topleft", frame, "topleft", 12, -7)
	scaleBar:SetFrameLevel(detailsFramework.FRAMELEVEL_OVERLAY)
	scaleBar.OnValueChanged = function(_, _, value)
		if (scaleBar.mouseDown) then
			config.scale = value
		end
	end

	scaleBar:SetAlpha(0.70)
	editbox.defaultValue = config.scale
	editbox:SetFocus(false)
	editbox:SetAutoFocus(false)
	editbox:ClearFocus()

	C_Timer.After(1, function()
		editbox:SetFocus(false)
		editbox:SetAutoFocus(false)
		editbox:ClearFocus()
	end)

	return scaleBar
end

local no_options = {}

---create a simple panel with a title bar, a close button and a background
---already has onmousedown and onmouseup scripts to make it movable
---the panelOptions table can be used to set some options:
---NoScripts = false, --if true, won't set OnMouseDown and OnMouseUp (won't be movable)
---NoTUISpecialFrame = false, --if true, won't add the frame to 'UISpecialFrames'
---DontRightClickClose = false, --if true, won't make the frame close when clicked with the right mouse button
---UseScaleBar = false, --if true, will create a scale bar in the top left corner (require a table on 'db' to save the scale)
---UseStatusBar = false, --if true, creates a status bar at the bottom of the frame (frame.StatusBar)
---NoCloseButton = false, --if true, won't show the close button
---NoTitleBar = false, --if true, don't create the title bar
---RoundedCorners = false, --use rounded corners if true
---@class simplepanel
---@field TitleBar frame
---@field Title fontstring
---@field Close button
---@field SetTitle fun(self: simplepanel, title: string)
---@param parent frame the parent frame
---@param width number|nil the width of the panel
---@param height number|nil the height of the panel
---@param title string|nil a string to show in the title bar
---@param frameName string|nil the name of the frame
---@param panelOptions table|nil a table with options described above
---@param savedVariableTable table|nil a table to save the scale of the panel
---@return frame
function detailsFramework:CreateSimplePanel(parent, width, height, title, frameName, panelOptions, savedVariableTable)
	--create a saved variable table if the savedVariableTable has been not passed within the function call
	if (savedVariableTable and frameName and not savedVariableTable[frameName]) then
		savedVariableTable[frameName] = {
			scale = 1
		}
	end

	--create a frame name if the frameName has been not passed within the function call
	if (not frameName) then
		frameName = "DetailsFrameworkSimplePanel" .. detailsFramework.SimplePanelCounter
		detailsFramework.SimplePanelCounter = detailsFramework.SimplePanelCounter + 1
	end

	--default parent is UIParent
	if (not parent) then
		parent = _G["UIParent"]
	end

	--default options
	panelOptions = panelOptions or no_options

	--create the frame
	local simplePanel = CreateFrame("frame", frameName, _G["UIParent"],"BackdropTemplate")
	simplePanel:SetSize(width or 400, height or 250)
	simplePanel:SetPoint("center", _G["UIParent"], "center", 0, 0)
	simplePanel:SetFrameStrata("FULLSCREEN")
	simplePanel:EnableMouse()
	simplePanel:SetMovable(true)

	--set the backdrop
	if (panelOptions.RoundedCorners) then
		local tRoundedCornerPreset = {
			roundness = 6,
			color = {.1, .1, .1, 0.98},
			border_color = {.05, .05, .05, 0.834},
			use_titlebar = true,
		}
		detailsFramework:AddRoundedCornersToFrame(simplePanel, tRoundedCornerPreset)
	else
		simplePanel:SetBackdrop(SimplePanel_frame_backdrop)
		simplePanel:SetBackdropColor(unpack(SimplePanel_frame_backdrop_color))
		simplePanel:SetBackdropBorderColor(unpack(SimplePanel_frame_backdrop_border_color))
	end

	simplePanel.DontRightClickClose = panelOptions.DontRightClickClose

	if (not panelOptions.NoTUISpecialFrame) then
		tinsert(UISpecialFrames, frameName)
	end

	if (panelOptions.UseStatusBar and not panelOptions.RoundedCorners) then
		local statusBar = detailsFramework:CreateStatusBar(simplePanel)
		simplePanel.StatusBar = statusBar
	end

	local titleBar = CreateFrame("frame", frameName .. "TitleBar", simplePanel, "BackdropTemplate")

	if (panelOptions.RoundedCorners) then
		simplePanel.TitleBar:SetColor(.2, .2, .2, 0.4)
		simplePanel.TitleBar:SetBorderCornerColor(0, 0, 0, 0)

	else
		simplePanel.TitleBar = titleBar
		titleBar:SetPoint("topleft", simplePanel, "topleft", 2, -3)
		titleBar:SetPoint("topright", simplePanel, "topright", -2, -3)
		titleBar:SetHeight(20)
		titleBar:SetBackdrop(SimplePanel_frame_backdrop)
		titleBar:SetBackdropColor(.2, .2, .2, 1)
		titleBar:SetBackdropBorderColor(0, 0, 0, 1)
		simplePanel.TitleBar = titleBar
	end

	local close = CreateFrame("button", frameName and frameName .. "CloseButton", titleBar)
	close:SetFrameLevel(detailsFramework.FRAMELEVEL_OVERLAY)
	close:SetSize(16, 16)

	close:SetNormalTexture([[Interface\GLUES\LOGIN\Glues-CheckBox-Check]])
	close:SetHighlightTexture([[Interface\GLUES\LOGIN\Glues-CheckBox-Check]])
	close:SetPushedTexture([[Interface\GLUES\LOGIN\Glues-CheckBox-Check]])
	close:GetNormalTexture():SetDesaturated(true)
	close:GetHighlightTexture():SetDesaturated(true)
	close:GetPushedTexture():SetDesaturated(true)

	close:SetAlpha(0.7)
	close:SetScript("OnClick", simple_panel_close_click)
	simplePanel.Close = close
	simplePanel.closeButton = close

	local titleText = titleBar:CreateFontString(frameName and frameName .. "Title", "overlay", "GameFontNormal")
	titleText:SetTextColor(.8, .8, .8, 1)
	titleText:SetText(title or "")
	simplePanel.Title = titleText

	if (panelOptions.UseScaleBar and savedVariableTable [frameName]) then
		detailsFramework:CreateScaleBar (simplePanel, savedVariableTable [frameName])
		simplePanel:SetScale(savedVariableTable [frameName].scale)
	end

	simplePanel.Title:SetPoint("center", titleBar, "center")
	simplePanel.Close:SetPoint("right", titleBar, "right", -2, 0)

	if (panelOptions.NoCloseButton or panelOptions.RoundedCorners) then
		simplePanel.Close:Hide()
	end

	if (panelOptions.NoTitleBar) then
		simplePanel.TitleBar:Hide()
	end

	if (not panelOptions.NoScripts) then
		simplePanel:SetScript("OnMouseDown", simple_panel_mouse_down)
		simplePanel:SetScript("OnMouseUp", simple_panel_mouse_up)
	end

	simplePanel.SetTitle = simple_panel_settitle

	return simplePanel
end

local Panel1PxBackdrop = {bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 64,
edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1, insets = {left = 2, right = 2, top = 3, bottom = 3}}

local Panel1PxOnClickClose = function(self)
	self:GetParent():Hide()
end
local Panel1PxOnToggleLock = function(self)
	if (self.IsLocked) then
		self.IsLocked = false
		self:SetMovable(true)
		self:EnableMouse(true)
		self.Lock:GetNormalTexture():SetTexCoord(16/64, 32/64, 0, 1)
		self.Lock:GetHighlightTexture():SetTexCoord(16/32, 32/64, 0, 1)
		self.Lock:GetPushedTexture():SetTexCoord(16/64, 32/64, 0, 1)
		if (self.OnUnlock) then
			self:OnUnlock()
		end
		if (self.db) then
			self.db.IsLocked = self.IsLocked
		end
	else
		self.IsLocked = true
		self:SetMovable(false)
		self:EnableMouse(false)
		self.Lock:GetNormalTexture():SetTexCoord(0/64, 16/64, 0, 1)
		self.Lock:GetHighlightTexture():SetTexCoord(0/64, 16/64, 0, 1)
		self.Lock:GetPushedTexture():SetTexCoord(0/64, 16/64, 0, 1)
		if (self.OnLock) then
			self:OnLock()
		end
		if (self.db) then
			self.db.IsLocked = self.IsLocked
		end
	end
end
local Panel1PxOnClickLock = function(self)
	local f = self:GetParent()
	Panel1PxOnToggleLock (f)
end
local Panel1PxSetTitle = function(self, text)
	self.Title:SetText(text or "")
end

local Panel1PxSetLocked= function(self, lock_state)
	if (type(lock_state) ~= "boolean") then
		return
	end
	if (lock_state) then
		-- lock it
		self.IsLocked = false
		Panel1PxOnClickLock (self.Lock)
	else
		-- unlockit
		self.IsLocked = true
		Panel1PxOnClickLock (self.Lock)
	end
end

local Panel1PxReadConfig = function(self)
	local db = self.db
	if (db) then
		db.IsLocked = db.IsLocked or false
		self.IsLocked = db.IsLocked
		db.position = db.position or {x = 0, y = 0}
		db.position.x = db.position.x or 0
		db.position.y = db.position.y or 0
		detailsFramework:RestoreFramePosition (self)
	end
end

function detailsFramework:SavePositionOnScreen (frame)
	if (frame.db and frame.db.position) then
		local x, y = detailsFramework:GetPositionOnScreen (frame)
		--print("saving...", x, y, frame:GetName())
		if (x and y) then
			frame.db.position.x, frame.db.position.y = x, y
		end
	end
end

function detailsFramework:GetPositionOnScreen (frame)
	local xOfs, yOfs = frame:GetCenter()
	if (not xOfs) then
		return
	end
	local scale = frame:GetEffectiveScale()
	local UIscale = UIParent:GetScale()
	xOfs = xOfs*scale - GetScreenWidth()*UIscale/2
	yOfs = yOfs*scale - GetScreenHeight()*UIscale/2
	return xOfs/UIscale, yOfs/UIscale
end

function detailsFramework:RestoreFramePosition (frame)
	if (frame.db and frame.db.position) then
		local scale, UIscale = frame:GetEffectiveScale(), UIParent:GetScale()
		frame:ClearAllPoints()
		frame.db.position.x = frame.db.position.x or 0
		frame.db.position.y = frame.db.position.y or 0
		frame:SetPoint("center", UIParent, "center", frame.db.position.x * UIscale / scale, frame.db.position.y * UIscale / scale)
	end
end

local Panel1PxSavePosition= function(self)
	detailsFramework:SavePositionOnScreen (self)
end

local Panel1PxHasPosition = function(self)
	local db = self.db
	if (db) then
		if (db.position and db.position.x and (db.position.x ~= 0 or db.position.y ~= 0)) then
			return true
		end
	end
end

function detailsFramework:Create1PxPanel(parent, width, height, title, name, config, titleAnchor, noSpecialFrame)
	local newFrame = CreateFrame("frame", name, parent or UIParent, "BackdropTemplate")
	newFrame:SetSize(width or 100, height or 75)
	newFrame:SetPoint("center", UIParent, "center", 0, 0)

	if (name and not noSpecialFrame) then
		tinsert(UISpecialFrames, name)
	end

	newFrame:SetScript("OnMouseDown", simple_panel_mouse_down)
	newFrame:SetScript("OnMouseUp", simple_panel_mouse_up)

	newFrame:SetBackdrop(Panel1PxBackdrop)
	newFrame:SetBackdropColor(0, 0, 0, 0.5)

	newFrame.IsLocked = (config and config.IsLocked ~= nil and config.IsLocked) or false
	newFrame:SetMovable(true)
	newFrame:EnableMouse(true)
	newFrame:SetUserPlaced (true)

	newFrame.db = config
	Panel1PxReadConfig(newFrame)

	local closeButton = CreateFrame("button", name and name .. "CloseButton", newFrame, "BackdropTemplate")
	closeButton:SetSize(16, 16)
	closeButton:SetNormalTexture([[Interface\GLUES\LOGIN\Glues-CheckBox-Check]])
	closeButton:SetHighlightTexture([[Interface\GLUES\LOGIN\Glues-CheckBox-Check]])
	closeButton:SetPushedTexture([[Interface\GLUES\LOGIN\Glues-CheckBox-Check]])
	closeButton:GetNormalTexture():SetDesaturated(true)
	closeButton:GetHighlightTexture():SetDesaturated(true)
	closeButton:GetPushedTexture():SetDesaturated(true)
	closeButton:SetAlpha(0.7)

	local lockButton = CreateFrame("button", name and name .. "LockButton", newFrame, "BackdropTemplate")
	lockButton:SetSize(16, 16)
	lockButton:SetNormalTexture([[Interface\GLUES\CharacterSelect\Glues-AddOn-Icons]])
	lockButton:SetHighlightTexture([[Interface\GLUES\CharacterSelect\Glues-AddOn-Icons]])
	lockButton:SetPushedTexture([[Interface\GLUES\CharacterSelect\Glues-AddOn-Icons]])
	lockButton:GetNormalTexture():SetDesaturated(true)
	lockButton:GetHighlightTexture():SetDesaturated(true)
	lockButton:GetPushedTexture():SetDesaturated(true)
	lockButton:SetAlpha(0.7)

	closeButton:SetPoint("topright", newFrame, "topright", -3, -3)
	lockButton:SetPoint("right", closeButton, "left", 3, 0)

	closeButton:SetScript("OnClick", Panel1PxOnClickClose)
	lockButton:SetScript("OnClick", Panel1PxOnClickLock)

	local titleString = newFrame:CreateFontString(name and name .. "Title", "overlay", "GameFontNormal")
	titleString:SetPoint("topleft", newFrame, "topleft", 5, -5)

	detailsFramework.Language.SetTextIfLocTableOrDefault(titleString, title or "")

	if (titleAnchor) then
		if (titleAnchor == "top") then
			titleString:ClearAllPoints()
			titleString:SetPoint("bottomleft", newFrame, "topleft", 0, 0)

			closeButton:ClearAllPoints()
			closeButton:SetPoint("bottomright", newFrame, "topright", 0, 0)
		end
		newFrame.title_anchor = titleAnchor
	end

	newFrame.SetTitle = Panel1PxSetTitle
	newFrame.Title = titleString
	newFrame.Lock = lockButton
	newFrame.Close = closeButton
	newFrame.HasPosition = Panel1PxHasPosition
	newFrame.SavePosition = Panel1PxSavePosition

	newFrame.IsLocked = not newFrame.IsLocked
	newFrame.SetLocked = Panel1PxSetLocked
	Panel1PxOnToggleLock(newFrame)

	return newFrame
end

------------------------------------------------------------------------------------------------------------------------------------------------
-- ~prompt
function detailsFramework:HidePromptPanel(promptName)
	if (detailsFramework.promtp_panel) then
		if (promptName) then
			if (detailsFramework.promtp_panel.promptName == promptName) then
				detailsFramework.promtp_panel:Hide()
				detailsFramework.promtp_panel.promptName = nil
			end
		else
			detailsFramework.promtp_panel:Hide()
			detailsFramework.promtp_panel.promptName = nil
		end
	end
end

---show a prompt to the player with a question (message) and two buttons "yes" and "no"
---@param message string the question to show to the player
---@param trueCallback function if the player clicks on "yes"
---@param falseCallback function if the player clicks on "no"
---@param dontOverride boolean|nil if true, won't show another prompt if theres already a shown prompt
---@param width number|nil width of the prompt frame, if ommited, will use the default width 400
---@param promptName string|nil set a name to the prompt, used on HidePromptPanel(promptName)
function detailsFramework:ShowPromptPanel(message, trueCallback, falseCallback, dontOverride, width, promptName)
	if (not DetailsFrameworkPromptSimple) then
		local promptFrame = CreateFrame("frame", "DetailsFrameworkPromptSimple", UIParent, "BackdropTemplate")
		promptFrame:SetSize(400, 80)
		promptFrame:SetFrameStrata("DIALOG")
		promptFrame:SetPoint("center", UIParent, "center", 0, 300)
		detailsFramework:ApplyStandardBackdrop(promptFrame)
		table.insert(UISpecialFrames, "DetailsFrameworkPromptSimple")

		detailsFramework:CreateTitleBar(promptFrame, "Prompt!")
		detailsFramework:ApplyStandardBackdrop(promptFrame)

		local prompt = promptFrame:CreateFontString(nil, "overlay", "GameFontNormal")
		prompt:SetPoint("top", promptFrame, "top", 0, -28)
		prompt:SetJustifyH("center")
		promptFrame.prompt = prompt

		local button_text_template = detailsFramework:GetTemplate("font", "OPTIONS_FONT_TEMPLATE")
		local options_dropdown_template = detailsFramework:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE")

		local buttonTrue = detailsFramework:CreateButton(promptFrame, nil, 60, 20, "Yes", nil, nil, nil, nil, nil, nil, options_dropdown_template)
		buttonTrue:SetPoint("bottomright", promptFrame, "bottomright", -5, 5)
		promptFrame.button_true = buttonTrue

		local buttonFalse = detailsFramework:CreateButton(promptFrame, nil, 60, 20, "No", nil, nil, nil, nil, nil, nil, options_dropdown_template)
		buttonFalse:SetPoint("bottomleft", promptFrame, "bottomleft", 5, 5)
		promptFrame.button_false = buttonFalse

		buttonTrue:SetClickFunction(function()
			local my_func = buttonTrue.true_function
			if (my_func) then
				local okey, errormessage = pcall(my_func, true)
				if (not okey) then
					print("error:", errormessage)
				end
				promptFrame:Hide()
			end
		end)

		buttonFalse:SetClickFunction(function()
			local my_func = buttonFalse.false_function
			if (my_func) then
				local okey, errormessage = pcall(my_func, true)
				if (not okey) then
					print("error:", errormessage)
				end
				promptFrame:Hide()
			end
		end)

		promptFrame.ShowAnimation = detailsFramework:CreateAnimationHub(promptFrame, function()
			promptFrame:SetBackdropBorderColor(0, 0, 0, 0)
			promptFrame.TitleBar:SetBackdropBorderColor(0, 0, 0, 0)
		end,
		function()
			promptFrame:SetBackdropBorderColor(0, 0, 0, 1)
			promptFrame.TitleBar:SetBackdropBorderColor(0, 0, 0, 1)
		end)

		detailsFramework:CreateAnimation(promptFrame.ShowAnimation, "scale", 1, .075, .2, .2, 1.1, 1.1, "center", 0, 0)
		detailsFramework:CreateAnimation(promptFrame.ShowAnimation, "scale", 2, .075, 1, 1, .90, .90, "center", 0, 0)

		promptFrame.FlashTexture = promptFrame:CreateTexture(nil, "overlay")
		promptFrame.FlashTexture:SetColorTexture(1, 1, 1, 1)
		promptFrame.FlashTexture:SetAllPoints()

		promptFrame.FlashAnimation = detailsFramework:CreateAnimationHub(promptFrame.FlashTexture, function() promptFrame.FlashTexture:Show() end, function() promptFrame.FlashTexture:Hide() end)
		detailsFramework:CreateAnimation(promptFrame.FlashAnimation, "alpha", 1, .075, 0, .25)
		detailsFramework:CreateAnimation(promptFrame.FlashAnimation, "alpha", 2, .075, .35, 0)

		promptFrame:Hide()
		detailsFramework.promtp_panel = promptFrame
	end

	assert(type(trueCallback) == "function" and type(falseCallback) == "function", "ShowPromptPanel expects two functions.")

	if (dontOverride) then
		if (detailsFramework.promtp_panel:IsShown()) then
			return
		end
	end

	if (width) then
		detailsFramework.promtp_panel:SetWidth(width)
	else
		detailsFramework.promtp_panel:SetWidth(400)
	end

	detailsFramework.promtp_panel.promptName = promptName

	detailsFramework.promtp_panel.prompt:SetText(message)
	detailsFramework.promtp_panel.button_true.true_function = trueCallback
	detailsFramework.promtp_panel.button_false.false_function = falseCallback

	detailsFramework.promtp_panel:Show()

	detailsFramework.promtp_panel.ShowAnimation:Play()
	detailsFramework.promtp_panel.FlashAnimation:Play()
end


function detailsFramework:ShowTextPromptPanel(message, callback)
	if (not detailsFramework.text_prompt_panel) then
		local promptFrame = CreateFrame("frame", "DetailsFrameworkPrompt", UIParent, "BackdropTemplate")
		promptFrame:SetSize(400, 120)
		promptFrame:SetFrameStrata("FULLSCREEN")
		promptFrame:SetPoint("center", UIParent, "center", 0, 100)
		promptFrame:EnableMouse(true)
		promptFrame:SetMovable(true)
		promptFrame:RegisterForDrag ("LeftButton")
		promptFrame:SetScript("OnDragStart", function() promptFrame:StartMoving() end)
		promptFrame:SetScript("OnDragStop", function() promptFrame:StopMovingOrSizing() end)
		promptFrame:SetScript("OnMouseDown", function(self, button) if (button == "RightButton") then promptFrame.EntryBox:ClearFocus() promptFrame:Hide() end end)
		tinsert(UISpecialFrames, "DetailsFrameworkPrompt")

		detailsFramework:CreateTitleBar (promptFrame, "Prompt!")
		detailsFramework:ApplyStandardBackdrop(promptFrame)

		local prompt = promptFrame:CreateFontString(nil, "overlay", "GameFontNormal")
		prompt:SetPoint("top", promptFrame, "top", 0, -25)
		prompt:SetJustifyH("center")
		prompt:SetSize(360, 36)
		promptFrame.prompt = prompt

		local button_text_template = detailsFramework:GetTemplate("font", "OPTIONS_FONT_TEMPLATE")
		local options_dropdown_template = detailsFramework:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE")

		local textbox = detailsFramework:CreateTextEntry(promptFrame, function()end, 380, 20, "textbox", nil, nil, options_dropdown_template)
		textbox:SetPoint("topleft", promptFrame, "topleft", 10, -60)
		promptFrame.EntryBox = textbox

		local buttonTrue = detailsFramework:CreateButton(promptFrame, nil, 60, 20, "Okey", nil, nil, nil, nil, nil, nil, options_dropdown_template)
		buttonTrue:SetPoint("bottomright", promptFrame, "bottomright", -10, 5)
		promptFrame.button_true = buttonTrue

		local buttonFalse = detailsFramework:CreateButton(promptFrame, function() promptFrame.textbox:ClearFocus() promptFrame:Hide() end, 60, 20, "Cancel", nil, nil, nil, nil, nil, nil, options_dropdown_template)
		buttonFalse:SetPoint("bottomleft", promptFrame, "bottomleft", 10, 5)
		promptFrame.button_false = buttonFalse

		local executeCallback = function()
			local my_func = buttonTrue.true_function
			if (my_func) then
				local okey, errormessage = pcall(my_func, textbox:GetText())
				textbox:ClearFocus()
				if (not okey) then
					print("error:", errormessage)
				end
				promptFrame:Hide()
			end
		end

		buttonTrue:SetClickFunction(function()
			executeCallback()
		end)

		textbox:SetHook("OnEnterPressed", function()
			executeCallback()
		end)

		promptFrame:Hide()
		detailsFramework.text_prompt_panel = promptFrame
	end

	detailsFramework.text_prompt_panel:Show()
	DetailsFrameworkPrompt.EntryBox:SetText("")
	detailsFramework.text_prompt_panel.prompt:SetText(message)
	detailsFramework.text_prompt_panel.button_true.true_function = callback
	detailsFramework.text_prompt_panel.textbox:SetFocus(true)
end


------------------------------------------------------------------------------------------------------------------------------------------------
--chart panel -- ~chart

local chart_panel_backdrop = {bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16,
edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 32, insets = {left = 5, right = 5, top = 5, bottom = 5}}

local chart_panel_align_timelabels = function(self, elapsed_time)
	self.TimeScale = elapsed_time

	local linha = self.TimeLabels[17]
	local minutes, seconds = math.floor(elapsed_time / 60), math.floor(elapsed_time % 60)
	if (seconds < 10) then
		seconds = "0" .. seconds
	end

	if (minutes > 0) then
		if (minutes < 10) then
			minutes = "0" .. minutes
		end
		linha:SetText(minutes .. ":" .. seconds)
	else
		linha:SetText("00:" .. seconds)
	end

	local time_div = elapsed_time / 16 --786 -- 49.125

	for i = 2, 16 do
		local linha = self.TimeLabels [i]
		local this_time = time_div * (i-1)
		local minutes, seconds = math.floor(this_time / 60), math.floor(this_time % 60)

		if (seconds < 10) then
			seconds = "0" .. seconds
		end

		if (minutes > 0) then
			if (minutes < 10) then
				minutes = "0" .. minutes
			end
			linha:SetText(minutes .. ":" .. seconds)
		else
			linha:SetText("00:" .. seconds)
		end
	end
end

local chart_panel_set_scale = function(self, amt, func, text)
	if (type(amt) ~= "number") then
		return
	end

	--each line amount, then multiply the line index by this number
	local piece = amt / 8

	for i = 1, 8 do
		if (func) then
			self ["dpsamt" .. math.abs(i-9)]:SetText(func (piece*i))
		else
			if (piece*i > 1) then
				self ["dpsamt" .. math.abs(i-9)]:SetText(detailsFramework.FormatNumber (piece*i))
			else
				self ["dpsamt" .. math.abs(i-9)]:SetText(format("%.3f", piece*i))
			end
		end
	end
end

local chart_panel_can_move = function(self, can)
	self.can_move = can
end

local chart_panel_overlay_reset = function(self)
	self.OverlaysAmount = 1
	for index, pack in ipairs(self.Overlays) do
		for index2, texture in ipairs(pack) do
			texture:Hide()
		end
	end
end

local chart_panel_reset = function(self)
	self.Graphic:ResetData()
	self.Graphic.max_value = 0

	self.TimeScale = nil
	self.BoxLabelsAmount = 1
	table.wipe(self.GData)
	table.wipe(self.OData)

	for index, box in ipairs(self.BoxLabels) do
		box.check:Hide()
		box.button:Hide()
		box.box:Hide()
		box.text:Hide()
		box.border:Hide()
		box.showing = false
	end

	chart_panel_overlay_reset (self)
end

local chart_panel_enable_line = function(f, thisbox)
	local index = thisbox.index
	local boxType = thisbox.type

	if (thisbox.enabled) then
		--disable
		thisbox.check:Hide()
		thisbox.enabled = false
	else
		--enable
		thisbox.check:Show()
		thisbox.enabled = true
	end

	if (boxType == "graphic") then
		f.Graphic:ResetData()
		f.Graphic.max_value = 0

		local max = 0
		local max_time = 0

		for index, box in ipairs(f.BoxLabels) do
			if (box.type == boxType and box.showing and box.enabled) then
				local data = f.GData[index]

				f.Graphic:AddDataSeries(data[1], data[2], nil, data[3])

				if (data[4] > max) then
					max = data[4]
				end
				if (data [5] > max_time) then
					max_time = data [5]
				end
			end
		end

		f:SetScale(max)
		f:SetTime (max_time)

	elseif (boxType == "overlay") then
		chart_panel_overlay_reset (f)

		for index, box in ipairs(f.BoxLabels) do
			if (box.type == boxType and box.showing and box.enabled) then
				f:AddOverlay(box.index)
			end
		end
	end
end

local create_box = function(self, next_box)
	local thisbox = {}
	self.BoxLabels [next_box] = thisbox

	local box = detailsFramework:NewImage(self.Graphic, nil, 16, 16, "border")
	local text = detailsFramework:NewLabel(self.Graphic)

	local border = detailsFramework:NewImage(self.Graphic, [[Interface\DialogFrame\UI-DialogBox-Gold-Corner]], 30, 30, "artwork")
	border:SetPoint("center", box, "center", -3, -4)
	border:SetTexture([[Interface\DialogFrame\UI-DialogBox-Gold-Corner]])

	local checktexture = detailsFramework:NewImage(self.Graphic, [[Interface\Buttons\UI-CheckBox-Check]], 18, 18, "overlay")
	checktexture:SetPoint("center", box, "center", 0, -1)
	checktexture:SetTexture([[Interface\Buttons\UI-CheckBox-Check]])

	thisbox.box = box
	thisbox.text = text
	thisbox.border = border
	thisbox.check = checktexture
	thisbox.enabled = true

	local button = CreateFrame("button", nil, self.Graphic, "BackdropTemplate")
	button:SetSize(20, 20)
	button:SetScript("OnClick", function()
		chart_panel_enable_line (self, thisbox)
	end)
	button:SetPoint("topleft", box.widget or box, "topleft", 0, 0)
	button:SetPoint("bottomright", box.widget or box, "bottomright", 0, 0)

	button:SetBackdrop({edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1, bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true})
	button:SetBackdropColor(0, 0, 0, 0.0)
	button:SetBackdropBorderColor(0, 0, 0, 1)

	thisbox.button = button

	thisbox.box:SetPoint("right", text, "left", -4, 0)

	if (next_box == 1) then
		thisbox.text:SetPoint("topright", self, "topright", -35, -16)
	else
		thisbox.text:SetPoint("right", self.BoxLabels [next_box-1].box, "left", -17, 0)
	end

	return thisbox

end

local realign_labels = function(self)
	if (not self.ShowHeader) then
		for _, box in ipairs(self.BoxLabels) do
			box.check:Hide()
			box.button:Hide()
			box.border:Hide()
			box.box:Hide()
			box.text:Hide()
		end
		return
	end

	local width = self:GetWidth() - 108

	local first_box = self.BoxLabels [1]
	first_box.text:SetPoint("topright", self, "topright", -35, -16)

	local line_width = first_box.text:GetStringWidth() + 26

	for i = 2, #self.BoxLabels do

		local box = self.BoxLabels [i]

		if (box.box:IsShown()) then

			line_width = line_width + box.text:GetStringWidth() + 26

			if (line_width > width) then
				line_width = box.text:GetStringWidth() + 26
				box.text:SetPoint("topright", self, "topright", -35, -40)
			else
				box.text:SetPoint("right", self.BoxLabels [i-1].box, "left", -27, 0)
			end
		else
			break
		end
	end

	if (self.HeaderOnlyIndicator) then
		for _, box in ipairs(self.BoxLabels) do
				box.check:Hide()
			box.button:Hide()
		end
		return
	end
end

local chart_panel_add_label = function(self, color, name, type, number)
	local next_box = self.BoxLabelsAmount
	local thisbox = self.BoxLabels [next_box]

	if (not thisbox) then
		thisbox = create_box (self, next_box)
	end

	self.BoxLabelsAmount = self.BoxLabelsAmount + 1

	thisbox.type = type
	thisbox.index = number

	thisbox.box:SetColorTexture(unpack(color))
	thisbox.text:SetText(name)

	thisbox.check:Show()
	thisbox.button:Show()
	thisbox.border:Hide()
	thisbox.box:Show()
	thisbox.text:Show()

	thisbox.showing = true
	thisbox.enabled = true

	realign_labels(self)
end

local line_default_color = {1, 1, 1}
local draw_overlay = function(self, this_overlay, overlayData, color)

	local pixel = self.Graphic:GetWidth() / self.TimeScale
	local index = 1
	local r, g, b, a = unpack(color or line_default_color)

	for i = 1, #overlayData, 2 do
		local aura_start = overlayData [i]
		local aura_end = overlayData [i+1]

		local this_block = this_overlay [index]
		if (not this_block) then
			this_block = self.Graphic:CreateTexture(nil, "border")
			tinsert(this_overlay, this_block)
		end
		this_block:SetHeight(self.Graphic:GetHeight())

		this_block:SetPoint("left", self.Graphic, "left", pixel * aura_start, 0)
		if (aura_end) then
			this_block:SetWidth((aura_end-aura_start)*pixel)
		else
			--malformed table
			this_block:SetWidth(pixel*5)
		end

		this_block:SetColorTexture(r, g, b, a or 0.25)
		this_block:Show()

		index = index + 1
	end
end

local chart_panel_add_overlay = function(self, overlayData, color, name, icon)
	if (not self.TimeScale) then
		error("Use SetTime (time) before adding an overlay.")
	end

	if (type(overlayData) == "number") then
		local overlay_index = overlayData
		draw_overlay (self, self.Overlays [self.OverlaysAmount], self.OData [overlay_index][1], self.OData [overlay_index][2])
	else
		local this_overlay = self.Overlays [self.OverlaysAmount]
		if (not this_overlay) then
			this_overlay = {}
			tinsert(self.Overlays, this_overlay)
		end

		draw_overlay (self, this_overlay, overlayData, color)

		tinsert(self.OData, {overlayData, color or line_default_color})
		if (name and self.HeaderShowOverlays) then
			self:AddLabel (color or line_default_color, name, "overlay", #self.OData)
		end
	end

	self.OverlaysAmount = self.OverlaysAmount + 1
end

-- Define the tricube weight function
function calc_cubeweight (i, j, d)
    local w = ( 1 - math.abs((j-i)/d)^3)^3
    if w < 0 then
        w = 0
    end
    return w
end

local calc_lowess_smoothing = function(self, data, bandwidth)
	local length = #data
	local newData = {}

	for i = 1, length do
		local A = 0
		local B = 0
		local C = 0
		local D = 0
		local E = 0

		-- Calculate span of values to be included in the regression
		local jmin = floor(i-bandwidth/2)
		local jmax = ceil (i+bandwidth/2)
		if jmin < 1 then
			jmin = 1
		end
		if jmax > length then
			jmax = length
		end

		-- For all the values in the span, compute the weight and then the linear fit

		for j = jmin, jmax do
			w = calc_cubeweight (i, j, bandwidth/2)
			x = j
			y = data [j]

			A = A + w*x
			B = B + w*y
			C = C + w*x^2
			D = D + w*x*y
			E = E + w
		end

		-- Calculate a (slope) and b (offset) for the linear fit
		local a = (A*B-D*E)/(A^2 - C*E)
		local b = (A*D-B*C)/(A^2 - C*E)

		-- Calculate the smoothed value by the formula y=a*x+b (x <- i)
		newData [i] = a*i+b
	end
	return newData
end

local calc_stddev = function(self, data)
	local total = 0
	for i = 1, #data do
		total = total + data[i]
	end
	local mean = total / #data

	local totalDistance = 0
	for i = 1, #data do
		totalDistance = totalDistance + ((data[i] - mean) ^ 2)
	end

	local deviation = math.sqrt (totalDistance / #data)
	return deviation
end

local SMA_table = {}
local SMA_max = 0
local reset_SMA = function()
	table.wipe(SMA_table)
	SMA_max = 0
end

local calc_SMA
calc_SMA = function(a, b, ...)
	if (b) then
		return calc_SMA (a + b, ...)
	else
		return a
	end
end

local do_SMA = function(value, max_value)
	if (#SMA_table == 10) then
		tremove(SMA_table, 1)
	end

	SMA_table [#SMA_table + 1] = value

	local new_value = calc_SMA (unpack(SMA_table)) / #SMA_table

	if (new_value > SMA_max) then
		SMA_max = new_value
		return new_value, SMA_max
	else
		return new_value
	end
end

local chart_panel_onresize = function(self)
	local width, height = self:GetSize()
	local spacement = width - 78 - 60
	spacement = spacement / 16

	for i = 1, 17 do
		local label = self.TimeLabels [i]
		label:SetPoint("bottomleft", self, "bottomleft", 78 + ((i-1)*spacement), self.TimeLabelsHeight)
		label.line:SetHeight(height - 45)
	end

	local spacement = (self.Graphic:GetHeight()) / 8
	for i = 1, 8 do
		self ["dpsamt"..i]:SetPoint("TOPLEFT", self, "TOPLEFT", 27, -25 + (-(spacement* (i-1))) )
		self ["dpsamt"..i].line:SetWidth(width-20)
	end

	self.Graphic:SetSize(width - 135, height - 67)
	self.Graphic:SetPoint("topleft", self, "topleft", 108, -35)
end

local chart_panel_add_data = function(self, graphicData, color, name, elapsedTime, lineTexture, smoothLevel, firstIndex)
	local chartPanel = self --chartPanel from the framework CreateChartPanel
	local LibGraphChartFrame = self.Graphic

	local builtData = {}
	local maxValue = graphicData.max_value
	local scaleWidth = 1 / LibGraphChartFrame:GetWidth()
	local content = graphicData

	--smooth the start and end of the chart
	tinsert(content, 1, 0)
	tinsert(content, 1, 0)
	tinsert(content, #content+1, 0)
	tinsert(content, #content+1, 0)

	local index = 3
	local graphMaxDps = math.max(LibGraphChartFrame.max_value, maxValue)

	--do smoothness progress
	if (not smoothLevel) then
		while (index <= #content-2) do
			local value = (content[index-2] + content[index-1] + content[index] + content[index+1] + content[index+2]) / 5 --normalize
			builtData[#builtData+1] = {scaleWidth * (index-2), value / graphMaxDps} -- x and y coords
			index = index + 1
		end

	elseif (smoothLevel == "SHORT") then
		while (index <= #content-2) do
			local value = (content[index] + content[index+1]) / 2
			builtData [#builtData+1] = {scaleWidth*(index-2), value}
			builtData [#builtData+1] = {scaleWidth*(index-2), value}
			index = index + 2
		end

	elseif (smoothLevel == "SMA") then
		reset_SMA()
		while (index <= #content-2) do
			local value, is_new_max_value = do_SMA(content[index], maxValue)
			if (is_new_max_value) then
				maxValue = is_new_max_value
			end
			builtData [#builtData+1] = {scaleWidth * (index-2), value} -- x and y coords
			index = index + 1
		end

	elseif (smoothLevel == -1) then
		while (index <= #content-2) do
			local current = content[index]

			local minus_2 = content[index-2] * 0.6
			local minus_1 = content[index-1] * 0.8
			local plus_1 = content[index+1] * 0.8
			local plus_2 = content[index+2] * 0.6

			local value = (current + minus_2 + minus_1 + plus_1 + plus_2) / 5 --normalize
			builtData [#builtData+1] = {scaleWidth * (index-2), value / graphMaxDps} -- x and y coords
			index = index + 1
		end

	elseif (smoothLevel == 1) then
		index = 2
		while (index <= #content-1) do
			local value = (content[index-1]+content[index]+content[index+1])/3 --normalize
			builtData [#builtData+1] = {scaleWidth*(index-1), value/graphMaxDps} -- x and y coords
			index = index + 1
		end

	elseif (smoothLevel == 2) then
		index = 1
		while (index <= #content) do
			local value = content[index] --do not normalize
			builtData [#builtData+1] = {scaleWidth*(index), value/graphMaxDps} -- x and y coords
			index = index + 1
		end
	end

	tremove(content, 1)
	tremove(content, 1)
	tremove(content, #graphicData)
	tremove(content, #graphicData)

	if (maxValue > LibGraphChartFrame.max_value) then
		--normalize previous data
		if (LibGraphChartFrame.max_value > 0) then
			local normalizePercent = LibGraphChartFrame.max_value / maxValue
			for dataIndex, Data in ipairs(LibGraphChartFrame.Data) do
				local Points = Data.Points
				for i = 1, #Points do
					Points[i][2] = Points[i][2] * normalizePercent
				end
			end
		end

		LibGraphChartFrame.max_value = maxValue
		chartPanel:SetScale(maxValue)
	end

	tinsert(chartPanel.GData, {builtData, color or line_default_color, lineTexture, maxValue, elapsedTime})
	if (name) then
		chartPanel:AddLabel(color or line_default_color, name, "graphic", #chartPanel.GData)
	end

	local newLineTexture = "Interface\\AddOns\\Details\\Libs\\LibGraph-2.0\\line"

	if (firstIndex) then
		table.insert(LibGraphChartFrame.Data, 1, {Points = builtData, Color = color or line_default_color, lineTexture = newLineTexture, ElapsedTime = elapsedTime})
		LibGraphChartFrame.NeedsUpdate = true
	else
		LibGraphChartFrame:AddDataSeries(builtData, color or line_default_color, nil, newLineTexture)
		LibGraphChartFrame.Data[#LibGraphChartFrame.Data].ElapsedTime = elapsedTime
	end

	local maxTime = 0
	for _, data in ipairs(LibGraphChartFrame.Data) do
		if (data.ElapsedTime > maxTime) then
			maxTime = data.ElapsedTime
		end
	end

	chartPanel:SetTime(maxTime)
	chart_panel_onresize(chartPanel)
end


local chart_panel_vlines_on = function(self)
	for i = 1, 17 do
		local label = self.TimeLabels[i]
		label.line:Show()
	end
end

local chart_panel_vlines_off = function(self)
	for i = 1, 17 do
		local label = self.TimeLabels[i]
		label.line:Hide()
	end
end

local chart_panel_set_title = function(self, title)
	self.chart_title.text = title
end

local chart_panel_mousedown = function(self, button)
	if (button == "LeftButton" and self.can_move) then
		if (not self.isMoving) then
			self:StartMoving()
			self.isMoving = true
		end
	elseif (button == "RightButton" and not self.no_right_click_close) then
		if (not self.isMoving) then
			self:Hide()
		end
	end
end

local chart_panel_mouseup = function(self, button)
	if (button == "LeftButton" and self.isMoving) then
		self:StopMovingOrSizing()
		self.isMoving = nil
	end
end

local chart_panel_hide_close_button = function(self)
	self.CloseButton:Hide()
end

local chart_panel_right_click_close = function(self, value)
	if (type(value) == "boolean") then
		if (value) then
			self.no_right_click_close = nil
		else
			self.no_right_click_close = true
		end
	end
end

function detailsFramework:CreateChartPanel(parent, width, height, name)
	if (not name) then
		name = "DFPanel" .. detailsFramework.PanelCounter
		detailsFramework.PanelCounter = detailsFramework.PanelCounter + 1
	end

	parent = parent or UIParent
	width = width or 800
	height = height or 500

	local chartFrame = CreateFrame("frame", name, parent, "BackdropTemplate")
	chartFrame:SetSize(width or 500, height or 400)
	chartFrame:EnableMouse(true)
	chartFrame:SetMovable(true)

	chartFrame:SetScript("OnMouseDown", chart_panel_mousedown)
	chartFrame:SetScript("OnMouseUp", chart_panel_mouseup)

	chartFrame:SetBackdrop(chart_panel_backdrop)
	chartFrame:SetBackdropColor(.3, .3, .3, .3)

	local closeButton = CreateFrame("Button", nil, chartFrame, "UIPanelCloseButton", "BackdropTemplate")
	closeButton:SetWidth(32)
	closeButton:SetHeight(32)
	closeButton:SetPoint("TOPRIGHT",  chartFrame, "TOPRIGHT", -3, -7)
	closeButton:SetFrameLevel(chartFrame:GetFrameLevel()+1)
	closeButton:SetAlpha(0.9)
	chartFrame.CloseButton = closeButton

	local title = detailsFramework:NewLabel(chartFrame, nil, "$parentTitle", "chart_title", "Chart!", nil, 20, {1, 1, 0})
	title:SetPoint("topleft", chartFrame, "topleft", 110, -13)

	chartFrame.Overlays = {}
	chartFrame.OverlaysAmount = 1

	chartFrame.BoxLabels = {}
	chartFrame.BoxLabelsAmount = 1

	chartFrame.ShowHeader = true
	chartFrame.HeaderOnlyIndicator = false
	chartFrame.HeaderShowOverlays = true

	--graphic
		local g = LibStub:GetLibrary("LibGraph-2.0"):CreateGraphLine (name .. "Graphic", chartFrame, "topleft","topleft", 108, -35, width - 120, height - 67)
		g:SetXAxis (-1,1)
		g:SetYAxis (-1,1)
		g:SetGridSpacing (false, false)
		g:SetGridColor ({0.5,0.5,0.5,0.3})
		g:SetAxisDrawing (false,false)
		g:SetAxisColor({1.0,1.0,1.0,1.0})
		g:SetAutoScale (true)
		g:SetLineTexture ("smallline")
		g:SetBorderSize ("right", 0.001)
		g:SetBorderSize ("left", 0.000)
		g:SetBorderSize ("top", 0.002)
		g:SetBorderSize ("bottom", 0.001)
		g.VerticalLines = {}
		g.max_value = 0

		g:SetLineTexture ("line")

		chartFrame.Graphic = g
		chartFrame.GData = {}
		chartFrame.OData = {}
		chartFrame.ChartFrames = {}

	--div lines
		for i = 1, 8, 1 do
			local line = g:CreateTexture(nil, "overlay")
			line:SetColorTexture(1, 1, 1, .05)
			line:SetWidth(670)
			line:SetHeight(1.1)

			local s = chartFrame:CreateFontString(nil, "overlay", "GameFontHighlightSmall")
			chartFrame ["dpsamt"..i] = s
			s:SetText("100k")
			s:SetPoint("topleft", chartFrame, "topleft", 27, -61 + (-(24.6*i)))

			line:SetPoint("topleft", s, "bottom", -27, 0)
			line:SetPoint("topright", g, "right", 0, 0)
			s.line = line
		end

	--create time labels and the bottom texture to use as a background to these labels
		chartFrame.TimeLabels = {}
		chartFrame.TimeLabelsHeight = 16

		for i = 1, 17 do
			local timeString = chartFrame:CreateFontString(nil, "overlay", "GameFontHighlightSmall")
			timeString:SetText("00:00")
			timeString:SetPoint("bottomleft", chartFrame, "bottomleft", 78 + ((i-1)*36), chartFrame.TimeLabelsHeight)
			chartFrame.TimeLabels [i] = timeString

			local line = chartFrame:CreateTexture(nil, "border")
			line:SetSize(1, height-45)
			line:SetColorTexture(1, 1, 1, .1)
			line:SetPoint("bottomleft", timeString, "topright", 0, -10)
			line:Hide()
			timeString.line = line
		end

		local bottom_texture = detailsFramework:NewImage(chartFrame, nil, 702, 25, "background", nil, nil, "$parentBottomTexture")
		bottom_texture:SetColorTexture(.1, .1, .1, .7)
		bottom_texture:SetPoint("topright", g, "bottomright", 0, 0)
		bottom_texture:SetPoint("bottomleft", chartFrame, "bottomleft", 8, 12)



	chartFrame.SetTime = chart_panel_align_timelabels
	chartFrame.EnableVerticalLines = chart_panel_vlines_on
	chartFrame.DisableVerticalLines = chart_panel_vlines_off
	chartFrame.SetTitle = chart_panel_set_title
	chartFrame.SetScale = chart_panel_set_scale
	chartFrame.Reset = chart_panel_reset
	chartFrame.AddLine = chart_panel_add_data
	chartFrame.CanMove = chart_panel_can_move
	chartFrame.AddLabel = chart_panel_add_label
	chartFrame.AddOverlay = chart_panel_add_overlay
	chartFrame.HideCloseButton = chart_panel_hide_close_button
	chartFrame.RightClickClose = chart_panel_right_click_close
	chartFrame.CalcStdDev = calc_stddev
	chartFrame.CalcLowessSmoothing = calc_lowess_smoothing

	chartFrame:SetScript("OnSizeChanged", chart_panel_onresize)
	chart_panel_onresize(chartFrame)

	return chartFrame
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ~gframe
local gframe_on_enter_line = function(self)
	self:SetBackdropColor(0, 0, 0, 0)

	local parent = self:GetParent()
	local ball = self.ball
	ball:SetBlendMode("ADD")

	local on_enter = parent._onenter_line
	if (on_enter) then
		return on_enter (self, parent)
	end
end

local gframe_on_leave_line = function(self)
	self:SetBackdropColor(0, 0, 0, .6)

	local parent = self:GetParent()
	local ball = self.ball
	ball:SetBlendMode("BLEND")

	local on_leave = parent._onleave_line
	if (on_leave) then
		return on_leave (self, parent)
	end
end

local gframe_create_line = function(self)
	local index = #self._lines+1

	local f = CreateFrame("frame", nil, self, "BackdropTemplate")
	self._lines [index] = f
	f.id = index
	f:SetScript("OnEnter", gframe_on_enter_line)
	f:SetScript("OnLeave", gframe_on_leave_line)

	f:SetWidth(self._linewidth)

	if (index == 1) then
		f:SetPoint("topleft", self, "topleft")
		f:SetPoint("bottomleft", self, "bottomleft")
	else
		local previous_line = self._lines [index-1]
		f:SetPoint("topleft", previous_line, "topright")
		f:SetPoint("bottomleft", previous_line, "bottomright")
	end

	local t = f:CreateTexture(nil, "background")
	t:SetWidth(1)
	t:SetPoint("topright", f, "topright")
	t:SetPoint("bottomright", f, "bottomright")
	t:SetColorTexture(1, 1, 1, .1)
	f.grid = t

	local b = f:CreateTexture(nil, "overlay")
	b:SetTexture([[Interface\COMMON\Indicator-Yellow]])
	b:SetSize(16, 16)
	f.ball = b
	local anchor = CreateFrame("frame", nil, f, "BackdropTemplate")
	anchor:SetAllPoints(b)
	b.tooltip_anchor = anchor

	local spellicon = f:CreateTexture(nil, "artwork")
	spellicon:SetPoint("bottom", b, "bottom", 0, 10)
	spellicon:SetSize(16, 16)
	f.spellicon = spellicon

	local text = f:CreateFontString(nil, "overlay", "GameFontNormal")
	local textBackground = f:CreateTexture(nil, "artwork")
	textBackground:SetSize(30, 16)
	textBackground:SetColorTexture(0, 0, 0, 0.5)
	textBackground:SetPoint("bottom", f.ball, "top", 0, -6)
	text:SetPoint("center", textBackground, "center")
	detailsFramework:SetFontSize(text, 10)
	f.text = text
	f.textBackground = textBackground

	local timeline = f:CreateFontString(nil, "overlay", "GameFontNormal")
	timeline:SetPoint("bottomright", f, "bottomright", -2, 0)
	detailsFramework:SetFontSize(timeline, 8)
	f.timeline = timeline

	return f
end

local gframe_getline = function(self, index)
	local line = self._lines [index]
	if (not line) then
		line = gframe_create_line (self)
	end
	return line
end

local gframe_reset = function(self)
	for i, line in ipairs(self._lines) do
		line:Hide()
	end
	if (self.GraphLib_Lines_Used) then
		for i = #self.GraphLib_Lines_Used, 1, -1 do
			local line = tremove(self.GraphLib_Lines_Used)
			tinsert(self.GraphLib_Lines, line)
			line:Hide()
		end
	end
end

local gframe_update = function(self, lines)
	local g = LibStub:GetLibrary ("LibGraph-2.0")
	local h = self:GetHeight()/100
	local amtlines = #lines
	local linewidth = self._linewidth

	local max_value = 0
	for i = 1, amtlines do
		if (lines [i].value > max_value) then
			max_value = lines [i].value
		end
	end

	self.MaxValue = max_value

	local o = 1
	local lastvalue = self:GetHeight()/2
	max_value = math.max(max_value, 0.0000001)

	for i = 1, min (amtlines, self._maxlines) do

		local data = lines [i]

		local pvalue = data.value / max_value * 100
		if (pvalue > 98) then
			pvalue = 98
		end
		pvalue = pvalue * h

		g:DrawLine (self, (o-1)*linewidth, lastvalue, o*linewidth, pvalue, linewidth, {1, 1, 1, 1}, "overlay")
		lastvalue = pvalue

		local line = self:GetLine (i)
		line:Show()
		line.ball:Show()

		line.ball:SetPoint("bottomleft", self, "bottomleft", (o*linewidth)-8, pvalue-8)
		line.spellicon:SetTexture(nil)
		line.timeline:SetText(data.text)
		line.timeline:Show()

		if (data.utext) then
			line.text:Show()
			line.textBackground:Show()
			line.text:SetText(data.utext)
		else
			line.text:Hide()
			line.textBackground:Hide()
		end

		line.data = data

		o = o + 1
	end
end

function detailsFramework:CreateGFrame(parent, width, height, lineWidth, onEnter, onLeave, member, name)
	local newGraphicFrame = CreateFrame("frame", name, parent, "BackdropTemplate")
	newGraphicFrame:SetSize(width or 450, height or 150)

	if (member) then
		parent[member] = newGraphicFrame
	end

	newGraphicFrame.CreateLine = gframe_create_line
	newGraphicFrame.GetLine = gframe_getline
	newGraphicFrame.Reset = gframe_reset
	newGraphicFrame.UpdateLines = gframe_update

	newGraphicFrame.MaxValue = 0

	newGraphicFrame._lines = {}

	newGraphicFrame._onenter_line = onEnter
	newGraphicFrame._onleave_line = onLeave

	newGraphicFrame._linewidth = lineWidth or 50
	newGraphicFrame._maxlines = floor(newGraphicFrame:GetWidth() / newGraphicFrame._linewidth)

	return newGraphicFrame
end


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--options tabs and buttons -dot

function detailsFramework:FindHighestParent(self)
	local highestParent
	if (self:GetParent() == UIParent) then
		highestParent = self
	end

	if (not highestParent) then
		highestParent = self
		for i = 1, 6 do
			local parent = highestParent:GetParent()
			if (parent == UIParent) then
				break
			else
				highestParent = parent
			end
		end
	end

	return highestParent
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ~right ~click to ~close

function detailsFramework:CreateRightClickToClose(parent, xOffset, yOffset, color, fontSize)
	--default values
	xOffset = xOffset or 0
	yOffset = yOffset or 0
	color = color or "white"
	fontSize = fontSize or 10

	local label = detailsFramework:CreateLabel(parent, "right click to close", fontSize, color)
	label:SetPoint("bottomright", parent, "bottomright", -4 + xOffset, 5 + yOffset)

	return label
end


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ~listbox

local simple_list_box_ResetWidgets = function(self)
	for _, widget in ipairs(self.widgets) do
		widget:Hide()
	end
	self.nextWidget = 1
end

local simple_list_box_onenter = function(self, capsule)
	self:GetParent().options.onenter (self, capsule, capsule.value)
end

local simple_list_box_onleave = function(self, capsule)
	self:GetParent().options.onleave (self, capsule, capsule.value)
	GameTooltip:Hide()
end

local simple_list_box_GetOrCreateWidget = function(self)
	local index = self.nextWidget
	local widget = self.widgets [index]
	if (not widget) then
		widget = detailsFramework:CreateButton(self, function()end, self.options.width, self.options.row_height, "", nil, nil, nil, nil, nil, nil, detailsFramework:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"))
		widget:SetHook("OnEnter", simple_list_box_onenter)
		widget:SetHook("OnLeave", simple_list_box_onleave)
		widget.textcolor = self.options.textcolor
		widget.textsize = self.options.text_size
		widget.onleave_backdrop = self.options.backdrop_color

		widget.XButton = detailsFramework:CreateButton(widget, function()end, 16, 16)
		widget.XButton:SetPoint("topright", widget.widget, "topright")
		widget.XButton:SetIcon ([[Interface\BUTTONS\UI-Panel-MinimizeButton-Up]], 16, 16, "overlay", nil, nil, 0, -4, 0, false)
		widget.XButton.icon:SetDesaturated(true)

		if (not self.options.show_x_button) then
			widget.XButton:Hide()
		end

		tinsert(self.widgets, widget)
	end
	self.nextWidget = self.nextWidget + 1
	return widget
end

local simple_list_box_RefreshWidgets = function(self)
	self:ResetWidgets()
	local amt = 0
	for value, _ in pairs(self.list_table) do
		local widget = self:GetOrCreateWidget()
		widget:SetPoint("topleft", self, "topleft", 1, -self.options.row_height * (self.nextWidget-2) - 4)
		widget:SetPoint("topright", self, "topright", -1, -self.options.row_height * (self.nextWidget-2) - 4)

		widget:SetClickFunction(self.func, value)

		if (self.options.show_x_button) then
			widget.XButton:SetClickFunction(self.options.x_button_func, value)
			widget.XButton.value = value
			widget.XButton:Show()
		else
			widget.XButton:Hide()
		end

		widget.value = value

		if (self.options.icon) then
			if (type(self.options.icon) == "string" or type(self.options.icon) == "number") then
				local coords = type(self.options.iconcoords) == "table" and self.options.iconcoords or {0, 1, 0, 1}
				widget:SetIcon (self.options.icon, self.options.row_height - 2, self.options.row_height - 2, "overlay", coords)

			elseif (type(self.options.icon) == "function") then
				local icon = self.options.icon (value)
				if (icon) then
					local coords = type(self.options.iconcoords) == "table" and self.options.iconcoords or {0, 1, 0, 1}
					widget:SetIcon (icon, self.options.row_height - 2, self.options.row_height - 2, "overlay", coords)
				end
			end
		else
			widget:SetIcon ("", self.options.row_height, self.options.row_height)
		end

		if (self.options.text) then
			if (type(self.options.text) == "function") then
				local text = self.options.text (value)
				if (text) then
					widget:SetText(text)
				else
					widget:SetText("")
				end
			else
				widget:SetText(self.options.text or "")
			end
		else
			widget:SetText("")
		end

		widget.value = value

		local r, g, b, a = detailsFramework:ParseColors(self.options.backdrop_color)
		widget:SetBackdropColor(r, g, b, a)

		widget:Show()
		amt = amt + 1
	end
	if (amt == 0) then
		self.EmptyLabel:Show()
	else
		self.EmptyLabel:Hide()
	end
end

local backdrop = {bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16, edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1}
local default_options = {
	height = 400,
	row_height = 16,
	width = 230,
	icon = false,
	text = "",
	text_size = 10,
	textcolor = "wheat",

	backdrop_color = {1, 1, 1, .5},
	panel_border_color = {0, 0, 0, 0.5},

	onenter = function(self, capsule)
		if (capsule) then
			capsule.textcolor = "white"
		end
	end,
	onleave = function(self, capsule)
		if (capsule) then
			capsule.textcolor = self:GetParent().options.textcolor
		end
		GameTooltip:Hide()
	end,
}

local simple_list_box_SetData = function(self, t)
	self.list_table = t
end

function detailsFramework:CreateSimpleListBox(parent, name, title, emptyText, listTable, onClick, options)
	local scroll = CreateFrame("frame", name, parent, "BackdropTemplate")

	scroll.ResetWidgets = simple_list_box_ResetWidgets
	scroll.GetOrCreateWidget = simple_list_box_GetOrCreateWidget
	scroll.Refresh = simple_list_box_RefreshWidgets
	scroll.SetData = simple_list_box_SetData
	scroll.nextWidget = 1
	scroll.list_table = listTable

	scroll.func = function(self, button, value)
		detailsFramework:QuickDispatch(onClick, value)
		scroll:Refresh()
	end
	scroll.widgets = {}

	detailsFramework:ApplyStandardBackdrop(scroll)

	scroll.options = options or {}
	self.table.deploy(scroll.options, default_options)

	if (scroll.options.x_button_func) then
		local original_X_function = scroll.options.x_button_func
		scroll.options.x_button_func = function(self, button, value)
			detailsFramework:QuickDispatch(original_X_function, value)
			scroll:Refresh()
		end
	end

	scroll:SetBackdropBorderColor(unpack(scroll.options.panel_border_color))

	scroll:SetSize(scroll.options.width + 2, scroll.options.height)

	local name = detailsFramework:CreateLabel(scroll, title, 12, "silver")
	name:SetTemplate(detailsFramework:GetTemplate("font", "OPTIONS_FONT_TEMPLATE"))
	name:SetPoint("bottomleft", scroll, "topleft", 0, 2)
	scroll.Title = name

	local emptyLabel = detailsFramework:CreateLabel(scroll, emptyText, 12, "gray")
	emptyLabel:SetAlpha(.6)
	emptyLabel:SetSize(scroll.options.width-10, scroll.options.height)
	emptyLabel:SetPoint("center", 0, 0)
	emptyLabel:Hide()
	emptyLabel.align = "center"
	scroll.EmptyLabel = emptyLabel

	return scroll
end


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ~scrollbox

---create a scrollbox with the methods :Refresh() :SetData() :CreateLine()
---@param parent table
---@param name string
---@param refreshFunc function
---@param data table
---@param width number
---@param height number
---@param lineAmount number
---@param lineHeight number
---@param createLineFunc function|nil
---@param autoAmount boolean|nil
---@param noScroll boolean|nil
---@return table
function detailsFramework:CreateScrollBox(parent, name, refreshFunc, data, width, height, lineAmount, lineHeight, createLineFunc, autoAmount, noScroll)
	--create the scrollframe, it is the base of the scrollbox
	local scroll = CreateFrame("scrollframe", name, parent, "FauxScrollFrameTemplate, BackdropTemplate")

	--apply the standard background color
	detailsFramework:ApplyStandardBackdrop(scroll)

	scroll:SetSize(width, height)
	scroll.LineAmount = lineAmount
	scroll.LineHeight = lineHeight
	scroll.IsFauxScroll = true
	scroll.HideScrollBar = noScroll
	scroll.Frames = {}
	scroll.ReajustNumFrames = autoAmount
	scroll.CreateLineFunc = createLineFunc
	scroll.DontHideChildrenOnPreRefresh = false

	detailsFramework:Mixin(scroll, detailsFramework.SortFunctions)
	detailsFramework:Mixin(scroll, detailsFramework.ScrollBoxFunctions)

	scroll.refresh_func = refreshFunc
	scroll.data = data

	scroll:SetScript("OnVerticalScroll", scroll.OnVerticalScroll)
	scroll:SetScript("OnSizeChanged", detailsFramework.ScrollBoxFunctions.OnSizeChanged)

	return scroll
end


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ~resizers

--these options are copied to the object with object:BuildOptionsTable()
local rezieGripOptions = {
	width = 32,
	height = 32,
	should_mirror_left_texture = true,
	normal_texture = [[Interface\CHATFRAME\UI-ChatIM-SizeGrabber-Up]],
	highlight_texture = [[Interface\CHATFRAME\UI-ChatIM-SizeGrabber-Highlight]],
	pushed_texture = [[Interface\CHATFRAME\UI-ChatIM-SizeGrabber-Down]],
}

---create the two resize grips for a frame, one in the bottom left and another in the bottom right
---@param parent frame
---@param options table|nil
---@param leftResizerName string|nil
---@param rightResizerName string|nil
---@return frame, frame
function detailsFramework:CreateResizeGrips(parent, options, leftResizerName, rightResizerName)
	local parentName = parent:GetName()

	local leftResizer = _G.CreateFrame("button", leftResizerName or (parentName and "$parentLeftResizer"), parent, "BackdropTemplate")
	local rightResizer = _G.CreateFrame("button", rightResizerName or (parentName and "$parentRightResizer"), parent, "BackdropTemplate")

	detailsFramework:Mixin(leftResizer, detailsFramework.OptionsFunctions)
	detailsFramework:Mixin(rightResizer, detailsFramework.OptionsFunctions)
	leftResizer:BuildOptionsTable(rezieGripOptions, options)
	rightResizer:BuildOptionsTable(rezieGripOptions, options)

	leftResizer:SetPoint("bottomleft", parent, "bottomleft", 0, 0)
	rightResizer:SetPoint("bottomright", parent, "bottomright", 0, 0)
	leftResizer:SetSize(leftResizer.options.width, leftResizer.options.height)
	rightResizer:SetSize(leftResizer.options.width, leftResizer.options.height)

	rightResizer:SetNormalTexture(rightResizer.options.normal_texture)
	rightResizer:SetHighlightTexture(rightResizer.options.highlight_texture)
	rightResizer:SetPushedTexture(rightResizer.options.pushed_texture)

	leftResizer:SetNormalTexture(leftResizer.options.normal_texture)
	leftResizer:SetHighlightTexture(leftResizer.options.highlight_texture)
	leftResizer:SetPushedTexture(leftResizer.options.pushed_texture)

	if (leftResizer.options.should_mirror_left_texture) then
		leftResizer:GetNormalTexture():SetTexCoord(1, 0, 0, 1)
		leftResizer:GetHighlightTexture():SetTexCoord(1, 0, 0, 1)
		leftResizer:GetPushedTexture():SetTexCoord(1, 0, 0, 1)
	end

	return leftResizer, rightResizer
end


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ~keybind


--------------------------------
--keybind frame ~key


local ignoredKeys = {
	["LSHIFT"] = true,
	["RSHIFT"] = true,
	["LCTRL"] = true,
	["RCTRL"] = true,
	["LALT"] = true,
	["RALT"] = true,
	["UNKNOWN"] = true,
}

local mouseKeys = {
	["LeftButton"] = "type1",
	["RightButton"] = "type2",
	["MiddleButton"] = "type3",
	["Button4"] = "type4",
	["Button5"] = "type5",
	["Button6"] = "type6",
	["Button7"] = "type7",
	["Button8"] = "type8",
	["Button9"] = "type9",
	["Button10"] = "type10",
	["Button11"] = "type11",
	["Button12"] = "type12",
	["Button13"] = "type13",
	["Button14"] = "type14",
	["Button15"] = "type15",
	["Button16"] = "type16",
}

local keysToMouse = {
	["type1"] = "LeftButton",
	["type2"] = "RightButton",
	["type3"] = "MiddleButton",
	["type4"] = "Button4",
	["type5"] = "Button5",
	["type6"] = "Button6",
	["type7"] = "Button7",
	["type8"] = "Button8",
	["type9"] = "Button9",
	["type10"] = "Button10",
	["type11"] = "Button11",
	["type12"] = "Button12",
	["type13"] = "Button13",
	["type14"] = "Button14",
	["type15"] = "Button15",
	["type16"] = "Button16",
}

local keybind_set_data = function(self, new_data_table)
	self.Data = new_data_table
	self.keybindScroll:UpdateScroll()
end

function detailsFramework:CreateKeybindBox (parent, name, data, callback, width, height, line_amount, line_height)

	local options_text_template = detailsFramework:GetTemplate("font", "OPTIONS_FONT_TEMPLATE")
	local options_dropdown_template = detailsFramework:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE")
	local options_switch_template = detailsFramework:GetTemplate("switch", "OPTIONS_CHECKBOX_TEMPLATE")
	local options_slider_template = detailsFramework:GetTemplate("slider", "OPTIONS_SLIDER_TEMPLATE")
	local options_button_template = detailsFramework:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE")

	local SCROLL_ROLL_AMOUNT = line_amount

	--keybind set frame
	local new_keybind_frame = CreateFrame("frame", name, parent, "BackdropTemplate")
	new_keybind_frame:SetSize(width, height)

	-- keybind scrollframe
	local keybindScroll = CreateFrame("scrollframe", "$parentScrollFrame", new_keybind_frame, "FauxScrollFrameTemplate, BackdropTemplate")
	keybindScroll:SetSize(1019, 348)
	keybindScroll.Frames = {}
	new_keybind_frame.keybindScroll = keybindScroll

	--waiting the player to press a key
	new_keybind_frame.IsListening = false

	--check for valid data table
	if (type(data) ~= "table") then
		print("error: data must be a table. DF > CreateKeybindBox()")
		return
	end

	if (not next (data)) then
		--build data table for the character class
		local _, unitClass = UnitClass("player")
		if (unitClass) then
			local specIds = detailsFramework:GetClassSpecIDs(unitClass)
			if (specIds) then
				for _, specId in ipairs(specIds) do
					data [specId] = {}
				end
			end
		end
	end

	new_keybind_frame.Data = data
	new_keybind_frame.SetData = keybind_set_data

	new_keybind_frame.EditingSpec = detailsFramework:GetCurrentSpec()
	new_keybind_frame.CurrentKeybindEditingSet = new_keybind_frame.Data [new_keybind_frame.EditingSpec]

	local allSpecButtons = {}
	local switch_spec = function(self, button, specID)
		new_keybind_frame.EditingSpec = specID
		new_keybind_frame.CurrentKeybindEditingSet = new_keybind_frame.Data [specID]

		for _, button in ipairs(allSpecButtons) do
			button.selectedTexture:Hide()
		end
		self.MyObject.selectedTexture:Show()

		--feedback ao jogador uma vez que as keybinds podem ter o mesmo valor
		C_Timer.After(.04, function() new_keybind_frame:Hide() end)
		C_Timer.After(.06, function() new_keybind_frame:Show() end)

		--atualiza a scroll
		keybindScroll:UpdateScroll()
	end

	--choose which spec to use
	local spec1 = detailsFramework:CreateButton(new_keybind_frame, switch_spec, 160, 20, "Spec1 Placeholder Text", 1, _, _, "SpecButton1", _, 0, options_button_template, options_text_template)
	local spec2 = detailsFramework:CreateButton(new_keybind_frame, switch_spec, 160, 20, "Spec2 Placeholder Text", 1, _, _, "SpecButton2", _, 0, options_button_template, options_text_template)
	local spec3 = detailsFramework:CreateButton(new_keybind_frame, switch_spec, 160, 20, "Spec3 Placeholder Text", 1, _, _, "SpecButton3", _, 0, options_button_template, options_text_template)
	local spec4 = detailsFramework:CreateButton(new_keybind_frame, switch_spec, 160, 20, "Spec4 Placeholder Text", 1, _, _, "SpecButton4", _, 0, options_button_template, options_text_template)

	--format the button label and icon with the spec information
	local className, class = UnitClass("player")
	local i = 1
	local specIds = detailsFramework:GetClassSpecIDs(class)

	for index, specId in ipairs(specIds) do
		local button = new_keybind_frame ["SpecButton" .. index]
		local spec_id, spec_name, spec_description, spec_icon, spec_background, spec_role, spec_class = DetailsFramework.GetSpecializationInfoByID (specId)
		button.text = spec_name
		button:SetClickFunction(switch_spec, specId)
		button:SetIcon (spec_icon)
		button.specID = specId

		local selectedTexture = button:CreateTexture(nil, "background")
		selectedTexture:SetAllPoints()
		selectedTexture:SetColorTexture(1, 1, 1, 0.5)
		if (specId ~= new_keybind_frame.EditingSpec) then
			selectedTexture:Hide()
		end
		button.selectedTexture = selectedTexture

		tinsert(allSpecButtons, button)
		i = i + 1
	end

	local specsTitle = detailsFramework:CreateLabel(new_keybind_frame, "Config keys for spec:", 12, "silver")
	specsTitle:SetPoint("topleft", new_keybind_frame, "topleft", 10, mainStartY)

	keybindScroll:SetPoint("topleft", specsTitle.widget, "bottomleft", 0, -120)

	spec1:SetPoint("topleft", specsTitle, "bottomleft", 0, -10)
	spec2:SetPoint("topleft", specsTitle, "bottomleft", 0, -30)
	spec3:SetPoint("topleft", specsTitle, "bottomleft", 0, -50)
	if (class == "DRUID") then
		spec4:SetPoint("topleft", specsTitle, "bottomleft", 0, -70)
	end

	local enter_the_key = CreateFrame("frame", nil, new_keybind_frame, "BackdropTemplate")
	enter_the_key:SetFrameStrata("tooltip")
	enter_the_key:SetSize(200, 60)
	enter_the_key:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16, edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1})
	enter_the_key:SetBackdropColor(0, 0, 0, 1)
	enter_the_key:SetBackdropBorderColor(1, 1, 1, 1)
	enter_the_key.text = detailsFramework:CreateLabel(enter_the_key, "- Press a keyboard key to bind.\n- Click to bind a mouse button.\n- Press escape to cancel.", 11, "orange")
	enter_the_key.text:SetPoint("center", enter_the_key, "center")
	enter_the_key:Hide()

	local registerKeybind = function(self, key)
		if (ignoredKeys [key]) then
			return
		end
		if (key == "ESCAPE") then
			enter_the_key:Hide()
			new_keybind_frame.IsListening = false
			new_keybind_frame:SetScript("OnKeyDown", nil)
			return
		end

		local bind = (IsShiftKeyDown() and "SHIFT-" or "") .. (IsControlKeyDown() and "CTRL-" or "") .. (IsAltKeyDown() and "ALT-" or "")
		bind = bind .. key

		--adiciona para a tabela de keybinds
		local keybind = new_keybind_frame.CurrentKeybindEditingSet [self.keybindIndex]
		keybind.key = bind

		new_keybind_frame.IsListening = false
		new_keybind_frame:SetScript("OnKeyDown", nil)

		enter_the_key:Hide()
		new_keybind_frame.keybindScroll:UpdateScroll()

		detailsFramework:QuickDispatch(callback)
	end

	local set_keybind_key = function(self, button, keybindIndex)
		if (new_keybind_frame.IsListening) then
			key = mouseKeys [button] or button
			return registerKeybind (new_keybind_frame, key)
		end
		new_keybind_frame.IsListening = true
		new_keybind_frame.keybindIndex = keybindIndex
		new_keybind_frame:SetScript("OnKeyDown", registerKeybind)

		enter_the_key:Show()
		enter_the_key:SetPoint("bottom", self, "top")
	end

	local new_key_bind = function(self, button, specID)
		tinsert(new_keybind_frame.CurrentKeybindEditingSet, {key = "-none-", action = "_target", actiontext = ""})
		FauxScrollFrame_SetOffset (new_keybind_frame.keybindScroll, max(#new_keybind_frame.CurrentKeybindEditingSet-SCROLL_ROLL_AMOUNT, 0))
		new_keybind_frame.keybindScroll:UpdateScroll()
	end

	local set_action_text = function(keybindIndex, _, text)
		local keybind = new_keybind_frame.CurrentKeybindEditingSet [keybindIndex]
		keybind.actiontext = text
		detailsFramework:QuickDispatch(callback)
	end

	local set_action_on_espace_press = function(textentry, capsule)
		capsule = capsule or textentry.MyObject
		local keybind = new_keybind_frame.CurrentKeybindEditingSet [capsule.CurIndex]
		textentry:SetText(keybind.actiontext)
		detailsFramework:QuickDispatch(callback)
	end

	local lock_textentry = {
		["_target"] = true,
		["_taunt"] = true,
		["_interrupt"] = true,
		["_dispel"] = true,
		["_spell"] = false,
		["_macro"] = false,
	}

	local change_key_action = function(self, keybindIndex, value)
		local keybind = new_keybind_frame.CurrentKeybindEditingSet [keybindIndex]
		keybind.action = value
		new_keybind_frame.keybindScroll:UpdateScroll()
		detailsFramework:QuickDispatch(callback)
	end
	local fill_action_dropdown = function()

		local locClass, class = UnitClass("player")

		local taunt = ""
		local interrupt = ""
		local dispel = ""

		if (type(dispel) == "table") then
			local dispelString = "\n"
			for specID, spellid in pairs(dispel) do
				local specid, specName = DetailsFramework.GetSpecializationInfoByID (specID)
				local spellName = GetSpellInfo(spellid)
				dispelString = dispelString .. "|cFFE5E5E5" .. (specName or "") .. "|r: |cFFFFFFFF" .. spellName .. "\n"
			end
			dispel = dispelString
		else
			dispel = ""
		end

		return {
			--{value = "_target", label = "Target", onclick = change_key_action, desc = "Target the unit"},
			--{value = "_taunt", label = "Taunt", onclick = change_key_action, desc = "Cast the taunt spell for your class\n\n|cFFFFFFFFSpell: " .. taunt},
			--{value = "_interrupt", label = "Interrupt", onclick = change_key_action, desc = "Cast the interrupt spell for your class\n\n|cFFFFFFFFSpell: " .. interrupt},
			--{value = "_dispel", label = "Dispel", onclick = change_key_action, desc = "Cast the interrupt spell for your class\n\n|cFFFFFFFFSpell: " .. dispel},
			{value = "_spell", label = "Cast Spell", onclick = change_key_action, desc = "Type the spell name in the text box"},
			{value = "_macro", label = "Run Macro", onclick = change_key_action, desc = "Type your macro in the text box"},
		}
	end

	local copy_keybind = function(self, button, keybindIndex)
		local keybind = new_keybind_frame.CurrentKeybindEditingSet [keybindIndex]
		for specID, t in pairs(new_keybind_frame.Data) do
			if (specID ~= new_keybind_frame.EditingSpec) then
				local key = CopyTable (keybind)
				local specid, specName = DetailsFramework.GetSpecializationInfoByID (specID)
				tinsert(new_keybind_frame.Data [specID], key)
				detailsFramework:Msg("Keybind copied to " .. (specName or ""))
			end
		end
		detailsFramework:QuickDispatch(callback)
	end

	local delete_keybind = function(self, button, keybindIndex)
		tremove(new_keybind_frame.CurrentKeybindEditingSet, keybindIndex)
		new_keybind_frame.keybindScroll:UpdateScroll()
		detailsFramework:QuickDispatch(callback)
	end

	local newTitle = detailsFramework:CreateLabel(new_keybind_frame, "Create a new Keybind:", 12, "silver")
	newTitle:SetPoint("topleft", new_keybind_frame, "topleft", 200, mainStartY)
	local createNewKeybind = detailsFramework:CreateButton(new_keybind_frame, new_key_bind, 160, 20, "New Key Bind", 1, _, _, "NewKeybindButton", _, 0, options_button_template, options_text_template)
	createNewKeybind:SetPoint("topleft", newTitle, "bottomleft", 0, -10)
	--createNewKeybind:SetIcon ([[Interface\Buttons\UI-GuildButton-PublicNote-Up]])

	local update_keybind_list = function(self)

		local keybinds = new_keybind_frame.CurrentKeybindEditingSet
		FauxScrollFrame_Update (self, #keybinds, SCROLL_ROLL_AMOUNT, 21)
		local offset = FauxScrollFrame_GetOffset (self)

		for i = 1, SCROLL_ROLL_AMOUNT do
			local index = i + offset
			local f = self.Frames [i]
			local data = keybinds [index]

			if (data) then
				--index
				f.Index.text = index
				--keybind
				local keyBindText = keysToMouse [data.key] or data.key

				keyBindText = keyBindText:gsub("type1", "LeftButton")
				keyBindText = keyBindText:gsub("type2", "RightButton")
				keyBindText = keyBindText:gsub("type3", "MiddleButton")

				f.KeyBind.text = keyBindText
				f.KeyBind:SetClickFunction(set_keybind_key, index, nil, "left")
				f.KeyBind:SetClickFunction(set_keybind_key, index, nil, "right")
				--action
				f.ActionDrop:SetFixedParameter(index)
				f.ActionDrop:Select(data.action)
				--action text
				f.ActionText.text = data.actiontext
				f.ActionText:SetEnterFunction (set_action_text, index)
				f.ActionText.CurIndex = index

				if (lock_textentry [data.action]) then
					f.ActionText:Disable()
				else
					f.ActionText:Enable()
				end

				--copy
				f.Copy:SetClickFunction(copy_keybind, index)
				--delete
				f.Delete:SetClickFunction(delete_keybind, index)

				f:Show()
			else
				f:Hide()
			end
		end

		self:Show()
	end



	keybindScroll:SetScript("OnVerticalScroll", function(self, offset)
		FauxScrollFrame_OnVerticalScroll (self, offset, 21, update_keybind_list)
	end)
	keybindScroll.UpdateScroll = update_keybind_list

	local backdropColor = {.3, .3, .3, .3}
	local backdropColorOnEnter = {.6, .6, .6, .6}
	local on_enter = function(self)
		self:SetBackdropColor(unpack(backdropColorOnEnter))
	end
	local on_leave = function(self)
		self:SetBackdropColor(unpack(backdropColor))
	end

	local font = "GameFontHighlightSmall"

	for i = 1, SCROLL_ROLL_AMOUNT do
		local f = CreateFrame("frame", "$KeyBindFrame" .. i, keybindScroll, "BackdropTemplate")
		f:SetSize(1009, 20)
		f:SetPoint("topleft", keybindScroll, "topleft", 0, -(i-1)*29)
		f:SetBackdrop({bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true})
		f:SetBackdropColor(unpack(backdropColor))
		f:SetScript("OnEnter", on_enter)
		f:SetScript("OnLeave", on_leave)
		tinsert(keybindScroll.Frames, f)

		f.Index = detailsFramework:CreateLabel(f, "1")
		f.KeyBind = detailsFramework:CreateButton(f, set_key_bind, 100, 20, "", _, _, _, "SetNewKeybindButton", _, 0, options_button_template, options_text_template)
		f.ActionDrop = detailsFramework:CreateDropDown (f, fill_action_dropdown, 0, 120, 20, "ActionDropdown", _, options_dropdown_template)
		f.ActionText = detailsFramework:CreateTextEntry(f, function()end, 660, 20, "TextBox", _, _, options_dropdown_template)
		f.Copy = detailsFramework:CreateButton(f, copy_keybind, 20, 20, "", _, _, _, "CopyKeybindButton", _, 0, options_button_template, options_text_template)
		f.Delete = detailsFramework:CreateButton(f, delete_keybind, 16, 20, "", _, _, _, "DeleteKeybindButton", _, 2, options_button_template, options_text_template)

		f.Index:SetPoint("left", f, "left", 10, 0)
		f.KeyBind:SetPoint("left", f, "left", 43, 0)
		f.ActionDrop:SetPoint("left", f, "left", 150, 0)
		f.ActionText:SetPoint("left", f, "left", 276, 0)
		f.Copy:SetPoint("left", f, "left", 950, 0)
		f.Delete:SetPoint("left", f, "left", 990, 0)

		f.Copy:SetIcon ([[Interface\Buttons\UI-GuildButton-PublicNote-Up]], nil, nil, nil, nil, nil, nil, 4)
		f.Delete:SetIcon ([[Interface\Buttons\UI-StopButton]], nil, nil, nil, nil, nil, nil, 4)

		f.Copy.tooltip = "copy this keybind to other specs"
		f.Delete.tooltip = "erase this keybind"

		--editbox
		f.ActionText:SetJustifyH("left")
		f.ActionText:SetHook("OnEscapePressed", set_action_on_espace_press)
		f.ActionText:SetHook("OnEditFocusGained", function()
			local playerSpells = {}
			local tab, tabTex, offset, numSpells = GetSpellTabInfo (2)
			for i = 1, numSpells do
				local index = offset + i
				local spellType, spellId = GetSpellBookItemInfo (index, "player")
				if (spellType == "SPELL") then
					local spellName = GetSpellInfo(spellId)
					tinsert(playerSpells, spellName)
				end
			end
			f.ActionText.WordList = playerSpells
		end)

		f.ActionText:SetAsAutoComplete ("WordList")
	end

	local header = CreateFrame("frame", "$parentOptionsPanelFrameHeader", keybindScroll, "BackdropTemplate")
	header:SetPoint("bottomleft", keybindScroll, "topleft", 0, 2)
	header:SetPoint("bottomright", keybindScroll, "topright", 0, 2)
	header:SetHeight(16)

	header.Index = detailsFramework:CreateLabel  (header, "Index", detailsFramework:GetTemplate("font", "OPTIONS_FONT_TEMPLATE"))
	header.Key = detailsFramework:CreateLabel  (header, "Key", detailsFramework:GetTemplate("font", "OPTIONS_FONT_TEMPLATE"))
	header.Action = detailsFramework:CreateLabel  (header, "Action", detailsFramework:GetTemplate("font", "OPTIONS_FONT_TEMPLATE"))
	header.Macro = detailsFramework:CreateLabel  (header, "Spell Name / Macro", detailsFramework:GetTemplate("font", "OPTIONS_FONT_TEMPLATE"))
	header.Copy = detailsFramework:CreateLabel  (header, "Copy", detailsFramework:GetTemplate("font", "OPTIONS_FONT_TEMPLATE"))
	header.Delete = detailsFramework:CreateLabel  (header, "Delete", detailsFramework:GetTemplate("font", "OPTIONS_FONT_TEMPLATE"))

	header.Index:SetPoint("left", header, "left", 10, 0)
	header.Key:SetPoint("left", header, "left", 43, 0)
	header.Action:SetPoint("left", header, "left", 150, 0)
	header.Macro:SetPoint("left", header, "left", 276, 0)
	header.Copy:SetPoint("left", header, "left", 950, 0)
	header.Delete:SetPoint("left", header, "left", 990, 0)

	new_keybind_frame:SetScript("OnShow", function()

		--new_keybind_frame.EditingSpec = EnemyGrid.CurrentSpec
		--new_keybind_frame.CurrentKeybindEditingSet = EnemyGrid.CurrentKeybindSet

		for _, button in ipairs(allSpecButtons) do
			if (new_keybind_frame.EditingSpec ~= button.specID) then
				button.selectedTexture:Hide()
			else
				button.selectedTexture:Show()
			end
		end

		keybindScroll:UpdateScroll()
	end)

	new_keybind_frame:SetScript("OnHide", function()
		if (new_keybind_frame.IsListening) then
			new_keybind_frame.IsListening = false
			new_keybind_frame:SetScript("OnKeyDown", nil)
		end
	end)

	return new_keybind_frame
end

function detailsFramework:BuildKeybindFunctions (data, prefix)

	--~keybind
	local classLoc, class = UnitClass("player")
	local bindingList = data

	local bindString = "self:ClearBindings()"
	local bindKeyBindTypeFunc = [[local unitFrame = ...]]
	local bindMacroTextFunc = [[local unitFrame = ...]]
	local isMouseBinding

	for i = 1, #bindingList do
		local bind = bindingList [i]
		local bindType

		--which button to press
		if (bind.key:find("type")) then
			local keyNumber = tonumber(bind.key:match ("%d"))
			bindType = keyNumber
			isMouseBinding = true
		else
			bindType = prefix .. "" .. i
			bindString = bindString .. "self:SetBindingClick (0, '" .. bind.key .. "', self:GetName(), '" .. bindType .. "')"
			bindType = "-" .. prefix .. "" .. i
			isMouseBinding = nil
		end

		--keybind type
		local shift, alt, ctrl = bind.key:match ("SHIFT"), bind.key:match ("ALT"), bind.key:match ("CTRL")
		local CommandKeys = alt and alt .. "-" or ""
		CommandKeys = ctrl and CommandKeys .. ctrl .. "-" or CommandKeys
		CommandKeys = shift and CommandKeys .. shift .. "-" or CommandKeys

		local keyBindType
		if (isMouseBinding) then
			keyBindType = [[unitFrame:SetAttribute ("@COMMANDtype@BINDTYPE", "macro")]]
		else
			keyBindType = [[unitFrame:SetAttribute ("type@BINDTYPE", "macro")]]
		end

		keyBindType = keyBindType:gsub("@BINDTYPE", bindType)
		keyBindType = keyBindType:gsub("@COMMAND", CommandKeys)
		bindKeyBindTypeFunc = bindKeyBindTypeFunc .. keyBindType

		--spell or macro
		if (bind.action == "_spell") then
			local macroTextLine
			if (isMouseBinding) then
				macroTextLine = [[unitFrame:SetAttribute ("@COMMANDmacrotext@BINDTYPE", "/cast [@mouseover] @SPELL")]]
			else
				macroTextLine = [[unitFrame:SetAttribute ("macrotext@BINDTYPE", "/cast [@mouseover] @SPELL")]]
			end
			macroTextLine = macroTextLine:gsub("@BINDTYPE", bindType)
			macroTextLine = macroTextLine:gsub("@SPELL", bind.actiontext)
			macroTextLine = macroTextLine:gsub("@COMMAND", CommandKeys)
			bindMacroTextFunc = bindMacroTextFunc .. macroTextLine

		elseif (bind.action == "_macro") then
			local macroTextLine
			if (isMouseBinding) then
				macroTextLine = [[unitFrame:SetAttribute ("@COMMANDmacrotext@BINDTYPE", "@MACRO")]]
			else
				macroTextLine = [[unitFrame:SetAttribute ("macrotext@BINDTYPE", "@MACRO")]]
			end
			macroTextLine = macroTextLine:gsub("@BINDTYPE", bindType)
			macroTextLine = macroTextLine:gsub("@MACRO", bind.actiontext)
			macroTextLine = macroTextLine:gsub("@COMMAND", CommandKeys)
			bindMacroTextFunc = bindMacroTextFunc .. macroTextLine

		end
	end

	--~key
	local bindTypeFuncLoaded = loadstring (bindKeyBindTypeFunc)
	local bindMacroFuncLoaded = loadstring (bindMacroTextFunc)

	if (not bindMacroFuncLoaded or not bindTypeFuncLoaded) then
		return
	end

	return bindString, bindTypeFuncLoaded, bindMacroFuncLoaded
end


function detailsFramework:SetKeybindsOnProtectedFrame (frame, bind_string, bind_type_func, bind_macro_func)

	bind_type_func (frame)
	bind_macro_func (frame)
	frame:SetAttribute ("_onenter", bind_string)

end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ~standard backdrop
---this is the standard backdrop for detailsframework, it's a dark-ish color semi transparent with a thin opaque black border
---for the background it uses UI-Tooltip-Background with detailsFramework:GetDefaultBackdropColor() color
---for the border it uses Interface\Buttons\WHITE8X8
---also creates an additional texture frame.__background = texture with the same setting of the backdrop background
---@param frame table
---@param bUseSolidColor any
---@param alphaScale number
function detailsFramework:ApplyStandardBackdrop(frame, bUseSolidColor, alphaScale)
	alphaScale = alphaScale or 0.95

	if (not frame.SetBackdrop)then
		--print(debugstack(1,2,1))
		Mixin(frame, BackdropTemplateMixin)
	end

	local red, green, blue, alpha = detailsFramework:GetDefaultBackdropColor()

	if (bUseSolidColor) then
		local colorDeviation = 0.05
		frame:SetBackdrop({edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1, bgFile = [[Interface\Buttons\WHITE8X8]], tileSize = 32, tile = true})
		frame:SetBackdropColor(red, green, blue, 0.872)
		frame:SetBackdropBorderColor(0, 0, 0, 0.95)

	else
		frame:SetBackdrop({edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1, bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true})
		frame:SetBackdropColor(red, green, blue, alpha * alphaScale)
		frame:SetBackdropBorderColor(0, 0, 0, 0.95)
	end

	if (not frame.__background) then
		frame.__background = frame:CreateTexture(nil, "border", nil, -6)
		frame.__background:SetColorTexture(red, green, blue)
		frame.__background:SetAllPoints()
	end

	frame.__background:SetAlpha(alpha * alphaScale)
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ~title bar

detailsFramework.TitleFunctions = {
	SetTitle = function(self, titleText, titleColor, font, size)
		local titleLabel = self.TitleLabel or self.Text

		titleLabel:SetText(titleText or titleLabel:GetText())

		if (titleColor) then
			local r, g, b, a = detailsFramework:ParseColors(titleColor)
			titleLabel:SetTextColor(r, g, b, a)
		end

		if (font) then
			detailsFramework:SetFontFace (titleLabel, font)
		end

		if (size) then
			detailsFramework:SetFontSize(titleLabel, size)
		end
	end
}

---@class df_titlebar : frame
---@field TitleBar frame
---@field TitleLabel fontstring
---@field CloseButton button
---@field SetTitle fun(self:df_titlebar, titleText:string, titleColor:any, font:string, size:number)

---create a title bar with a font string in the center and a close button in the right side
---@param parent frame
---@param titleText string
---@return df_titlebar
function detailsFramework:CreateTitleBar(parent, titleText)
	local titleBar = CreateFrame("frame", parent:GetName() and parent:GetName() .. "TitleBar" or nil, parent, "BackdropTemplate")
	titleBar:SetPoint("topleft", parent, "topleft", 2, -3)
	titleBar:SetPoint("topright", parent, "topright", -2, -3)
	titleBar:SetHeight(20)
	titleBar:SetBackdrop(SimplePanel_frame_backdrop) --it's an upload from this file
	titleBar:SetBackdropColor(.2, .2, .2, 1)
	titleBar:SetBackdropBorderColor(0, 0, 0, 1)

	local closeButton = CreateFrame("button", titleBar:GetName() and titleBar:GetName() .. "CloseButton" or nil, titleBar, "BackdropTemplate")
	closeButton:SetSize(16, 16)

	closeButton:SetNormalTexture([[Interface\GLUES\LOGIN\Glues-CheckBox-Check]])
	closeButton:SetHighlightTexture([[Interface\GLUES\LOGIN\Glues-CheckBox-Check]])
	closeButton:SetPushedTexture([[Interface\GLUES\LOGIN\Glues-CheckBox-Check]])
	closeButton:GetNormalTexture():SetDesaturated(true)
	closeButton:GetHighlightTexture():SetDesaturated(true)
	closeButton:GetPushedTexture():SetDesaturated(true)

	closeButton:SetAlpha(0.7)
	closeButton:SetScript("OnClick", simple_panel_close_click) --upvalue from this file

	local titleLabel = titleBar:CreateFontString(titleBar:GetName() and titleBar:GetName() .. "TitleText" or nil, "overlay", "GameFontNormal")
	titleLabel:SetTextColor(detailsFramework:ParseColors("gold"))
	titleLabel:SetText(titleText or "")

	--anchors
	closeButton:SetPoint("right", titleBar, "right", -2, 0)
	titleLabel:SetPoint("center", titleBar, "center")

	--members
	parent.TitleBar = titleBar
	parent.CloseButton = closeButton
	parent.TitleLabel = titleLabel
	parent.SetTitle = titleBar.SetTitle

	titleBar.TitleBar = titleBar --to fit documentation
	titleBar.CloseButton = closeButton
	titleBar.Text = titleLabel

	detailsFramework:Mixin(parent, detailsFramework.TitleFunctions)

	return titleBar
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--radio group

local default_radiogroup_options = {
	width = 1,
	height = 1,
	backdrop = {edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1, bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true},
	backdrop_color = {0, 0, 0, 0.2},
	backdrop_border_color = {0.1, 0.1, 0.1, .2},
	is_radio = false,
}

detailsFramework.RadioGroupCoreFunctions = {
	Disable = function(self)
		local frameList = self:GetAllCheckboxes()
		for _, checkbox in ipairs(frameList) do
			checkbox = checkbox.GetCapsule and checkbox:GetCapsule() or checkbox
			checkbox:Disable()
		end
	end,

	Enable = function(self)
		local frameList = self:GetAllCheckboxes()
		for _, checkbox in ipairs(frameList) do
			checkbox = checkbox.GetCapsule and checkbox:GetCapsule() or checkbox
			checkbox:Enable()
		end
	end,

	DeselectAll = function(self)
		local frameList = self:GetAllCheckboxes()
		for _, checkbox in ipairs(frameList) do
			checkbox = checkbox.GetCapsule and checkbox:GetCapsule() or checkbox
			checkbox:SetValue(false)
		end
	end,

	FadeIn = function(self)
		local frameList = self:GetAllCheckboxes()
		for _, checkbox in ipairs(frameList) do
			checkbox:SetAlpha(1)
		end
	end,

	FadeOut = function(self)
		local frameList = self:GetAllCheckboxes()
		for _, checkbox in ipairs(frameList) do
			checkbox:SetAlpha(.7)
		end
	end,

	SetFadeState = function(self, state)
		if (state) then
			self:FadeIn()
		else
			self:FadeOut()
		end
	end,

	GetAllCheckboxes = function(self)
		return {self:GetChildren()}
	end,

	GetCheckbox = function(self, checkboxId)
		local allCheckboxes = self:GetAllCheckboxes()
		local checkbox = allCheckboxes[checkboxId]
		if (not checkbox) then
			checkbox = self:CreateCheckbox()
		end
		return checkbox
	end,

	CreateCheckbox = function(self)
		local checkbox = detailsFramework:CreateSwitch(self, function()end, false, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, detailsFramework:GetTemplate("switch", "OPTIONS_CHECKBOX_BRIGHT_TEMPLATE"))
		checkbox:SetAsCheckBox()
		checkbox.Icon = detailsFramework:CreateImage(checkbox, "", 16, 16)
		checkbox.Label = detailsFramework:CreateLabel(checkbox, "")

		return checkbox
	end,

	ResetAllCheckboxes = function(self)
		local radioCheckboxes = self:GetAllCheckboxes()
		for i = 1, #radioCheckboxes do
			local checkBox = radioCheckboxes[i]
			checkBox:Hide()
		end
	end,

	--if the list of checkboxes are a radio group
	RadioOnClick = function(checkbox, fixedParam, value)
		--turn off all checkboxes
		checkbox:GetParent():DeselectAll()

		--turn on the clicked checkbox
		checkbox:SetValue(true)

		--callback
		if (checkbox._callback) then
			detailsFramework:QuickDispatch(checkbox._callback, fixedParam, checkbox._optionid)
		end
	end,

	RefreshCheckbox = function(self, checkbox, optionTable, optionId)
		checkbox = checkbox.GetCapsule and checkbox:GetCapsule() or checkbox

		local setFunc = self.options.is_radio and self.RadioOnClick or optionTable.set
		checkbox:SetSwitchFunction(setFunc)
		checkbox._callback = optionTable.callback
		checkbox._set = self.options.is_radio and optionTable.callback or optionTable.set
		checkbox._optionid = optionId
		checkbox:SetFixedParameter(optionTable.param or optionId)

		local isChecked = type(optionTable.get) == "function" and detailsFramework:Dispatch(optionTable.get) or false
		checkbox:SetValue(isChecked)

		checkbox.Label:SetText(optionTable.name)

		if (optionTable.texture) then
			checkbox.Icon:SetTexture(optionTable.texture)
			checkbox.Icon:SetPoint("left", checkbox, "right", 2, 0)
			checkbox.Label:SetPoint("left", checkbox.Icon, "right", 2, 0)

			if (optionTable.texcoord) then
				checkbox.Icon:SetTexCoord(unpack(optionTable.texcoord))
			else
				checkbox.Icon:SetTexCoord(0, 1, 0, 1)
			end
		else
			checkbox.Icon:SetTexture("")
			checkbox.Label:SetPoint("left", checkbox, "right", 2, 0)
		end
	end,

	Refresh = function(self)
		self:ResetAllCheckboxes()
		local radioOptions = self:GetOptions()
		local radioCheckboxes = self:GetAllCheckboxes()

		for optionId, optionsTable in ipairs(radioOptions) do
			local checkbox = self:GetCheckbox(optionId)
			checkbox.OptionID = optionId
			checkbox:Show()
			self:RefreshCheckbox(checkbox, optionsTable, optionId)
		end

		--sending false to automatically use the radio group children
		self:ArrangeFrames(false, self.AnchorOptions)
	end,

	SetOptions = function(self, radioOptions)
		self.RadioOptionsTable = radioOptions
		self:Refresh()
	end,

	GetOptions = function(self)
		return self.RadioOptionsTable
	end,
}

--[=[
	radionOptions: an index table with options for the radio group {name = "", set = func (self, param, value), param = value, get = func, texture = "", texcoord = {}}
		set function receives as self the checkbox, use :GetParent() to get the radion group frame
		if get function return nil or false the checkbox isn't checked
	name: the name of the frame
	options: override options for default_radiogroup_options table
	anchorOptions: override options for default_framelayout_options table
--]=]
function detailsFramework:CreateCheckboxGroup(parent, radioOptions, name, options, anchorOptions)
	local f = CreateFrame("frame", name, parent, "BackdropTemplate")

	detailsFramework:Mixin(f, detailsFramework.OptionsFunctions)
	detailsFramework:Mixin(f, detailsFramework.RadioGroupCoreFunctions)
	detailsFramework:Mixin(f, detailsFramework.LayoutFrame)

	f:BuildOptionsTable (default_radiogroup_options, options)

	f:SetSize(f.options.width, f.options.height)
	f:SetBackdrop(f.options.backdrop)
	f:SetBackdropColor(unpack(f.options.backdrop_color))
	f:SetBackdropBorderColor(unpack(f.options.backdrop_border_color))

	f.AnchorOptions = anchorOptions or {}

	if (f.options.title) then
		local titleLabel = detailsFramework:CreateLabel(f, f.options.title, detailsFramework:GetTemplate("font", "ORANGE_FONT_TEMPLATE"))
		titleLabel:SetPoint("bottomleft", f, "topleft", 0, 2)
		f.Title = titleLabel
	end

	f:SetOptions (radioOptions)

	return f
end

function detailsFramework:CreateRadionGroup(parent, radioOptions, name, options, anchorOptions) --alias for miss spelled old function
	return detailsFramework:CreateRadioGroup(parent, radioOptions, name, options, anchorOptions)
end

function detailsFramework:CreateRadioGroup(parent, radioOptions, name, options, anchorOptions)
	options = options or {}
	options.is_radio = true
	return detailsFramework:CreateCheckboxGroup(parent, radioOptions, name, options, anchorOptions)
end


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--load conditions panel

--this is the table prototype to hold load conditions settings
local default_load_conditions = {
	class = {},
	spec = {},
	race = {},
	talent = {},
	pvptalent = {},
	group = {},
	role = {},
	affix = {},
	encounter_ids = {},
	map_ids = {},
}

local default_load_conditions_frame_options = {
	title = "Details! Framework: Load Conditions",
	name = "Object",
}

function detailsFramework:CreateLoadFilterParser (callback)
	local f = CreateFrame("frame")
	f:RegisterEvent("PLAYER_ENTERING_WORLD")
	if IS_WOW_PROJECT_MAINLINE then
		f:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
		f:RegisterEvent("PLAYER_TALENT_UPDATE")
	end
	f:RegisterEvent("PLAYER_ROLES_ASSIGNED")
	f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	if IS_WOW_PROJECT_MAINLINE then
		f:RegisterEvent("CHALLENGE_MODE_START")
	end
	f:RegisterEvent("ENCOUNTER_START")
	f:RegisterEvent("PLAYER_REGEN_ENABLED")

	f:SetScript("OnEvent", function(self, event, ...)
		if (event == "ENCOUNTER_START") then
			local encounterID = ...
			f.EncounterIDCached = encounterID

		elseif (event == "ENCOUNTER_END") then
			f.EncounterIDCached = nil

		elseif (event == "PLAYER_REGEN_ENABLED") then
			--f.EncounterIDCached = nil
			--when the player dies during an encounter, the game is triggering regen enabled

		elseif (event == "PLAYER_SPECIALIZATION_CHANGED") then
			if (DetailsFrameworkLoadConditionsPanel and DetailsFrameworkLoadConditionsPanel:IsShown()) then
				DetailsFrameworkLoadConditionsPanel:Refresh()
			end

			local unit = ...
			if (not unit or not UnitIsUnit("player", unit)) then
				return
			end

		elseif (event == "PLAYER_ROLES_ASSIGNED") then
			local assignedRole = UnitGroupRolesAssigned("player")
			if (assignedRole == "NONE") then
				local spec = DetailsFramework.GetSpecialization()
				if (spec) then
					assignedRole = DetailsFramework.GetSpecializationRole (spec)
				end
			end

			if (detailsFramework.CurrentPlayerRole == assignedRole) then
				return
			end

			detailsFramework.CurrentPlayerRole = assignedRole
		end

		--print("Plater Script Update:", event, ...)

		detailsFramework:QuickDispatch(callback, f.EncounterIDCached)
	end)
end

function detailsFramework:PassLoadFilters(loadTable, encounterID)
	--class
	local passLoadClass
	if (loadTable.class.Enabled) then
		local _, classFileName = UnitClass("player")
		if (not loadTable.class[classFileName]) then
			return false
		else
			passLoadClass = true
		end
	end

	--spec
	if (IS_WOW_PROJECT_MAINLINE and loadTable.spec.Enabled) then
		local canCheckTalents = true

		if (passLoadClass) then
			--if is allowed to load on this class, check if the talents isn't from another class
			local _, classFileName = UnitClass("player")
			local specsForThisClass = detailsFramework:GetClassSpecIDs(classFileName)

			canCheckTalents = false

			for _, specID in ipairs(specsForThisClass) do
				if (loadTable.spec[specID] or loadTable.spec[specID..""]) then
					--theres a talent for this class
					canCheckTalents = true
					break
				end
			end
		end

		if (canCheckTalents) then
			local specIndex = DetailsFramework.GetSpecialization()
			if (specIndex) then
				local specID = DetailsFramework.GetSpecializationInfo(specIndex)
				if not specID or (not loadTable.spec[specID] and not loadTable.spec[specID .. ""]) then
					return false
				end
			else
				return false
			end
		end
	end

	--race
	if (loadTable.race.Enabled) then
		local raceName, raceFileName, raceID = UnitRace ("player")
		if (not loadTable.race [raceFileName]) then
			return false
		end
	end

	--talents
	if (IS_WOW_PROJECT_MAINLINE and loadTable.talent.Enabled) then
		local talentsInUse = detailsFramework:GetCharacterTalents (false, true)
		local hasTalent
		for talentID, _ in pairs(talentsInUse) do
			if talentID and (loadTable.talent [talentID] or loadTable.talent [talentID .. ""]) then
				hasTalent =  true
				break
			end
		end
		if (not hasTalent) then
			return false
		end
	end

	--pvptalent
	if (IS_WOW_PROJECT_MAINLINE and loadTable.pvptalent.Enabled) then
		local talentsInUse = detailsFramework:GetCharacterPvPTalents (false, true)
		local hasTalent
		for talentID, _ in pairs(talentsInUse) do
			if talentID and (loadTable.pvptalent [talentID] or loadTable.pvptalent [talentID .. ""]) then
				hasTalent =  true
				break
			end
		end
		if (not hasTalent) then
			return false
		end
	end

	--group
	if (loadTable.group.Enabled) then
		local _, zoneType = GetInstanceInfo()
		if (not loadTable.group [zoneType]) then
			return
		end
	end

	--role
	if (loadTable.role.Enabled) then
		local assignedRole = UnitGroupRolesAssigned("player")
		if (assignedRole == "NONE") then
			local spec = DetailsFramework.GetSpecialization()
			if (spec) then
				assignedRole = DetailsFramework.GetSpecializationRole (spec)
			end
		end
		if (not loadTable.role [assignedRole]) then
			return false
		end
	end

	--affix
	if (IS_WOW_PROJECT_MAINLINE and loadTable.affix.Enabled) then
		local isInMythicDungeon = C_ChallengeMode.IsChallengeModeActive()
		if (not isInMythicDungeon) then
			return false
		end

		local level, affixes, wasEnergized = C_ChallengeMode.GetActiveKeystoneInfo()
		local hasAffix = false
		for _, affixID in ipairs(affixes) do
			if affixID and (loadTable.affix [affixID] or loadTable.affix [affixID .. ""]) then
				hasAffix = true
				break
			end
		end

		if (not hasAffix) then
			return false
		end
	end

	--encounter id
	if (loadTable.encounter_ids.Enabled) then
		if (not encounterID) then
			return
		end
		local hasEncounter
		for _, ID in pairs(loadTable.encounter_ids) do
			if (ID == encounterID) then
				hasEncounter = true
				break
			end
			if (not hasEncounter) then
				return false
			end
		end
	end

	--map id
	if (loadTable.map_ids.Enabled) then
		local _, _, _, _, _, _, _, zoneMapID = GetInstanceInfo()
		local uiMapID = C_Map.GetBestMapForUnit ("player")

		local hasMapID
		for _, ID in pairs(loadTable.map_ids) do
			if (ID == zoneMapID or ID == uiMapID) then
				hasMapID = true
				break
			end
			if (not hasMapID) then
				return false
			end
		end
	end

	return true
end

--this func will deploy the default values from the prototype into the config table
function detailsFramework:UpdateLoadConditionsTable(configTable)
	configTable = configTable or {}
	detailsFramework.table.deploy(configTable, default_load_conditions)
	return configTable
end

--/run Plater.OpenOptionsPanel()PlaterOptionsPanelContainer:SelectIndex (Plater, 14)

function detailsFramework:OpenLoadConditionsPanel(optionsTable, callback, frameOptions)
	frameOptions = frameOptions or {}
	detailsFramework.table.deploy(frameOptions, default_load_conditions_frame_options)

	detailsFramework:UpdateLoadConditionsTable(optionsTable)

	if (not DetailsFrameworkLoadConditionsPanel) then
		local loadConditionsFrame = detailsFramework:CreateSimplePanel(UIParent, 970, 505, "Load Conditions", "DetailsFrameworkLoadConditionsPanel")
		loadConditionsFrame:SetBackdropColor(0, 0, 0, 1)
		loadConditionsFrame.AllRadioGroups = {}
		loadConditionsFrame.AllTextEntries = {}
		loadConditionsFrame.OptionsTable = optionsTable

		detailsFramework:ApplyStandardBackdrop(loadConditionsFrame, false, 1.1)

		local xStartAt = 10
		local x2StartAt = 500
		local anchorPositions = {
			class = {xStartAt, -70},
			spec = {xStartAt, -170},
			race = {xStartAt, -210},
			role = {xStartAt, -310},
			talent = {xStartAt, -350},
			pvptalent = {x2StartAt, -70},
			group = {x2StartAt, -210},
			affix = {x2StartAt, -270},
			encounter_ids = {x2StartAt, -420},
			map_ids = {x2StartAt, -460},
		}

		local editingLabel = detailsFramework:CreateLabel(loadConditionsFrame, "Load Conditions For:")
		local editingWhatLabel = detailsFramework:CreateLabel(loadConditionsFrame, "")
		editingLabel:SetPoint("topleft", loadConditionsFrame, "topleft", 10, -35)
		editingWhatLabel:SetPoint("left", editingLabel, "right", 2, 0)

		--this label store the name of what is being edited
		loadConditionsFrame.EditingLabel = editingWhatLabel

		--when the user click on an option, run the callback
			loadConditionsFrame.RunCallback = function()
				detailsFramework:Dispatch (loadConditionsFrame.CallbackFunc)
			end

		--when the user click on an option or when the panel is opened
		--check if there's an option enabled and fadein all options, fadeout otherwise
			loadConditionsFrame.OnRadioStateChanged = function(radioGroup, subConfigTable)
				subConfigTable.Enabled = nil
				subConfigTable.Enabled = next (subConfigTable) and true or nil
				radioGroup:SetFadeState (subConfigTable.Enabled)
			end

		--create the radio group for character class
			loadConditionsFrame.OnRadioCheckboxClick = function(self, key, value)
				--hierarchy: DBKey ["class"] key ["HUNTER"] value TRUE
				local DBKey = self:GetParent().DBKey
				loadConditionsFrame.OptionsTable [DBKey] [key and key .. ""] = value and true or nil
				if not value then -- cleanup "number" type values
					loadConditionsFrame.OptionsTable [DBKey] [key] = nil
				end
				loadConditionsFrame.OnRadioStateChanged (self:GetParent(), loadConditionsFrame.OptionsTable [DBKey])
				loadConditionsFrame.RunCallback()
			end

		--create the radio group for classes
			local classes = {}
			for _, classTable in pairs(detailsFramework:GetClassList()) do
				tinsert(classes, {
					name = classTable.Name,
					set = loadConditionsFrame.OnRadioCheckboxClick,
					param = classTable.FileString,
					get = function() return loadConditionsFrame.OptionsTable.class[classTable.FileString] end,
					texture = classTable.Texture,
					texcoord = classTable.TexCoord,
				})
			end

			local classGroup = detailsFramework:CreateCheckboxGroup (loadConditionsFrame, classes, name, {width = 200, height = 200, title = "Character Class"}, {offset_x = 130, amount_per_line = 3})
			classGroup:SetPoint("topleft", loadConditionsFrame, "topleft", anchorPositions.class[1], anchorPositions.class[2])
			classGroup.DBKey = "class"
			tinsert(loadConditionsFrame.AllRadioGroups, classGroup)

		--create the radio group for character spec
			if IS_WOW_PROJECT_MAINLINE then
				local specs = {}
				for _, specID in ipairs(detailsFramework:GetClassSpecIDs(select(2, UnitClass("player")))) do
					local specID, specName, specDescription, specIcon, specBackground, specRole, specClass = DetailsFramework.GetSpecializationInfoByID (specID)
					tinsert(specs, {
						name = specName,
						set = loadConditionsFrame.OnRadioCheckboxClick,
						param = specID,
						get = function() return loadConditionsFrame.OptionsTable.spec[specID] or loadConditionsFrame.OptionsTable.spec[specID..""] end,
						texture = specIcon,
					})
				end
				local specGroup = detailsFramework:CreateCheckboxGroup (loadConditionsFrame, specs, name, {width = 200, height = 200, title = "Character Spec"}, {offset_x = 130, amount_per_line = 4})
				specGroup:SetPoint("topleft", loadConditionsFrame, "topleft", anchorPositions.spec[1], anchorPositions.spec[2])
				specGroup.DBKey = "spec"
				tinsert(loadConditionsFrame.AllRadioGroups, specGroup)
			end

		--create radio group for character races
			local raceList = {}
			for _, raceTable in ipairs(detailsFramework:GetCharacterRaceList()) do
				tinsert(raceList, {
					name = raceTable.Name,
					set = loadConditionsFrame.OnRadioCheckboxClick,
					param = raceTable.FileString,
					get = function() return loadConditionsFrame.OptionsTable.race [raceTable.FileString] end,
				})
			end
			local raceGroup = detailsFramework:CreateCheckboxGroup (loadConditionsFrame, raceList, name, {width = 200, height = 200, title = "Character Race"})
			raceGroup:SetPoint("topleft", loadConditionsFrame, "topleft", anchorPositions.race [1], anchorPositions.race [2])
			raceGroup.DBKey = "race"
			tinsert(loadConditionsFrame.AllRadioGroups, raceGroup)

		--create radio group for talents
			if IS_WOW_PROJECT_MAINLINE then
				local talentList = {}
				for _, talentTable in ipairs(detailsFramework:GetCharacterTalents()) do
					if talentTable.ID then
						tinsert(talentList, {
							name = talentTable.Name,
							set = loadConditionsFrame.OnRadioCheckboxClick,
							param = talentTable.ID,
							get = function() return loadConditionsFrame.OptionsTable.talent [talentTable.ID] or loadConditionsFrame.OptionsTable.talent [talentTable.ID .. ""] end,
							texture = talentTable.Texture,
						})
					end
				end
				local talentGroup = detailsFramework:CreateCheckboxGroup (loadConditionsFrame, talentList, name, {width = 200, height = 200, title = "Characer Talents"}, {offset_x = 150, amount_per_line = 3})
				talentGroup:SetPoint("topleft", loadConditionsFrame, "topleft", anchorPositions.talent [1], anchorPositions.talent [2])
				talentGroup.DBKey = "talent"
				tinsert(loadConditionsFrame.AllRadioGroups, talentGroup)
				loadConditionsFrame.TalentGroup = talentGroup

				do
					--create a frame to show talents selected in other specs or characters
					local otherTalents = CreateFrame("frame", nil, loadConditionsFrame, "BackdropTemplate")
					otherTalents:SetSize(26, 26)
					otherTalents:SetPoint("left", talentGroup.Title.widget, "right", 10, -2)
					otherTalents.Texture = detailsFramework:CreateImage(otherTalents, [[Interface\BUTTONS\AdventureGuideMicrobuttonAlert]], 24, 24)
					otherTalents.Texture:SetAllPoints()

					local removeTalent = function(_, _, talentID)
						loadConditionsFrame.OptionsTable.talent [talentID] = nil
						GameCooltip2:Hide()
						loadConditionsFrame.OnRadioStateChanged (talentGroup, loadConditionsFrame.OptionsTable [talentGroup.DBKey])
						loadConditionsFrame.CanShowTalentWarning()
					end

					local buildTalentMenu = function()
						local playerTalents = detailsFramework:GetCharacterTalents()
						local indexedTalents = {}
						for _, talentTable in ipairs(playerTalents) do
							tinsert(indexedTalents, talentTable.ID)
						end

						--talents selected to load
						GameCooltip2:AddLine("select a talent to remove it (added from a different spec or character)", "", 1, "orange", "orange", 9)
						GameCooltip2:AddLine("$div", nil, nil, -1, -1)

						for talentID, _ in pairs(loadConditionsFrame.OptionsTable.talent) do
							if (type(talentID) == "number" and not detailsFramework.table.find (indexedTalents, talentID)) then
								local talentID, name, texture, selected, available = GetTalentInfoByID (talentID)
								if (name) then
									GameCooltip2:AddLine(name)
									GameCooltip2:AddIcon (texture, 1, 1, 16, 16, .1, .9, .1, .9)
									GameCooltip2:AddMenu (1, removeTalent, talentID)
								end
							end
						end
					end

					otherTalents.CoolTip = {
						Type = "menu",
						BuildFunc = buildTalentMenu,
						OnEnterFunc = function(self) end,
						OnLeaveFunc = function(self) end,
						FixedValue = "none",
						ShowSpeed = 0.05,
						Options = function()
							GameCooltip2:SetOption("TextFont", "Friz Quadrata TT")
							GameCooltip2:SetOption("TextColor", "orange")
							GameCooltip2:SetOption("TextSize", 12)
							GameCooltip2:SetOption("FixedWidth", 220)
							GameCooltip2:SetOption("ButtonsYMod", -4)
							GameCooltip2:SetOption("YSpacingMod", -4)
							GameCooltip2:SetOption("IgnoreButtonAutoHeight", true)

							GameCooltip2:SetColor (1, 0.5, 0.5, 0.5, 0)

							local preset2_backdrop = {bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], edgeFile = [[Interface\Buttons\WHITE8X8]], tile = true, edgeSize = 1, tileSize = 16, insets = {left = 0, right = 0, top = 0, bottom = 0}}
							local gray_table = {0.37, 0.37, 0.37, 0.95}
							local black_table = {0.2, 0.2, 0.2, 1}
							GameCooltip2:SetBackdrop(1, preset2_backdrop, gray_table, black_table)
							GameCooltip2:SetBackdrop(2, preset2_backdrop, gray_table, black_table)
						end,
					}
					GameCooltip2:CoolTipInject (otherTalents)

					function loadConditionsFrame.CanShowTalentWarning()
						local playerTalents = detailsFramework:GetCharacterTalents()
						local indexedTalents = {}
						for _, talentTable in ipairs(playerTalents) do
							tinsert(indexedTalents, talentTable.ID)
						end
						for talentID, _ in pairs(loadConditionsFrame.OptionsTable.talent) do
							if (type(talentID) == "number" and not detailsFramework.table.find (indexedTalents, talentID)) then
								otherTalents:Show()
								return
							end
						end
						otherTalents:Hide()
					end
				end
			end

		--create radio group for pvp talents
			if IS_WOW_PROJECT_MAINLINE then
				local pvpTalentList = {}
				for _, talentTable in ipairs(detailsFramework:GetCharacterPvPTalents()) do
					tinsert(pvpTalentList, {
						name = talentTable.Name,
						set = loadConditionsFrame.OnRadioCheckboxClick,
						param = talentTable.ID,
						get = function() return loadConditionsFrame.OptionsTable.pvptalent [talentTable.ID] or loadConditionsFrame.OptionsTable.pvptalent [talentTable.ID .. ""] end,
						texture = talentTable.Texture,
					})
				end
				local pvpTalentGroup = detailsFramework:CreateCheckboxGroup (loadConditionsFrame, pvpTalentList, name, {width = 200, height = 200, title = "Characer PvP Talents"}, {offset_x = 150, amount_per_line = 3})
				pvpTalentGroup:SetPoint("topleft", loadConditionsFrame, "topleft", anchorPositions.pvptalent [1], anchorPositions.pvptalent [2])
				pvpTalentGroup.DBKey = "pvptalent"
				tinsert(loadConditionsFrame.AllRadioGroups, pvpTalentGroup)
				loadConditionsFrame.PvPTalentGroup = pvpTalentGroup

				do
					--create a frame to show talents selected in other specs or characters
					local otherTalents = CreateFrame("frame", nil, loadConditionsFrame, "BackdropTemplate")
					otherTalents:SetSize(26, 26)
					otherTalents:SetPoint("left", pvpTalentGroup.Title.widget, "right", 10, -2)
					otherTalents.Texture = detailsFramework:CreateImage(otherTalents, [[Interface\BUTTONS\AdventureGuideMicrobuttonAlert]], 24, 24)
					otherTalents.Texture:SetAllPoints()

					local removeTalent = function(_, _, talentID)
						loadConditionsFrame.OptionsTable.pvptalent [talentID] = nil
						GameCooltip2:Hide()
						loadConditionsFrame.OnRadioStateChanged (pvpTalentGroup, loadConditionsFrame.OptionsTable [pvpTalentGroup.DBKey])
						loadConditionsFrame.CanShowPvPTalentWarning()
					end

					local buildTalentMenu = function()
						local playerTalents = detailsFramework:GetCharacterPvPTalents()
						local indexedTalents = {}
						for _, talentTable in ipairs(playerTalents) do
							tinsert(indexedTalents, talentTable.ID)
						end

						--talents selected to load
						GameCooltip2:AddLine("select a talent to remove it (added from a different spec or character)", "", 1, "orange", "orange", 9)
						GameCooltip2:AddLine("$div", nil, nil, -1, -1)

						for talentID, _ in pairs(loadConditionsFrame.OptionsTable.pvptalent) do
							if (type(talentID) == "number" and not detailsFramework.table.find (indexedTalents, talentID)) then
								local _, name, texture = GetPvpTalentInfoByID (talentID)
								if (name) then
									GameCooltip2:AddLine(name)
									GameCooltip2:AddIcon (texture, 1, 1, 16, 16, .1, .9, .1, .9)
									GameCooltip2:AddMenu (1, removeTalent, talentID)
								end
							end
						end
					end

					otherTalents.CoolTip = {
						Type = "menu",
						BuildFunc = buildTalentMenu,
						OnEnterFunc = function(self) end,
						OnLeaveFunc = function(self) end,
						FixedValue = "none",
						ShowSpeed = 0.05,
						Options = function()
							GameCooltip2:SetOption("TextFont", "Friz Quadrata TT")
							GameCooltip2:SetOption("TextColor", "orange")
							GameCooltip2:SetOption("TextSize", 12)
							GameCooltip2:SetOption("FixedWidth", 220)
							GameCooltip2:SetOption("ButtonsYMod", -4)
							GameCooltip2:SetOption("YSpacingMod", -4)
							GameCooltip2:SetOption("IgnoreButtonAutoHeight", true)

							GameCooltip2:SetColor (1, 0.5, 0.5, 0.5, 0)

							local preset2_backdrop = {edgeFile = [[Interface\Buttons\WHITE8X8]], edgeFile = [[Interface\Buttons\WHITE8X8]], tile = true, edgeSize = 1, tileSize = 16, insets = {left = 0, right = 0, top = 0, bottom = 0}}
							local gray_table = {0.37, 0.37, 0.37, 0.95}
							local black_table = {0.2, 0.2, 0.2, 1}
							GameCooltip2:SetBackdrop(1, preset2_backdrop, gray_table, black_table)
							GameCooltip2:SetBackdrop(2, preset2_backdrop, gray_table, black_table)
						end,
					}
					GameCooltip2:CoolTipInject (otherTalents)

					function loadConditionsFrame.CanShowPvPTalentWarning()
						local playerTalents = detailsFramework:GetCharacterPvPTalents()
						local indexedTalents = {}
						for _, talentTable in ipairs(playerTalents) do
							tinsert(indexedTalents, talentTable.ID)
						end
						for talentID, _ in pairs(loadConditionsFrame.OptionsTable.pvptalent) do
							if (type(talentID) == "number" and not detailsFramework.table.find (indexedTalents, talentID)) then
								otherTalents:Show()
								return
							end
						end
						otherTalents:Hide()
					end
				end
			end

		--create radio for group types
			local groupTypes = {}
			for _, groupTable in ipairs(detailsFramework:GetGroupTypes()) do
				tinsert(groupTypes, {
					name = groupTable.Name,
					set = loadConditionsFrame.OnRadioCheckboxClick,
					param = groupTable.ID,
					get = function() return loadConditionsFrame.OptionsTable.group [groupTable.ID] or loadConditionsFrame.OptionsTable.group [groupTable.ID .. ""] end,
				})
			end
			local groupTypesGroup = detailsFramework:CreateCheckboxGroup (loadConditionsFrame, groupTypes, name, {width = 200, height = 200, title = "Group Types"})
			groupTypesGroup:SetPoint("topleft", loadConditionsFrame, "topleft", anchorPositions.group [1], anchorPositions.group [2])
			groupTypesGroup.DBKey = "group"
			tinsert(loadConditionsFrame.AllRadioGroups, groupTypesGroup)

		--create radio for character roles
			local roleTypes = {}
			for _, roleTable in ipairs(detailsFramework:GetRoleTypes()) do
				tinsert(roleTypes, {
					name = roleTable.Texture .. " " .. roleTable.Name,
					set = loadConditionsFrame.OnRadioCheckboxClick,
					param = roleTable.ID,
					get = function() return loadConditionsFrame.OptionsTable.role [roleTable.ID] or loadConditionsFrame.OptionsTable.role [roleTable.ID .. ""] end,
				})
			end
			local roleTypesGroup = detailsFramework:CreateCheckboxGroup (loadConditionsFrame, roleTypes, name, {width = 200, height = 200, title = "Role Types"})
			roleTypesGroup:SetPoint("topleft", loadConditionsFrame, "topleft", anchorPositions.role [1], anchorPositions.role [2])
			roleTypesGroup.DBKey = "role"
			tinsert(loadConditionsFrame.AllRadioGroups, roleTypesGroup)

		--create radio group for mythic+ affixes
			if IS_WOW_PROJECT_MAINLINE then
				local affixes = {}
				for i = 2, 1000 do
					local affixName, desc, texture = C_ChallengeMode.GetAffixInfo (i)
					if (affixName) then
						tinsert(affixes, {
							name = affixName,
							set = loadConditionsFrame.OnRadioCheckboxClick,
							param = i,
							get = function() return loadConditionsFrame.OptionsTable.affix [i] or loadConditionsFrame.OptionsTable.affix [i .. ""] end,
							texture = texture,
						})
					end
				end
				local affixTypesGroup = detailsFramework:CreateCheckboxGroup (loadConditionsFrame, affixes, name, {width = 200, height = 200, title = "M+ Affixes"})
				affixTypesGroup:SetPoint("topleft", loadConditionsFrame, "topleft", anchorPositions.affix [1], anchorPositions.affix [2])
				affixTypesGroup.DBKey = "affix"
				tinsert(loadConditionsFrame.AllRadioGroups, affixTypesGroup)
			end

		--text entries functions
			local textEntryRefresh = function(self)
				local idList = loadConditionsFrame.OptionsTable [self.DBKey]
				self:SetText("")
				for _, id in pairs(idList) do
					if tonumber(id) then
						self:SetText(self:GetText() .. " " .. id)
					end
				end
				self:SetText(self:GetText():gsub("^ ", ""))
			end

			local textEntryOnEnterPressed = function(_, self)
				wipe (loadConditionsFrame.OptionsTable [self.DBKey])
				local text = self:GetText()

				for _, ID in ipairs({strsplit(" ", text)}) do
					ID = detailsFramework:trim (ID)
					ID = tonumber(ID)
					if (ID) then
						tinsert(loadConditionsFrame.OptionsTable [self.DBKey], ID)
						loadConditionsFrame.OptionsTable [self.DBKey].Enabled = true
					end
				end
			end

		--create the text entry to type the encounter ID
			local encounterIDLabel = detailsFramework:CreateLabel(loadConditionsFrame, "Encounter ID", detailsFramework:GetTemplate("font", "ORANGE_FONT_TEMPLATE"))
			local encounterIDEditbox = detailsFramework:CreateTextEntry(loadConditionsFrame, function()end, 200, 20, "EncounterEditbox", _, _, detailsFramework:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"))
			encounterIDLabel:SetPoint("topleft", loadConditionsFrame, "topleft", anchorPositions.encounter_ids [1], anchorPositions.encounter_ids [2])
			encounterIDEditbox:SetPoint("topleft", encounterIDLabel, "bottomleft", 0, -2)
			encounterIDEditbox.DBKey = "encounter_ids"
			encounterIDEditbox.Refresh = textEntryRefresh
			encounterIDEditbox.tooltip = "Enter multiple IDs separating with a whitespace.\nExample: 35 45 95\n\nSanctum of Domination:\n"
			for _, encounterTable in ipairs(detailsFramework:GetCLEncounterIDs()) do
				encounterIDEditbox.tooltip = encounterIDEditbox.tooltip .. encounterTable.ID .. " - " .. encounterTable.Name .. "\n"
			end
			encounterIDEditbox:SetHook("OnEnterPressed", textEntryOnEnterPressed)
			tinsert(loadConditionsFrame.AllTextEntries, encounterIDEditbox)

		--create the text entry for map ID
			local mapIDLabel = detailsFramework:CreateLabel(loadConditionsFrame, "Map ID", detailsFramework:GetTemplate("font", "ORANGE_FONT_TEMPLATE"))
			local mapIDEditbox = detailsFramework:CreateTextEntry(loadConditionsFrame, function()end, 200, 20, "MapEditbox", _, _, detailsFramework:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"))
			mapIDLabel:SetPoint("topleft", loadConditionsFrame, "topleft", anchorPositions.map_ids [1], anchorPositions.map_ids [2])
			mapIDEditbox:SetPoint("topleft", mapIDLabel, "bottomleft", 0, -2)
			mapIDEditbox.DBKey = "map_ids"
			mapIDEditbox.Refresh = textEntryRefresh
			mapIDEditbox.tooltip = "Enter multiple IDs separating with a whitespace\nExample: 35 45 95"
			mapIDEditbox:SetHook("OnEnterPressed", textEntryOnEnterPressed)
			tinsert(loadConditionsFrame.AllTextEntries, mapIDEditbox)

		function loadConditionsFrame.Refresh (self)
			if IS_WOW_PROJECT_MAINLINE then
				--update the talents (might have changed if the player changed its specializationid)
				local talentList = {}
				for _, talentTable in ipairs(detailsFramework:GetCharacterTalents()) do
					if talentTable.ID then
						tinsert(talentList, {
							name = talentTable.Name,
							set = DetailsFrameworkLoadConditionsPanel.OnRadioCheckboxClick,
							param = talentTable.ID,
							get = function() return DetailsFrameworkLoadConditionsPanel.OptionsTable.talent [talentTable.ID] or DetailsFrameworkLoadConditionsPanel.OptionsTable.talent [talentTable.ID .. ""] end,
							texture = talentTable.Texture,
						})
					end
				end
				DetailsFrameworkLoadConditionsPanel.TalentGroup:SetOptions (talentList)
			end

			if IS_WOW_PROJECT_MAINLINE then
				local pvpTalentList = {}
				for _, talentTable in ipairs(detailsFramework:GetCharacterPvPTalents()) do
					tinsert(pvpTalentList, {
						name = talentTable.Name,
						set = DetailsFrameworkLoadConditionsPanel.OnRadioCheckboxClick,
						param = talentTable.ID,
						get = function() return DetailsFrameworkLoadConditionsPanel.OptionsTable.pvptalent [talentTable.ID] or DetailsFrameworkLoadConditionsPanel.OptionsTable.pvptalent [talentTable.ID .. ""] end,
						texture = talentTable.Texture,
					})
				end
				DetailsFrameworkLoadConditionsPanel.PvPTalentGroup:SetOptions (pvpTalentList)
			end

			--refresh the radio group
			for _, radioGroup in ipairs(DetailsFrameworkLoadConditionsPanel.AllRadioGroups) do
				radioGroup:Refresh()
				DetailsFrameworkLoadConditionsPanel.OnRadioStateChanged (radioGroup, DetailsFrameworkLoadConditionsPanel.OptionsTable [radioGroup.DBKey])
			end

			--refresh text entries
			for _, textEntry in ipairs(DetailsFrameworkLoadConditionsPanel.AllTextEntries) do
				textEntry:Refresh()
			end

			if IS_WOW_PROJECT_MAINLINE then
				DetailsFrameworkLoadConditionsPanel.CanShowTalentWarning()
				DetailsFrameworkLoadConditionsPanel.CanShowPvPTalentWarning()
			end
		end

	end

	--set the options table
	DetailsFrameworkLoadConditionsPanel.OptionsTable = optionsTable

	--set the callback func
	DetailsFrameworkLoadConditionsPanel.CallbackFunc = callback
	DetailsFrameworkLoadConditionsPanel.OptionsTable = optionsTable

	--set title
	DetailsFrameworkLoadConditionsPanel.EditingLabel:SetText(frameOptions.name)
	DetailsFrameworkLoadConditionsPanel.Title:SetText(frameOptions.title)

	--show the panel to the user
	DetailsFrameworkLoadConditionsPanel:Show()

	DetailsFrameworkLoadConditionsPanel:Refresh()
end


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--simple data scroll

detailsFramework.DataScrollFunctions = {
	RefreshScroll = function(self, data, offset, totalLines)
		local filter = self.Filter
		local currentData = {}
		if (type(filter) == "string" and filter ~= "") then
			for i = 1, #data do
				for o = 1, #data[i] do
					if (data[i][o]:find(filter)) then
						tinsert(currentData, data[i])
						break
					end
				end
			end
		else
			currentData = data
		end

		if (self.SortAlphabetical) then
			table.sort (currentData, function(t1, t2) return t1[1] < t2[1] end)
		end

		--update the scroll
		for i = 1, totalLines do
			local index = i + offset
			local thisData = currentData [index]
			if (thisData) then
				local line = self:GetLine (i)
				line:Update (index, thisData)
			end
		end
	end,

	CreateLine = function(self, index)
		--create a new line
		local line = CreateFrame("button", "$parentLine" .. index, self, "BackdropTemplate")
		line.Update = self.options.update_line_func

		--set its parameters
		line:SetPoint("topleft", self, "topleft", 1, -((index-1) * (self.options.line_height+1)) - 1)
		line:SetSize(self.options.width - 2, self.options.line_height)
		line:RegisterForClicks ("LeftButtonDown", "RightButtonDown")

		line:SetScript("OnEnter",	self.options.on_enter)
		line:SetScript("OnLeave",	self.options.on_leave)
		line:SetScript("OnClick",	self.options.on_click)

		line:SetBackdrop(self.options.backdrop)
		line:SetBackdropColor(unpack(self.options.backdrop_color))
		line:SetBackdropBorderColor(unpack(self.options.backdrop_border_color))

		local title = detailsFramework:CreateLabel(line, "", detailsFramework:GetTemplate("font", self.options.title_template))
		local date = detailsFramework:CreateLabel(line, "", detailsFramework:GetTemplate("font", self.options.title_template))
		local text = detailsFramework:CreateLabel(line, "", detailsFramework:GetTemplate("font", self.options.text_tempate))

		title.textsize = 14
		date.textsize = 14
		text:SetSize(self.options.width - 20, self.options.line_height)
		text:SetJustifyV ("top")

		--setup anchors
		if (self.options.show_title) then
			title:SetPoint("topleft", line, "topleft", 2, 0)
			date:SetPoint("topright", line, "topright", -2, 0)
			text:SetPoint("topleft", title, "bottomleft", 0, -4)
		else
			text:SetPoint("topleft", line, "topleft", 2, 0)
		end

		line.Title = title
		line.Date = date
		line.Text = text

		line.backdrop_color = self.options.backdrop_color or {.1, .1, .1, .3}
		line.backdrop_color_highlight = self.options.backdrop_color_highlight or {.3, .3, .3, .5}

		return line
	end,

	LineOnEnter = function(self)
		self:SetBackdropColor(unpack(self.backdrop_color_highlight))
	end,
	LineOnLeave = function(self)
		self:SetBackdropColor(unpack(self.backdrop_color))
	end,

	OnClick = function(self)

	end,

	UpdateLine = function(line, lineIndex, data)
		local parent = line:GetParent()

		if (parent.options.show_title) then
			line.Title.text = data [2] or ""
			line.Date.text = data [3] or ""
			line.Text.text = data [4] or ""
		else
			line.Text.text = data [2] or ""
		end

		if (line:GetParent().OnUpdateLineHook) then
			detailsFramework:CoreDispatch((line:GetName() or "ScrollBoxDataScrollUpdateLineHook") .. ":UpdateLineHook()", line:GetParent().OnUpdateLineHook, line, lineIndex, data)
		end
	end,
}

local default_datascroll_options = {
	width = 400,
	height = 700,
	line_amount = 10,
	line_height = 20,

	show_title = true,

	backdrop = {edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1, bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true},
	backdrop_color = {0, 0, 0, 0.2},
	backdrop_color_highlight = {.2, .2, .2, 0.4},
	backdrop_border_color = {0.1, 0.1, 0.1, .2},

	title_template = "ORANGE_FONT_TEMPLATE",
	text_tempate = "OPTIONS_FONT_TEMPLATE",

	create_line_func = detailsFramework.DataScrollFunctions.CreateLine,
	update_line_func = detailsFramework.DataScrollFunctions.UpdateLine,
	refresh_func = detailsFramework.DataScrollFunctions.RefreshScroll,
	on_enter = detailsFramework.DataScrollFunctions.LineOnEnter,
	on_leave = detailsFramework.DataScrollFunctions.LineOnLeave,
	on_click =  detailsFramework.DataScrollFunctions.OnClick,

	data = {},
}

--[=[
	Create a scroll frame to show text in an organized way
	Functions in the options table can be overritten to customize the layout
	@parent = the parent of the frame
	@name = the frame name to use in the CreateFrame call
	@options = options table to override default values from the table above
--]=]
function detailsFramework:CreateDataScrollFrame (parent, name, options)
	--call the mixin with a dummy table to built the default options before the frame creation
	--this is done because CreateScrollBox needs parameters at creation time
	local optionsTable = {}
	detailsFramework.OptionsFunctions.BuildOptionsTable (optionsTable, default_datascroll_options, options)
	optionsTable = optionsTable.options

	--scroll frame
	local newScroll = detailsFramework:CreateScrollBox (parent, name, optionsTable.refresh_func, optionsTable.data, optionsTable.width, optionsTable.height, optionsTable.line_amount, optionsTable.line_height)
	detailsFramework:ReskinSlider(newScroll)

	detailsFramework:Mixin(newScroll, detailsFramework.OptionsFunctions)
	detailsFramework:Mixin(newScroll, detailsFramework.LayoutFrame)

	newScroll:BuildOptionsTable (default_datascroll_options, options)

	--create the scrollbox lines
	for i = 1, newScroll.options.line_amount do
		newScroll:CreateLine (newScroll.options.create_line_func)
	end

	newScroll:Refresh()

	return newScroll
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--"WHAT's NEW" window

local default_newsframe_options = {
	width = 400,
	height = 700,

	line_amount = 16,
	line_height = 40,

	backdrop = {edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1, bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true},
	backdrop_color = {0, 0, 0, 0.2},
	backdrop_border_color = {0.1, 0.1, 0.1, .2},

	title = "What's New?",
	show_title = true,
}

detailsFramework.NewsFrameFunctions = {

}

--[=[
	Get the amount of news that the player didn't see yet
	@newsTable = an indexed table of tables
	@lastNewsTime = last time the player opened the news window
--]=]
function detailsFramework:GetNumNews (newsTable, lastNewsTime)
	local now = time()
	local nonReadNews = 0

	for _, news in ipairs(newsTable) do
		if (news[1] > lastNewsTime) then
			nonReadNews = nonReadNews + 1
		end
	end

	return nonReadNews
end

--[=[
	Creates a panel with a scroll to show texts organized in separated lines
	@parent =  the parent of the frame
	@name = the frame name to use in the CreateFrame call
	@options = options table to override default values from the table above
	@newsTable = an indexed table of tables
	@db = (optional) an empty table from the addon database to store the position of the frame between game sessions
--]=]
function detailsFramework:CreateNewsFrame (parent, name, options, newsTable, db)

	local f = detailsFramework:CreateSimplePanel(parent, 400, 700, options and options.title or default_newsframe_options.title, name, {UseScaleBar = db and true}, db)
	f:SetFrameStrata("MEDIUM")
	detailsFramework:ApplyStandardBackdrop(f)

	detailsFramework:Mixin(f, detailsFramework.OptionsFunctions)
	detailsFramework:Mixin(f, detailsFramework.LayoutFrame)

	f:BuildOptionsTable (default_newsframe_options, options)

	f:SetSize(f.options.width, f.options.height)
	f:SetBackdrop(f.options.backdrop)
	f:SetBackdropColor(unpack(f.options.backdrop_color))
	f:SetBackdropBorderColor(unpack(f.options.backdrop_border_color))

	local scrollOptions = {
		data = newsTable,
		width = f.options.width - 32, --frame distance from walls and scroll bar space
		height = f.options.height - 40 + (not f.options.show_title and 20 or 0),
		line_amount = f.options.line_amount,
		line_height = f.options.line_height,
	}
	local newsScroll = detailsFramework:CreateDataScrollFrame (f, "$parentScroll", scrollOptions)

	if (not f.options.show_title) then
		f.TitleBar:Hide()
		newsScroll:SetPoint("topleft", f, "topleft", 5, -10)
	else
		newsScroll:SetPoint("topleft", f, "topleft", 5, -30)
	end

	f.NewsScroll = newsScroll

	return f
end



------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--statusbar info

--[[
	authorTable = {
		{
			authorName = "author name 1",
			link = "twitter.com/author1Handle",
		}
	}
]]

function detailsFramework:BuildStatusbarAuthorInfo(f, addonBy, authorsNameString)
	local authorName = detailsFramework:CreateLabel(f, "" .. (addonBy or "An addon by ") .. "|cFFFFFFFF" .. (authorsNameString or "Terciob") .. "|r")
	authorName.textcolor = "silver"
	local discordLabel = detailsFramework:CreateLabel(f, "Discord: ")
	discordLabel.textcolor = "silver"

	local options_dropdown_template = detailsFramework:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE")
	local discordTextEntry = detailsFramework:CreateTextEntry(f, function()end, 200, 18, "DiscordTextBox", _, _, options_dropdown_template)
	discordTextEntry:SetText("https://discord.gg/AGSzAZX")
	discordTextEntry:SetFrameLevel(5000)

	authorName:SetPoint("left", f, "left", 2, 0)
	discordLabel:SetPoint("left", authorName, "right", 20, 0)
	discordTextEntry:SetPoint("left", discordLabel, "right", 2, 0)

	--format
	authorName:SetAlpha(.6)
	discordLabel:SetAlpha(.6)
	discordTextEntry:SetAlpha(.6)
	discordTextEntry:SetBackdropBorderColor(1, 1, 1, 0)

	discordTextEntry:SetHook("OnEditFocusGained", function()
		discordTextEntry:HighlightText()
	end)

	f.authorName = authorName
	f.discordLabel = discordLabel
	f.discordTextEntry = discordTextEntry
end

local statusbar_default_options = {
	attach = "bottom", --bottomleft from statusbar attach to bottomleft of the frame | other option is "top": topleft attach to bottomleft
}

function detailsFramework:CreateStatusBar(f, options)
	local statusBar = CreateFrame("frame", nil, f, "BackdropTemplate")

	detailsFramework:Mixin(statusBar, detailsFramework.OptionsFunctions)
	detailsFramework:Mixin(statusBar, detailsFramework.LayoutFrame)

	statusBar:BuildOptionsTable (statusbar_default_options, options)

	if (statusBar.options.attach == "bottom") then
		statusBar:SetPoint("bottomleft", f, "bottomleft")
		statusBar:SetPoint("bottomright", f, "bottomright")

	else
		statusBar:SetPoint("topleft", f, "bottomleft")
		statusBar:SetPoint("topright", f, "bottomright")
	end

	statusBar:SetHeight(20)
	detailsFramework:ApplyStandardBackdrop(statusBar)
	statusBar:SetAlpha(0.8)

	return statusBar
end


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--border frame

--[=[
	DF:CreateBorderFrame (parent, name)
	creates a frame with 4 child textures attached to each one of the 4 sides of a frame
	@parent = parent frame to pass to CreateFrame function
	@name = name of the frame, if omitted a random name is created
--]=]

detailsFramework.BorderFunctions = {
	SetBorderColor = function(self, r, g, b, a)
		r, g, b, a = detailsFramework:ParseColors(r, g, b, a)
		for _, texture in ipairs(self.allTextures) do
			texture:SetVertexColor(r, g, b, a)
		end
	end,

	SetBorderThickness = function(self, newThickness)
		PixelUtil.SetWidth (self.leftBorder, newThickness, newThickness)
		PixelUtil.SetWidth (self.rightBorder, newThickness, newThickness)
		PixelUtil.SetHeight(self.topBorder, newThickness, newThickness)
		PixelUtil.SetHeight(self.bottomBorder, newThickness, newThickness)
	end,

	WidgetType = "border",
}

-- ~borderframe
function detailsFramework:CreateBorderFrame(parent, name)
	local parentName = name or ("DetailsFrameworkBorderFrame" .. tostring(math.random(1, 100000000)))

	local f = CreateFrame("frame", parentName, parent, "BackdropTemplate")
	f:SetFrameLevel(f:GetFrameLevel()+1)
	f:SetAllPoints()

	detailsFramework:Mixin(f, detailsFramework.BorderFunctions)

	f.allTextures = {}

	--create left border
		local leftBorder = f:CreateTexture(nil, "overlay")
		leftBorder:SetDrawLayer("overlay", 7)
		leftBorder:SetColorTexture(1, 1, 1, 1)
		tinsert(f.allTextures, leftBorder)
		f.leftBorder = leftBorder
		PixelUtil.SetPoint(leftBorder, "topright", f, "topleft", 0, 1, 0, 1)
		PixelUtil.SetPoint(leftBorder, "bottomright", f, "bottomleft", 0, -1, 0, -1)
		PixelUtil.SetWidth (leftBorder, 1, 1)

	--create right border
		local rightBorder = f:CreateTexture(nil, "overlay")
		rightBorder:SetDrawLayer("overlay", 7)
		rightBorder:SetColorTexture(1, 1, 1, 1)
		tinsert(f.allTextures, rightBorder)
		f.rightBorder = rightBorder
		PixelUtil.SetPoint(rightBorder, "topleft", f, "topright", 0, 1, 0, 1)
		PixelUtil.SetPoint(rightBorder, "bottomleft", f, "bottomright", 0, -1, 0, -1)
		PixelUtil.SetWidth (rightBorder, 1, 1)

	--create top border
		local topBorder = f:CreateTexture(nil, "overlay")
		topBorder:SetDrawLayer("overlay", 7)
		topBorder:SetColorTexture(1, 1, 1, 1)
		tinsert(f.allTextures, topBorder)
		f.topBorder = topBorder
		PixelUtil.SetPoint(topBorder, "bottomleft", f, "topleft", 0, 0, 0, 0)
		PixelUtil.SetPoint(topBorder, "bottomright", f, "topright", 0, 0, 0, 0)
		PixelUtil.SetHeight(topBorder, 1, 1)

	--create  border
		local bottomBorder = f:CreateTexture(nil, "overlay")
		bottomBorder:SetDrawLayer("overlay", 7)
		bottomBorder:SetColorTexture(1, 1, 1, 1)
		tinsert(f.allTextures, bottomBorder)
		f.bottomBorder = bottomBorder
		PixelUtil.SetPoint(bottomBorder, "topleft", f, "bottomleft", 0, 0, 0, 0)
		PixelUtil.SetPoint(bottomBorder, "topright", f, "bottomright", 0, 0, 0, 0)
		PixelUtil.SetHeight(bottomBorder, 1, 1)

	return f
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--horizontal scroll frame

local timeline_options = {
	width = 400,
	height = 700,
	line_height = 20,
	line_padding = 1,

	show_elapsed_timeline = true,
	elapsed_timeline_height = 20,

	--space to put the player/spell name and icons
	header_width = 150,

	--how many pixels will be use to represent 1 second
	pixels_per_second = 20,

	scale_min = 0.15,
	scale_max = 1,

	backdrop = {edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1, bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true},
	backdrop_color = {0, 0, 0, 0.2},
	backdrop_color_highlight = {.2, .2, .2, 0.4},
	backdrop_border_color = {0.1, 0.1, 0.1, .2},

	slider_backdrop = {edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1, bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true},
	slider_backdrop_color = {0, 0, 0, 0.2},
	slider_backdrop_border_color = {0.1, 0.1, 0.1, .2},

	title_template = "ORANGE_FONT_TEMPLATE",
	text_tempate = "OPTIONS_FONT_TEMPLATE",

	on_enter = function(self)
		self:SetBackdropColor(unpack(self.backdrop_color_highlight))
	end,
	on_leave = function(self)
		self:SetBackdropColor(unpack(self.backdrop_color))
	end,

	block_on_enter = function(self)

	end,
	block_on_leave = function(self)

	end,
}

local elapsedtime_frame_options = {
	backdrop = {bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true},
	backdrop_color = {.3, .3, .3, .7},

	text_color = {1, 1, 1, 1},
	text_size = 12,
	text_font = "Arial Narrow",
	text_outline = "NONE",

	height = 20,

	distance = 200, --distance in pixels between each label informing the time
	distance_min = 50, --minimum distance in pixels
	draw_line = true, --if true it'll draw a vertical line to represent a segment
	draw_line_color = {1, 1, 1, 0.2},
	draw_line_thickness = 1,
}

detailsFramework.TimeLineElapsedTimeFunctions = {
	--get a label and update its appearance
	GetLabel = function(self, index)
		local label = self.labels [index]

		if (not label) then
			label = self:CreateFontString(nil, "artwork", "GameFontNormal")
			label.line = self:CreateTexture(nil, "artwork")
			label.line:SetColorTexture(1, 1, 1)
			label.line:SetPoint("topleft", label, "bottomleft", 0, -2)
			self.labels [index] = label
		end

		detailsFramework:SetFontColor(label, self.options.text_color)
		detailsFramework:SetFontSize(label, self.options.text_size)
		detailsFramework:SetFontFace (label, self.options.text_font)
		detailsFramework:SetFontOutline (label, self.options.text_outline)

		if (self.options.draw_line) then
			label.line:SetVertexColor(unpack(self.options.draw_line_color))
			label.line:SetWidth(self.options.draw_line_thickness)
			label.line:Show()
		else
			label.line:Hide()
		end

		return label
	end,

	Reset = function(self)
		for i = 1, #self.labels do
			self.labels [i]:Hide()
		end
	end,

	Refresh = function(self, elapsedTime, scale)
		local parent = self:GetParent()

		self:SetHeight(self.options.height)
		local effectiveArea = self:GetWidth() --already scaled down width
		local pixelPerSecond = elapsedTime / effectiveArea --how much 1 pixels correlate to time

		local distance = self.options.distance --pixels between each segment
		local minDistance = self.options.distance_min --min pixels between each segment

		--scale the distance between each label showing the time with the parent's scale
		distance = distance * scale
		distance = max(distance, minDistance)

		local amountSegments = ceil (effectiveArea / distance)

		for i = 1, amountSegments do
			local label = self:GetLabel (i)
			local xOffset = distance * (i - 1)
			label:SetPoint("left", self, "left", xOffset, 0)

			local secondsOfTime = pixelPerSecond * xOffset

			label:SetText(detailsFramework:IntegerToTimer(floor(secondsOfTime)))

			if (label.line:IsShown()) then
				label.line:SetHeight(parent:GetParent():GetHeight())
			end

			label:Show()
		end
	end,
}

--creates a frame to show the elapsed time in a row
function detailsFramework:CreateElapsedTimeFrame(parent, name, options)
	local elapsedTimeFrame = CreateFrame("frame", name, parent, "BackdropTemplate")

	detailsFramework:Mixin(elapsedTimeFrame, detailsFramework.OptionsFunctions)
	detailsFramework:Mixin(elapsedTimeFrame, detailsFramework.LayoutFrame)
	detailsFramework:Mixin(elapsedTimeFrame, detailsFramework.TimeLineElapsedTimeFunctions)

	elapsedTimeFrame:BuildOptionsTable(elapsedtime_frame_options, options)

	elapsedTimeFrame:SetBackdrop(elapsedTimeFrame.options.backdrop)
	elapsedTimeFrame:SetBackdropColor(unpack(elapsedTimeFrame.options.backdrop_color))

	elapsedTimeFrame.labels = {}

	return elapsedTimeFrame
end


detailsFramework.TimeLineBlockFunctions = {
	--self is the line
	SetBlock = function(self, index, blockInfo)
		--get the block information
		--see what is the current scale
		--adjust the block position

		local block = self:GetBlock (index)

		--need:
			--the total time of the timeline
			--the current scale of the timeline
			--the elapsed time of this block
			--icon of the block
			--text
			--background color

	end,

	SetBlocksFromData = function(self)
		local parent = self:GetParent():GetParent()
		local data = parent.data
		local defaultColor = parent.defaultColor --guarantee to have a value

		self:Show()

		--none of these values are scaled, need to calculate
		local pixelPerSecond = parent.pixelPerSecond
		local totalLength = parent.totalLength
		local scale = parent.currentScale

		pixelPerSecond = pixelPerSecond * scale

		local headerWidth = parent.headerWidth

		--dataIndex stores which line index from the data this line will use
		--lineData store members: .text .icon .timeline
		local lineData = data.lines[self.dataIndex]

		self.spellId = lineData.spellId

		--if there's an icon, anchor the text at the right side of the icon
		--this is the title and icon of the title
		if (lineData.icon) then
			self.icon:SetTexture(lineData.icon)
			if (lineData.coords) then
				self.icon:SetTexCoord(unpack(lineData.coords))
			else
				self.icon:SetTexCoord(.1, .9, .1, .9)
			end
			self.text:SetText(lineData.text or "")
			self.text:SetPoint("left", self.icon.widget, "right", 2, 0)
		else
			self.icon:SetTexture(nil)
			self.text:SetText(lineData.text or "")
			self.text:SetPoint("left", self, "left", 2, 0)
		end

		if (self.dataIndex % 2 == 1) then
			self:SetBackdropColor(0, 0, 0, 0)
		else
			local r, g, b, a = unpack(self.backdrop_color)
			self:SetBackdropColor(r, g, b, a)
		end

		self:SetWidth(5000)

		local timelineData = lineData.timeline
		local spellId = lineData.spellId
		local useIconOnBlock = data.useIconOnBlocks

		local baseFrameLevel = parent:GetFrameLevel() + 10

		for i = 1, #timelineData do
			local blockInfo = timelineData[i]

			local timeInSeconds = blockInfo[1]
			local length = blockInfo[2]
			local isAura = blockInfo[3]
			local auraDuration = blockInfo[4]
			local blockSpellId = blockInfo[5]

			local payload = blockInfo.payload

			local xOffset = pixelPerSecond * timeInSeconds
			local width = pixelPerSecond * length

			if (timeInSeconds < -0.2) then
				xOffset = xOffset / 2.5
			end

			local block = self:GetBlock(i)
			block:Show()
			block:SetFrameLevel(baseFrameLevel + i)

			PixelUtil.SetPoint(block, "left", self, "left", xOffset + headerWidth, 0)

			block.info.spellId = blockSpellId or spellId
			block.info.time = timeInSeconds
			block.info.duration = auraDuration
			block.info.payload = payload

			if (useIconOnBlock) then
				local iconTexture = lineData.icon
				if (blockSpellId) then
					iconTexture = GetSpellTexture(blockSpellId)
				end

				block.icon:SetTexture(iconTexture)
				block.icon:SetTexCoord(.1, .9, .1, .9)
				block.icon:SetAlpha(.834)
				block.icon:SetSize(self:GetHeight(), self:GetHeight())

				if (timeInSeconds < -0.2) then
					block.icon:SetDesaturated(true)
				else
					block.icon:SetDesaturated(false)
				end

				PixelUtil.SetSize(block, self:GetHeight(), self:GetHeight())

				if (isAura) then
					block.auraLength:Show()
					block.auraLength:SetWidth(pixelPerSecond * isAura)
					block:SetWidth(max(pixelPerSecond * isAura, 16))
				else
					block.auraLength:Hide()
				end

				block.background:SetVertexColor(0, 0, 0, 0)
			else
				block.background:SetVertexColor(0, 0, 0, 0)
				PixelUtil.SetSize(block, max(width, 16), self:GetHeight())
				block.auraLength:Hide()
			end
		end
	end,

	GetBlock = function(self, index)
		local block = self.blocks [index]
		if (not block) then
			block = CreateFrame("frame", nil, self, "BackdropTemplate")
			self.blocks [index] = block

			local background = block:CreateTexture(nil, "background")
			background:SetColorTexture(1, 1, 1, 1)
			local icon = block:CreateTexture(nil, "artwork")
			local text = block:CreateFontString(nil, "artwork")
			local auraLength = block:CreateTexture(nil, "border")

			background:SetAllPoints()
			icon:SetPoint("left")
			text:SetPoint("left", icon, "left", 2, 0)
			auraLength:SetPoint("topleft", icon, "topleft", 0, 0)
			auraLength:SetPoint("bottomleft", icon, "bottomleft", 0, 0)
			auraLength:SetColorTexture(1, 1, 1, 1)
			auraLength:SetVertexColor(1, 1, 1, 0.1)

			block.icon = icon
			block.text = text
			block.background = background
			block.auraLength = auraLength

			block:SetScript("OnEnter", self:GetParent():GetParent().options.block_on_enter)
			block:SetScript("OnLeave", self:GetParent():GetParent().options.block_on_leave)

			block:SetMouseClickEnabled(false)
			block.info = {}
		end

		return block
	end,

	Reset = function(self)
		--attention, it doesn't reset icon texture, text and background color
		for i = 1, #self.blocks do
			self.blocks [i]:Hide()
		end
		self:Hide()
	end,
}

detailsFramework.TimeLineFunctions = {
	GetLine = function(self, index)
		local line = self.lines [index]
		if (not line) then
			--create a new line
			line = CreateFrame("frame", "$parentLine" .. index, self.body, "BackdropTemplate")
			detailsFramework:Mixin(line, detailsFramework.TimeLineBlockFunctions)
			self.lines [index] = line

			local lineHeader = CreateFrame("frame", nil, line, "BackdropTemplate")
			lineHeader:SetPoint("topleft", line, "topleft", 0, 0)
			lineHeader:SetPoint("bottomleft", line, "bottomleft", 0, 0)
			lineHeader:SetScript("OnEnter", self.options.header_on_enter)
			lineHeader:SetScript("OnLeave", self.options.header_on_leave)

			line.lineHeader = lineHeader

			--store the individual textures that shows the timeline information
			line.blocks = {}
			line.SetBlock = detailsFramework.TimeLineBlockFunctions.SetBlock
			line.GetBlock = detailsFramework.TimeLineBlockFunctions.GetBlock

			--set its parameters

			if (self.options.show_elapsed_timeline) then
				line:SetPoint("topleft", self.body, "topleft", 1, -((index-1) * (self.options.line_height + 1)) - 2 - self.options.elapsed_timeline_height)
			else
				line:SetPoint("topleft", self.body, "topleft", 1, -((index-1) * (self.options.line_height + 1)) - 1)
			end
			line:SetSize(1, self.options.line_height) --width is set when updating the frame

			line:SetScript("OnEnter", self.options.on_enter)
			line:SetScript("OnLeave", self.options.on_leave)
			line:SetMouseClickEnabled(false)

			line:SetBackdrop(self.options.backdrop)
			line:SetBackdropColor(unpack(self.options.backdrop_color))
			line:SetBackdropBorderColor(unpack(self.options.backdrop_border_color))

			local icon = detailsFramework:CreateImage(line, "", self.options.line_height, self.options.line_height)
			icon:SetPoint("left", line, "left", 2, 0)
			line.icon = icon

			local text = detailsFramework:CreateLabel(line, "", detailsFramework:GetTemplate("font", self.options.title_template))
			text:SetPoint("left", icon.widget, "right", 2, 0)
			line.text = text

			line.backdrop_color = self.options.backdrop_color or {.1, .1, .1, .3}
			line.backdrop_color_highlight = self.options.backdrop_color_highlight or {.3, .3, .3, .5}
		end

		return line
	end,

	ResetAllLines = function(self)
		for i = 1, #self.lines do
			self.lines[i]:Reset()
		end
	end,

	AdjustScale = function(self, index)

	end,

	--todo
	--make the on enter and leave tooltips
	--set icons and texts
	--skin the sliders

	RefreshTimeLine = function(self)
		--debug
		--self.currentScale = 1

		--calculate the total width
		local pixelPerSecond = self.options.pixels_per_second
		local totalLength = self.data.length or 1
		local currentScale = self.currentScale

		self.scaleSlider:Enable()

		--how many pixels represent 1 second
		local bodyWidth = totalLength * pixelPerSecond * currentScale
		self.body:SetWidth(bodyWidth + self.options.header_width)
		self.body.effectiveWidth = bodyWidth

		--reduce the default canvas size from the body with and don't allow the max value be negative
		local newMaxValue = max(bodyWidth - (self:GetWidth() - self.options.header_width), 0)

		--adjust the scale slider range
		local oldMin, oldMax = self.horizontalSlider:GetMinMaxValues()
		self.horizontalSlider:SetMinMaxValues(0, newMaxValue)
		self.horizontalSlider:SetValue(detailsFramework:MapRangeClamped(oldMin, oldMax, 0, newMaxValue, self.horizontalSlider:GetValue()))

		local defaultColor = self.data.defaultColor or {1, 1, 1, 1}

		--cache values
		self.pixelPerSecond = pixelPerSecond
		self.totalLength = totalLength
		self.defaultColor = defaultColor
		self.headerWidth = self.options.header_width

		--calculate the total height
		local lineHeight = self.options.line_height
		local linePadding = self.options.line_padding

		local bodyHeight = (lineHeight + linePadding) * #self.data.lines
		self.body:SetHeight(bodyHeight)
		self.verticalSlider:SetMinMaxValues(0, max(bodyHeight - self:GetHeight(), 0))
		self.verticalSlider:SetValue(0)

		--refresh lines
		self:ResetAllLines()
		for i = 1, #self.data.lines do
			local line = self:GetLine(i)
			line.dataIndex = i --this index is used inside the line update function to know which data to get
			line.lineHeader:SetWidth(self.options.header_width)
			line:SetBlocksFromData() --the function to update runs within the line object
		end

		--refresh elapsed time frame
		--the elapsed frame must have a width before the refresh function is called
		self.elapsedTimeFrame:ClearAllPoints()
		self.elapsedTimeFrame:SetPoint("topleft", self.body, "topleft", self.options.header_width, 0)
		self.elapsedTimeFrame:SetPoint("topright", self.body, "topright", 0, 0)
		self.elapsedTimeFrame:Reset()

		self.elapsedTimeFrame:Refresh(self.data.length, self.currentScale)
	end,

	SetData = function(self, data)
		self.data = data
		self:RefreshTimeLine()
	end,
}

--creates a regular scroll in horizontal position
function detailsFramework:CreateTimeLineFrame(parent, name, options, timelineOptions)
	local width = options and options.width or timeline_options.width
	local height = options and options.height or timeline_options.height
	local scrollWidth = 800 --placeholder until the timeline receives data
	local scrollHeight = 800 --placeholder until the timeline receives data

	local frameCanvas = CreateFrame("scrollframe", name, parent, "BackdropTemplate")

	detailsFramework:Mixin(frameCanvas, detailsFramework.TimeLineFunctions)
	detailsFramework:Mixin(frameCanvas, detailsFramework.OptionsFunctions)
	detailsFramework:Mixin(frameCanvas, detailsFramework.LayoutFrame)

	frameCanvas.data = {}
	frameCanvas.lines = {}
	frameCanvas.currentScale = 0.5
	frameCanvas:SetSize(width, height)

	detailsFramework:ApplyStandardBackdrop(frameCanvas)

	local frameBody = CreateFrame("frame", nil, frameCanvas, "BackdropTemplate")
	frameBody:SetSize(scrollWidth, scrollHeight)

	frameCanvas:SetScrollChild(frameBody)
	frameCanvas.body = frameBody

	frameCanvas:BuildOptionsTable(timeline_options, options)

	--create elapsed time frame
	frameCanvas.elapsedTimeFrame = detailsFramework:CreateElapsedTimeFrame(frameBody, frameCanvas:GetName() and frameCanvas:GetName() .. "ElapsedTimeFrame", timelineOptions)

	--create horizontal slider
		local horizontalSlider = CreateFrame("slider", frameCanvas:GetName() .. "HorizontalSlider", parent, "BackdropTemplate")
		horizontalSlider.bg = horizontalSlider:CreateTexture(nil, "background")
		horizontalSlider.bg:SetAllPoints(true)
		horizontalSlider.bg:SetTexture(0, 0, 0, 0.5)
		frameCanvas.horizontalSlider = horizontalSlider

		horizontalSlider:SetBackdrop(frameCanvas.options.slider_backdrop)
		horizontalSlider:SetBackdropColor(unpack(frameCanvas.options.slider_backdrop_color))
		horizontalSlider:SetBackdropBorderColor(unpack(frameCanvas.options.slider_backdrop_border_color))

		horizontalSlider.thumb = horizontalSlider:CreateTexture(nil, "OVERLAY")
		horizontalSlider.thumb:SetTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
		horizontalSlider.thumb:SetSize(24, 24)
		horizontalSlider.thumb:SetVertexColor(0.6, 0.6, 0.6, 0.95)
		horizontalSlider:SetThumbTexture(horizontalSlider.thumb)

		horizontalSlider:SetOrientation("horizontal")
		horizontalSlider:SetSize(width + 20, 20)
		horizontalSlider:SetPoint("topleft", frameCanvas, "bottomleft")
		horizontalSlider:SetMinMaxValues(0, scrollWidth)
		horizontalSlider:SetValue(0)
		horizontalSlider:SetScript("OnValueChanged", function(self)
			local _, maxValue = horizontalSlider:GetMinMaxValues()
			local stepValue = ceil(ceil(self:GetValue() * maxValue) / max(maxValue, SMALL_FLOAT))
			if (stepValue ~= horizontalSlider.currentValue) then
				horizontalSlider.currentValue = stepValue
				frameCanvas:SetHorizontalScroll(stepValue)
			end
		end)

	--create scale slider
		local scaleSlider = CreateFrame("slider", frameCanvas:GetName() .. "ScaleSlider", parent, "BackdropTemplate")
		scaleSlider.bg = scaleSlider:CreateTexture(nil, "background")
		scaleSlider.bg:SetAllPoints(true)
		scaleSlider.bg:SetTexture(0, 0, 0, 0.5)
		scaleSlider:Disable()
		frameCanvas.scaleSlider = scaleSlider

		scaleSlider:SetBackdrop(frameCanvas.options.slider_backdrop)
		scaleSlider:SetBackdropColor(unpack(frameCanvas.options.slider_backdrop_color))
		scaleSlider:SetBackdropBorderColor(unpack(frameCanvas.options.slider_backdrop_border_color))

		scaleSlider.thumb = scaleSlider:CreateTexture(nil, "OVERLAY")
		scaleSlider.thumb:SetTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
		scaleSlider.thumb:SetSize(24, 24)
		scaleSlider.thumb:SetVertexColor(0.6, 0.6, 0.6, 0.95)
		scaleSlider:SetThumbTexture(scaleSlider.thumb)

		scaleSlider:SetOrientation("horizontal")
		scaleSlider:SetSize(width + 20, 20)
		scaleSlider:SetPoint("topleft", horizontalSlider, "bottomleft", 0, -2)
		scaleSlider:SetMinMaxValues(frameCanvas.options.scale_min, frameCanvas.options.scale_max)
		scaleSlider:SetValue(detailsFramework:GetRangeValue(frameCanvas.options.scale_min, frameCanvas.options.scale_max, 0.5))

		scaleSlider:SetScript("OnValueChanged", function(self)
			local stepValue = ceil(self:GetValue() * 100) / 100
			if (stepValue ~= frameCanvas.currentScale) then
				local current = stepValue
				frameCanvas.currentScale = stepValue
				frameCanvas:RefreshTimeLine()
			end
		end)

	--create vertical slider
		local verticalSlider = CreateFrame("slider", frameCanvas:GetName() .. "VerticalSlider", parent, "BackdropTemplate")
		verticalSlider.bg = verticalSlider:CreateTexture(nil, "background")
		verticalSlider.bg:SetAllPoints(true)
		verticalSlider.bg:SetTexture(0, 0, 0, 0.5)
		frameCanvas.verticalSlider = verticalSlider

		verticalSlider:SetBackdrop(frameCanvas.options.slider_backdrop)
		verticalSlider:SetBackdropColor(unpack(frameCanvas.options.slider_backdrop_color))
		verticalSlider:SetBackdropBorderColor(unpack(frameCanvas.options.slider_backdrop_border_color))

		verticalSlider.thumb = verticalSlider:CreateTexture(nil, "OVERLAY")
		verticalSlider.thumb:SetTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
		verticalSlider.thumb:SetSize(24, 24)
		verticalSlider.thumb:SetVertexColor(0.6, 0.6, 0.6, 0.95)
		verticalSlider:SetThumbTexture(verticalSlider.thumb)

		verticalSlider:SetOrientation("vertical")
		verticalSlider:SetSize(20, height - 2)
		verticalSlider:SetPoint("topleft", frameCanvas, "topright", 0, 0)
		verticalSlider:SetMinMaxValues(0, scrollHeight)
		verticalSlider:SetValue(0)
		verticalSlider:SetScript("OnValueChanged", function(self)
		    frameCanvas:SetVerticalScroll(self:GetValue())
		end)

	--mouse scroll
		frameCanvas:EnableMouseWheel(true)
		frameCanvas:SetScript("OnMouseWheel", function(self, delta)
			local minValue, maxValue = horizontalSlider:GetMinMaxValues()
			local currentHorizontal = horizontalSlider:GetValue()

			if (IsShiftKeyDown() and delta < 0) then
				local amountToScroll = frameBody:GetHeight() / 20
				verticalSlider:SetValue(verticalSlider:GetValue() + amountToScroll)

			elseif (IsShiftKeyDown() and delta > 0) then
				local amountToScroll = frameBody:GetHeight() / 20
				verticalSlider:SetValue(verticalSlider:GetValue() - amountToScroll)

			elseif (IsControlKeyDown() and delta > 0) then
				scaleSlider:SetValue(min(scaleSlider:GetValue() + 0.1, 1))

			elseif (IsControlKeyDown() and delta < 0) then
				scaleSlider:SetValue(max(scaleSlider:GetValue() - 0.1, 0.15))

			elseif (delta < 0 and currentHorizontal < maxValue) then
				local amountToScroll = frameBody:GetWidth() / 20
				horizontalSlider:SetValue(currentHorizontal + amountToScroll)

			elseif (delta > 0 and maxValue > 1) then
				local amountToScroll = frameBody:GetWidth() / 20
				horizontalSlider:SetValue(currentHorizontal - amountToScroll)

			end
		end)

	--mouse drag
	frameBody:SetScript("OnMouseDown", function(self, button)
		local x = GetCursorPosition()
		self.MouseX = x

		frameBody:SetScript("OnUpdate", function(self, deltaTime)
			local x = GetCursorPosition()
			local deltaX = self.MouseX - x
			local current = horizontalSlider:GetValue()
			horizontalSlider:SetValue(current +(deltaX * 1.2) *((IsShiftKeyDown() and 2) or(IsAltKeyDown() and 0.5) or 1))
			self.MouseX = x
		end)
	end)

	frameBody:SetScript("OnMouseUp", function(self, button)
		frameBody:SetScript("OnUpdate", nil)
	end)

	return frameCanvas
end


--[=[
local f = CreateFrame("frame", "TestFrame", UIParent)
f:SetPoint("center")
f:SetSize(900, 420)
f:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16,	insets = {left = 1, right = 1, top = 0, bottom = 1}})

local scroll = DF:CreateTimeLineFrame (f, "$parentTimeLine", {width = 880, height = 400})
scroll:SetPoint("topleft", f, "topleft", 0, 0)

--need fake data to test fills
scroll:SetData ({
	length = 360,
	defaultColor = {1, 1, 1, 1},
	lines = {
			{text = "player 1", icon = "", timeline = {
				--each table here is a block shown in the line
				--is an indexed table with: [1] time [2] length [3] color (if false, use the default) [4] text [5] icon [6] tooltip: if number = spellID tooltip, if table is text lines
				{1, 10}, {13, 11}, {25, 7}, {36, 5}, {55, 18}, {76, 30}, {105, 20}, {130, 11}, {155, 11}, {169, 7}, {199, 16}, {220, 18}, {260, 10}, {290, 23}, {310, 30}, {350, 10}
			}
		}, --end of line 1
	},
})


f:Hide()

--scroll.body:SetScale(0.5)

--]=]

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--error message box

function detailsFramework:ShowErrorMessage (errorMessage, titleText)

	if (not detailsFramework.ErrorMessagePanel) then
		local f = CreateFrame("frame", "DetailsFrameworkErrorMessagePanel", UIParent, "BackdropTemplate")
		f:SetSize(400, 120)
		f:SetFrameStrata("FULLSCREEN")
		f:SetPoint("center", UIParent, "center", 0, 100)
		f:EnableMouse(true)
		f:SetMovable(true)
		f:RegisterForDrag ("LeftButton")
		f:SetScript("OnDragStart", function() f:StartMoving() end)
		f:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)
		f:SetScript("OnMouseDown", function(self, button) if (button == "RightButton") then f:Hide() end end)
		tinsert(UISpecialFrames, "DetailsFrameworkErrorMessagePanel")
		detailsFramework.ErrorMessagePanel = f

		detailsFramework:CreateTitleBar (f, "Details! Framework Error!")
		detailsFramework:ApplyStandardBackdrop(f)

		local errorLabel = f:CreateFontString(nil, "overlay", "GameFontNormal")
		errorLabel:SetPoint("top", f, "top", 0, -25)
		errorLabel:SetJustifyH("center")
		errorLabel:SetSize(360, 66)
		f.errorLabel = errorLabel

		local button_text_template = detailsFramework:GetTemplate("font", "OPTIONS_FONT_TEMPLATE")
		local options_dropdown_template = detailsFramework:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE")

		local closeButton = detailsFramework:CreateButton(f, nil, 60, 20, "close", nil, nil, nil, nil, nil, nil, options_dropdown_template)
		closeButton:SetPoint("bottom", f, "bottom", 0, 5)
		f.closeButton = closeButton

		closeButton:SetClickFunction(function()
			f:Hide()
		end)

		f.ShowAnimation = detailsFramework:CreateAnimationHub (f, function()
			f:SetBackdropBorderColor(0, 0, 0, 0)
			f.TitleBar:SetBackdropBorderColor(0, 0, 0, 0)
		end, function()
			f:SetBackdropBorderColor(0, 0, 0, 1)
			f.TitleBar:SetBackdropBorderColor(0, 0, 0, 1)
		end)
		detailsFramework:CreateAnimation(f.ShowAnimation, "scale", 1, .075, .2, .2, 1.1, 1.1, "center", 0, 0)
		detailsFramework:CreateAnimation(f.ShowAnimation, "scale", 2, .075, 1, 1, .90, .90, "center", 0, 0)

		f.FlashTexture = f:CreateTexture(nil, "overlay")
		f.FlashTexture:SetColorTexture(1, 1, 1, 1)
		f.FlashTexture:SetAllPoints()

		f.FlashAnimation = detailsFramework:CreateAnimationHub (f.FlashTexture, function() f.FlashTexture:Show() end, function() f.FlashTexture:Hide() end)
		detailsFramework:CreateAnimation(f.FlashAnimation, "alpha", 1, .075, 0, .05)
		detailsFramework:CreateAnimation(f.FlashAnimation, "alpha", 2, .075, .1, 0)

		f:Hide()
	end

	detailsFramework.ErrorMessagePanel:Show()
	detailsFramework.ErrorMessagePanel.errorLabel:SetText(errorMessage)
	detailsFramework.ErrorMessagePanel.TitleLabel:SetText(titleText)
	detailsFramework.ErrorMessagePanel.ShowAnimation:Play()
	detailsFramework.ErrorMessagePanel.FlashAnimation:Play()
end

--[[
	DF:SetPointOffsets(frame, xOffset, yOffset)

	Set an offset into the already existing offset of the frame
	If passed xOffset:1 and yOffset:1 and the frame has 1 -1,  the new offset will be 2 -2
	This function is great to create a 1 knob for distance

	@frame: a frame to have the offsets changed
	@xOffset: the amount to apply into the x offset
	@yOffset: the amount to apply into the y offset
--]]
function detailsFramework:SetPointOffsets(frame, xOffset, yOffset)
	for i = 1, frame:GetNumPoints() do
		local anchor1, anchorTo, anchor2, x, y = frame:GetPoint(i)
		x = x or 0
		y = y or 0

		if (x >= 0) then
			xOffset = x + xOffset

		elseif (x < 0) then
			xOffset = x - xOffset
		end

		if (y >= 0) then
			yOffset = y + yOffset

		elseif (y < 0) then
			yOffset = y - yOffset
		end

		frame:SetPoint(anchor1, anchorTo, anchor2, xOffset, yOffset)
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--list box

detailsFramework.ListboxFunctions = {
	scrollRefresh = function(self, data, offset, totalLines)
		for i = 1, totalLines do
			local index = i + offset
			local lineData = data[index] --what is shown in the textentries, array

			if (lineData) then
				local line = self:GetLine(i)
				line.dataIndex = index
				line.deleteButton:SetClickFunction(detailsFramework.ListboxFunctions.deleteEntry, data, index)
				line.indexText:SetText(index)

				local amountEntries = #lineData
				for o = 1, amountEntries do
					--data
					local textEntry = line.widgets[o]
					textEntry.dataTable = lineData
					textEntry.dataTableIndex = o
					local text = lineData[o]
					textEntry:SetText(text)
				end
			end
		end
	end,

	addEntry = function(self)
		local frameCanvas = self:GetParent()
		local data = frameCanvas.data
		local newEntry = {}
		for i = 1, frameCanvas.headerLength do
			tinsert(newEntry, "")
		end
		tinsert(data, newEntry)
		frameCanvas.scrollBox:Refresh()
	end,

	deleteEntry = function(self, button, data, index)
		tremove(data, index)
		--get the line, get the scrollframe
		self:GetParent():GetParent():Refresh()
	end,

	createScrollLine = function(self, index)
		local listBox = self:GetParent()
		local line = CreateFrame("frame", self:GetName().. "line_" .. index, self, "BackdropTemplate")

		line:SetPoint("topleft", self, "topleft", 1, -((index-1)*(self.lineHeight+1)) - 1)
		line:SetSize(self:GetWidth() - 28, self.lineHeight) -- -28 space for the scrollbar

		local options = listBox.options
		line:SetBackdrop(options.line_backdrop)
		line:SetBackdropColor(unpack(options.line_backdrop_color))
		line:SetBackdropBorderColor(unpack(options.line_backdrop_border_color))

		detailsFramework:Mixin(line, detailsFramework.HeaderFunctions)

		line.widgets = {}

		for i = 1, (listBox.headerLength+2) do --+2 to add the delete button and index
			local headerColumn = listBox.headerTable[i]

			if (headerColumn.isDelete) then
				local deleteButton = detailsFramework:CreateButton(line, detailsFramework.ListboxFunctions.deleteEntry, 20, self.lineHeight, "X", listBox.data, index, nil, nil, nil, nil, detailsFramework:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"), detailsFramework:GetTemplate("font", "ORANGE_FONT_TEMPLATE"))
				line.deleteButton = deleteButton
				line:AddFrameToHeaderAlignment(deleteButton)

			elseif (headerColumn.isIndex) then
				local indexText = detailsFramework:CreateLabel(line)
				line.indexText = indexText
				line:AddFrameToHeaderAlignment(indexText)

			elseif (headerColumn.text) then
				local template = detailsFramework.table.copy({}, detailsFramework:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"))
				template.backdropcolor = {.1, .1, .1, .7}
				template.backdropbordercolor = {.2, .2, .2, .6}

				local textEntry = detailsFramework:CreateTextEntry(line, function()end, headerColumn.width, self.lineHeight, nil, nil, nil, template)
				textEntry:SetHook("OnEditFocusGained", function() textEntry:HighlightText(0) end)
				textEntry:SetHook("OnEditFocusLost", function()
					textEntry:HighlightText(0, 0)
					local text = textEntry.text
					local dataTable = textEntry.dataTable
					dataTable[textEntry.dataTableIndex] = text
				end)
				tinsert(line.widgets, textEntry)
				line:AddFrameToHeaderAlignment(textEntry)
			end
		end

		line:AlignWithHeader(listBox.header, "left")
		return line
	end,

	SetData = function(frameCanvas, newData)
		if (type(newData) ~= "table") then
			error("ListBox:SetData received an invalid newData on parameter 2.")
			return
		end

		frameCanvas.data = newData
		frameCanvas.scrollBox:SetData(newData)
		frameCanvas.scrollBox:Refresh()
	end,
}

local listbox_options = {
	width = 800,
	height = 600,
	auto_width = true,
	line_height = 16,
	line_backdrop = {bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true},
	line_backdrop_color = {.1, .1, .1, .6},
	line_backdrop_border_color = {0, 0, 0, .5},
}

--@parent: parent frame
--@name: name of the frame to be created
--@data: table with current data to fill the column, this table are also used for values changed or added
--@options: table with options to overwrite the default setting from 'listbox_options'
--@header: a table to create a header widget
--@header_options: a table with options to overwrite the default header options
function detailsFramework:CreateListBox(parent, name, data, options, headerTable, headerOptions)

	options = options or {}
	name = name or "ListboxUnamed_" .. (math.random(100000, 1000000))

	--canvas
	local frameCanvas = CreateFrame("scrollframe", name, parent, "BackdropTemplate")
	detailsFramework:Mixin(frameCanvas, detailsFramework.ListboxFunctions)
	detailsFramework:Mixin(frameCanvas, detailsFramework.OptionsFunctions)
	detailsFramework:Mixin(frameCanvas, detailsFramework.LayoutFrame)
	frameCanvas.headerTable = headerTable

	if (not data or type(data) ~= "table") then
		error("CreateListBox() parameter 3 'data' must be a table.")
	end

	frameCanvas.data = data
	frameCanvas.lines = {}
	detailsFramework:ApplyStandardBackdrop(frameCanvas)
	frameCanvas:BuildOptionsTable(listbox_options, options)

	--header
		--check for default values in the header
		headerTable = headerTable or {
			{text = "Spell Id", width = 70},
			{text = "Spell Name", width = 70},
		}
		headerOptions = headerOptions or {
			padding = 2,
		}

		--each header is an entry in the data, if the header has 4 indexes the data has sub tables with 4 indexes as well
		frameCanvas.headerLength = #headerTable

		--add the detele line column into the header frame
		tinsert(headerTable, 1, {text = "#", width = 20, isIndex = true}) --isDelete signals the createScrollLine() to make the delete button for the line
		tinsert(headerTable, {text = "Delete", width = 50, isDelete = true}) --isDelete signals the createScrollLine() to make the delete button for the line

		local header = detailsFramework:CreateHeader(frameCanvas, headerTable, headerOptions)
		--set the header point
		header:SetPoint("topleft", frameCanvas, "topleft", 5, -5)
		frameCanvas.header = header

	--auto size
		if (frameCanvas.options.auto_width) then
			local width = 10 --padding 5 on each side
			width = width + 20 --scrollbar reserved space
			local headerPadding = headerOptions.padding or 0

			for _, header in pairs(headerTable) do
				if (header.width) then
					width = width + header.width + headerPadding
				end
			end

			frameCanvas.options.width = width
			frameCanvas:SetWidth(width)
		end

		local width = frameCanvas.options.width
		local height = frameCanvas.options.height

		frameCanvas:SetSize(frameCanvas.options.width, height)

	--scroll frame
		local lineHeight = frameCanvas.options.line_height
		--calc the size of the space occupied by the add button, header etc
		local lineAmount = floor((height - 60) / lineHeight)

		-- -12 is padding: 5 on top, 7 bottom, 2 header scrollbar blank space | -24 to leave space to the add button
		local scrollBox = detailsFramework:CreateScrollBox(frameCanvas, "$parentScrollbox", frameCanvas.scrollRefresh, data, width-4, height - header:GetHeight() - 12 - 24, lineAmount, lineHeight)
		scrollBox:SetPoint("topleft", header, "bottomleft", 0, -2)
		scrollBox:SetPoint("topright", header, "bottomright", 0, -2) -- -20 for the scrollbar
		detailsFramework:ReskinSlider(scrollBox)
		scrollBox.lineHeight = lineHeight
		scrollBox.lineAmount = lineAmount
		frameCanvas.scrollBox = scrollBox

		for i = 1, lineAmount do
			scrollBox:CreateLine(frameCanvas.createScrollLine)
		end

		scrollBox:Refresh()

	--add line button
		local addLineButton = detailsFramework:CreateButton(frameCanvas, detailsFramework.ListboxFunctions.addEntry, 80, 20, "Add", nil, nil, nil, nil, nil, nil, detailsFramework:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"), detailsFramework:GetTemplate("font", "ORANGE_FONT_TEMPLATE"))
		addLineButton:SetPoint("topleft", scrollBox, "bottomleft", 0, -4)

	return frameCanvas
end

--[=[ -- test case

    local pframe = ListBoxTest or CreateFrame("frame", "ListBoxTest", UIParent)
    pframe:SetSize(900, 700)
    pframe:SetPoint("left")

    local data = {{254154, "spell name 1", 45}, {299154, "spell name 2", 05}, {354154, "spell name 3", 99}}
    local headerTable = {
        {text = "spell id", width = 120},
        {text = "spell name", width = 180},
        {text = "number", width = 90},
    }

    local listbox = DetailsFramework:CreateListBox(pframe, "$parentlistbox", data, nil, headerTable, nil)
    listbox:SetPoint("topleft", pframe, "topleft", 10, -10)

--]=]

