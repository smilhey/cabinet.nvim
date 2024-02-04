local Instance = require("compartiment.instance")

vim.api.nvim_create_autocmd("BufDelete", {
	group = vim.api.nvim_create_augroup("BufDel", { clear = true }),
	callback = function()
		local current_session = Instance:get_current_session()
		current_session.del_buffer(vim.fn.expand("<abuf>"))
	end,
})

vim.api.nvim_create_autocmd("BufAdd", {
	group = vim.api.nvim_create_augroup("BufAdd", { clear = true }),
	callback = function()
		local current_session = Instance:get_current_session()
		current_session.add_buffer(vim.fn.expand("<afile>"))
	end,
})
