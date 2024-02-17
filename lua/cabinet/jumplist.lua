local utils = require("cabinet.utils")
local M = {}

local restore_jumplist = function(window, jumplist, buffer)
	vim.api.nvim_set_current_win(window)
	vim.cmd("clearjumps")
	if vim.tbl_isempty(jumplist[1]) then
		return
	end
	local jumps, start = unpack(jumplist)
	for _, jump in ipairs(jumps) do
		if vim.api.nvim_buf_is_valid(jump.bufnr) then
			vim.api.nvim_win_set_buf(window, jump.bufnr)
			vim.api.nvim_win_set_cursor(window, { jump.lnum, jump.col })
		end
	end
	if start == #jumps then
		vim.api.nvim_win_set_buf(window, buffer)
	elseif #jumps - (start + 1) ~= 0 then
		local ctrl_o = vim.api.nvim_replace_termcodes((#jumps - (start + 1)) .. "<C-o>", true, true, true)
		vim.api.nvim_feedkeys(ctrl_o, "ntx", true)
	end
end

function M.generate(win_layout, buffers)
	if win_layout[1] == "leaf" then
		return { "leaf", vim.fn.getjumplist(win_layout[2]), vim.api.nvim_win_get_buf(win_layout[2]) }
	elseif win_layout[1] == "col" or win_layout[1] == "row" then
		local subwin_layouts = {}
		for _, subwin_layout in ipairs(win_layout[2]) do
			table.insert(subwin_layouts, M.generate(subwin_layout, buffers))
		end
		return { win_layout[1], subwin_layouts }
	end
end

function M.buf_to_filename(jumplist)
	local jumps, _ = unpack(jumplist)
	for _, j in ipairs(jumps) do
		j.bufnr = vim.api.nvim_buf_get_name(j.bufnr)
	end
end

function M.filename_to_buf(jumplist)
	local jumps, _ = unpack(jumplist)
	for _, j in ipairs(jumps) do
		j.bufnr = utils.find_buffer_by_name(j.bufnr)
	end
end

function M.filename_generate(jump_layout)
	if jump_layout[1] == "leaf" then
		return { "leaf", M.buf_to_filename(jump_layout[2]) }
	elseif jump_layout[1] == "col" or jump_layout[1] == "row" then
		local subjump_layouts = {}
		for _, subjump_layout in ipairs(jump_layout[2]) do
			table.insert(subjump_layouts, M.generate_save(subjump_layout))
		end
		return { jump_layout[1], subjump_layouts }
	end
end

function M.restore(win_layout, jump_layout)
	if jump_layout[1] ~= win_layout[1] then
		error("Jump layout and window layout does not match")
		return
	end
	local current_win = vim.api.nvim_get_current_win()
	if jump_layout[1] == "leaf" then
		restore_jumplist(win_layout[2], jump_layout[2], jump_layout[3])
		vim.api.nvim_set_current_win(current_win)
		return
	elseif jump_layout[1] == "col" then
		local subwin_layout = win_layout[2]
		for i, sublayout in ipairs(jump_layout[2]) do
			M.restore(subwin_layout[i], sublayout)
		end
	elseif jump_layout[1] == "row" then
		local subwin_layout = win_layout[2]
		for i, sublayout in ipairs(jump_layout[2]) do
			M.restore(subwin_layout[i], sublayout)
		end
	end
end

return M
