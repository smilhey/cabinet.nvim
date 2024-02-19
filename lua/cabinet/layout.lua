local WinInfo = require("cabinet.wininfo")
local M = {}

---Generating a nested table containg some wininfo ala winalyout()
---@param tabnr number
---@param win_layout table
---@return table
function M.generate(tabnr, win_layout)
	if win_layout[1] == "leaf" then
		return { "leaf", WinInfo:get(tabnr, win_layout[2]) }
	else
		local subwin_layouts = {}
		for _, subwin_layout in ipairs(win_layout[2]) do
			table.insert(subwin_layouts, M.generate(tabnr, subwin_layout))
		end
		return { win_layout[1], subwin_layouts }
	end
end

---Restoring the layout from a nested table in the tab tabnr.
---@param tabnr number
---@param win_layout table
---@param layout table
function M.restore(tabnr, win_layout, layout)
	if layout[1] ~= win_layout[1] then
		error("Jump layout and window layout does not match")
		return
	end
	if layout[1] == "leaf" then
		---@type WinInfo
		local wininfo = layout[2]
		wininfo:restore(win_layout[2])
		return
	else
		local subwin_layout = win_layout[2]
		for i, sublayout in ipairs(layout[2]) do
			M.restore(tabnr, subwin_layout[i], sublayout)
		end
	end
end

return M
