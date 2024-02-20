---@class WinInfo
---@field tabnr number @Tabpage number.
---@field winid number @winid
---@field buffer number @Buffer handle.
---@field jumplist table
---@field loclist table
---@field curpos tuple<number>
local WinInfo = {}

---Getting the information of a window in tab tabnr.
---@param tabnr number @Tabpage number.
---@param window number @Window winid.
---@return WinInfo
function WinInfo:get(tabnr, window)
	local wininfo = {
		tabnr = tabnr,
		winid = window,
		buffer = vim.api.nvim_win_get_buf(window),
		jumplist = vim.fn.getjumplist(window, tabnr),
		loclist = vim.fn.getloclist(window),
		curpos = vim.api.nvim_win_get_cursor(window),
		cwd = vim.fn.getcwd(window, tabnr),
	}
	self.__index = self
	return setmetatable(wininfo, self)
end

---@param window number @The window we're setting the jumplist for.
function WinInfo:restore_jumplist(window)
	vim.api.nvim_set_current_win(window)
	vim.cmd("clearjumps")
	if vim.tbl_isempty(self.jumplist[1]) then
		return
	end
	local jumps, start = unpack(self.jumplist)
	for _, jump in ipairs(jumps) do
		if vim.api.nvim_buf_is_valid(jump.bufnr) then
			vim.api.nvim_win_set_buf(window, jump.bufnr)
			vim.api.nvim_win_set_cursor(window, { jump.lnum, jump.col })
		end
	end
	if start == #jumps then
		vim.api.nvim_win_set_buf(window, self.buffer)
		vim.api.nvim_win_set_cursor(window, self.curpos)
	elseif #jumps - (start + 1) ~= 0 then
		local ctrl_o = vim.api.nvim_replace_termcodes((#jumps - (start + 1)) .. "<C-o>", true, true, true)
		vim.api.nvim_feedkeys(ctrl_o, "ntx", true)
	end
end

---@param window number @The window we're setting the loclist for.
function WinInfo:restore_loclist(window)
	if vim.tbl_isempty(self.loclist) then
		return
	end
	vim.fn.setloclist(window, self.loclist)
end

---@param window number @The window used for restoring.
function WinInfo:restore(window)
	self:restore_jumplist(window)
	self:restore_loclist(window)
end

return WinInfo
