local Manager = require("cabinet.manager")

---Cabinet is a plugin that allows you to manage your buffers in drawers.
local M = {}

local default_config = {
	initial_drawers = {},
	usercmd = true,
}

---Setup user commands and autocmds, create the manager and the cache directory to store the mksession files for this nvim instance.
function M:setup(config)
	local config = config or {}
	config = {
		initial_drawers = config.initial_drawers or default_config.initial_drawers,
		usercmd = config.usercmd == nil and default_config.usercmd or config.usercmd,
	}
	M.drawer_manager = Manager:new(config.initial_drawers)
	local cache = vim.fn.stdpath("cache")
	if vim.fn.isdirectory(cache .. "/cabinet/saved") == 0 then
		vim.fn.mkdir(cache .. "/cabinet/saved", "p")
	end
	if vim.fn.isdirectory(cache .. "/cabinet/" .. M.drawer_manager.id) == 0 then
		vim.fn.mkdir(cache .. "/cabinet/" .. M.drawer_manager.id, "p")
	end

	require("cabinet.autocmd")
	if config.usercmd then
		require("cabinet.usercmd").setup(self)
	end
end

---@param drawnm string|nil @Name of the drawer to created : can be nil in which case the drawer will be created with a default name.
---@return boolean @True if the drawer is created successfully (if the name is available), false otherwise.
function M.drawer_create(drawnm)
	drawnm = drawnm or nil
	assert(type(drawnm) == "nil" or type(drawnm) == "string", "Drawer must be a string or nil")
	if M.drawer_manager:is_name_available(drawnm) then
		M.drawer_manager:create_drawer(drawnm)
		return true
	else
		print("Drawer " .. drawnm .. " already exists")
		return false
	end
end

---@param drawnm string @Name of the drawer you want to switch to.
---@return boolean @True if the switch is succesful (if the drawer exists), false otherwise.
function M.drawer_select(drawnm)
	assert(type(drawnm) == "string", "Drawer drawnm must be a string")
	assert(drawnm ~= "", "Drawer drawnm can't be empty string")

	if not M.drawer_manager:is_name_available(drawnm) then
		local handle = M.drawer_manager:get_drawer(drawnm).handle
		M.drawer_manager:switch_drawer(handle)
		return true
	else
		print("Drawer " .. drawnm .. " does not exist")
		return false
	end
end

---@param drawnm string @Name of the drawer to delete.
---@return boolean @True if the drawer is deleted successfully (if the drawer exists), false otherwise.
function M.drawer_delete(drawnm)
	assert(type(drawnm) == "string", "Drawer name must be a string")
	assert(drawnm ~= "", "Drawer name can't be empty string")
	if not M.drawer_manager:is_name_available(drawnm) then
		local handle = M.drawer_manager:get_drawer(drawnm).handle
		M.drawer_manager:delete_drawer(handle)
		return true
	else
		print("Drawer " .. drawnm .. " does not exist")
		return false
	end
end

---@param old_drawnm string @Name of the drawer to rename.
---@param new_drawnm string @New name of the drawer.
---@return boolean @True if the drawer is renamed successfully (if the new name is available), false otherwise.
function M.drawer_rename(old_drawnm, new_drawnm)
	assert(type(old_drawnm) == "string" and type(new_drawnm) == "string", "Drawer name must be a string")
	assert(old_drawnm ~= "" and new_drawnm ~= "", "Drawer name can't be empty string")
	if M.drawer_manager:is_name_available(new_drawnm) then
		M.drawer_manager:get_drawer(old_drawnm):rename(new_drawnm)
		return true
	else
		print("Drawer name already exists")
		return false
	end
end

---Switch to the previous drawer (order of creation).
function M.drawer_previous()
	local previous_drawer = M.drawer_manager:previous_drawer()
	M.drawer_manager:switch_drawer(previous_drawer)
end

---Switch to the next drawer (order of creation).
function M.drawer_next()
	local next_drawer = M.drawer_manager:next_drawer()
	M.drawer_manager:switch_drawer(next_drawer)
end

---@return table<number> @List of buffers managed by the current drawer including the ones that are not listed.
function M.drawer_list_buffers(drawnm)
	local drawer = M.drawer_manager:get_drawer(drawnm)
	local drawer_buffer_list = drawer:list_buffers()
	local complete_buffer_list = vim.api.nvim_list_bufs()
	return vim.tbl_filter(function(buffer)
		return vim.tbl_contains(drawer_buffer_list, buffer)
	end, complete_buffer_list)
end

---@return table<string> @List of all the drawers names.
function M.drawer_list()
	local drawers = M.drawer_manager:get_drawers()
	return vim.tbl_map(function(drawer)
		return drawer.name
	end, drawers)
end

---@return string @Name of the current drawer.
function M.drawer_current()
	return M.drawer_manager:get_current_drawer().name
end

---@param buffer number @Buffer handle.
---@param drawnm_from string @Name of the drawer to move the buffer from.
---@param drawnm_to string @Name of the drawer to move the buffer to.
---@return boolean @True if the buffer is moved successfully, false otherwise.
function M.buf_move(buffer, drawnm_from, drawnm_to)
	assert(
		vim.bo[buffer].bufhidden ~= "wipe" and vim.bo[buffer].bufhidden ~= "unload",
		"Buftype must be different from wipe and unload"
	)
	local drawer_from = M.drawer_manager:get_drawer(drawnm_from)
	local drawer_to = M.drawer_manager:get_drawer(drawnm_to)
	local current_drawnm = M.drawer_current()
	if not M.drawer_select(drawnm_from) then
		return false
	end
	local windows = vim.fn.getbufinfo(buffer)[1].windows
	for _, win in ipairs(windows) do
		if #drawer_from:list_buffers() == 1 then
			print("Can't move the only buffer of the Drawer")
			return false
		else
			vim.api.nvim_set_current_win(win)
			drawer_to:add_buffer(buffer)
			vim.schedule(function()
				vim.cmd("bp")
				vim.bo[buffer].buflisted = false
			end)
		end
	end
	drawer_from:del_buffer(buffer)
	M.drawer_select(current_drawnm)
	return true
end

return M
