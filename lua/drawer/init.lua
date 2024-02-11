local Manager = require("drawer.manager")

local M = {}

M.setup = function()
	local complete_function = function(ArgLead, _, _)
		local completion_list = vim.tbl_filter(function(v)
			return string.find(v, "^" .. ArgLead) ~= nil
		end, M.drawer_manager.order)
		return completion_list
	end

	M.drawer_manager = Manager:new()

	require("drawer.autocmd")

	vim.api.nvim_create_user_command("Drawer", function(opts)
		if opts.args == nil or opts.args == "" then
			M.drawer_select()
		else
			M.drawer_select(opts.args)
		end
	end, {
		nargs = "?",
		complete = complete_function,
	})
	vim.api.nvim_create_user_command("DrawerNew", function(opts)
		if opts.args == nil or opts.args == "" then
			M.drawer_create()
		else
			M.drawer_create(opts.args)
		end
	end, { nargs = "?" })
	vim.api.nvim_create_user_command("DrawerDelete", function(opts)
		if opts.args == nil or opts.args == "" then
			M.drawer_delete()
		else
			M.drawer_delete(opts.args)
		end
	end, {
		nargs = "?",
		complete = complete_function,
	})
	vim.api.nvim_create_user_command("DrawerRename", function(opts)
		if opts.args == nil or opts.args == "" then
			M.drawer_rename()
		else
			M.drawer_delete(opts.args)
		end
	end, {
		nargs = "?",
	})
	vim.api.nvim_create_user_command("DrawerPrevious", M.drawer_previous, {})
	vim.api.nvim_create_user_command("DrawerNext", M.drawer_next, {})
	vim.api.nvim_create_user_command("DrawerListBuffers", M.drawer_list_buffers, {})
	vim.api.nvim_create_user_command("DrawerList", M.drawer_list, {})
end

M.drawer_create = function(handle)
	if handle == nil then
		vim.ui.input({ prompt = "New drawer : " }, function(input)
			if input == "" then
				return
			end
			M.drawer_manager:create_drawer(input)
		end)
	else
		M.drawer_manager:create_drawer(handle)
	end
end

M.drawer_select = function(handle)
	if handle == nil then
		-- Get the list of available drawers
		local handles = M.drawer_manager.order
		vim.ui.select(handles, {
			prompt = "Switch to drawer : ",
		}, function(choice)
			if choice == nil then
				return
			end
			M.drawer_manager:switch_drawer(choice)
		end)
	else
		M.drawer_manager:switch_drawer(handle)
	end
end

M.drawer_delete = function(handle)
	if handle == nil then
		local current_handle = M.drawer_manager.current_handle
		M.drawer_manager:delete_drawer(current_handle)
	else
		M.drawer_manager:delete_drawer(handle)
	end
end

M.drawer_rename = function(handle)
	local old_handle = M.drawer_manager.current_handle
	if handle == nil then
		vim.ui.input({ prompt = "Renaming drawer : " }, function(input)
			if input == "" then
				return
			end
			M.drawer_manager:rename_drawer(old_handle, input)
		end)
	else
		M.drawer_manager:rename_drawer(old_handle, handle)
	end
end

M.drawer_previous = function()
	local previous_drawer = M.drawer_manager:previous_drawer()
	M.drawer_manager:switch_drawer(previous_drawer)
end

M.drawer_next = function()
	local next_drawer = M.drawer_manager:next_drawer()
	M.drawer_manager:switch_drawer(next_drawer)
end

M.drawer_list_buffers = function()
	local current_drawer = M.drawer_manager:get_current_drawer()
	local buffer_list = current_drawer:list_buffers()
	print(vim.inspect(buffer_list))
end

M.drawer_list = function()
	local handles = M.drawer_manager.order
	for _, handle in ipairs(handles) do
		print(handle)
	end
end

return M
