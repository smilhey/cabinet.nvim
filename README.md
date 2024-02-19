Cabinet

Cabinet is a plugin for Neovim that allows you to manage your buffers in drawers.
Features

    Organize your buffers into different drawers.
    Switch easily between drawers.
    Create, rename, delete drawers.
    Move buffers between drawers.
    Save and restore layouts for each drawer.
    Integrate with Telescope for easy drawer selection.
    Exposes an API for advanced customization.

Installation

You can install Cabinet using your preferred plugin manager. For example, using vim-plug:

vim

Plug 'username/cabinet'

Then, reload your Neovim configuration and run :PlugInstall to install the plugin.
Usage
Basic Commands

    :Drawer [name] - Switch to a specific drawer.
    :DrawerNew [name] - Create a new drawer with an optional name.
    :DrawerRename - Will promput for a new name for the current drawer.
    :DrawerDelete [name] - Delete a drawer.
    :DrawerList - List all drawers.
    :DrawerPrevious - Switch to the previous drawer.
    :DrawerNext - Switch to the next drawer.

Buffer Management

    :DrawerListBuffers - List all buffers in the current drawer.
    :DrawerBufMove [drawer_name] - Move the current buffer to a different drawer.

Telescope Integration

Use Telescope to select drawers easily:

    :Telescope cabinet

Configuration

You can customize Cabinet by setting up additional options in your Neovim configuration file. Two fields for now : 
    
    initial_drawers - A list of names for the drawers you want nvim to start with 
    usercmds - A boolean to enable or disable the user commands (default is true)


## Exposed API

Cabinet exposes a simple API for interacting with its functionality programmatically. 

### Functions

#### `M.setup(config)`

Set up the Cabinet plugin with the provided configuration options.

- `config`: (table) Optional. Configuration options for Cabinet.
  - `initial_drawers`: (table) Optional. List of initial drawer names. Defaults to an empty table.
  - `usercmd`: (boolean) Optional. Whether to set up user commands. Defaults to `true`.

#### `M.drawer_create(drawnm)`

Create a new drawer with the specified name.

- `drawnm`: (string|nil) Optional. Name of the drawer to create. If `nil`, a default name will be assigned.

Returns `true` if the drawer is created successfully; otherwise, `false`.

#### `M.drawer_select(drawnm)`

Switch to the specified drawer.

- `drawnm`: (string) Name of the drawer to switch to.

Returns `true` if the switch is successful; otherwise, `false`.

#### `M.drawer_delete(drawnm)`

Delete the specified drawer.

- `drawnm`: (string) Name of the drawer to delete.

Returns `true` if the drawer is deleted successfully; otherwise, `false`.

#### `M.drawer_rename(old_drawnm, new_drawnm)`

Rename a drawer.

- `old_drawnm`: (string) Name of the drawer to rename.
- `new_drawnm`: (string) New name for the drawer.

Returns `true` if the drawer is renamed successfully; otherwise, `false`.

#### `M.drawer_previous()`

Switch to the previous drawer in the order of creation.

#### `M.drawer_next()`

Switch to the next drawer in the order of creation.

#### `M.drawer_list_buffers()`

Get a list of buffers managed by the current drawer, excluding those that are not listed.

Returns a table containing the buffer numbers.

#### `M.drawer_list()`

Get a list of names of all drawers.

Returns a table containing the drawer names.

#### `M.drawer_current()`

Get the name of the current drawer.

Returns the name of the current drawer as a string.

#### `M.buf_move(buffer, drawnm_from, drawnm_to)`

Move a buffer from one drawer to another.

- `buffer`: (number) Buffer handle.
- `drawnm_from`: (string) Name of the drawer to move the buffer from.
- `drawnm_to`: (string) Name of the drawer to move the buffer to.

Returns `true` if the buffer is moved successfully; otherwise, `false`.

#### `M.get_drawer_manager()`

Get the current drawer manager instance.

Returns the current drawer manager instance, allowing external modules or scripts to access and interact with the Cabinet drawer manager directly.


Config example : 


return {
	dir = "~/Misc/cabinet.nvim",
	config = function()
		local cabinet = require("cabinet")
		cabinet:setup({ initial_drawers = { "bar", "foo" }, usercmd = false })
		require("telescope").load_extension("cabinet")

		vim.api.nvim_create_autocmd("User", {
			nested = true,
			pattern = "DrawAdd",
			callback = function(event)
				-- This is the name of the new drawer
				local new_drawnm = event.data
				cabinet.drawer_select(new_drawnm)
			end,
		})

		-- vim.api.nvim_create_autocmd("User", {
		-- 	nested = true,
		-- 	pattern = "DrawNewEnter",
		-- 	callback = function(event)
		-- 		vim.cmd("term")
		-- 	end,
		-- })

		vim.keymap.set("n", "<leader>dp", function()
			vim.cmd("DrawerPrevious")
		end)
		vim.keymap.set("n", "<leader>dn", function()
			vim.cmd("DrawerNext")
		end)
		vim.keymap.set("n", "<leader>dc", function()
			vim.cmd("DrawerNew")
		end)
		vim.keymap.set("n", "<leader>dr", function()
			vim.cmd("DrawerRename")
		end)
		vim.keymap.set("n", "<leader>dt", function()
			vim.cmd("Telescope cabinet")
		end)
	end,
}
