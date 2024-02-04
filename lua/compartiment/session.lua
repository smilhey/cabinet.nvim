local Session = {}

--@class Session
--@field buffers table
--@field name string
--@method del_buffer function
--@method add_buffer function
--@method list_buffers function

function Session:new(buffers, name)
	local obj = {
		buffers = buffers or {},
		name = name or "session_test",
	}
	setmetatable(obj, self)
	self.__index = self
	return obj
end

function Session:del_buffer(buffer)
	for i, b in ipairs(self.buffers) do
		if b == buffer then
			table.remove(self.buffers, i)
			return true
		end
	end
	return false
end

function Session:add_buffer(buffer)
	table.insert(self.buffers, buffer)
end

function Session:list_buffers()
	print(vim.inspect(self.buffers))
end

return Session
