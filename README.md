# winhist.nvim

Allows per-window buffer history tracking for backwards and forwards
navigation.

## Installation

Adjust to your liking.

### lazy.nvim

```lua
---@module 'lazy'
---@type LazyPluginSpec
return {
	'veigaribo/winhist.nvim',
	lazy = false, -- Start tracking histories as soon as possible.

	---@module 'winhist'
	---@type WinHistOptions
	opts = {
		-- Maximum history size *per window*, in number of buffers.
		-- Default is 100.
		max_history_height = 100,
	},

	config = function(_, opts)
		local winhist = require('winhist')
		winhist.setup(opts)

		-- Load the previous buffer.
		vim.keymap.set('n', '<leader>b[', winhist.previous)
		-- Load the next buffer (in case you went to a previous one).
		vim.keymap.set('n', '<leader>b]', winhist.next)
		-- Print the histories, if you are curious.
		vim.keymap.set('n', '<leader>b?', winhist.dump)
	end,
}
```

## Know issues

There seems to be some way to destroy windows that this plugin is not
detecting. So, over time, it may end up tracking more windows than there
actually are. If you notice that's happening to you, you can run the
`prune` function like so:

```vim
:lua require('winhist').prune()
```

This should remove tracking for every nonexistent window.
