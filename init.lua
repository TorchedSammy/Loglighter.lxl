-- mod-version:2 -- lite-xl 2.0
local core = require 'core'
local config = require 'core.config'
local common = require 'core.common'
local style = require 'core.style'
local LogView = require 'core.logview'

local function merge(orig, tbl)
	if tbl == nil then return orig end
	for k, v in pairs(tbl) do
		orig[k] = v
	end

	return orig
end

local conf = merge({
	taggedOnly = false
}, config.plugins.loglighter)

local item_height_result = {}
-- schem: type = color
local itemTypes = {}

local function lines(text)
  local _, count = text:gsub('\n', '')
  return count
end

local function get_item_height(item)
	local h = item_height_result[item]
	if not h then
		h = {}
		local l = 1 + lines(item.text) + lines(item.info or '')
		h.normal = style.font:get_height() + style.padding.y
		h.expanded = l * style.font:get_height() + style.padding.y
		h.current = h.normal
		h.target = h.current
		item_height_result[item] = h
	end
	return h
end

local function draw_text_multiline(font, text, x, y, color)
	local th = font:get_height()
	local resx = x
	for line in text:gmatch('[^\n]+') do
		resx = renderer.draw_text(style.font, line, x, y, color)
		y = y + th
	end
	return resx, y
end

local function is_expanded(item)
  local item_height = get_item_height(item)
  return item_height.target == item_height.expanded
end

local function randomColor()
	return {common.color(string.format('rgb(%d, %d, %d)', math.random(1, 255), math.random(1, 255), math.random(1, 255)))}
end

local function handleColor(typ)
	if not typ then return nil end

	local typeName = typ:lower()
	if not itemTypes[typeName] then
		itemTypes[typeName] = randomColor()
	end

	return itemTypes[typeName]
end

local function extractPluginName(path)
	return path:match '.*/plugins/(.-)[\\/]'
end

local oldCoreLog = core.log
function core.log(...)
	if not conf.taggedOnly then
		local dbgInfo = debug.getinfo(2)
		if dbgInfo.short_src and dbgInfo.short_src:sub(0, USERDIR:len()) == USERDIR then
			handleColor(extractPluginName(dbgInfo.short_src))
		end
	end
	return oldCoreLog(...)
	--[[
	local vararg = ...
	local logOpt = vararg[#vararg]
	if type(logOpt) == 'table' and logOpt.log_color then
		
	end
	]]--
end

local oldCoreLogQuiet = core.log_quiet
function core.log_quiet(...)
	if not conf.taggedOnly then
		local dbgInfo = debug.getinfo(2)
		if dbgInfo.short_src and dbgInfo.short_src:sub(0, USERDIR:len()) == USERDIR then
			handleColor(extractPluginName(dbgInfo.short_src))
		end
	end
	return oldCoreLogQuiet(...)
end

local datestr = os.date()
function LogView:draw()
	self:draw_background(style.background)

	local th = style.font:get_height()
	local lh = th + style.padding.y -- for one line
	local iw = math.max(
		style.icon_font:get_width(style.log.ERROR.icon),
		style.icon_font:get_width(style.log.INFO.icon)
	)

	local tw = style.font:get_width(datestr)
	for _, item, x, y, w, h in self:each_item() do
		local color
		local itemTyp = item.text:match '^%[(.+)%]'
		if not conf.taggedOnly then
			local plug = extractPluginName(item.at)
			print(itemTyp, plug)
			color = handleColor(itemTyp or plug)
		else
			color = handleColor(itemTyp)
		end

		if color then renderer.draw_rect(x, y, w, h, color) end
		core.push_clip_rect(x, y, w, h)
		x = x + style.padding.x

		x = common.draw_text(
			style.icon_font,
			style.log[item.level].color,
			style.log[item.level].icon,
			'center',
			x, y, iw, lh
		)
		x = x + style.padding.x

		-- timestamps are always 15% of the width
		local time = os.date(nil, item.time)
		common.draw_text(style.font, style.dim, time, 'left', x, y, tw, lh)
		x = x + tw + style.padding.x

		w = w - (x - self:get_content_offset())

		if is_expanded(item) then
			y = y + common.round(style.padding.y / 2)
			_, y = draw_text_multiline(style.font, item.text, x, y, style.text)
			local at = 'at ' .. common.home_encode(item.at)
			_, y = common.draw_text(style.font, style.dim, at, 'left', x, y, w, lh)
			if item.info then
				_, y = draw_text_multiline(style.font, item.info, x, y, style.dim)
			end
		else
			local line, has_newline = string.match(item.text, '([^\n]+)(\n?)')
			if has_newline ~= '' then
				line = line .. ' ...'
			end
			_, y = common.draw_text(style.font, style.text, line, 'left', x, y, w, lh)
		end
		core.pop_clip_rect()
	end
end

core.log '[Loglighter] Loaded! If this log has color, everything is working.'
