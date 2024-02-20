local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local previewers = require("telescope.previewers")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local drawer_manager = require("cabinet").drawer_manager
local cabinet = require("cabinet")

-- Return a picker for the available drawers
local function picker(opts)
	if #opts == 0 then
		opts = require("telescope.themes").get_dropdown({})
	end

	local available_drawers = drawer_manager.drawers
	available_drawers = vim.tbl_map(function(drawer)
		if drawer.name == cabinet.drawer_current() then
			return (drawer.name .. " - " .. vim.fn.getcwd(0))
		elseif drawer.current_wininfo == nil then
			return (drawer.name .. " - " .. "cwd has not been set")
		end
		return drawer.name .. " - " .. drawer.current_wininfo.cwd
	end, available_drawers)

	local function attach_mappings(prompt_bufnr, _)
		actions.select_default:replace(function()
			actions.close(prompt_bufnr)
			local selection = action_state.get_selected_entry()
			local sep = string.find(selection.value, " - ")
			local drawnm = string.sub(selection.value, 1, sep - 1)
			cabinet.drawer_select(drawnm)
		end)
		return true
	end
	pickers
		.new(opts, {
			prompt_title = "Drawers",
			finder = finders.new_table({
				results = available_drawers,
			}),
			previewer = previewers.new_buffer_previewer({
				title = "Buffers",
				define_preview = function(self, entry, status)
					local sep = string.find(entry.value, " - ")
					local drawnm = string.sub(entry.value, 1, sep - 1)
					local buffers = cabinet.drawer_list_buffers(drawnm)
					vim.api.nvim_buf_set_lines(
						self.state.bufnr,
						0,
						-1,
						false,
						vim.tbl_map(function(bufnr)
							return vim.api.nvim_buf_get_name(bufnr)
						end, buffers)
					)
				end,
			}),
			sorter = conf.generic_sorter(opts),
			attach_mappings = attach_mappings,
		})
		:find()
end

return picker
