local has_telescope, telescope = pcall(require, "telescope")

if not has_telescope then
	return
end

return telescope.register_extension({
	exports = {
		drawer = require("drawer.picker"),
	},
})
