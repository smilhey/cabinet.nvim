# Cabinet

cabinet.nvim is a plugin for Neovim that allows you to manage your 
buffers in an object called drawer, cabinet tries to be as unobtrusive as possible.

The goal is to add a level of grouping and organization to your buffers without 
change how you you navigate them.

### Features : 

- Organize your buffers into different drawers with separate quickfixlists, jumplists, directory. 
- Switch easily between drawers.
- Create, rename, delete drawers.
- Move buffers between drawers.
- A telescope picker
- Exposes an API for some customization

### Installation

You can install Cabinet using your preferred plugin manager. You need to at least call setup for the plugin to work.

With Lazy :

    return {
        "smilhey/cabinet", 
        config = function () 
            local cabinet = require("cabinet")
            cabinet:setup()
        end
    }

### Usage

#### Basic Commands

    :Drawer [name] - Switch to a specific drawer.
    :DrawerNew [name] - Create a new drawer with an optional name.
    :DrawerRename - Will prompt you for a new name for the current drawer.
    :DrawerDelete [name] - Delete a drawer.
    :DrawerList - List all drawers.
    :DrawerPrevious - Switch to the previous drawer.
    :DrawerNext - Switch to the next drawer.

#### Buffer Management

    :DrawerListBuffers - List all buffers in the current drawer even the unlisted ones. Otherwise ls is sufficent.
    :DrawerBufMove [drawer_name] - Move the current buffer to a different drawer.

#### Telescope Integration

Use Telescope to select drawers easily:

    :Telescope cabinet

### Exposed API

Cabinet exposes a simple API for interacting with its functionality programmatically. 

#### Functions

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

### User Events: 

The plugin emits the following user events that you can listen for and respond to in your Neovim configuration: 

#### "DrawLeave" 

Emitted when the user leaves a drawer, any buffer added at this point will belong to the next drawer. data = {previous_drawnm, next_drawnm}

#### "DrawAdd" 

Emitted when a new drawer is created. data = {new_drawnm}

#### "DrawNewEnter"  

Emitted when the user enters the name of a new drawer. data = {previous_drawnm, new_drawnm}

#### "DrawEnter" 

Emitted when the user enters an existing drawer after the layout and window information has been restored. data = {previous_drawnm, new_drawnm}

Here are some ways you could use those events  

#### Config example : 

    return {
        dir = "~/Misc/cabinet.nvim",
        config = function()
            local cabinet = require("cabinet")
            cabinet:setup({ initial_drawers = { "bar", "foo" }, usercmd = false })
            require("telescope").load_extension("cabinet")

            -- Switch to drawer on creation
            vim.api.nvim_create_autocmd("User", {
                nested = true,
                pattern = "DrawAdd",
                callback = function(event)
                    -- This is the name of the new drawer
                    local new_drawnm = event.data
                    cabinet.drawer_select(new_drawnm)
                end,
            })

            -- Open a terminal when entering a new drawer
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

