local U = {}
local user_command = vim.api.nvim_create_user_command
local utils = require("cabinet.utils")

---comment
---@param M table @The cabinet module
function U.setup(M)
	local complete_function = function(ArgLead, _, _)
		local completion_list = vim.tbl_filter(function(v)
			return string.find(v, "^" .. ArgLead) ~= nil
		end, M.drawer_list())
		return completion_list
	end

	user_command("Drawer", function(opts)
		if opts.args == nil or opts.args == "" then
			return
		else
			M.drawer_select(opts.args)
		end
	end, {
		nargs = "?",
		complete = complete_function,
	})

	user_command("DrawerDelete", function(opts)
		if opts.args == nil or opts.args == "" then
			M.drawer_delete(M.drawer_current())
		else
			M.drawer_delete(opts.args)
		end
	end, {
		nargs = "?",
		complete = complete_function,
	})

	user_command("DrawerNew", function(opts)
		if opts.args == nil or opts.args == "" then
			M.drawer_create()
		else
			M.drawer_create(opts.args)
		end
	end, { nargs = "?" })

	user_command("DrawerRename", function(opts)
		local old_name = M.drawer_current()
		if opts.args == nil or opts.args == "" then
			vim.ui.input({ prompt = "Renaming drawer : " }, function(input)
				if input == "" then
					return
				end
				M.drawer_rename(old_name, input)
			end)
		else
			M.drawer_rename(old_name, opts.args)
		end
	end, { nargs = "?" })

	user_command("DrawerPrevious", M.drawer_previous, {})

	user_command("DrawerNext", M.drawer_next, {})

	user_command("DrawerListBuffers", function()
		local current_drawnm = M.drawer_current()
        local list = {}
		for _, buffer in ipairs(M.drawer_list_buffers(current_drawnm)) do
			local bufname = vim.api.nvim_buf_get_name(buffer)
			local listed = " "
			if vim.bo[buffer].buflisted == false then
				listed = "u"
			end
            local str =  buffer .. " " .. listed .. " " .. bufname
			table.insert(list, str)
		end
        vim.notify(utils.table_to_string(list), vim.log.levels.INFO)
	end, {})

	user_command("DrawerList", function()
        local list = {}
		for _, drawer in ipairs(M.drawer_list()) do
			table.insert(list, drawer)
		end
        vim.notify(utils.table_to_string(list), vim.log.levels.INFO)
	end, {})
	user_command("DrawerBufMove", function(opts)
		local buffer = vim.api.nvim_get_current_buf()
		local drawnm_from = M.drawer_current()
		if opts.args == nil or opts.args == "" then
			return
		else
			M.buf_move(buffer, drawnm_from, opts.args)
		end
	end, { nargs = "?", complete = complete_function })
end

return U
