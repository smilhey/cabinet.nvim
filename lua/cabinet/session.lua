local jumplist = require("cabinet.jumplist")
local M = {}

function M.save_session(manager)
	local cache = vim.fn.stdpath("cache")
	local manager_copy = vim.deepcopy(manager)
	local drawers = manager_copy.drawers
	local drawer_sessions = vim.tbl_map(function(drawer)
		return drawer.session
	end, drawers)
	for d in drawers do
		d.buffers = vim.tbl_map(function(buffer)
			vim.api.nvim_buf_get_name(buffer)
		end, d.buffers)
	end
	for _, d in ipairs(drawers) do
		d.jump_layout = jumplist.filename_generate(d.jump_layout)
	end

	for session in drawer_sessions do
		vim.cmd("!cp " .. cache .. "/cabinet/drawer." .. session .. " " .. cache .. "/cabinet/saved/")
	end
	vim.fn.writefile(vim.json.encode(manager_copy), cache .. "/cabinet/saved", "p")
end

function M.restore_session() end

return M
