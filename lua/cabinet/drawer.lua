local jumplist = require("cabinet.jumplist")
local utils = require("cabinet.utils")
local cache = vim.fn.stdpath("cache")

---@class Drawer
---@field buffers table<number> @List of buffers managed by the drawer.
---@field handle number @Handle for the drawer.
---@field name string @Name of the drawer.
---@field session string @ID of the session : filename of the mksession file created for this drawer.
---@field jump_layout table Jumplist of all windows in the drawer laid in a similary way to winlayout().
local Drawer = {}

function Drawer:new(params)
	local drawer = {
		buffers = params.buffers or {},
		handle = params.handle or 0,
		name = params.name or ("drawer_" .. tostring(params.handle)),
		session = nil,
		jump_layout = nil,
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

---Unlist all buffers managed by the drawer then resets the window layout
function Drawer:close()
	self.buffers = vim.tbl_filter(function(buffer)
		return vim.api.nvim_buf_is_valid(buffer) and vim.api.nvim_buf_is_loaded(buffer)
	end, self.buffers)
	for _, buffer in ipairs(self.buffers) do
		vim.schedule(function()
			vim.bo[buffer].buflisted = false
		end)
	end
	vim.cmd("silent only")
	vim.cmd("cd")
end

---Save the jumplist for each window.
function Drawer:save_jump()
	self.jump_layout = jumplist.generate(vim.fn.winlayout(), self.buffers)
end

---Save the drawer session.
function Drawer:save_session()
	if not self.session then
		self.session = utils.uuid()
	end
	local ses_opt = "blank,buffers,curdir,folds,localoptions,help,tabpages,winsize,terminal"
	local user_ses_opt = vim.o.sessionoptions
	vim.o.sessionoptions = ses_opt
	vim.cmd("mksession! " .. cache .. "/cabinet/active/drawer." .. self.session)
	vim.o.sessionoptions = user_ses_opt
end

-- TODO : getting the cursor back at the right position at the end
-- as well as handling the case of multiple tabs do we want to restore
-- everything ?
---Restore the jumplist for each window.
function Drawer:restore_jump()
	if self.jump_layout then
		local win_layout = vim.fn.winlayout()
		jumplist.restore(win_layout, self.jump_layout)
	else
		return
	end
end

---Restore the session if it exists.
function Drawer:restore_session()
	if self.session then
		vim.cmd("silent source " .. cache .. "/cabinet/active/drawer." .. self.session)
	else
		return
	end
end

---Rename the drawer.
---@param name string @New name for the drawer.
function Drawer:rename(name)
	self.name = name
end

return Drawer
