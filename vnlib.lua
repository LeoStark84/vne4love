-- MAKING LIBRARY ACCESSIBLE

vnlib = {}

-- PLEASE NOTE THAT THIS IS AN
-- EARLY TEST VERSION AND AS SUCH
-- IT CONTAINS ALL SORTS OF ERRORS,
-- BUGS AND BROKEN CODE.
-- THE ONLY REASON THIS IS IN
-- GITHUB IS BECAUSE I NEED TO
-- ACCESS IT ON MORE THAN ONE
-- DEVICE.

vnlib.ver = 1
vnlib.subver = 5


-- LOCAL TABLES AND VARIABLES

-- VALUES IN VNLIB.CONF
local config = {}

-- SCREEN SIZE AND CENTER POSITIONS
-- VALUES USED WHEN ADDING AN AREA
local scr = {
	width = 0,
	height = 0,
	centerx = 0,
	centery = 0
}

-- CONSTANTS (K)
local ks = {
	dims = { left = "width", right = "width", top = "height", bottom = "height" }
}

-- AREAS DEFINITION TABLES
local areas = {}

-- CHARACTERS DEFINITION TABLE
local chars = {}

-- TABLE WITH CACHED IMAGES AND SOME
-- DATA ABOUT THEM
local images = {}

-- TABLE WITH MUST-HAVE AREAS AS KEY
-- AND REFERENCES TO THE AREAS
-- DEFINITION AS VALUE
local targets = {}

-- ARRAY WITH REVERSE DRAWING
-- ORDER OF TARGETTED AREAS
local draword = {}

-- TABLE WITH EVERY CURRENTLY LOADED
-- DIALOG LINE
local dialogs = {}

-- POINTER TO CURRENT DIALOG LINE,
-- REGARDLESS OF TYPE
local dialog_index = 0

