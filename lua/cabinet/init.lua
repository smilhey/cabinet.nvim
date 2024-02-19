local Manager = require("cabinet.manager")

-- TODO : Add a way for users to be able to dispatch a buffer to group
-- on the fly automatically. Think about the use of events. What would you
-- want to do before entering a drawer : for example launch some linter and stuff ...
-- Important to precise at which point the drawer is stable so that the user
-- can safely do stuff at that time.
-- TODO : Add some customization for setup
-- Initial drawer name
-- Creating a drawer with a new buffer at the same time
-- Disabling user commands
-- order rule ?
-- Should be able to switch to drawers based on absolute value : meaning providing not moving list
-- TODO : Being able to create a set of drawers on start and eventually to restore state
-- of the drawers from previous session

local M = {}

function M:setup()
	M.drawer_manager = Manager:new()
	local cache = vim.fn.stdpath("cache")
	if vim.fn.isdirectory(cache .. "/cabinet/" .. M.drawer_manager.id) == 0 then
		vim.fn.mkdir(cache .. "/cabinet/" .. M.drawer_manager.id, "p")
	end

	require("cabinet.autocmd")
	require("cabinet.usercmd").setup(self)
end

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

function M.drawer_rename(old_name, new_name)
	assert(type(old_name) == "string" and type(new_name) == "string", "Drawer name must be a string")
	assert(old_name ~= "" and new_name ~= "", "Drawer name can't be empty string")
	if M.drawer_manager:is_name_available(new_name) then
		M.drawer_manager:get_drawer(old_name):rename(new_name)
		return true
	else
		print("Drawer name already exists")
		return false
	end
end

function M.drawer_previous()
	local previous_drawer = M.drawer_manager:previous_drawer()
	M.drawer_manager:switch_drawer(previous_drawer)
end

function M.drawer_next()
	local next_drawer = M.drawer_manager:next_drawer()
	M.drawer_manager:switch_drawer(next_drawer)
end

function M.drawer_list_buffers()
	local current_drawer = M.drawer_manager:get_current_drawer()
	local drawer_buffer_list = current_drawer:list_buffers()
	local complete_buffer_list = vim.api.nvim_list_bufs()
	return vim.tbl_filter(function(buffer)
		return vim.tbl_contains(drawer_buffer_list, buffer)
	end, complete_buffer_list)
end

function M.drawer_list()
	local drawers = M.drawer_manager:get_drawers()
	return vim.tbl_map(function(drawer)
		return drawer.name
	end, drawers)
end

function M.drawer_current()
	return M.drawer_manager:get_current_drawer().name
end

function M.buf_move(buffer, drawnm_from, drawnm_to)
	assert(
		vim.bo[buffer].bufhidden ~= "wipe" and vim.bo[buffer].bufhidden ~= "unload",
		"Buftype must be different from wipe and unload"
	)
	local drawer_from = M.drawer_manager:get_drawer(drawnm_from)
	local drawer_to = M.drawer_manager:get_drawer(drawnm_to)
	local current_drawnm = M.drawer_current()
	if not M.drawer_select(drawnm_from) then
		return
	end
	local windows = vim.fn.getbufinfo(buffer)[1].windows
	for _, win in ipairs(windows) do
		if #drawer_from:list_buffers() == 1 then
			print("Can't move the only buffer of the Drawer")
			return
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
end

return M
