local M = {}

function M.date()
	return os.date("%Y-%m-%d_%H:%M:%S")
end

function M.uuid()
	math.randomseed(os.clock())
	local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
	local id = string.gsub(template, "[xy]", function(c)
		local v = (c == "x") and math.random(0, 0xf) or math.random(8, 0xb)
		return string.format("%x", v)
	end)
	return id
end

function M.find_buffer_by_name(name)
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		local buf_name = vim.api.nvim_buf_get_name(buf)
		if buf_name == name then
			return buf
		end
	end
end

function M.win_set_scratch(window)
	local temp = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_win_set_buf(window, temp)
	return temp
end

return M