-- TABLE  WITH STRINGS TO BE REPLACED
-- IN DIALOG LINES, CHOICE CAPTION
-- AND OPTIONS AND INTERACTION CAPTIONS
-- AND THE STRING TO REOLACE IT WITH
-- AS VALUE
-- a new replace is created automatically
-- upon character adding, with _[char id] as
-- key, and [character name as value.
local reps = {}

-- Similar to reps, except it's indexed
-- and values are "_uservar". Replacement
-- is performed ijñnmediately prior to
-- render
local usereps = {}

-- TABLE CONTAINING SOME MUST HAVE
-- FONTS. DIALOG, CHOICE AND CHARNAME
-- MORE CAN BE ADDED
local fonts = {}

-- VERY IMPORTANT VAR THAT STATES
-- HOW PROGRAM FLOW IS CONTROLLED
--  VALUES ARE "dialog", "interact", and
-- "choice"
local control = "dialog"

-- TABLE CONTAINING VARIABLES CREATED
-- AT RUNTIME, CAN BE ACCESED VIA
-- getVal AND assignVal FUNCTIONS
local uservars = {}

-- TABLE CONTAINING FUNCTIONS DEFINED
-- AT RUNTIME, THEY ARE LOADED FROM
-- acrions.lua
local useractions = {}



-- LOCAL FUNCTIONS

-- CONTAINER FOR THE VARIOUS AREA
-- BACKGROUND DRAWING FUNCTIOBS
local drawbg = {}

-- CONTAINER FOR DIALOG DRAWING
-- FUNCTIONS
local drawDialog = {}

-- CONTAINER FOR COORDINATE CHECKING
-- FUNCTIONS
local checkCoord = {}

-- CONTAINER FOR TOUCH EVALUATION
-- FUNCTIONS.
-- THOUGH THE NAME SUGGESTS IT
-- WORKS WITH TOUCHSCREEN DEVICES
-- ONLY, THE MAIN vnlib.evalTouch() IS
-- MEANT TO RECEIVE COORDINATES
-- REGARDLESS OF WHAT CAUSES THEM
-- THIS ALSO MEANS THE USER MUST
-- PUT A CALL TO IT IN IT'S main.lua
local touch = {}

-- CONTAINER FOR COMPARING VALUES
-- WITH USER-DEFINED VARS
local compareTo = {}

-- CONTAINER FOR AREA FOREGROUND
-- DRAWING FUNCTIONS
local drawfg = {}

-- Returns true for strings that end in a
-- % sign
local function isper(val)
	if (type(val) == "string") and (val:sub(#val,#val) == "%") then
		return true
	else
		return false
	end
end

-- Draws the solid color background
-- of an area
function drawbg.color(adef)
	love.graphics.setColor(adef.background.color[1], adef.background.color[2], adef.background.color[3])
	love.graphics.rectangle("fill", adef.geometry.left, adef.geometry.top, adef.geometry.width, adef.geometry.height)
end

-- Draws the image background of an
-- area
function drawbg.image(adef)
	love.graphics.setColor(1,1,1,1)
	love.graphics.draw(images[adef.background.image].image, adef.geometry.left, adef.geometry.top, 0, adef.background.scalex, adef.background.scaley)
end

function drawfg.color(fgdef)
	
	love.graphics.setColor(fgdef.fcolor[1], fgdef.fcolor[2], fgdef.fcolor[3])
	for k, v in pairs(fgdef.lines) do
		love.graphics.rectangle("fill", v[1], v[2], v[3], v[4])
	end
	love.graphics.setColor(fgdef.bcolor[1], fgdef.bcolor[2], fgdef.fcolor[3])
	for k, v in pairs(fgdef.squares) do
		love.graphics.rectangle("line", v[1], v[2], v[3], v[4])
	end
end
		

-- Draws the active image of a character
local function drawChar(cdef)
	love.graphics.setColor(1,1,1,1)
	love.graphics.draw(images[cdef.images[cdef.actimg].image].image, cdef.images[cdef.actimg].left, cdef.images[cdef.actimg].top, 0, cdef.images[cdef.actimg].scale)
end

-- dumps the content of vnlib.conf to
-- the [config] table
local function readconf(dir)
	local r2g, g2b = 0
	local r,g,b = 0,0,0
	for line in love.filesystem.lines(dir .. "vnlib.conf") do
		local sep = line:find("=")
		local k = line:sub(1,sep-1)
		local v = line:sub(sep+1,#line)
		if k == "def_font_color" then
			r2g = string.find(v, ",")
			r = tonumber(string.sub(v, 0, r2g-1))
			v = string.sub(v, 0, r2g+1)
			g2b = string.find(v, ",")
			g = tonumber(string.sub(v, 0, g2b-1))
			b = tonumber(string.sub(v, g2b+1, #v))
			v = { r, g, b }
		end
		if v ~= "" then
			config[k] = v
		end
	end
end

-- Checks for references to uservars in
-- in [str], if found, it replaces it with
-- the uservar value
function rtRep(str)
	local nustr = str
	for k, v in pairs(usereps) do
		nustr = nustr:gsub(v, tostring(uservars[k]))
	end
	return nustr
end

-- Draws a normal dialog line in the
-- dialog area
function drawDialog.dialog(ddef)
	love.graphics.setColor(chars[ddef.char].color[1] or config.def_font_color[1], chars[ddef.char].color[2] or config.def_font_color[2], chars[ddef.char].color[3] or config.def_font_color[3])
	love.graphics .print(rtRep(ddef.line), fonts.dialog, areas[targets.dialog].sgeometry.left+5, areas[targets.dialog].sgeometry.top+5)
end

-- Draws a choice type dialog
function drawDialog.choice(ddef)
	love.graphics.setColor(config.def_font_color[1], config.def_font_color[2], config.def_font_color[3])
	love.graphics.print(rtRep(ddef.caption), fonts.choice, areas[targets.dialog].sgeometry.left+5, areas[targets.dialog].sgeometry.top+5)
	for i, v in ipairs(ddef.choices) do
		love.graphics.line(areas[targets.dialog].sgeometry.left, v.top, areas[targets.dialog].sgeometry.right, v.top)
		if evalCond(v.cond) then
			love.graphics.print(rtRep(v.choice), fonts.choice, v.left, v.top)
		end
	end
	love.graphics.line(areas[targets.dialog].sgeometry.left, ddef.lastline, areas[targets.dialog].sgeometry.right, ddef.lastline)
end

-- Just closes the game
function drawDialog.quit()
	love.event.quit()
end

-- Draws the caption of an interaction
-- dialog
function drawDialog.interact()
	love.graphics.setColor(config.def_font_color[1], config.def_font_color[2], config.def_font_color[3])
	love.graphics.print(rtRep(dialogs[dialog_index].line), fonts.interaction, areas[targets.dialog].sgeometry.left+5, areas[targets.dialog].sgeometry.top+5)
end


-- Draws characters' names in the
-- name area (if it exists)
function drawName()
	love.graphics.setColor(chars[dialogs[dialog_index].char].color[1], chars[dialogs[dialog_index].char].color[2], chars[dialogs[dialog_index].char].color[3])
	love.graphics.print(chars[dialogs[dialog_index].char].name, fonts.name, areas[targets.name].sgeometry.left+5, areas[targets.name].sgeometry.top+5)
end


-- Takes a condition definition and
-- passes it to the apropriate function
-- returns true if no condition is defined
function evalCond(condef)
	if not condef then
		return true
	else
		return compareTo[condef.type](condef.var, condef.val)
	end
end


-- returns true if uservars.[var] is equal
-- to [val], false otherwise
function compareTo.equal(var, val)
	return val == uservars[var]
end

-- returns true if uservars.[var] is more
-- than [val], false otherwise
function compareTo.more(var, val)
	return val > uservars[var]
end

-- returns true if uservars.[var] is less
-- than [val], false otherwise
function compareTo.less(var, val)
	return val < uservars[var]
end

-- reads the content of the received
-- directory and caches PNG images
local function cacheimages(dir)
	local data = ""
	local w, h = 0,0
	local files = love.filesystem.getDirectoryItems(dir)
	for _, v in ipairs(files) do
		if v:sub(#v-3,#v) == ".png" then
			data = love.image.newImageData(dir .. v)
			w, h = data:getDimensions()
			images[v:sub(0, #v-4)] = {
				image = love.graphics.newImage(dir .. v),
				width = w,
				height = h
			}
		end
	end
end

-- Recalculates the scales of all images
-- for all added characters, according to
-- the [scale] parameter
function recalcScales(scale)
	local iw, ih = 0,0
	local wrat, hrat = 0, 0
	if type(scale) == "number" then
		for k, v in pairs(chars) do
			for i, w in ipairs(v.images) do
				w.scale = scale
				w.left = areas[targets.stage].sgeometry.centerx - ((images[w.image].width * scale) / 2)
				w.top = areas[targets.stage].sgeometry.top + (areas[targets.stage].sgeometry.height - w.height)
			end
		end
	elseif type(scale) == "string" then
		if scale == "max" then
			for k, v in pairs(chars) do
				for i, w in ipairs(v.images) do
					wrat = images[w.image].width / areas[targets.stage].sgeometry.width
					hrat = images[w.image].height / areas[targets.stage].sgeometry.height
					if (wrat > 1) or (hrat > 1) then
						w.scale = 1 / math.max(wrat, hrat)
					else
						w.scale = 1 / math.max(wrat, hrat)
					end
					w.left = areas[targets.stage].sgeometry.centerx - ((images[w.image].width * w.scale) / 2)
					w.top = areas[targets.stage].sgeometry.top + (areas[targets.stage].sgeometry.height - (images[w.image].height * w.scale))
				end
			end
		elseif scale == "eqmax" then
			local tallest, widest, lscale = 0,0,0
			for k,v in pairs(chars) do
				for i, w in ipairs(v.images) do
					if images[w.image].width > widest then widest = images[w.image].width end
					if images[w.image].height > tallest then tallest = images[w.image].height end
				end
			end
			wrat = areas[targets.stage].sgeometry.width / widest
			hrat = areas[targets.stage].sgeometry.height / tallest
			lscale = math.min(wrat, hrat)
			for k,v in pairs(chars) do
				for i, w in ipairs(v.images) do
					w.scale = lscale
					w.left = areas[targets.stage].sgeometry.centerx - ((images[w.image].width * w.scale) / 2)
					w.top = areas[targets.stage].sgeometry.top + (areas[targets.stage].sgeometry.height - (images[w.image].height * w.scale))
				end
			end
		end
	end
end

-- Takes a cached image reference
-- (file name without extension) and
-- creates a new image with the
-- image tiled to specified size [tw], 
-- [th], caches it, and returns image ref
local function createTile(imageref, dw, dh)
	local sdata = love.image.newImageData(config.basedir .. imageref .. ".png")
	local sw, sh = sdata:getDimensions()
	local ddata = love.image.newImageData(dw, dh)
	for x = 0, dw-1 do
		for y = 0, dh-1 do
			ax = (x-1)% sw
			ay = (y-1)%sh
			r,g,b,a = sdata:getPixel(ax,ay)
			ddata:setPixel(x,y,r,g,b,a)
		end
	end
	local nuref = imageref .. "_tiled"
	images[nuref] = {
		image = love.graphics.newImage(ddata),
		width = dw,
		height = dh
	}
	return nuref
end

-- Makes a dialog line (for any kind of
-- dialog) fit horizontally within [tw] by
-- adding new lines (\n)
local function adjustLine(str, tw, fontref)
	local spaces = {}
	local found = false
	local rtv = ""
	local strl = #str
	for i = 1, strl do
		if str:sub(i,i) == " " then
			table.insert(spaces, i)
		end
	end
	local i = #spaces
	while (not found) and (i > 0) do
		 if fonts[fontref]:getWidth(str:sub(0, spaces[i])) < tw then
			found = true
			if fonts[fontref]:getWidth(str:sub(spaces[i]+1,#str)) < tw then
				rtv = str:sub(0, spaces[i]-1) .. "\n" .. str:sub(spaces[i]+1, #str)
			else
				rtv = str:sub(0, spaces[i]-1) .. "\n" .. adjustLine(str:sub(spaces[i]+1, #str), tw, fontref)
			end
		else
			i = i - 1
		end
	end
	return rtv
end

-- Reads the dialog from a file and
-- dumps it into [dialogs] table
local function getDialog(file)
	dialog = {}
	local topts, acumh, theight, telems = 0,0,0,0
	local tfound = false
	local nuopt, nuact, cond = {}, {}, {}
	local predlg = require(config.basedir .. file)
	-- for all lines run reps and adjust
	-- line to area
	for i, v  in ipairs(predlg) do
		if v.line then
			for k, w in pairs(reps) do
				v.line = string.gsub(v.line, k,w)
			end
			if fonts.dialog:getWidth(v.line) >= areas[targets.dialog].sgeometry.width then
				v.line = adjustLine(v.line, areas[targets.dialog].sgeometry.width, "dialog")
			end
		elseif v.caption then
			for k, w in pairs(reps) do
				v.caption = string.gsub(v.caption, k,w)
			end
			if fonts.dialog:getWidth(v.caption) >= areas[targets.dialog].sgeometry.width then
				v.caption = adjustcaption(v.caption, areas[targets.dialog].sgeometry.width, "dialog")
			end
		end
		-- FOR CHOICE DIALOGS
		if v.char == "choice" then
			topts = #v.opt
			for _, w in ipairs(v.opt) do
				theight = theight + fonts.choice:getHeight(w.choice)
			end
			acumh =  fonts.choice:getHeight(v.line) + 5
			for i, w in ipairs(v.opt) do
				for k, vvv in pairs(reps) do
					w.choice = string.gsub(w.choice, k,vvv)
				end
				if fonts.choice:getWidth(w.choice) >= areas[targets.dialog].sgeometry.width then
					w.choice = adjustLine(w.choice, areas[targets.dialog].sgeometry.width, "choice")
				end
				if w.cond then
					cond = {
						var = w.cond.compare,
						type = w.cond.method,
						val = w.cond.value
					}
				else
					cond = nil
				end
				nuopt[i] = {
					cond = cond,
					choice = w.choice,
					next = w.next,
					top = areas[targets.dialog].sgeometry.top + acumh + 10,
					left = areas[targets.dialog].sgeometry.left+5,
					bottom = areas[targets.dialog].sgeometry.top + acumh + fonts.choice:getHeight(w.choice) + 5,
					right = areas[targets.dialog].sgeometry.right
				}
				acumh = acumh + fonts.choice:getHeight(w.choice) + 10
			end
			dialogs[i] = {
				type = "choice",
				caption = v.line,
				choices = nuopt,
				lastline = areas[targets.dialog].geometry.top + acumh + fonts.choice:getHeight(v.opt[opts]) + 5
				-- lastline = areas[targets.dialog].geometry.top + acumh+5
			}
		-- FOR INTERACT DIALOG
		elseif v.char == "interact" then
			for j, w in ipairs(v.actions) do
				if type(w.whentouch) == "string" then
					if w.whentouch == "always" then
						coords = { type = "always" }
					else
						if chars[w.whentouch] then
							coords = { type = "char", char = w.whentouch }
						end
					end
				else
					coords = { type = "direct", x = w.x, y = w.y }
				end
				nuact[j] = {
					coords = coords,
					action = w.action
				}
			end
			dialogs[i] = {
				type = "interact",
				actions = nuact,
				line = v.line
			}
		-- FOR IN-DIALOG QUIT REQUEST
		elseif v.char == "quit" then
			dialogs[i] = {
				type = "quit"
			}
		--;FOR NORMAL DIALOG
		else
			dialogs[i] = {
				type = "dialog",
				char = v.char,
				line = v.line
			}
		end
	end
	dialog_index = 1
	control = dialogs[dialog_index].type
end

-- Reruns the replacements on a dialog
-- useful when addingba new character
-- after a dialog has been loaded
local function updateDialog()
	for i, v in ipairs(dialogs) do
		for k, w in pairs(reps) do
			if v.line then
				v.line = string.gsub(v.line, k, w)
			else
				v.caption = string.gsub(v.caption, k, w)
			end
			if v.choices then
				for j, vvv in ipairs(v.choices) do
					vvv.choice = string.gsub(vvv.choice, k, w)
				end
				v.caption = string.gsub(v.caption, k, v)
			end
		end
		if v.line then
			if fonts.dialog:getWidth(v.line) >= areas[targets.dialog].sgeometry.width then
				v.line = adjustLine(v.line, areas[targets.dialog].sgeometry.width, "dialog")
			end
		else
			if fonts.dialog:getWidth(v.caption) >= areas[targets.dialog].sgeometry.width then
				v.caption = adjustLine(v.caption, areas[targets.dialog].sgeometry.width, "dialog")
			end
		end
	end
end

-- Advances dialog pointer by one and
-- transfers flow control to the correct
-- function
local function advanceDialog()
	if dialog_index < #dialogs then
		dialog_index = dialog_index + 1
		control = dialogs[dialog_index].type
	end
end

-- Performs tap/click (touch) detection
-- for normal dialogs
function touch.dialog(x,y)
	if (x >= areas[targets.dialog].geometry.left) and (x <= areas[targets.dialog].geometry.right) and (y >= areas[targets.dialog].geometry.top) and (y <= areas[targets.dialog].geometry.bottom) then
		advanceDialog()
	end
end

-- Performs touch detection for choice
-- type dialogs
function touch.choice(x, y)
	for i, v in ipairs(dialogs[dialog_index].choices) do
		if evalCond(v.cond) then
			if (x >= v.left) and (x <= v.right) and (y >= v.top) and (y <= v.bottom) then
				if v.next == "end" then
					drawDialog.quit()
				else
					getDialog(v.next)
				end
			end
		end
	end
end

-- Performs touch detection for
-- interact type dialogs
function touch.interact(x, y)
	local actions = dialogs[dialog_index].actions
	if actions[1].coords.type == "always" then
		useractions[actions[1].action]()
	else
		local tacts = #actions
		local i = 1
		while (not done) and (i <= tacts) do
			if checkCoord[actions[i].coords.type](x, y, actions[i].coords, actions[i].coords.char) then
				done = true
				useractions[actions[i].action]()
			else
				i = i + 1
			end
		end
	end
end

-- returns true if [x] and [y] are within 
-- [coordef] and falsebotherwise
function checkCoord.direct(x, y, coordef, _)
	return ((x >= coordef.left) and (x <= coordef.right) and (y >= coordef.top) and (y <= coordef.bottom))
end

-- returns true if [x] and [y] are within 
-- [cid] character's current image coords
function checkCoord.char(x, y, _, cid)
	local refleft = chars[cid].images[chars[cid].actimg].left
	local reftop = chars[cid].images[chars[cid].actimg].top
	local refright = chars[cid].images[chars[cid].actimg].left + (chars[cid].images[chars[cid].actimg].scale * images[chars[cid].images[chars[cid].actimg].image].width)
	local refbottom = chars[cid].images[chars[cid].actimg].top + (chars[cid].images[chars[cid].actimg].scale * images[chars[cid].images[chars[cid].actimg].image].height)
	return (x >= refleft) and (x <= refright) and (y >= reftop) and (y <= refbottom)
end

-- Caches the fonts specified in .conf
-- file
function getDefaultFonts()
	-- Vars init
	local lines = 7
	local tf = ""
	local th = 40
	local ts = "Los hermanos sean unidos"
	-- Set font size or calculate default
	if (not config.dlg_font_size) or (config.dlg_font_size == "") or (config.dlg_font_size == "auto") then
		while not found do
			tf = love.graphics.newFont(config.basedir .. config.dlg_font, th)
			if tf:getHeight(ts) * lines >= areas[targets.dialog].sgeometry.height - 10 then
				while not found do
					th = th - 1
					tf = love.graphics.newFont(config.basedir .. config.dlg_font, th)
					if tf:getHeight(ts) * lines < areas[targets.dialog].sgeometry.height - 10 then
						found = true
						config.dlg_font_size = th
					end
				end
			else
				th = th + 10
			end
		end
	else
		th = tonumber(config.dlg_font_size)
	end
	-- Get dialog font
	vnlib.addFont("dialog", th, config.basedir .. config.dlg_font)
	-- Reinit vars
	lines = 6
	th = 60
	found = false
	-- Set choice font size or calculate default
	if (not config.choice_font_size) or (config.choice_font_size == "") or (config.choice_font_size == "auto") then
		while not found do
			tf = love.graphics.newFont(config.basedir .. config.choice_font, th)
			if tf:getHeight(ts) * lines >= areas[targets.dialog].sgeometry.height - 10 then
				while not found do
					th = th - 1
					tf = love.graphics.newFont(config.basedir .. config.choice_font, th)
					if tf:getHeight(ts) * lines < areas[targets.dialog].sgeometry.height -10 then
						found = true
						config.choice_font_size = th
					end
				end
			else
				th = th + 10
			end
		end
	else
		th = tonumber(config.choice_font_size)
	end
	-- Get choice font
	vnlib.addFont("choice", tonumber(config.choice_font_size), config.basedir .. config.choice_font)
	-- Reinit font
	lines = 5
	th = 60
	found = false
	-- Set interaction font size or calculate default
	if (not config.int_font_size) or (config.int_font_size == "") or (config.int_font_size == "auto") then
		while not found do
			tf = love.graphics.newFont(config.basedir .. config.int_font, th)
			if tf:getHeight(ts) * lines >= areas[targets.dialog].sgeometry.height - 10 then
				while not found do
					th = th - 1
					tf = love.graphics.newFont(config.basedir .. config.int_font, th)
					if tf:getHeight(ts) * lines < areas[targets.dialog].sgeometry.height - 10  then
						found = true
						config.int_font_size = th
					end
				end
			else
				th = th + 10
			end
		end
	else
		th = tonumber(config.int_font_size)
	end
	-- Get interaction font
	vnlib.addFont("interaction", th, config.basedir .. config.int_font)
	-- Reinit vars
	found = false
	lines = 1
	th = 60
	-- Set name font size or calculate default
	if (not config.name_font_size) or (config.name_font_size == "") or (config.name_font_size == "auto") then
		while not found do
			tf = love.graphics.newFont(config.basedir .. config.name_font, th)
			if tf:getHeight(ts) * lines >= areas[targets.name].sgeometry.height - 10 then
				while not found do
					th = th - 1
					tf = love.graphics.newFont(config.basedir .. config.name_font, th)
					if tf:getHeight(ts) * lines < areas[targets.name].sgeometry.height - 10 then
						found = true
						config.name_font_size = th
					end
				end
			else
				th = th + 10
			end
		end
	else
		th = tonumber(config.name_font_size)
	end
	-- Set name font
	vnlib.addFont("name", tonumber(config.name_font_size), config.basedir .. config.name_font)
end


-- ACCESIBLE FUNCTIONS

function vnlib.init(width, height, confdir)
	confdir = confdir or ""
	-- init screen geometry
	scr.height = height
	scr.width = width
	scr.centerx = width/2
	scr.centery = width/2
	-- read config file
	readconf(confdir)
	-- cache images
	cacheimages((config.basedir or "") .. (config.resdir or ""))
	-- run start code
	local fullpath = love.filesystem.getSource() .. config.basedir
	dofile(fullpath .. "start.lua")
	-- sort layers
	if targets.dialog then table.insert(draword, "dialog") end
	if targets.stage then table.insert(draword, "stage") end
	if targets.name then table.insert(draword, "name") end
	if targets.portrait then table.insert(draword, "portrait") end
	-- get and store fonts for dialogs, choices and char names
	getDefaultFonts()
	-- load uaer actions
	useractions = require(config.basedir .. "actions")
	if useractions.start then useractions.start() end
	-- load dialog
	getDialog(config.entry_point)
end


function vnlib.draw()
	if targets.stage then
		drawbg[areas[targets.stage].background.type](areas[targets.stage])
		for _,v in pairs(chars) do
			if v.visible then
				drawChar(v)
			end
		end
		drawfg[areas[targets.stage].foreground.type](areas[targets.stage].foreground)
	end
	if targets.dialog then
		drawbg[areas[targets.dialog].background.type](areas[targets.dialog])
		drawDialog[dialogs[dialog_index].type](dialogs[dialog_index])
		drawfg[areas[targets.dialog].foreground.type](areas[targets.dialog].foreground)
	end
	if targets.name then
		drawbg[areas[targets.name].background.type](areas[targets.name])
		if dialogs[dialog_index].char then
			drawName()
		end
		drawfg[areas[targets.name].foreground.type](areas[targets.name].foreground)
	end
	if targets.portrait then
		drawbg[areas[targets.portrait].background.type](areas[targets.portrait].background)
		drawfg[areas[targets.portrait].foreground.type](areas[targets.portrait].foreground)
	end
end

function vnlib.srtDefaultLayout(nflag, pflag)
	vnlib.addArea("stgarea", {
		left = 0,
		right = "100%",
		top = 0,
		bottom = "72.5%",
		background = {
			type = "color",
			color = { 0.4, 0, 0 }
		},
		foreground = {
			type = "color",
			fill_color = { 0.25, 0, 0 },
			border_color = { 1, 1, 1 },
			thickness = "4%",
			same_thickness = true,
			draw_inner_border = true,
			draw_outer_border = false
		}
	})
	vnlib.makeTarget("stgarea", "stage")
	local stl, stt, str, stb = vnlib.getAreaCoords("stage")
	local stsl, stst, stsr, stsb = vnlib.getAreaSafeCoords("stage")
	vnlib.addArea("dlgarea", {
		left = 0,
		right = "100%",
		top = "77.5%",
		bottom = "100%",
		background = {
			type = "color",
			color = { 0.1, 0.1, 0.15 }
		},
		foreground = {
			type = "color",
			fill_color = { 0.25, 0, 0 },
			border_color = { 1, 1, 1 },
			thickness = stsl - stl,
			same_thickness = true,
			draw_inner_border = true,
			draw_outer_border = false
		}
	})
	vnlib.makeTarget("dlgarea", "dialog")
	local dlsl, dlst, dlsr, dlsb = vnlib.getAreaSafeCoords("dialog")
	vnlib.addArea("namarea", {
		left = stsl,
		top = stsb + 1,
		right = stsr,
		bottom = dlst - 1,
		background = {
			type = "color",
			color = { 0.4, 0, 0 }
		},
		foreground = {
			type = "color",
			fill_color = { 0.25, 0, 0 },
			border_color = { 1, 1, 1 },
			thickness = stsl - stl,
			same_thickness = true,
			draw_inner_border = true,
			draw_outer_border = false
		}
	})
	vnlib.makeTarget("namarea", "name")
end


function vnlib.addChar(cid, cdef)
	-- init vars
	local aw, ah, tw, th, wdif, hdif = 0,0,0,0,0,0
	local itbl, ptbl = {}, {}
	-- calculate character images scale based on image size and target area size
	tw = areas[targets.stage].sgeometry.width
	th = areas[targets.stage].sgeometry.height
	for i, v in ipairs(cdef.images) do
		aw = images[v].width
		ah = images[v].height
		wdif = aw / tw
		hdif = ah / th
		if (wdif > 1) and (wdif >= hdif) then
			scale = wdif
		elseif (hdif > 1) and (hdif >= wdif) then
			scale = hdif
		else
			scale = 1
		end
		-- add character's  image, size and positions to a temp tableñ
		itbl[i] = {
			image = v,
			scale = scale,
			top = areas[targets.stage].sgeometry.top + (areas[targets.stage].geometry.height - (ah * scale)),
			left = areas[targets.stage].sgeometry.centerx - ((aw * scale) / 2)
		}
	end
		-- calculate portrait's scale based on it's size amd target area size, but only if a target area exists
	if cdef.portrait and targets.portrait then
		tw = areas[targets.stage].geometry.width
		th = areas[targets.stage].geometry.height
		for i, v in ipairs(cdef.portraits) do
			aw = images[cdef.portraits[i]].width
			ah = images[cdef.portaits[i]].height
			wdif = aw / tw
			hdif = ah / th
			if (wdif > 1) or (hdif > 1) then
				scale =  math.max(wdif, hdif)
			elseif (wdif < 1) and (hdif < 1) then
				scale = 1 / (math.min(wdif, hdif))
			else
				scale = 1
			end
			ptbl[i] = {
				image = cdef.portraits[i],
				scale = scale
			}
		end
	else
		ptbl = nil
	end
	chars[cid] = {
		name = cdef.name,
		images = itbl,
		portraits = ptbl,
		color = cdef.color or {1,1,1,1}, -- text color
		visible = false,
		actimg = 1 -- pointer to images array
	}
	reps["_" .. cid] = cdef.name
	updateDialog()
end


function vnlib.getCharImage(cid, imgname)
	local found = false
	local timgs = #chars[cid].images
	local rtv = false
	local idx = 1
	if images[imgname] then
		while (not found) and (idx <= timgs) do
			if chars[cid].images[idx].image == imgname then
				found = true
				rtv = idx
			else
				idx = idx + 1
			end
		end
	end
	return rtv
end

function vnlib.getCharWidth(cid)
	return images[chars[cid].images[chars[cid].actimg].image].width * chars[cid].images[chars[cid].actimg].scale
end

function vnlib.getCharHeight(cid)
	return images[chars[cid].images[chars[cid].actimg].image].height * chars[cid].images[chars[cid].actimg].scale
end

function vnlib.getCharPos(cid)
	return chars[cid].images[chars[cid].actimg].left, chars[cid].images[chars[cid].actimg].top
end 

function vnlib.showChar(cid, imgp)
	chars[cid].visible = true
	if not imgp then
		imgp = chars[cid].actimg
	elseif type(imgp) == "string" then
		imgo = vnlib.getCharImage(cid, imgp)
	end
	chars[cid].actimg = imgp
end


function vnlib.hideChar(cid)
	chars[cid].visible = false
end


function vnlib.moveChar(cid, posx, posy)
	if isper(posx) then
		posx = areas[targets.stage].geometry.width * (posx:sub(1,#posx-1) / 100)
	end
	if isper(posy) then
		posy = areas[targets.stage].geometry.height * (posy:sub(1,#posy-1) / 100)
	end
	chars[cid].images[chars[cid].actimg].left = posx or chars[cid].images[chars[cid].actimg].left
	chars[cid].images[chars[cid].actimg].top = posy or chars[cid].images[chars[cid].actimg].top
end

function vnlib.distribChars(charar)
	local tchars = #charar
	local l = 1 / (tchars +1)
	local offset, gridline, charwidth, charscale = 0,0,0,0
	offset = areas[targets.stage].geometry.left
	for i, v in ipairs(charar) do
		gridline = areas[targets.stage].geometry.width * (i*l)
		charwidth = vnlib.getCharWidth(v)
		vnlib.moveChar(v,  offset + (gridline - (charwidth / 2)))
	end
end


function vnlib.eqScales()
	local tmp = {}
	local minscale = 9999
	local maxscale = 0
	local widest, tallest = 0,0
	local wratio, hratio = 0,0
	for k, v in pairs(chars) do
		for i, w in ipairs(v.images) do
			if w.scale < minscale then minscale = w.scale end
			if w.scale > maxscale then maxscale = w.scale end
			table.insert(tmp, w.image)
		end
	end
	if minscale < 1 then
		recalcScales(minscale)
	else
		for _, v in ipairs(tmp) do
			if images[v].width > widest then widest = images[v].width end
			if images[v].height > tallest then tallest = images[v].height end
		end
		wratio = widest / areas[targets.stage].sgeometry.width
		hratio = tallest / areas[targets.stage].sgeometry.height
		recalcScales(math.min(1/wratio, 1/hratio))
	end
end


function vnlib.maxScales()
	recalcScales("max")
end


function vnlib.eqmaxScales()
	recalcScales("eqmax")
end

function vnlib.addArea(aname, adef)
	local dims = {
		left = 0,
		right = 0,
		top = 0,
		bottom = 0
	}
	local vlt, hlt = 0,0
	local sg = {}
	local isq, osq = nil, nil
	local fgt = nil
	for k, _ in pairs(dims) do
		if isper(adef[k]) then
			dims[k] = scr[ks.dims[k]] * (tonumber(adef[k]:sub(1,#adef[k]-1)) / 100)
		else
			dims[k] = adef[k]
		end
	end
	dims.width = dims.right - dims.left
	dims.height = dims.bottom - dims.top
	dims.centerx = dims.left + (dims.width / 2)
	dims.centery = dims.top + (dims.height / 2)
	if adef.background.type == "color" then
		bgt = {
			type = "color",
			color = adef.background.color
		}
	elseif adef.background.type == "image" then
		bgt = {
			type = "image",
			image = adef.background.image,
			scalex = images[adef.background.image].width / (dims.right - dims.left),
			scaley = images[adef.background.image].width / (dim.bottom - dims.top)
		}
	elseif adef.background.type == "tile" then
		iref = createTile(adef.background.tile, dims.right - dims.left, dims.bottom - dims.top)
		bgt = {
			type = "image",
			image = iref,
			scalex = 1,
			scaley = 1
		}
	end
	if adef.foreground and (adef.foreground.type == "color") then
		if isper(adef.foreground.thickness) then
			if adef.foreground.same_thickness then
				vlt = ((dims.width * (tonumber(adef.foreground.thickness:sub(1,#adef.foreground.thickness-1)) / 100) + dims.height * (tonumber(adef.foreground.thickness:sub(1,#adef.foreground.thickness-1)) / 100)) / 2)
				hlt = vlt
			else
				vlt = dims.width * (tonumber(adef.foreground.thickness:sub(1,#adef.foreground.thickness-1)) / 100)
				hlt = dims.height * (tonumber(adef.foreground.thickness:sub(1,#adef.foreground.thickness-1)) / 100)
			end
		else
			vlt = adef.foreground.thickness
			hlt = adef.foreground.thickness
		end
		if adef.foreground.draw_inner_border then
			isq = {
					dims.left + vlt,
					dims.top + hlt,
					dims.width - (vlt * 2),
					dims.height - (hlt * 2)
				}
		end
		if adef.foreground.draw_outer_border then
			osq = {
					dims.left,
					dims.top,
					dims.width,
					dims.height
				}
		end
		fgt = {
			type = "color",
			bcolor = adef.foreground.border_color,
			fcolor = adef.foreground.fill_color,
			lines = {
				left = {
					dims.left,
					dims.top,
					vlt,
					dims.height - hlt
				},
				top = {
					dims.left + vlt,
					dims.top,
					dims.width - vlt,
					hlt
				},
				right = {
					dims.right - vlt,
					dims.top + hlt,
					vlt,
					dims.height - hlt
				},
				bottom = {
					dims.left,
					dims.bottom - hlt,
					dims.width -vlt,
					hlt
				}
			},
			squares = {
				inner = isq,
				outter = osq
			}
		}
		sg = {
			left = dims.left + vlt,
			top = dims.top + hlt,
			right = dims.right - vlt,
			bottom = dims.bottom - hlt,
			width = (dims.right - vlt) - (dims.left + vlt),
			height = (dims.bottom - hlt) - (dims.top + hlt),
			centerx = (dims.left + vlt) + (((dims.right - vlt) - (dims.left + vlt)) / 2),
			centery = (dims.top + hlt) + (((dims.bottom - hlt) - (dims.top + hlt)) / 2)
		}
	elseif not adef.foreground then
		sg = dims
	end
	if adef.type then
		targets[type] = aname
	end
	areas[aname] = {
		geometry = dims,
		sgeometry = sg,
		background = bgt,
		foreground = fgt
	}
end


function vnlib.getAreaCoords(aname)
	if areas[aname] then
		return areas[aname].geometry.left, areas[aname].geometry.top, areas[aname].geometry.right, areas[aname].geometry.bottom
	elseif areas[targets[aname]] then
		return areas[targets[aname]].geometry.left, areas[targets[aname]].geometry.top, areas[targets[aname]].geometry.right, areas[targets[aname]].geometry.bottom
	else
		return 0, 0, 0, 0
	end
end


function vnlib.getAreaSafeCoords(aname)
	if areas[aname] then
		return areas[aname].sgeometry.left, areas[aname].sgeometry.top, areas[aname].sgeometry.right, areas[aname].sgeometry.bottom
	elseif areas[targets[aname]] then
		return areas[targets[aname]].sgeometry.left, areas[targets[aname]].sgeometry.top, areas[targets[aname]].sgeometry.right, areas[targets[aname]].sgeometry.bottom
	else
		return 0, 0, 0, 0
	end
end


function vnlib.getAreaSize(aname, axis)
	if axis then
		return areas[aname].geometry[axis]
	else
		return areas[aname].geometry.width, areas[aname].geometry.height
	end
end


function vnlib.getSafeAreaSize(aname, axis)
	if axis then
		return areas[aname].sgeometry[axis]
	else
		return areas[aname].sgeometry.width, areas[aname].sgeometry.height
	end
end

function vnlib.getSafeAreaCenter(aname, axis)
	if axis then
		return areas[aname].sgeometry["center" .. axis]
	else
		return areas[aname].sgeometry.centerx, areas[aname].sgeometry.centery
	end
end

function vnlib.getAreaCenter(aname, axis)
	if axis then
		return areas[aname].geometry["center" .. axis]
	else
		return areas[aname].geometry.centerx, areas[aname].geometry.centery
	end
end

function vnlib.isTarget(aname)
	local found = false
	local rtv = false
	for k, v in pairs(targets) do
		if aname == v then
			found = true
			rtv = k
		end
	end
	return rtv
end

function vnlib.makeTarget(aname, target)
	targets[target] = aname
end

function vnlib.showDialogOnce(str, timeout)
	str = adjustLine(str, areas[targets.dialog].geometry.width, "dialog")
	love.graphics.setColor(1,1,1,1)
	love.graphics.print(str, fonts.dialog, areas[targets.dialog].geometrt.left+5, areas[targets.dialog].geometry.top+5)
end

function vnlib.addRep(k, v)
		reps[k] = v
end

function vnlib.toDialog()
	control = "dialog"
	advanceDialog()
end

function vnlib.evalTouch(x,y)
	touch[control](x,y)
end

function vnlib.getVal(varp)
	return uservars[varp]
end

function vnlib.assignVal(varp,value)
	if not uservars[varp] then
		usereps[varp] = "_" .. varp
	end
	uservars[varp] = value
end

function vnlib.addFont(target, fontsize, fontfile)
	fontsize = fontsize or 16
	if fontfile and (fontfile ~= "") then
		if fontfile:sub(#fontfile-3,#fontfile) ~= ".ttf" then fontfile = fontfile .. ".ttf" end
		fonts[target] = love.graphics.newFont(fontfile, fontsize)
	else
		fonts[target] = love.graphics.newFont(fontsize, "normal", love.graphics.getDPIScale())
	end
end

-- OS-SPECIFIC FUNCTIONS

-- THIS IS A MOBILE-SOECIFIC FUNCTION
-- FEEL FREE TO REMOVE FOR PC VERSIONS
function love.touchpressed(id, tx, ty, dx, dy, tp)
	nutouch = true
end

return vnlib