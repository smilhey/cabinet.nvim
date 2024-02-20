local WinInfo = require("cabinet.wininfo")
local layout = require("cabinet.layout")
local utils = require("cabinet.utils")
local cache = vim.fn.stdpath("cache")

---@class Drawer
---@field tabs table<number> @List of tabs managed by the drawer.
---@field buffers table<number> @List of buffers managed by the drawer.
---@field handle number @Handle for the drawer.
---@field name string @Name of the drawer.
---@field session string @ID of the session : filename of the mksession file created for this drawer.
---@field tabs_layout table @Windows specific info (loclist, jumplist ...) laid out the same as vim.fn.winlayout() for all tabs.
---@field qflist table @Quickflix list.
---@field current_wininfo WinInfo @Wininfo of the current window.
local Drawer = {}

function Drawer:new(params)
	local drawer = {
		buffers = params.buffers or {},
		handle = params.handle or 0,
		name = params.name or ("drawer_" .. tostring(params.handle)),
		session = nil,
		tabs_layout = {},
		qflist = nil,
		current_wininfo = nil,
	}
	self.__index = self
	return setmetatable(drawer, self)
end

---@param buffer ?number @Buffer to remove from the drawer.
---@return boolean @True if buffer is removed successfully, false otherwise.
function Drawer:del_buffer(buffer)
	for i, b in ipairs(self.buffers) do
		if b == buffer then
			table.remove(self.buffers, i)
			return true
		end
	end
	return false
end

---@param buffer ?number @Buffer to add to the drawer.
---@return boolean @True if buffer is added successfully, false otherwise.
function Drawer:add_buffer(buffer)
	if vim.bo[buffer].buflisted == false or vim.tbl_contains(self.buffers, buffer) then
		return false
	else
		table.insert(self.buffers, buffer)
		return true
	end
end

function Drawer:list_tabs()
	return self.tabs
end

---@return table<number> @List of buffers managed by the drawer.
function Drawer:list_buffers()
	return self.buffers
end

---Buflist all buffers managed by the drawer.
function Drawer:open()
	self.buffers = vim.tbl_filter(function(buffer)
		return vim.api.nvim_buf_is_valid(buffer) and vim.api.nvim_buf_is_loaded(buffer)
	end, self.buffers)
	for _, buffer in ipairs(self.buffers) do
		vim.schedule(function()
			vim.bo[buffer].buflisted = true
		end)
	end
end

---Unlist all buffers managed by the drawer and cleaning up the unloaded ones
---then resets the window and tab layout
function Drawer:close()
	self.buffers = vim.tbl_filter(function(buffer)
		return vim.api.nvim_buf_is_loaded(buffer)
	end, self.buffers)
	for _, buffer in ipairs(self.buffers) do
		vim.schedule(function()
			vim.bo[buffer].buflisted = false
		end)
	end
end

function Drawer:save_qflist()
	self.qflist = vim.fn.getqflist()
end

---Save the wininfo for each windwo in each tab
function Drawer:save_layout()
	self.current_wininfo = WinInfo:get(vim.fn.tabpagenr(), vim.api.nvim_get_current_win())
	self.tabs_layout = {}
	local tabs = vim.api.nvim_list_tabpages()
	for tabnr, _ in ipairs(tabs) do
		local win = vim.fn.winlayout(tabnr)
		local tab_layout = layout.generate(tabnr, win)
		table.insert(self.tabs_layout, tab_layout)
	end
end

---@param manager_id string
---Save the drawer session.
function Drawer:save_session(manager_id)
	if not self.session then
		self.session = utils.uuid()
	end
	local windows = vim.api.nvim_list_wins()
	--- This works for Telescope like window
	for _, win in ipairs(windows) do
		if vim.fn.win_gettype() == "popup" then
			vim.api.nvim_set_current_win(win)
			break
		end
		local buffer = vim.api.nvim_win_get_buf(win)
		local invalid_buftype = vim.bo[buffer].buftype == "quickfix" or vim.bo[buffer].buftype == "prompt"
		if vim.bo[buffer].bufhidden == "wipe" or invalid_buftype then
			local name = vim.api.nvim_buf_get_name(buffer)
			local ok, _ = pcall(vim.api.nvim_win_close, win, true)
			assert(ok, "Failed to hide window with following buffer " .. name)
		end
	end
	local ses_opt = "blank,buffers,curdir,folds,localoptions,help,tabpages,winsize,terminal"
	local user_ses_opt = vim.o.sessionoptions
	vim.o.sessionoptions = ses_opt
	vim.cmd("mksession! " .. cache .. "/cabinet/" .. manager_id .. "/drawer." .. self.session)
	vim.o.sessionoptions = user_ses_opt
end

---Restore the layout
function Drawer:restore_layout()
	if self.tabs_layout == {} then
		return
	end
	local tabs = vim.api.nvim_list_tabpages()
	for i, t in ipairs(tabs) do
		local win_layout = vim.fn.winlayout(i)
		layout.restore(t, win_layout, self.tabs_layout[i])
	end
	local tabpage = vim.api.nvim_list_tabpages()[self.current_wininfo.tabnr]
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
		if vim.api.nvim_win_get_buf(win) == self.current_wininfo.buffer then
			vim.api.nvim_set_current_win(win)
			vim.api.nvim_win_set_cursor(win, self.current_wininfo.curpos)
			return
		end
	end
end

---@param manager_id string
---Restore the session if it exists.
function Drawer:restore_session(manager_id)
	if self.session then
		vim.cmd("silent source " .. cache .. "/cabinet/" .. manager_id .. "/drawer." .. self.session)
		return
	end
end

function Drawer:restore_qflist()
	vim.fn.setqflist(self.qflist)
end

---Rename the drawer.
---@param name string @New name for the drawer.
function Drawer:rename(name)
	self.name = name
end

return Drawer
