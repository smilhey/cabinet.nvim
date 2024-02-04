local Session = require("compartiment.session")
local Instance = {}

--@class Instance
--@field sessions table
--@method get_current_session function
--@method create_session function
--@method get_session function
--@method switch_session function

function Instance:new()
	local obj = {
		sessions = {},
	}
	setmetatable(obj, self)
	self.__index = self
	return obj
end

function Instance:get_session(name)
	return self.sessions[name]
end

function Instance:get_current_session()
	return next(self.sessions, 1) or nil
end

function Instance:switch_session(name)
	local target_session = self:get_session(name)
	if target_session then
		local target_bufnr = target_session.buffers[1]
		self.sessions[name] = nil
		self.sessions[name] = target_session
		vim.api.nvim_set_current_buf(target_bufnr)
	else
		print("Session not found: " .. name)
	end
end

function Instance:create_session(name)
	local new_session = Session:new({}, name)
	self.sessions[name] = new_session
	return new_session
end

return Instance
