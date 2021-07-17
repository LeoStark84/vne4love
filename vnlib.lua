vnl = {}

-- LOTSA VAR INITIALIZATIONS

local imanip = require("vnlite/imanip")
local screen = {}
local comres = {}
local areas = {}
local chars = {}
local props = {}
local dialog = {}
local reps = {}
local fonts = {}
local useractions = {}
local uservars = {}
local visiblechars = {}
local visibleprops = {
	front = {},
	back = {}
}
local menu = {}
local basedir = ""
local comdir = ""
local charsdir = ""
local propsdir = ""
local dialogsdir = ""
local dindex = 1
local dcontrol = ""
local prepro = false
local procdiag = {}
local curmenlev = "main"
local firstdialog = {}

-- BACKEND

local function getNum(per)
	local super = tonumber(per:sub(1,-2))
	return per / 100
end

local function areageometry(adef)
	local geom = {
		left = screen.geometry.right * adef.left,
		top = screen.geometry.bottom * adef.top,
		right = screen.geometry.right * adef.right,
		bottom = screen.geometry.bottom * adef.bottom
	}
	geom.width = geom.right - geom.left
	geom.height = geom.bottom - geom.top
	geom.centerx = geom.left + (geom.width / 2)
	geom.centery = geom.top + (geom.height / 2)
	return geom
end

local function colorbg(bgdef)
	return bgdef
end

local function imagebg(bgdef, geom)
	local xscale = geom.width / comres[bgdef.image].width
	local yscale = geom.height / comres[bgdef.image].height
	-- create background subtable
	return {
		type = "image",
		image = bgdef.image,
		xscale = xscale,
		yscale = yscale
	}
end

function tilebg(bgdef, geom)
	local tid = love.image.newImageData(basedir .. "common/" .. bgdef.image .. ".png")
	tid = imanip.tile(tid, geom.width, geom.height)
	local tname = bgdef.image .. "_t" .. geom.width .. "x" .. geom.height
	comres[tname] = {
		image = love.graphics.newImage(tid),
		width = geom.width,
		height = geom.height
	}
	return {
		type = "image",
		image = tname,
		xscale = 1,
		yscale = 1
	}
end

function plainfg(fgdef, geom)
	local verthickness, horthickness = 0, 0
	local fg, sgeom = {}, {}
	local sqind = 0
	if fgdef.thickness then
		verthickness = ((geom.width + geom.height) / 2) * fgdef.thickness
		horthickness = ((geom.width + geom.height) / 2) * fgdef.thickness
	else
		verthickness = geom.width * fgdef.vertical_thickness
		horthickness = geom.height * fgdef.horizontal_thickness
	end
	fg = {
		type = "plain",
		fill = fgdef.fill_color,
		border = fgdef.border_color,
		squares = {
			left = {
				left = geom.left,
				top = geom.top,
				width = verthickness,
				height = geom.height - horthickness
			},
			top = {
				left = geom.left + verthickness,
				top = geom.top,
				width = geom.width - verthickness,
				height = horthickness
			},
			right = {
				left = geom.right - verthickness,
				top = geom.top + horthickness,
				width = verthickness,
				height = geom.height - horthickness
			},
			bottom = {
				left = geom.left,
				top = geom.bottom - horthickness,
				width = geom.width - verthickness,
				height = horthickness
			}
		}
	}
	fg.lines = {}
	if (fgdef.border == "inner") or (fgdef.border == "both") then
		fg.lines[1] = {
			left = geom.left + verthickness,
			top = geom.top + horthickness,
			width = geom.width - (verthickness * 2),
			height = geom.height - (horthickness * 2)
		}
	end
	if (fgdef.border == "outer") or (fgdef.border == "both") then
		if #fg.lines == 1 then
			sqind = 2
		else
			sqind = 1
		end
		fg.lines[sqind] = {
			left = geom.left,
			top = geom.top,
			width = geom.width,
			height = geom.height
		}
	end
	sgeom = {
		left = geom.left + verthickness,
		top = geom.top + horthickness,
		right = geom.right - verthickness,
		bottom = geom.bottom - horthickness,
		width = geom.width - (verthickness * 2),
		height = geom.height - (horthickness * 2),
	}
	return fg, sgeom
end

local function getFrameLineData(il)
	-- lotsa tables
	local lids = {
		left = "",
		top = "",
		right = "",
		bottom = ""
	}
	local opo = {
		left = "right",
		top = "bottom",
		right = "left",
		bottom = "top"
	}
	local rots = {
		left = { "top", "bottom" },
		top = { "left", "right" },
		right = { "bottom", "top" },
		bottom = { "right", "left" }
	}
	-- init vars
	local htr = ""
	local oplace = ""
	local nuplace = ""
	--:get available image files and turn
	-- them to imagedatas
	for place, _ in pairs(lids) do
		if il[place] then
			lids[place] = love.image.newImageData(comdir .. il[place] .. ".png")
		end
	end
	-- fill the missing imagedatas by 
	-- rotating available images
	for place, _ in pairs(lids) do
		-- when an image dara is missing
		if not il[place] then
			-- always prefer to rotate 180°
			if il[opo[place]] then
				oplace = opo[place]
				nuplace = place
				htr = imanip.figureFrameRot(oplace, nuplace)
				lids[place] = imanip[htr](lids[oplace])
			else
				-- if no 180° image available find one
				-- to rotate 90° or 270°
				if il[rots[place][1]] then
					oplace = rots[place][1]
					nuplace = place
					htr = imanip.figureFrameRot(oplace, nuplace)
					lids[place] = imanip[htr](lids[oplace])
				else -- il[rots[place][2]] == true is implied
					oplace = rots[place][2]
					nuplace = place
					htr = imanip.figureFrameRot(oplace, nuplace)
					lids[place] = imanip[htr](lids[oplace])
				end
			end
		end
	end
	return lids
end

local function getTiledLines(lids, geom)
	local vt = lids.right:getWidth()
	local ht = lids.top:getHeight()
	local nulids = {
		left = imanip.tile(lids.left, vt, geom.height - (ht * 2)),
		top = imanip.tile(lids.top, geom.width - (vt * 2), ht),
		right = imanip.tile(lids.right, vt, geom.height - (ht * 2)),
		bottom = imanip.tile(lids.bottom,  geom.width - (vt * 2), ht)
	}
	return nulids, vt, ht
end

local function getFrameCornerData(il)
	local cids = {
		top_left = "",
		top_right = "",
		bottom_right = "",
		bottom_left = ""
	}
	local avaicid = ""
	-- turn available irefs to imagedatas
	for place, _ in pairs(cids) do
		if il[place] then
			cids[place] = love.image.newImageData(comdir .. il[place] .. ".png")
			avaicid = place
		end
	end
	-- fill missing imagedatas by rotating
	-- available ones
	for place, iref in pairs(cids) do
		if not il[place] then
			htr = imanip.figureFrameRot(avaicid, place)
			cids[place] = imanip[htr](cids[avaicid])
		end
	end
	cs = cids[avaicid]:getHeight()
	return cids, cs
