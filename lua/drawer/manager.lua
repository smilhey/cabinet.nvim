local Drawer = require("drawer.drawer")

-- Define the Manager class
local Manager = {}

--@class Manager
--@field drawers table: A table containing all drawers, indexed by their handles
--@field order table: An array containing the drawer handles sorted by their last access time
--@field current_handle string: The handle of the currently active drawer

-- Define the constructor for the Manager class
function Manager:new()
	-- Initialize the drawers table with a default drawer
	local drawers = {}
	drawers["default"] = Drawer:new()
	local manager = {
		drawers = drawers,
		order = { "default" },
		current_handle = "default",
	}
	self.__index = self
	return setmetatable(manager, self)
end

--@param handle string: The handle of the drawer to retrieve
--@return Drawer: The drawer object corresponding to the provided handle
function Manager:get_drawer(handle)
	return self.drawers[handle]
end

--@return table: A table containing all drawers
function Manager:get_drawers()
	return self.drawers
end

--@return Drawer: The currently active drawer object
function Manager:get_current_drawer()
	return self.drawers[self.current_handle]
end

-- Populate the jump list for the given drawer handle
--@param handle string: The handle of the drawer for which to populate the jump list
function Manager:populate_jumplist(handle)
	vim.cmd("clearjumps")
	local drawer_jumplist = self.drawers[handle].jumplist
	if drawer_jumplist == nil then
		return
	end
	for _, jump in ipairs(drawer_jumplist) do
		-- vim.api.nvim_buf_set_mark(jump.bufnr, "'", jump.lnum, jump.col, {})
		-- does not work as expected for ' marks upstream bug
		vim.api.nvim_set_current_buf(jump.bufnr)
		vim.api.nvim_win_set_cursor(0, { jump.lnum, jump.col })
		vim.cmd("normal! m'")
	end
end

--@param handle string: The handle of the drawer to switch to
function Manager:switch_drawer(handle)
	vim.api.nvim_exec_autocmds("User", { pattern = "DrawerLeaving " .. handle })
	local target_drawer = self:get_drawer(handle)
	local current_drawer = self:get_current_drawer()
	current_drawer:save_jumplist()

	if target_drawer then
		current_drawer:close()
		self.current_handle = handle
		if target_drawer.buffers[1] == nil then
			print("Welcome to drawer : " .. handle)
			vim.api.nvim_command("term")
		else
			local target_buffer = target_drawer.current_buffer
			vim.api.nvim_set_current_buf(target_buffer)
			target_drawer:open()
		end
		for i, h in ipairs(self.order) do
			if h == handle then
				table.remove(self.order, i)
			end
		end
		table.insert(self.order, 1, handle)
		self:populate_jumplist(handle)
	else
		print("Drawer " .. handle .. " not found")
	end
	vim.api.nvim_exec_autocmds("User", { pattern = "DrawerSwitched " .. handle })
end

--@param old_handle string: The current handle of the drawer to be renamed
--@param new_handle string: The new handle to assign to the drawer
function Manager:rename_drawer(old_handle, new_handle)
	if self.current_handle == old_handle then
		self.current_handle = new_handle
	end
	self.drawers[new_handle] = self.drawers[old_handle]
	self.drawers[old_handle] = nil
	for i, h in ipairs(self.order) do
		if h == old_handle then
			self.order[i] = new_handle
		end
	end
end

--@param handle string: The handle of the new drawer to create
function Manager:create_drawer(handle)
	self.drawers[handle] = Drawer:new()
	self.order[#self.order + 1] = handle
	vim.api.nvim_exec_autocmds("User", { pattern = "DrawerCreated " .. handle })
end

--@param handle string: The handle of the drawer to delete
function Manager:delete_drawer(handle)
	if #self.order == 1 then
		print("Can't delete the last drawer")
		return
	end
	if self.current_handle == handle then
		local current_drawer_order = self:get_drawer_order(handle)
		local previous_handle = "default"
		if current_drawer_order == 1 then
			previous_handle = self.order[#self.order]
		else
			previous_handle = self.order[current_drawer_order - 1]
		end
		table.remove(self.order, current_drawer_order)
		self:switch_drawer(previous_handle)
	end
	self.drawers[handle] = nil
end

--@param handle string: The handle of the drawer to get the order of
--@return number: The position of the drawer in the order array
function Manager:get_drawer_order(handle)
	local drawer_order = 0
	for i, h in ipairs(self.order) do
		if h == handle then
			drawer_order = i
		end
	end
	return drawer_order
end

--@return string: The handle of the previous drawer
function Manager:previous_drawer()
	local current_drawer_order = self:get_drawer_order(self.current_handle)
	if current_drawer_order == 1 then
		return self.order[#self.order]
	else
		return self.order[current_drawer_order - 1]
	end
end

--@return string: The handle of the next drawer
function Manager:next_drawer()
	local current_drawer_order = self:get_drawer_order(self.current_handle)
	if current_drawer_order == #self.order then
		return self.order[1]
	else
		return self.order[current_drawer_order + 1]
	end
end

-- Return the Manager class
return Manager
