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
	local cache = vim.fn.stdpath("cache")
	if vim.fn.isdirectory(cache .. "/cabinet/active") == 0 then
		vim.fn.mkdir(cache .. "/cabinet/active", "p")
	end

	M.drawer_manager = Manager:new()
	require("cabinet.autocmd")
	require("cabinet.usercmd").setup(self)
end

function M.drawer_create(name)
	name = name or nil
	if type(name) ~= "string" and type(name) ~= "nil" then
		error("Drawer name must be a string or nil")
	end
	if M.drawer_manager:is_name_available(name) then
		M.drawer_manager:create_drawer(name)
	else
		print("Drawer " .. name .. " already exists")
	end
end

function M.drawer_select(name)
	if type(name) ~= "string" then
		error("Drawer name must be a string")
	end
	if name == "" then
		error("Drawer name can't be empty string")
	end

	if not M.drawer_manager:is_name_available(name) then
		local handle = M.drawer_manager:get_drawer(name).handle
		M.drawer_manager:switch_drawer(handle)
	else
		print("Drawer " .. name .. " does not exist")
	end
end

function M.drawer_delete(name)
	if type(name) ~= "string" then
		error("Drawer name must be a string")
	end
	if name == "" then
		error("Drawer name can't be empty string")
	end
	if not M.drawer_manager:is_name_available(name) then
		local handle = M.drawer_manager:get_drawer(name).handle
		M.drawer_manager:delete_drawer(handle)
	else
		print("Drawer " .. name .. " does not exist")
	end
end

function M.drawer_rename(old_name, new_name)
	if type(old_name) ~= "string" or type(new_name) ~= "string" then
		error("Drawer name must be a string")
	end
	if old_name == "" or new_name == "" then
		error("Drawer name can't be empty string")
	end
	if M.drawer_manager:is_name_available(new_name) then
		M.drawer_manager:get_drawer(old_name):rename(new_name)
	else
		print("Drawer name already exists")
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

-- TODO : how to handle buffer moves between drawers
-- User would want to move to the group with the buffer
-- this implies cleaning up the state of the drawer (jumplists and sessions)
function M.buf_move(buffer, name)
	local current_drawer = M.drawer_manager:get_current_drawer()
	local target_drawer = M.drawer_manager:get_drawer(name)
	M.drawer_manager:switch_drawer(target_drawer.handle)
	current_drawer:del_buffer(buffer)
	target_drawer:add_buffer(buffer)
end

return M