end

local function composeFrame(lids, cids, geom, vt, ht, cs)
	-- lotsa tables, revisited
	local loff = {
		left = {
			left = 0,
			top = ht
		},
		top = {
			left = vt,
			top = 0
		},
		right = {
			left = geom.width - vt,
			top = ht
		},
		bottom = {
			left = vt,
			top = geom.height - ht
		}
	}
	local coff = {
		top_left = {
			left = 0,
			top = 0
		},
		top_right = {
			left = geom.width - cs,
			top = 0
		},
		bottom_right = {
			left = geom.width - cs,
			top = geom.height - cs
		},
		bottom_left = {
			left = 0,
			top = geom.height - cs
		}
	}
	-- init vars (and create frame image
	-- data)
	local ow, oh, lox, loy, r, g, b, a = 0, 0, 0, 0, 0, 0, 0, 0
	local frame = love.image.newImageData(geom.width, geom.height)
	-- put lines in frame
	for place, idata in pairs(lids) do
		ow, oh = idata:getDimensions()
		lox = ow - 1
		loy = oh - 1
		for y = 0, loy do
			for x = 0, lox do
				r, g, b, a = idata:getPixel(x, y)
				if a > 0 then
					frame:setPixel(x + loff[place].left, y + loff[place].top, r, g, b, a)
				end
			end
		end
	end
	-- put corners in frame
	ow, oh = cids.top_left:getDimensions()
	lox = ow - 1
	loy = oh - 1
	for place, idata in pairs(cids) do
		for y = 0, lox do
			for x = 0, loy do
				r, g, b, a = idata:getPixel(x, y)
				if a > 0 then
					frame:setPixel(x + coff[place].left, y + coff[place].top, r, g, b, a)
				end
			end
		end
	end
	return frame
end

local function getFrameName()
	local i = 1
	local found = false
	local name =""
	while not found do
		if not comres["frame" .. i] then
			found = true
			name = "frame" .. i
		else
			i = i + 1
		end
	end
	return name
end

local function imageFG(fgdef, geom)
	-- INICIAR VARIABLES
	-- LINEAS
	-- buscar idatas disponibles y crear
	-- idatas faltantes
	local lids = getFrameLineData(fgdef.images)
	-- crear tiles
	local lids, vth, hth = getTiledLines(lids, geom)
	-- RINCONES
	--buscar idatas disponibles y crear
	-- faltantes
	local cids, cs = getFrameCornerData(fgdef.images)
	-- COMPOSICIÓN Y GENERACIÓN
	-- componer imagen
	local framedata = composeFrame(lids, cids, geom, vth, hth, cs)
	-- convertir imagedata a imagen, 
	-- generar nombre y poner en cache
	local framename = getFrameName()
	comres[framename] = {
		image = love.graphics.newImage(framedata),
		width = geom.width,
		height = geom.height
	}
	-- generar fg
	fg = {
		type = "image",
		image = framename,
		xscale = 1,
		yscale = 1
	}
	-- generar safe geom
	sg = {
		left = geom.left + vth,
		top = geom.top + hth,
		right = geom.right - vth,
		bottom = geom.bottom - hth,
		width = geom.width - (vth * 2),
		height = geom.height - (hth * 2)
	}
	-- DEVOLVER
	return fg, sg
end

-- accepts either a file or a table
local function getAreas(adef)
	-- init vars
	local bg, geom, fg, sgeom = {}, {}, {}
	if type(adef) == "string" then
		adef = require(basedir .. afile)
	end
	-- big fat iterator
	for k, v in pairs(adef) do
		-- get basic area geometry
		geom = areageometry(v)
		if v.background.type == "color" then
			bg = colorbg(v.background)
		elseif v.background.type == "image" then
			bg = imagebg(v.background, geom)
		elseif v.background.type == "tile" then
			bg = tilebg(v.background, geom)
		end
		if v.foreground then
			if v.foreground.type == "plain" then
				fg, sgeom = plainfg(v.foreground, geom)
			elseif v.foreground.type == "frame" then
				fg, sgeom = imageFG(v.foreground, geom)
			else
				fg = false
				sgeom = geom
			end
		else
			fg = false
			sgeom = geom
		end
		areas[k] = {
			geometry = geom,
			background = bg,
			foreground = fg,
			safe = sgeom
		}
	end
end

local drawfg = {}

function drawfg.plain(adef)
	local bgdef = adef.foreground
	love.graphics.setColor(unpack(bgdef.fill))
	for _, v in pairs(bgdef.squares) do
		love.graphics.rectangle("fill", v.left, v.top, v.width, v.height)
	end
	if bgdef.border then
		love.graphics.setColor(unpack(bgdef.border))
		for _, v in ipairs(bgdef.lines) do
			love.graphics.rectangle("line", v.left, v.top, v.width, v.height)
		end
	end
end

function drawfg.image(adef)
	love.graphics.setColor(1, 1, 1)
	love.graphics.draw(comres[adef.foreground.image].image, adef.geometry.left, adef.geometry.top, 0, xscale, yscale)
end

local drawbg = {}

function drawbg.color(adef)
	love.graphics.setColor(unpack(adef.background.color))
	love.graphics.rectangle("fill", adef.geometry.left, adef.geometry.top, adef.geometry.width, adef.geometry.height)
end

function drawbg.image(adef)
	love.graphics.setColor(1, 1, 1)
	love.graphics.draw(comres[adef.background.image].image, adef.geometry.left, adef.geometry.top, 0, adef.background.xscale, adef.background.yscale)
end

local function drawChar(cdef)
	love.graphics.setColor(1, 1, 1, cdef.active.alpha)
	love.graphics.draw(cdef.images[cdef.active.ref].image, cdef.active.x, cdef.active.y, cdef.active.angle, cdef.active.scale)
end

local function drawProp(propdef)
	love.graphics.setColor(1, 1, 1)
	love.graphics.draw(propdef.image, propdef.x, propdef.y, 0, propdef.xscale, propdef.yscale)
end

local drawDialog = {}

function drawDialog.normal(ddef)
	love.graphics.setColor(unpack(chars[ddef.char].color))
	love.graphics.print(ddef.litchar, fonts.name, ddef.nameleft, ddef.nametop)
	love.graphics.print(ddef.line, fonts.dialog, areas.dialog.safe.left + 2, areas.dialog.safe.top + 2)
end

function drawDialog.choice(ddef)
	love.graphics.setColor(1, 1, 1)
	love.graphics.print(ddef.line, fonts.caption, ddef.capleft, ddef.captop)
	for _, chc in ipairs(ddef.choices) do
		love.graphics.print(chc.choice, fonts.choice, chc.chleft, chc.chtop)
		love.graphics.line(areas.dialog.geometry.left, chc.chtop, areas.dialog.geometry.right, chc.chtop)
	end
	love.graphics.line(areas.dialog.geometry.left, ddef.bline, areas.dialog.geometry.right, ddef.bline)
