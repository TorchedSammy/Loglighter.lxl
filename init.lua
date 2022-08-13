local core = require 'core'
local common = require 'core.common'
local style = require 'core.style'
local LogView = require 'core.logview'

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

--[[
local oldCoreLog = core.log
function core.log(...)
	local vararg = ...
	local logOpt = vararg[#vararg]
	if type(logOpt) == 'table' and logOpt.log_color then
		
	end
end
]]--

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
		local itemTyp = item.text:match '^%[(.+)%]'
		if itemTyp then
			local typeName = itemTyp:lower()
			if not itemTypes[typeName] then
				itemTypes[typeName] = {common.color(string.format('rgb(%d, %d, %d)', math.random(1, 255), math.random(1, 255), math.random(1, 255)))}
			end
			local color = itemTypes[typeName]
			renderer.draw_rect(x, y, w, h, color)
		end
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
