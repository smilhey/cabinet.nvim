local Session = require("compartiment.session")
local Instance = require("compartiment.instance")

local M = {}

M.create_session = function()
	local session_name = vim.fn.input({ "Session name : " })
	Instance:create_session(session_name)
	Instance:switch_session(session_name)
	vim.fn.term()
end

M.delete_session = function()
	local session_name = vim.fn.input({ "Session name : " })
	Instance:previous_session()
	Instance.delete_session(session_name)
end
