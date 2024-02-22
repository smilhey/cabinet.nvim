
https://github.com/smilhey/cabinet.nvim/assets/128088782/61572d78-7d54-4827-a16a-affa54d5302d

# Cabinet

## This still a WIP all suggestions and PR are welcome !

cabinet.nvim is a plugin for Neovim that allows you to manage your 
partition your buffers in order to help nvim be a better multiplexing tool.

The goal is to add a level of grouping and organization to your buffers without 
changing how you you navigate them. 

Here is the workflow it enables : 

- You open nvim and start working on a project. At some point you open a file in another project ! You wander for 
a bit and then you want to go back to the previous project. You use telescope find files but you've changed directory ! You find your way baback but your jumplist is all over the place ... Trying telescope buffers is no better because at this point you've opened too many files.

- With cabinet you only need to switch to a different drawer at the beginning of you getting sidetracked. When you want to come back, you only need to go back to the previous drawer. All your tabs and windows with their jumplists, loclists, quickfix and current directory will have been preserved. 

- Inside a drawer you only interact with buffers that you have deliberatly opened in that drawer. (:bnext, :bprev, <C-O>, <C-I> ... )

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
        "smilhey/cabinet.nvim", 
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

| Function                           | Description                                                                                                 |
|------------------------------------|-------------------------------------------------------------------------------------------------------------|
| `M.setup(config)`                  | Set up the Cabinet plugin with the provided configuration options.                                          |
| `M.drawer_create(drawnm)`          | Create a new drawer with the specified name.                                                                |
| `M.drawer_select(drawnm)`          | Switch to the specified drawer.                                                                             |
| `M.drawer_delete(drawnm)`          | Delete the specified drawer.                                                                                |
| `M.drawer_rename(old_drawnm, new_drawnm)` | Rename a drawer.                                                                                           |
| `M.drawer_previous()`              | Switch to the previous drawer in the order of creation.                                                      |
| `M.drawer_next()`                  | Switch to the next drawer in the order of creation.                                                          |
| `M.drawer_list_buffers()`          | Get a list of buffers managed by the current drawer.                                                         |
| `M.drawer_list()`                  | Get a list of names of all drawers.                                                                         |
| `M.drawer_current()`               | Get the name of the current drawer.                                                                         |
| `M.buf_move(buffer, drawnm_from, drawnm_to)` | Move a buffer from one drawer to another.                                                               |

### User Events:

| Event Name      | Description                                                                                                       | Data                    |
|-----------------|-------------------------------------------------------------------------------------------------------------------|-------------------------|
| "DrawLeave"     | Emitted when the user leaves a drawer, any buffer added at this point will belong to the next drawer.             | `{previous_drawnm, next_drawnm}` |
| "DrawAdd"       | Emitted when a new drawer is created.                                                                             | `{new_drawnm}`         |
| "DrawNewEnter"  | Emitted when the user enters the name of a new drawer.                                                           | `{previous_drawnm, new_drawnm}` |
| "DrawEnter"     | Emitted when the user enters an existing drawer after the layout and window information has been restored.        | `{previous_drawnm, new_drawnm}` |
Here are some ways you could use those events  

#### Config example : 

    return {
        "smilhey/cabinet.nvim",
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

### Experimental Features

Cabinet should also allow to backup it's current state and reload it. To enable this use, add to the config function 

		local save = require("cabinet.save")
		save.save_cmd()
		save.load_cmd()

this will add the commands :CabinetSave and :CabinetLoad. 

- CabinetSave will save only the current drawers name with their buffers and the windows layout.  
- CabinetLoad will restore the state. This cmd will wipeout the currents buffers !
    :CabinetLoad [date] - Will restore the state at the given date. 

The date format is the one returned by os.date("%Y-%m-%d-%H-%M-%S") and is the name of the folder saved in the $HOME/.cache/nvim/cabinet/saved.
