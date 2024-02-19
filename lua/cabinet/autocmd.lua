local cabinet_augroup = vim.api.nvim_create_augroup("cabinet", { clear = true })
local drawer_manager = require("cabinet").drawer_manager
local autocmd = vim.api.nvim_create_autocmd

autocmd("BufDelete", {
	group = cabinet_augroup,
	callback = function()
		local current_drawer = drawer_manager:get_current_drawer()
		current_drawer:del_buffer(tonumber(vim.fn.expand("<abuf>")))
	end,
})

autocmd("BufAdd", {
	group = cabinet_augroup,
	callback = function()
		local current_drawer = drawer_manager:get_current_drawer()
		current_drawer:add_buffer(tonumber(vim.fn.expand("<abuf>")))
	end,
})

autocmd("UIEnter", {
	group = cabinet_augroup,
	callback = function()
		vim.cmd("clearjumps")
		local current_drawer = drawer_manager:get_current_drawer()
		for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
			if vim.bo[buffer].buflisted then
				current_drawer:add_buffer(buffer)
			end
		end
	end,
})

autocmd("UILeave", {
	group = cabinet_augroup,
	callback = function()
		local instance = drawer_manager.id
		local cache = vim.fn.stdpath("cache")
		vim.cmd("!rm -rf" .. cache .. "/cabinet/" .. instance)
	end,
})
