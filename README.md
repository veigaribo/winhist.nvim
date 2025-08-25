# winhist.nvim

Allows per-window buffer history tracking for backwards and forwards
navigation.

## Installation

### lazy.nvim

```lua
---@module 'lazy'
---@type LazyPluginSpec
return {
	'veigaribo/winhist.nvim',
	lazy = false, -- Start tracking histories as soon as possible.
	config = function()
		local winhist = require('winhist')
		winhist.setup()

		-- Load the previous buffer.
		vim.keymap.set('n', '<leader>b[', winhist.previous)
		-- Load the next buffer (in case you went to a previous one).
		vim.keymap.set('n', '<leader>b]', winhist.next)
		-- Print the histories, if you are curious.
		vim.keymap.set('n', '<leader>b?', winhist.dump)
	end,
}
```
