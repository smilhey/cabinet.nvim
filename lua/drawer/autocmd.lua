local compartiment_augroup = vim.api.nvim_create_augroup("drawer", { clear = true })
local drawer_manager = require("drawer").drawer_manager

vim.api.nvim_create_autocmd("BufDelete", {
	group = compartiment_augroup,
	callback = function()
		local current_drawer = drawer_manager:get_current_drawer()
		current_drawer:del_buffer(tonumber(vim.fn.expand("<abuf>")))
	end,
})

vim.api.nvim_create_autocmd("BufAdd", {
	group = compartiment_augroup,
	callback = function()
		local current_drawer = drawer_manager:get_current_drawer()
		current_drawer:add_buffer(tonumber(vim.fn.expand("<abuf>")))
	end,
})

vim.api.nvim_create_autocmd("BufEnter", {
	group = compartiment_augroup,
	callback = function()
		local current_drawer = drawer_manager:get_current_drawer()
		current_drawer.current_buffer = tonumber(vim.fn.expand("<abuf>"))
	end,
})

vim.api.nvim_create_autocmd("UIEnter", {
	group = compartiment_augroup,
	callback = function()
		local current_drawer = drawer_manager:get_current_drawer()
		for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
			if vim.api.nvim_get_option_value("buflisted", { buf = buffer }) then
				current_drawer:add_buffer(buffer)
			end
		end
	end,
})