end

function drawDialog.touch(ddef)
	love.graphics.setColor(1, 1, 1)
	love.graphics.print(ddef.line, fonts.dialog, areas.dialog.safe.left + 2, areas.dialog.safe.top + 2)
end

local function drawMenu()
	local curmenu = menu[curmenlev]
	
	if curmenu.background.type == "color" then
		love.graphics.setColor(unpack(curmenu.background.color))
		love.graphics.rectangle("fill", screen.geometry.left, screen.geometry.top, screen.geometry.right, screen.geometry.bottom)
	else
		love.graphics.setColor(1, 1, 1)
		love.graphics.draw(comres[curmenu.background.image].image, screen.geometry.left, screen.geometry.top)
	end
	love.graphics.setColor(1, 1, 1)
	for _, deco in ipairs(curmenu.deco) do
		love.graphics.draw(comres[deco.image].image, deco.left, deco.top, 0, deco.xscale, deco.yscale)
	end
	local buttype = curmenu.buttons.type
	local buttcom = curmenu.buttons[buttype]
	for _, butt in ipairs(curmenu.buttons.options) do
		
		love.graphics.setColor(unpack(buttcom.background))
		love.graphics[buttype]("fill", butt.left, butt.top, butt.width, butt.height)
		love.graphics.setColor(unpack(buttcom.border))
		love.graphics[buttype]("line", butt.left, butt.top, butt.width, butt.height)
		love.graphics.setColor(unpack(buttcom.text))
		love.graphics.print(butt.caption, curmenu.font, butt.txleft, butt.txtop)
		
	end
	
end

