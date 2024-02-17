local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local drawer_manager = require("cabinet").drawer_manager

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
			drawer_manager:switch_drawer(selection.value)
		end)
		return true
	end
	pickers
		.new(opts, {
			prompt_title = "Drawers",
			finder = finders.new_table({
				results = available_drawers,
			}),
			sorter = conf.generic_sorter(opts),
			attach_mappings = attach_mappings,
		})
		:find()
end

return picker
