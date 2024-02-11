local Drawer = {}

--@class Drawer
--@field buffers table: A table containing buffers associated with the drawer
--@field name string: The name of the drawer
--@field jumplist table: A table containing jump list entries associated with the drawer

function Drawer:new()
	local drawer = {
		buffers = {},
		current_buffer = nil,
		jumplist = {}, -- Initialize an empty table for the jumplist
	}
	self.__index = self
	return setmetatable(drawer, self)
end

--@param buffer number: The buffer to remove from the drawer's buffer list
--@return boolean: True if the buffer was removed, false otherwise
function Drawer:del_buffer(buffer)
	for i, b in ipairs(self.buffers) do
		if b == buffer then
			table.remove(self.buffers, i)
			return true
		end
	end
	return false
end

--@param buffer number: The buffer to add to the drawer's buffer list
--@return boolean: True if the buffer was added, false otherwise
function Drawer:add_buffer(buffer)
	if vim.api.nvim_get_option_value("buflisted", { buf = buffer }) == false then
		return false
	else
		table.insert(self.buffers, buffer)
		return true
	end
end

--@return table: A table containing the names of all buffers associated with the drawer
function Drawer:list_buffers()
	local buffer_list = {}
	for _, buffer in ipairs(self.buffers) do
		table.insert(buffer_list, vim.api.nvim_buf_get_name(buffer))
	end
	return self.buffers
end

function Drawer:open()
	for _, buffer in ipairs(self.buffers) do
		vim.schedule(function()
			vim.api.nvim_set_option_value("buflisted", true, { buf = buffer })
		end)
	end
end

function Drawer:close()
	for _, buffer in ipairs(self.buffers) do
		vim.schedule(function()
			vim.api.nvim_set_option_value("buflisted", false, { buf = buffer })
		end)
	end
end

-- Update the jumplist
function Drawer:save_jumplist()
	local jumplist, _ = unpack(vim.fn.getjumplist())
	local drawer_jumplist = vim.tbl_filter(function(jump)
		return vim.tbl_contains(self.buffers, jump.bufnr)
	end, jumplist)
	self.jumplist = drawer_jumplist
end

return Drawer
