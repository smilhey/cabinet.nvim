local utils = require("cabinet.utils")
local Drawer = require("cabinet.drawer")

---@class Manager
---@field drawers table<Drawer> @List of drawers managed by the manager.
---@field current_handle number @Handle of the current drawer.
---@field id string @ID of the manager for differentiating between nvim instances.
local Manager = {}

---@return Manager
function Manager:new()
	-- Initialize the drawers table with a default drawer
	local drawers = {}
	drawers = { Drawer:new({ handle = 1 }) }
	local manager = {
		drawers = drawers,
		current_handle = 1,
		id = utils.uuid(),
	}
	self.__index = self
	return setmetatable(manager, self)
end

---@param id number|string @ID of the drawer to retrieve.
---@return Drawer @The drawer with the specified ID, or nil if not found.
function Manager:get_drawer(id)
	if type(id) == "number" then
		return vim.tbl_filter(function(drawer)
			return drawer.handle == id
		end, self.drawers)[1]
	elseif type(id) == "string" then
		return vim.tbl_filter(function(drawer)
			return drawer.name == id
		end, self.drawers)[1]
	else
		error("Invalid type of drawer ID")
	end
end

---@return table<Drawer> @List of drawers managed by the manager.
function Manager:get_drawers()
	return self.drawers
end

---@return Drawer @The current drawer.
function Manager:get_current_drawer()
	return self:get_drawer(self.current_handle)
end

---@param handle number @Handle of the drawer to switch to.
function Manager:switch_drawer(handle)
	local next_drawer = self:get_drawer(handle)
	local previous_drawer = self:get_current_drawer()

	if next_drawer then
		vim.api.nvim_exec_autocmds("User", {
			pattern = "DrawLeave",
			data = { previous_drawer.name, next_drawer.name },
		})
		previous_drawer:save_session()
		previous_drawer:save_jump()
		previous_drawer:close()

		self.current_handle = handle
		if vim.tbl_isempty(next_drawer.buffers) then
			print("manager " .. utils.win_set_scratch(0))
			vim.cmd("clearjumps")
			vim.api.nvim_exec_autocmds("User", {
				pattern = "DrawNewEnter",
				data = { previous_drawer.name, next_drawer.name },
			})
		else
			next_drawer:restore_session()
			next_drawer:open()
			next_drawer:restore_jump()
			vim.api.nvim_exec_autocmds("User", {
				pattern = "DrawEnter",
				data = { previous_drawer.name, next_drawer.name },
			})
		end
	else
		error("Tried to switch with invalid handle " .. vim.inspect(handle))
	end
end

---@param name ?string @Name of the new drawer.
function Manager:create_drawer(name)
	local params = { name = name, handle = #self.drawers + 1 }
	local new_drawer = Drawer:new(params)
	table.insert(self.drawers, new_drawer)
	vim.api.nvim_exec_autocmds("User", {
		pattern = "DrawAdd",
		data = new_drawer.name,
	})
end

---@param handle number @Handle of the drawer to delete.
function Manager:delete_drawer(handle)
	local drawer = self:get_drawer(handle)
	if self.current_handle == handle then
		local previous_handle = self:previous_drawer()
		self:switch_drawer(previous_handle)
	else
		drawer:close()
	end
	if #self.drawers == 1 then
		vim.cmd("bd!")
	end
	for i, d in ipairs(self.drawers) do
		if d.handle == handle then
			table.remove(self.drawers, i)
		end
	end
end

---@param handle number @Handle of the drawer.
---@return number @Index of the drawer in the manager's drawers table.
function Manager:get_drawer_position(handle)
	for i, d in ipairs(self.drawers) do
		if d.handle == handle then
			return i
		end
	end
	return 0
end

---@return number @Handle of the previous drawer.
function Manager:previous_drawer()
	local current_index = self:get_drawer_position(self.current_handle)
	if current_index == 1 then
		return self.drawers[#self.drawers].handle
	else
		return self.drawers[current_index - 1].handle
	end
end

---@return number @Handle of the next drawer.
function Manager:next_drawer()
	local current_index = self:get_drawer_position(self.current_handle)
	if current_index == #self.drawers then
		return self.drawers[1].handle
	else
		return self.drawers[current_index + 1].handle
	end
end

---@param name string @A name.
---@return boolean @True if the name is available, false otherwise.
function Manager:is_name_available(name)
	for _, d in ipairs(self.drawers) do
		if d.name == name then
			return false
		end
	end
	return true
end

return Manager
