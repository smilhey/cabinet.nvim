local cabinet = require("cabinet")
local utils = require("cabinet.utils")
local M = {}
local cache = vim.fn.stdpath("cache") .. "/cabinet/"

---@param manager Manager
function M.save_cabinet(manager)
	manager:get_current_drawer():save_session(manager.id)
	local manager_copy = vim.deepcopy(manager)
	local drawers = manager_copy.drawers
	for _, d in ipairs(drawers) do
		d.buffers = {}
		d.tabs_layout = {}
		d.qflist = nil
		d.current_wininfo = nil
	end
	vim.cmd("!mkdir " .. cache .. "saved/" .. manager_copy.id)
	vim.cmd("!cp -r " .. cache .. manager_copy.id .. " " .. cache .. "saved/")
	local json = { vim.json.encode(manager_copy) }
	vim.fn.writefile(json, cache .. "saved/" .. manager_copy.id .. "/manager")
end

function M.restore_cabinet(saved_manager)
	local manager = cabinet.drawer_manager
	for _, d in ipairs(manager.drawers) do
		d.handle = -d.handle
		d:rename("~" .. d.name)
	end
	manager.current_handle = -manager.current_handle
	vim.cmd("silent tabonly")
	vim.cmd("silent only")
	utils.win_set_scratch(0)

	for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
		vim.api.nvim_buf_delete(buffer, { force = true })
	end

	for _, d in ipairs(saved_manager.drawers) do
		local handle = manager:create_drawer(d.name)
		manager:switch_drawer(handle)
		vim.cmd("silent source " .. cache .. "saved/" .. saved_manager.id .. "/drawer." .. d.session)
	end

	for _, d in ipairs(manager.drawers) do
		if d.handle < 0 then
			vim.schedule(function()
				manager:delete_drawer(d.handle)
			end)
		end
	end
end

function M.save_cmd()
	vim.api.nvim_create_user_command("CabinetSave", function()
		M.save_cabinet(cabinet.drawer_manager)
	end, {})
end

function M.load_cmd()
	local backups = {}
	for n, _ in vim.fs.dir(cache .. "saved") do
		table.insert(backups, n)
	end
	local complete_function = function(ArgLead, _, _)
		local completion_list = vim.tbl_filter(function(v)
			return string.find(v, "^" .. ArgLead) ~= nil
		end, backups)
		return completion_list
	end
	vim.api.nvim_create_user_command("CabinetLoad", function(opts)
		if opts.args == nil or opts.args == "" then
			vim.log.levels("No backup specified", vim.log.levels.ERROR)
			return
		end
		local manager_file = vim.fn.readfile(cache .. "saved/" .. opts.args .. "/manager")
		local manager = vim.json.decode(manager_file[1])
		M.restore_cabinet(manager)
	end, { nargs = "?", complete = complete_function })
end

return M
