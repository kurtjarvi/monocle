Debugger = Class("Debugger")

function Debugger:init(params)
	self.active = params.isActive or false
	self.names = {}
	self.listeners = {}
    self.results = {}
    self.panes = params.panes or {}

	self.x = params.x
	self.y = params.y
	self.r = params.r
	self.sx = params.sx
	self.sy = params.sy
	self.ox = params.ox
	self.oy = params.oy
	self.kx = params.kx
	self.ky = params.ky

	self.printqueue = {}

	self.commands = {}
	self.cmdresults = {}

	self.text = 'Debugger'
	self.textCursorPosition = 0

	self.printer = params.customPrinter or false
	self.printColor = params.customColor or {0.25, 0.25, 0.25, 0.5}
	self.printFont = params.customFont or love.graphics.getFont()

	self.debugToggle = params.debugToggle or '`'

	self.watchedFiles = params.filesToWatch or {}
	self.watchedFileTimes = {}
	for i, v in ipairs(self.watchedFiles) do
		assert(love.filesystem.getLastModified(v),v .. ' must not exist or is in the wrong directory.')
		self.watchedFileTimes[i] = love.filesystem.getLastModified(v)
	end
	self.print('Debugger Initialized.')
end

function Debugger:keypressed(key)
	if key == self.debugToggle then
		self:toggle()
	end
	if self.active then
		-- If entering a command:
		if key == "enter" then
            -- parses string
            self:watch(self.text, loadstring('return ' .. self.text))

			-- Clear self.text.
			self.text = ''
		elseif key == 'backspace' then
			self.text = string.sub(self.text,1,string.len(self.text)-1)
		end
	end
end

function Debugger:setFactors(x, y, r, sx, sy, ox, oy, kx, ky)
    self.x, self.y, self.r, self.sx,
    self.sy, self.ox, self.oy, self.kx,
    self.ky = x, y, r, sx, sy, ox, oy, kx, ky
end

function Debugger:enable()
	self.active = true
end

function Debugger:disable()
	self.active = false
end

function Debugger:toggle()
	self.active = not self.active
end

function Debugger:print(text,justtext)
	if self.printer and not justtext then
		print("[Debugger]: " .. text)
	elseif justtext then
		return "[Debugger]: " .. text
	end
end

function Debugger:update(dt)
	for key, object in ipairs(self.listeners) do
		if type(object) == 'function' then
			self.results[key] = object() or 'Error!'
		elseif type(object) == 'table' then
			self.results[key] = object
		end
	end

	for i, v in ipairs(self.watchedFiles) do
		if self.watchedFileTimes[i] ~= love.filesystem.getLastModified(v) then
			print('reloading...')
			self.watchedFileTimes[i] = love.filesystem.getLastModified(v)
			love.filesystem.load('main.lua')()
		end
	end
end

local function any(t, k)
    k = k or true
    for i, v in ipairs(t) do
        if v == k then
            return true, i
        end
    end
    return false
end

function Debugger:watch(name, object)
	if type(object) == 'string' then
		object = load(object)
	end
	if type(object) == 'function' then
        self:print('Watching ' .. name)
        local d, i = any(self.names, name)
        if d then
            self.listeners[i] = object
            self.names[i] = name
        else
            table.insert(self.listeners, object)
            table.insert(self.names, name)
        end
	else
		self:print('Object to watch is not a string')
		error('Object to watch is not a string')
	end
end

function Debugger:unwatch(name)
	for i, v in ipairs(self.names) do
		if v == name then
			self.names[i] = nil
			self.listeners[i] = nil
		end
	end
	self.listeners[name] = nil
	self.results = {}
end

function Debugger:render()
	if self.active then
		love.graphics.setColor(self.printColor)
		love.graphics.setFont(self.printFont)
		local draw_x, draw_y = self.x or 10, self.y or 0
		local title_text = self.text
		love.graphics.print(title_text, draw_x, draw_y)
		love.graphics.rectangle("line", draw_x, draw_y - 1,
			self.printFont:getWidth(title_text),
			self.printFont:getHeight() + 2
		)
		for name, result in pairs(self.results) do
			if type(result) == 'number' or type(result) == 'string' then
				if type(result) == 'string' and result == '' then
					result = 'nil'
				elseif type(result) == 'boolean' then
					result = tostring(result)
				elseif (type(result) == 'userdata') or (type(result) == 'function') then
					result = type(result)
				end
				love.graphics.print(self.names[name] .. " : " .. result, draw_x, (draw_y + 1) * self.printFont:getHeight(),
					self.r, self.sx, self.sy, self.ox, self.oy, self.kx, self.ky)
			elseif type(result) == 'table' then
				love.graphics.print(self.names[name] .. " : Table:", draw_x, (draw_y + 1) * self.printFont:getHeight(),
					self.r, self.sx, self.sy, self.ox, self.oy, self.kx, self.ky)
				draw_y = draw_y + 1
				for i, v in pairs(result) do
					if type(v) == 'table' then
						love.graphics.print("\t" .. i .. " : " .. "Table:", draw_x, (draw_y + 1) * self.printFont:getHeight(),
							self.r, self.sx, self.sy, self.ox, self.oy, self.kx, self.ky)
						for i, v in pairs(v) do
							if type(v) == "table" then
								v = "table"
							elseif type(v) == 'boolean' then
								v = tostring(v)
							elseif type(v) == 'string' and v == '' then
								v = 'nil'
							elseif (type(v) == 'userdata') or (type(v) == 'function') then
								v = type(v)
							end
							draw_y = draw_y + 1
							love.graphics.print("\t\t" .. i .. " : " .. v, draw_x, (draw_y + 1) * self.printFont:getHeight(),
								self.r, self.sx, self.sy, self.ox, self.oy, self.kx, self.ky)
						end
					else
						if type(v) == 'string' and v == '' then
							v = 'nil'
						elseif type(v) == 'boolean' then
							v = tostring(v)
						elseif (type(v) == 'userdata') or (type(v) == 'function') then
							v = type(v)
						end
						love.graphics.print("\t" .. i .. " : " .. v, draw_x, (draw_y + 1) * self.printFont:getHeight(),
							self.r, self.sx, self.sy, self.ox, self.oy, self.kx, self.ky)
					end
					draw_y = draw_y + 1
				end
			end
			draw_y = draw_y + 1
		end	-- For name,result
	end -- self.active
end

return Debugger