local function getFileList(dir, type)
	local flist, ilist = {}, {}
	flist = love.filesystem.getDirectoryItems(dir)
	for _, v in ipairs(flist) do
		if v:sub(-#type - 1, -1) == "." .. type then
			table.insert(ilist, v)
		end
	end
	return ilist
end

local function getImageList(dir)
	return getFileList(dir, "png")
end

local function cacheCommon()
	-- comdir = basedir .. "common/"
	local imgs, idat = {}, {}
	imgs = getImageList(comdir)
	for _, iref in ipairs(imgs) do
		idat = love.image.newImageData(comdir .. iref)
		comres[iref:sub(1,-5)] = {
			image = love.graphics.newImage(idat),
			width = idat:getWidth(),
			height = idat:getHeight()
		}
	end
end

local function findFontFile(dir)
	local flist = love.filesystem.getDirectoryItems(dir)
	local found = false
	local idx = 1
	local font = false
	while (not found) and (idx <= #flist) do
		if flist[idx]:sub(-4, -1) == ".ttf" then
			found = true
			font = flist[idx]
		else
			idx = idx + 1
		end
	end
	return font
end

local schars = {}

function schars.fixTo(scale)
	local ah = areas.stage.geometry.bottom - areas.stage.safe.top
	local th = scale * ah
	local actim = ""
	for char, cdef in pairs(chars) do
		for iref, idef in pairs(cdef.images) do
			chars[char].images[iref].scale = th / idef.height
		end
		actim = cdef.active.ref
		chars[char].active.scale = cdef.images[actim].scale
		chars[char].active.x = areas.stage.safe.left + (areas.stage.geometry.centerx - ((cdef.images[actim].width * cdef.active.scale) * cdef.active.relx))
		chars[char].active.y = areas.stage.geometry.bottom - (cdef.active.scale * cdef.images[actim].height)
		chars[char].active.fx = chars[char].active.x + (chars[char].images[chars[char].active.ref].width * chars[char].active.scale)
		chars[char].active.fy = chars[char].active.y + (chars[char].images[chars[char].active.ref].height * chars[char].active.scale)
	end
end

function schars.propmax()
	local tallest = 0
	local ah = areas.stage.geometry.bottom - areas.stage.safe.top
	local tscale = 0
	local actim = ""
	for char, cdef in pairs(chars) do
		for iref, idef in pairs(cdef.images) do
			if idef.height > tallest then
				tallest = idef.height
			end
		end
	end
	tscale = ah / tallest
	for char, cdef in pairs(chars) do
		for iref, idef in pairs(cdef.images) do
			chars[char].images[iref].scale = tscale
		end
		actim = cdef.active.ref
		chars[char].active.scale = cdef.images[actim].scale
		chars[char].active.x = areas.stage.safe.left + (areas.stage.geometry.centerx - ((cdef.images[actim].width * cdef.active.scale) / 2))
		chars[char].active.y = areas.stage.geometry.bottom - (cdef.active.scale * cdef.images[actim].height)
		chars[char].active.fx = chars[char].active.x + (chars[char].images[chars[char].active.ref].width * chars[char].active.scale)
		chars[char].active.fy = chars[char].active.y + (chars[char].images[chars[char].active.ref].height * chars[char].active.scale)
	end
end

local function scaleChars(mode)
	if type(mode) == "string" then
		if mode == "max" then
			schars.fixTo(1)
		else
			schars[mode]()
		end
	else
		if mode then
			schars.fixTo(mode)
		end
	end
end

local function getChars(scmode)
	-- init vars
	local flist = love.filesystem.getDirectoryItems(charsdir)
	local inf = {}
	local curcd = ""
	local curid = ""
	local iw, ih = 0, 0
	local txr, txg, txb, sep = 0, 0, 0, 0
	local chardef = {}
	local xpos, ypos = 0, 0
	local remstr = ""
	-- build chars table
	for _, file in ipairs(flist) do
		inf = love.filesystem.getInfo(charsdir .. file)
		if inf.type == "directory" then
			chars[file] = { images = {} }
		end
	end
	for char, _ in pairs(chars) do
		-- add all images
		curcd = charsdir .. char .. "/"
		il = getImageList(curcd)
		for _, iref in ipairs(il) do
			curid = love.image.newImageData(curcd .. iref)
			iw, ih = curid:getDimensions()
			chars[char].images[iref:sub(1, -5)] = {
				image = love.graphics.newImage(curid),
				width = iw,
				height = ih,
				scale = 1,
				ref = iref:sub(1, -5),
				mask = imanip.createMask(curid)
			}
		end
		-- take additionl parameters for
		-- [char id].chr file
		chardef = {}
		for line in love.filesystem.lines(curcd .. char .. ".chr") do
			table.insert(chardef, line)
		end
		-- take char's name from line 1
		chars[char].name = chardef[1]
		-- extract rgb values for speech
		-- from line 2
		sep = chardef[2]:find(",")
		txr = tonumber(chardef[2]:sub(1, sep-1))
		remstr = chardef[2]:sub(sep+1, -1)
		sep = remstr:find(",")
		txg = tonumber(remstr:sub(1, sep-1))
		txb = tonumber(remstr:sub(sep+1, -1))
		chars[char].color = { txr, txg, txb }
		-- get active image from line 3
		-- and center it
		xpos = areas.stage.geometry.centerx - (chars[char].images[chardef[3]].width / 2)
		ypos = areas.stage.geometry.bottom - chars[char].images[chardef[3]].height
		chars[char].active = {
			ref = chardef[3],
			x = xpos,
			y = ypos,
			alpha = 1,
			scale = 1,
			angle = 0,
			relx = 0.5,
			rely = 1,
			fx = xpos + chars[char].images[chardef[3]].width,
			fy = ypos + chars[char].images[chardef[3]].height
		}
		-- make char visible at start or not
		-- based on line 4
		if chardef[4] == "true" then
			chars[char].visible = true
			table.insert(visiblechars, char)
		else
			chars[char].visible = false
		end
		-- add replacemdment
		reps[char] = chardef[1]
	end
	scaleChars(scmode)
	chars.narrator = {
		name = "",
		color = { 1, 1, 1 }
	}
end

local function isInStage(x, y)
	if x < areas.stage.safe.left then
		return false
	elseif x > areas.stage.safe.right then
		return false
	elseif y < areas.stage.safe.top then
		return false
	elseif y > areas.stage.safe.bottom then
		return false
	else
		return true
	end
end

local function getValues(string, sepchar)
	local retable = {}
	local remstring = string
	local found, last = false, false
	local idx = 1
	local val
	while not last do
		while (not found) and (idx <= #remstring) do
			 if remstring:sub(idx, idx) == sepchar then
				val = remstring:sub(1, idx - 1)
				val = tonumber(val) or val
				table.insert(retable, val)
				remstring = remstring:sub(idx + 1, -1)
				found = true
			else
				idx = idx + 1
			end
		end
		if found then
			found = false
			idx = 1
		else
			remstring = tonumber(remstring) or remstring
			table.insert(retable, remstring)
			last = true
		end
	end
	return retable
end

local function getTouched(x, y)
	-- INIT VARS
	local z = visibleprops.front
	local piz = #z
	local found = false
	local toth = false
	local idx = piz
	local nux, nuy = 0, 0
	local stdef = {}
	local curchar, charac, charim = "", {}, {}
	-- CHECK FRONT PROPS IN
	-- REVERSE DRAWING ORDER
	while (not found) and (idx >= 1) do
		stdef = props[z[idx].prid].states[z[idx].stid]
		nux, nuy = imanip.toMask(x, y, stdef.x, stdef.y, stdef.fx, stdef.fy, stdef.xscale, stdef.yscale)
		if (nux and nuy) and (stdef.mask[nux][nuy]) then
			found = true
			toth = {
				type = "prop",
				pid = z[idx].prid,
				sid = z[idx].stid
			}
		else
			idx = idx - 1
		end
	end
	-- RESET VARS
	if not found then
		idx = #visiblechars
	end
	-- CHECK CHARS IN TEVERSE
	-- DRAWING ORDER
	while (not found) and (idx >= 1) do
		curchar = visiblechars[idx]
		charac = chars[curchar].active
		charim = chars[curchar].images[charac.ref]
		nux, nuy = imanip.toMask(x, y, charac.x, charac.y, charac.fx, charac.fy, charac.scale)
		if (nux and nuy) and (charim.mask[nux][nuy]) then
			found = true
			toth = {
				type = "char",
				pid = curchar,
				sid = charac.ref
			}
		else
			idx = idx - 1
		end
	end
	-- RESET VARS
	if not found then
		z = visibleprops.back
		piz = #z
		idx = piz
	end
	-- CHECK FRONT PROPS IN
	-- REVERSE DRAWING ORDER
	while (not found) and (idx >= 1) do
		stdef = props[z[idx].prid].states[z[idx].stid]
		nux, nuy = imanip.toMask(x, y, stdef.x, stdef.y, stdef.fx, stdef.fy, stdef.xscale, stdef.xy)
		if (nux and nuy) and (stdef.mask[nux][nuy]) then
			found = true
			toth = {
				type = "prop",
				pid = z[idx].prid,
				sid = z[idx].stid
			}
		else
			idx = idx - 1
		end
	end
	-- RETURN TOUCHED THING
	return toth
end

local touch = {}

function touch.chars(x, y)
	local tch = #visiblechars
	local touched = false
	local idx = tch
	local curim, curac = {}, {}
	while (not touched) and (idx >= 1) do
		curac = chars[visiblechars[idx]].active
		curim = chars[visiblechars[idx]].images[curac.ref]
		nux, nuy = imanip.toMask(x, y, curac.x, curac.y, curac.fx, curac.fy, curac.scale)
		if (nux and nuy) and curim.mask[nux][nuy] then
			vnl.hideChar(visiblechars[idx])
			touched = true
		else
			idx = idx - 1
		end
	end
end

local function getProps()
	local prlist = getFileList(propsdir, "prp")
	if prlist and (#prlist > 0) then
		local tid, iw, ih = "", 0, 0
		local stdtable = {}
		local nw, nh = 0, 0
		local propcom = {}
		local lind = 1
		local tx, ty, tzx, tzy = 0, 0
		local vis = false
		local rleft, rtop, rright, rbottom = 0, 0, 0, 0
		local active = ""
		for line in love.filesystem.lines(basedir .. "common.prp") do
			propcom = getValues(line, ",")
		end
		nw = tonumber(propcom[1]) or 0
		nh = tonumber(propcom[2]) or 0
		tzx = areas.stage.geometry.width / nw
		tzy = (areas.stage.geometry.bottom - areas.stage.safe.top) / nh
		for order, prid in ipairs(prlist) do
			props[prid:sub(1,-5)] = { states = {} }
			for stdef in love.filesystem.lines(propsdir .. prid) do
				stdtable = getValues(stdef, ",")
				tid = love.image.newImageData(propsdir .. stdtable[1] .. ".png")
				iw, ih = tid:getDimensions()
				tx = areas.stage.geometry.left + ((areas.stage.geometry.width * stdtable[2]) - ((iw * tzx) / 2))
				ty = areas.stage.geometry.top + ((areas.stage.geometry.height * stdtable[3]) - ((ih * tzy) / 2))
				vis = stdtable[5] == "true"
				props[prid:sub(1, -5)].states[stdtable[1]] = {
					x = tx,
					y = ty,
					xscale = tzx,
					yscale = tzy,
					image = love.graphics.newImage(tid),
					visible = vis,
					fx = tx + (iw * tzx),
					fy = ty + (ih * tzy),
					mask = imanip.createMask(tid)
				}
				active = stdtable[1]
				if vis then
					table.insert(visibleprops[stdtable[4]], { prid = prid:sub(1, -5), stid = stdtable[1] })
				end
			end
			props[prid:sub(1,-5)].active = active
			props[prid:sub(1, -5)].z = stdtable[4]
		end
	end
end

local function halfAssParse(str)
	local funparsep = str:find("%(")
	local fun = str:sub(1, funparsep - 1)
	local pars = str:sub(funparsep + 1, -2)
	local params = getValues(pars, ",")
	local funplace = ""
	if vnl[fun] then
		funplace = "sys"
	elseif useractions[fun] then
		funplace = "custom"
	end
	return { type = funplace, command = fun, parameters = params }
end

local function halfAssCondParse(str)
	local evalop = {
		{ sym = "=", fun = "equal" },
		{ sym = "<", fun = "smaller" },
		{ sym = ">", fun = "bigger" }
	}
	local found, idx, oppo = false, 1, 0
	local op, fu = "", ""
	while (not found) and (idx <= #evalop) do
		oppo = str:find(evalop[idx].sym)
		if oppo then
			found = true
			op = evalop[idx].sym
			fu = evalop[idx].fun
		else
			idx = idx + 1
		end
	end
	if found then
		var = str:sub(1, oppo - 1)
		val = str:sub(oppo + 1, -1)
		return {
			ref = var,
			operator = fu,
			value = val
		}
	else
		return true
	end
end

local function getDlgAction(acdef)
	if not acdef then
		return false
	else
		return halfAssParse(acdef)
	end
end

local function getFonts(fdef)
	local ffil = findFontFile(comdir)
	local str = "Los hermanos sean unidos"
	local arbitsize = 50
	local arbitfont = ""
	local tyar = {
		name = "caption",
		caption = "caption",
		dialog = "dialog",
		choice = "dialog"
	}
	if ffil then
		arbitfont = love.graphics.newFont(comdir .. ffil, arbitsize)
	else
		arbitfont = love.graphics.newFont(arbitsize)
	end
	local arbitheight = arbitfont:getHeight(str)
	local desirheight = 0
	local desirsize = 0
	for font, lines in pairs(fdef) do
		desirheight = (areas[tyar[font]].safe.height - 4) / lines
		desirsize = (desirheight * arbitsize) / arbitheight
		if ffil then
			fonts[font] = love.graphics.newFont(comdir .. ffil, desirsize)
		else
			fonts[font] = love.graphics.newFont(desirsize)
		end
	end
end

local function adjustLine(str, tw, fontref)
	local spaces = {}
	local found = false
	local rtv = ""
	local strl = #str
	local tls = 1
	if fonts[fontref]:getWidth(str) <= tw then
		rtv = str
	else
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
	end
	strl = #str
	for i = 1, strl do
		if str:sub(i,i) == "\n" then
			tls = tls + 1
		end
	end
	return rtv, tls
end

local function performAction(act)
	if act.type == "sys" then
		vnl[act.command](unpack(act.parameters))
	else
		useractions[act.command](unpack(act.parameters))
	end
end

local function getDialog(fname)
	-- INIT VARS
	local dlgt = {}
	local act, next = {}, ""
	local capx  capy, chleft, chtop, acumtop = 0, 0, 0, 0, 0
	local nuchc, chs, cond = "", {}, {}
	local tchdef, tchtype, tchth, touchables = {}, "", "", {}
	-- ERASE PREVIOUS DIALOG
	-- AND FETCH DIALOG FILE
	dialog = {}
	dlgdef = require(dialdir .. fname)
	-- PROCESS EACH REGISTRY
	for order, dlg in ipairs(dlgdef) do
		-- COMMON ACTIONS
		for ref, nu in pairs(reps) do
			dlg.line = dlg.line:gsub("_" .. ref, nu)
		end
		-- EACH DIALOG TYPE IS
		-- PROCESSED IN A 
		-- DIFFERENT WAY
		if dlg.char == "choice" then
			-- FOR CHOICE TYPE DIALOGS
			for order, chc in ipairs(dlg.choices) do
				for ref, nu in pairs(reps) do
					nuchc = chc.line:gsub(ref, nu)
				end
				if chc.cond then
					cond = halfAssCondParse(chc.cond)
				else
					cond = false
				end
				if chc.action then
					act = getDlgAction(chc.action)
				elseif chc.next then
					act = chc.next
				else
					act = false
				end
				chs[order] = {
					choice = nuchc,
					cond = cond,
					consequence = act,
					chleft = 0,
					chtop = 0
				}
			end
			capx = areas.caption.geometry.centerx - (fonts.name:getWidth(dlg.line) /2)
			capy = areas.caption.geometry.centery - (fonts.name:getHeight(dlg.line) / 2)
			dlgt = {
				type = "choice",
				line = dlg.line,
				capleft = 0,
				captop = 0,
				choices = chs
			}
			nuchc = nil
			chs = {}
		elseif dlg.char == "touch" then
			-- FOR TOUCH TYPE DIALOG
			for order, tch in ipairs(dlg.touchables) do
				touchables = {}
				if tch.cond then
					cond = halfAssCondParse(tch.cond)
				else
					cond = false
				end
				if chars[tch.thing] then
					tchtype = "char"
					tchth = tch.thing
				elseif props[tch.thing] then
					tchtype = "prop"
					tchth = tch.thing
				elseif tch.thing == "any" then
					tchtype = "background"
					tchth = false
				end
				if tch.action then
					act = getDlgAction(tch.action)
				else
					act = tch.next
				end
				tchdef = {
					cond = cond,
					type = tchtype,
					thing = tchth,
					consequence = act,
					advance = tch.advance
				}
				table.insert(touchables, tchdef)
			end
			dlgt = {
				type = "touch",
				line = dlg.line,
				touches = touchables
			}
		else -- normal dialog assumed
			-- FOR NORMAL TYPE DIALOG
			if dlg.action then
				act = getDlgAction(dlg.action)
			elseif dialog.next then
				act = dlg.next
			else
				act = false
			end
			capx = areas.caption.geometry.centerx - (fonts.name:getWidth(chars[dlg.char].name) /2)
			capy = areas.caption.geometry.centery - (fonts.name:getHeight(chars[dlg.char].name) / 2)
			dlgt = {
				type = "normal",
				char = dlg.char,
				litchar = chars[dlg.char].name,
				nameleft = capx,
				nametop = capy,
				line = dlg.line,
				consequence = act
			}
		end
		-- PUT THE PROCESSED DIALOG
		-- LINE IN THE MAIN DIALOG
		-- TABLE
		table.insert(dialog, dlgt)
	end
	dindex = 1
	dcontrol = dialog[1].type
	prepro = false
	if dialog[1].consequence then
		performAction(dialog[1].consequence)
	end
end

local evalSpec = {}

function evalSpec.equal(r, v)
	return uservars[r] == v
end

function evalSpec.smaller(r, v)
	return uservars[r] < v
end

function evalSpec.bigger(r, v)
	return uservars[r] > v
end

local function evalCond(condef)
	if condef then
		return evalSpec[condef.operator](condef.ref, condef.value)
	else
		return true
	end
end

local function actionConsequence(conseq)
	if type(conseq) == "table" then
		if conseq.type == "sys" then
			vnl[conseq.command](unpack(conseq.parameters))
		else -- custom assumed
			useractions[conseq.command](unpack(conseq.parameters))
		end
		dindex = dindex + 1
		dcontrol = dialog[dindex].type
		prepro = false
	else -- type = string assumed
		getDialog(conseq)
	end
end

local preProcess = {}

function preProcess.normal(ddef)
	for ref, val in pairs(uservars) do
		ddef.line = ddef.line:gsub("_" .. ref, tostring(val))
	end
	ddef.line = adjustLine(ddef.line, areas.dialog.safe.width - 4, "dialog")
	prepro = true
	return ddef
end

function preProcess.touch(ddef)
	local rems = {}
	for ref, val in pairs(uservars) do
		ddef.line = ddef.line:gsub("_" .. ref, tostring(val))
	end
	for i, v in ipairs(ddef.touches) do
		if not evalCond(v.cond) then
			table.insert(rems, i)
		end
	end
	for i = #rems, 1, -1 do
		table.remove(ddef.touchables, rems[i])
	end
	ddef.line = adjustLine(ddef.line, areas.dialog.safe.width - 4, "dialog")
	prepro = true
	return ddef
end

function preProcess.choice(ddef)
	local ls = 0
	local rems = {}
	local acum = 0
	local chcl = 0
	local lh = fonts.choice:getHeight()
	for ref, val in pairs(uservars) do
		ddef.line:gsub("_" .. ref, tostring(val))
	end
	ddef.line, ls = adjustLine(ddef.line, areas.dialog.safe.width - 4, "choice")
	ddef.capleft = areas.caption.geometry.centerx - (fonts.caption:getWidth(ddef.line) / 2)
	ddef.captop = areas.caption.geometry.centery - ((fonts.caption:getHeight() * ls) / 2)
	for order, chc in pairs(ddef.choices) do
		if evalCond(chc.cond) then
			for ref, val in pairs(uservars) do
				chc.choice = chc.choice:gsub("_" .. ref, tostring(val))
			end
			chc.choice, chcl = adjustLine(chc.choice, areas.dialog.safe.width, "choice")
			chc.chleft = areas.dialog.safe.left + 2
			chc.chtop = areas.dialog.safe.top + 2 + acum
			chc.chbottom = areas.dialog.safe.top + 2 + acum + (chcl * lh)
			acum = acum + (chcl * lh)
		else
			table.insert(rems, order)
		end
	end
	for i = #rems, 1, -1 do
		table.remove(ddef.choices, rems[i])
	end
	ddef.bline = areas.dialog.safe.top + 2 + acum
	prepro = true
	return  ddef
end

local function getMenuTouch(x, y)
	local found, idx, rtv = false, 1, false
	local cmen = menu[curmenlev].buttons.options
	local topts = #cmen
	local copt = {}
	while (not found) and (idx <= topts) do
		copt = cmen[idx]
		if (x >= copt.left) and (x <= copt.right) and (y >= copt.top) and (y <= copt.bottom) then
			found = true
			rtv = idx
		else
			idx = idx + 1
		end
	end
	if found then
		return cmen[rtv].action
	else
		return false
	end
end

local menuactions = {}

function menuactions.start()
	getDialog(firstdialog)
end

function menuactions.quit()
	love.event.quit(0)
end

function menuactions.exit()
	love.event.quit(0)
end

local function performMenuAction(act)
	if menu[act] then
		curmenlev = act
	elseif menuactions[act] then
		menuactions[act]()
	elseif useractions[act] then
		useractions[act]()
	else
		
	end
	
end

local touch = {}

function touch.normal(x, y)
	if dialog[dindex].consequence and (type(dialog[dindex].consequence) == "string") then
		getDialog(dialog[dindex].consequence)
	else
		dindex = dindex + 1
		dcontrol = dialog[dindex].type
		prepro = false
		if dialog[dindex].consequence and type(dialog[dindex].consequence) == "table" then
			performAction(dialog[dindex].consequence)
		end
	end
end

function touch.choice(x, y)
	local found, idx = false, 1
	local tchoices = #dialog[dindex].choices
	local cht = dialog[dindex].choices
	while (not found) and (idx <= tchoices) do
		if (x >= areas.dialog.safe.left) and (x <= areas.dialog.safe.right) and (y >= cht[idx].chtop) and (y <= cht[idx].chbottom) then
			actionConsequence(cht[idx].consequence)
			found = true
		else
			idx = idx + 1
		end
	end
end

function touch.touch(x, y)
	local toth = getTouched(x, y)
	local things = dialog[dindex].touches
	local found, idx = false, 1
	local totalthings = #things
	if toth then
		while (not found) and (idx <= totalthings) do
			if (toth.pid == things[idx].thing) then
				found = true
				performAction(things[idx].consequence)
				if things[idx].advance then
					dindex = dindex + 1
					dcontrol = dialog[dindex].type
					prepro = false
				end
			else
				idx = idx + 1
			end
		end
	end
end

function touch.menu(x, y)
	local touched = getMenuTouch(x, y)
	if touched then performMenuAction(touched) end
end

local function getCustom()
	uservars = require(userdir .. "variables")
	useractions = require(userdir .. "actions")
end

local function getMenu(menudef)
	local tid,tirw, tirh, sw, sh = "", 0, 0, 0, 0
	local fts, fsize = 0, 0
	local bl, bt, br, bb, bw, bh = 0, 0, 0, 0, 0, 0
	if type(menudef) == "string" then
		menudef = require(mendef)
	end
	for mename, def in pairs(menudef) do
		if def.background.type == "tile" then
			tid = iman.tile(love.image.newImageData(comdir .. def.background.image .. ".png"), screen.geometry.right, screen.geometry.left)
			def.background.type = "image"
			def.background.image = love.graphics.newImage(tid)
		end
		for order, decodef in ipairs(def.deco) do
			tirw = comres[decodef.image].width
			tirh = comres[decodef.image].height
			decodef.xscale = (screen.geometry.right * decodef.xspan) / tirw
			decodef.yscale = (screen.geometry.bottom * decodef.yspan) / tirh
			sw = tirw * decodef.xscale
			sh = tirh * decodef.yscale
			decodef.left = (screen.geometry.right * decodef.xpos) - (sw / 2)
			decodef.top = (screen.geometry.bottom * decodef.ypos) - (sh / 2)
			decodef.xspan = nil
			decodef.yspan = nil
			decodef.xpos = nil
			decodef.ypos = nil
		end
		fts = screen.geometry.bottom * def.font.size
		fsize = fts
		if def.font.face and (def.font.face ~= "") then
			def.font = love.graphics.newFont(comdir .. def.font.face, fsize)
		else
			def.font = love.graphics.newFont(fsize)
		end
		combutt = def.buttons
		for order, bdef in ipairs(def.buttons.options) do
			if def.buttons.type == "rectangle" then
				bw = screen.geometry.right * bdef.xspan
				bh = screen.geometry.bottom * bdef.yspan
				bl = (screen.geometry.right * bdef.xpos) - (bw / 2)
				bt = (screen.geometry.bottom * bdef.ypos) - (bh / 2)
				br = bl + bw
				bb = bt + bh
				btxw = def.font:getWidth(bdef.caption)
				btxh = def.font:getHeight()
				bdef.width = bw
				bdef.height = bh
				bdef.left = bl
				bdef.top = bt
				bdef.right = br
				bdef.bottom = bb
				bdef.txleft = bdef.left + (bdef.width / 2) - (btxw / 2)
				bdef.txtop = bdef.top + (bdef.height / 2) - (btxh / 2)
				bdef.xspan = nil
				bdef.yspan = nil
				bdef.xpos = nil
				bdef.ypos = nil
			end
		end
	end
	menu = menudef
	curmenlev = "main"
end

-- PUBLIC FUNCTIONS

-- LOVE CONNECTION

function vnl.init(width, height, bd, adef, charscale, dlgf, fontdef, mendef)
	-- BUILD SCREEN GEOMETRY
	-- TABLE
	screen = {
		dpi = love.window.getDPIScale(),
		geometry = {
			left = 0,
			top = 0,
			right = width,
			bottom = height,
			centerx = width / 2,
			centery = height / 2
		}
	}
	-- HERE SHOULD GO DEFAULT
	-- VALUES
	
	
	
	-- SET DIRECTORIES
	basedir = bd
	comdir = bd .. "common/"
	charsdir = bd .. "chars/"
	propsdir = bd .. "props/"
	dialdir = bd .. "dialogs/"
	userdir = bd .. "user/"
	-- DO STARTUP STUFF
	cacheCommon()
	getMenu(mendef)
	getAreas(adef)
	getCustom()
	getFonts(fontdef)
	getChars(charscale)
	getProps()
	firstdialog = dlgf
	--'getDialog(dlgf)
	dcontrol = "menu"
end

function vnl.draw(dt)
	if dcontrol ~= "menu" then
		
		-- AREAS' BACKGROUNDS
		for k, v in pairs(areas) do
			drawbg[v.background.type](v)
		end
		-- BACK PROPS
		for i, v in ipairs(visibleprops.back) do
			drawprop(props[v.prid].states[v.stid])
		end
		-- CHARACTERS
		for order, char in ipairs(visiblechars) do
			drawChar(chars[char])
		end
		-- FRONT PROPS
		for i, v in ipairs(visibleprops.front) do
			drawProp(props[v.prid].states[v.stid])
		end
		-- DIALOG
		if not prepro then
			procdiag = preProcess[dcontrol](dialog[dindex])
		end
		drawDialog[dcontrol](procdiag)
		-- AREAS' FOREGROUNDS
		for _, v in pairs(areas) do
			if v.foreground then
				drawfg[v.foreground.type](v)
			end
		end
	else
		drawMenu()
	end
end

function vnl.evalTouch(x, y)
	touch[dcontrol](x, y)
end

-- A REALLY DUMB FUNCTION THAT
-- DOES NOTHING
function vnl.nop() end

-- AREA-RELATED

function vnl.getAreaSize(aname)
	return areas[aname].geometry.width, areas[aname].geometry.height
end

function vnl.getAreaPos(aname)
	return areas[aname].geometry.left, areas[aname].geometry.top, areas[aname].geometry.right, areas[aname].geometry.bottom
end

function vnl.getSafeAreaSize(aname)
	return areas[aname].safe.width, areas[aname].safe.height
end

function vnl.getSafeAreaPos(aname)
	return areas[aname].safe.left, areas[aname].safe.top, areas[aname].safe.right, areas[aname].safe.bottom
end

function vnl.setAreaBG(aname, iref)
	local xs = areas[aname].geometry.width / comres[iref].width
	local ys = areas[aname].geometry.height / comres[iref].height
	areas[aname].background.image = iref
	areas[aname].background.xscale = xs
	areas[aname].background.yscale = ys
	areas[aname].background.type = "image"
end

function vnl.setForegroundColor(fc, bc)
	if fc then
		areas[aname].foreground.fill = fc
	end
	if bc then
		areas[aname].foreground.border = bc
	end
end

function vnl.getBackgroundImage(aname)
	return areas[aname].background.image
end

-- CHARACTER-RELATED

function vnl.showChar(cid, iref)
	local found = false
	if iref then
		vnl.changeCharImage(char, iref)
	end
	for order, char in ipairs(visibleChars) do
		if char == cid then
			found = true
		end
	end
	if not found then
		table.insert(visiblechars, cid)
	end
	chars[cid].visible = true
end

function vnl.hideChar(cid)
	local found, idx = false, 1
	chars[cid].visible = false
	while (not found) and (idx <= #visiblechars) do
		if visiblechars[idx] == cid then
			table.remove(visiblechars, idx)
			found = true
		else
			idx = idx + 1
		end
	end
end

function vnl.changeCharImage(cid, iref)
	local acref = chars[cid].active
	local chimg = chars[cid].images[iref]
	local th = areas.stage.geometry.bottom - areas.stage.safe.top
	acref.ref = iref
	acref.scale = chimg.scale
	acref.x = areas.stage.safe.left + ((areas.stage.safe.width * acref.relx) - (chimg.width * acref.scale) / 2)
	acref.y = areas.stage.safe.top + ((th * acref.rely) - (chimg.height * acref.scale) / 2)
	chars[cid].active.fx = chars[cid].active.x + (chars[cid].images[chars[cid].active.ref].width * chars[cid].active.scale)
	chars[cid].active.fy = chars[cid].active.y + (chars[cid].images[chars[cid].active.ref].height * chars[cid].active.scale)
end

function vnl.getCharOrder(cid)
	local idx = 1
	while (not found) and (idx <= #visiblechars) do
		if visiblechars[idx] == cid then
			return idx
		end
	end
	return false
end

function vnl.stepCharFront(cid)
	local order = vnl.getCharOrder(cid)
	if order and order > 1 then
		visiblechars[order] = visblechars[order - 1]
		visiblechars[order - 1] = cid
	end
end

function vnl.stepCharBack(cid)
	local order = vnl.getCharOrder(cid)
	if order and order < #visiblechars then
		visiblechard[order] = visiblechars[order+1]
		visiblechars[order + 1] = cid
	end
end

function vnl.bringCharFront(cid)
	local order = vnl.getCharOrder(cid)
	if order and order > 1 then
		table.remove(visiblechars, order)
		table.insert(visiblechars, cid,1)
	end
end

function vnl.bringCharBack(cid)
	local order = vnl.getCharOrder(cid)
	if order and order > 1 then
		table.remove(visiblechars, order)
		table.insert(visiblechars, cid)
	end
end

function vnl.moveChar(cid, nurelx, nurely)
	local th = areas.stage.geometry.bottom - areas.stage.safe.top
	if nurelx then
		chars[cid].active.relx = nurelx
		chars[cid].active.x = areas.stage.safe.left + ((areas.stage.safe.width * chars[cid].active.relx) - (chars[cid].images[chars[cid].active.ref].width * chars[cid].active.scale) / 2)
		chars[cid].active.fx = chars[cid].active.x + (chars[cid].images[chars[cid].active.ref].width * chars[cid].active.scale)
	end
	if nurely then
		chars[cid].active.rely = nurely
		chars[cid].active.y = areas.stage.safe.top + ((th * chars[cid].active.rely) - (chars[cid].images[chars[cid].active.ref].height * chars[cid].active.scale) / 2)
		chars[cid].active.fy = chars[cid].active.y + (chars[cid].images[chars[cid].active.ref].height * chars[cid].active.scale)
	end
end

function vnl.getCharWidth(cid)
	return chars[cid].images[chars[cid].active.ref].width * chars[cid].active.scale
end

function vnl.getCharHeight(cid)
	return chars[cid].images[chars[cid].active.ref].height * chars[cid].active.scale
end

function vnl.getCharBox(cid)
	local left = chars[cid].active.x
	local top = chars[cid].active.y
	return left, top, left + vnl.getCharWidth(cid), top + vnl.getCharHeight(cid)
end

function vnl.getCharPos(cid)
	return chars[cid].active.x, chars[cid].active.y
end

function vnl.getCharRelativePos(cid)
	return chars[cid].active.relx, chars[cid].active.rely
end

-- PROP-RELATED

function vnl.hideProp(prid, stid)
	local zprops = visibleprops[props[prid].z]
	local tprops = #zprops
	stid = stid or props[prid].active
	local found, idx = false, 1
	while (not found) and (idx <= tprops) do
		if zprops[idx].prid == prid then
			found = true
			table.remove(visibleprops[props[prid].z], idx)
		else
			idx = idx + 1
		end
	end
	props[prid].states[stid]. visible = false
end

function vnl.showProp(prid, stid, z)
	z = z or props[prid].z
	stid = stid or props[prid].active
	local found, idx = false, 1
	local zprop = visibleprops[z]
	local tprops = #zprop
	local tdef = {}
	while (not found) and (idx <= tprops) do
		if zprop[idx] == prid then
			found = true
		else
			idx = idx + 1
		end
	end
	if not found then
		tdef = {
			prid = prid,
			stid = stid
		}
		table.insert(visibleprops[z], tdef)
	end
	props[prid].states[stid].visible = false
end

function vnl.changePropState(prid, stid)
	-- INIT VARD
	local zprop = visibleprops[props[prid].z]
	local tprops = #zprop
	local found, idx = false, 1
	-- MAKE ALL STATES OF PRID PROP
	-- INVISIBLE
	for state, stdef in pairs(props[prid].states) do
		if state == stid then
			props[prid].states[stid].visible = true
		else
			props[prid].states[stid].visible = false
		end
	end
	-- CHANGE ACTIVE STATE TO STID
	-- MAKE STID STATE VISIBLE
	props[prid].active = stid
	props[prid].states[stid].visible = true
	-- FIND PRID IN DRAWING PIPELINE
	-- AND IF FOUND CHANGE DTSTE TO
	-- STID
	while (not found) and (idx <= tprops) do
		if zprop[idx].prid == prid then
			found = true
			visibleprops[props[prid].z].stid = stid
		else
			idx = idx + 1
		end
	end
end

function vnl.getPropVisibility(prid)
	return props[prid].states[props[prid].active].visible
end

function vnl.getPropState(prid)
	return ptops[prid].active
end

function vnl.getPropSize(prid, stid)
	stid = stid or props[prid].states[props[prid].active]
	local prop = props[prid].states[stid]
	return prop.fx - prop.x, prop.fy - ptop.y
end

function vnl.getPropPos(prid)
	local stid = props[prid].states[props[prid].active]
	return stid.x, stid.y
end

function vnl.propBehindChars(prid)
	local stid = props[prid].states[props[prid].active]
	local found, idx = false, 1
	local zprop = visibleprops.front
	local tprops = #zprop
	local tdef = {}
	if props[prid].z == "front" then
		while (not found) and (ifx <= tprops) do
			if zprop[idx].prid == prid then
				found = true
				table.remove(visibleprops.front, idx)
				tdef = { prid = prid, stid = props[prid].active }
				table.insert(visibleprops.front, tdef)
			else
				idx = idx + 1
			end
		end
		props[prid].z = "back"
	end
end

function vnl.propsAheadChars(prid)
	local stid = props[prid].states[props[prid].active]
	local found, idx = false, 1
	local zprop = visibleprops.back
	local tprops = #zprop
	local tdef = {}
	if props[prid].z == "back" then
		while (not found) and (ifx <= tprops) do
			if zprop[idx].prid == prid then
				found = true
				table.remove(visibleprops.back, idx)
				tdef = { prid = prid, stid = props[prid].active }
				table.insert(visibleprops.front, tdef)
			else
				idx = idx + 1
			end
		end
		props[prid].z = "front"
	end
end

function vnl.getPropOrder(prid)
	local zprop = visiblechars[props[prid].z]
	local tprops = #zprops
	local order = false
	while (not found) and (idx <= tprops) do
		if zprops[idx].prid == prid then
			order = idx
			found = true
		else
			idx = idx + 1
		end
	end
	return order
end

function vnl.stepPropFront(prid)
	local order = vnl.getPropOrder(prid)
	local zprop = visibleprops[props[prid].z]
	if order < #zprop then
		zprop[order] = zprop[order + 1]
		zprop[order + 1] = { prid = prid, stid = props[prid].active }
	end
end

function vnl.stepPropBack(prid)
	local order = vnl.getPropOrder(prid)
	local zprop = visibleprops[props[prid].z]
	if order > 1 then
		zprop[order] = zprop[order - 1]
		zprop[order - 1] = { prid = prid, stid = props[prid].active }
	end
end

function vnl.bringPropFront(prid)
	local order = vnl.getPropOrder(prid)
	local zprop = visibleprops[props[prid].z]
	local tprops = #zprop
	if order < #zprop then
		table.remove(zprop, order)
		tdef = { prid = prid, stid = props[prid].active }
		table.insert(zprop, tdef)
	end
end

function vnl.bringPropBack(prid)
	local order = vnl.getPropOrder(prid)
	local zprop = visibleprops[props[prid].z]
	local tprops = #zprop
	if order > 1 then
		table.remove(zprop, order)
		tdef = { prid = prid, stid = props[prid].active }
		table.insert(zprop, tdef, 1)
	end
end

-- USERVARS-RELATED

function vnl.setVar(var, val)
	uservars[var] = val
end

function vnl.getVar(var)
	return uservars[var]
end

function vnl.sumVar(var, val)
	uservars[var] = uservars[var] + val
end

function vnl.minusVar(var, val)
	uservars[var] = val - uservars[var]
end

function vnl.varMinus(var, val)
	uservars[var] = uservars[var] - val
end

function vnl.timesVar(var, val)
	uservars[var] = uservars[var] * val
end

function vnl.byVar(var, val)
	uservars[var] = val / uservars[var]
end

function vnl.varBy(var, val)
	uservars[var] = uservars[var] / val
end

function vnl.incVar(var, val)
	uservars[var] = uservars[var], 1
end

function vnl.decVar(var, val)
	uservars[var] = uservars[var] - 1
end

return vnl