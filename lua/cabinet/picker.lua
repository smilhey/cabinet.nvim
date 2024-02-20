local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local previewers = require("telescope.previewers")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

-- Return a picker for the available drawers
local function picker(opts)
	if #opts == 0 then
		opts = require("telescope.themes").get_dropdown({})
	end

	local available_drawers = require("cabinet").drawer_list()
	local function attach_mappings(prompt_bufnr, _)
		actions.select_default:replace(function()
			actions.close(prompt_bufnr)
			local selection = action_state.get_selected_entry()
			require("cabinet").drawer_select(selection.value)
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
					local buffers = require("cabinet").drawer_list_buffers(entry.value)
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
