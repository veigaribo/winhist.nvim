---@class (exact) History
---@field buffers integer[]
---@field idx     integer

local M = {
	---Map between windows and buffer histories.
	---@type table<integer, History>
	histories = {},

	---True if this plugin is causing a buffer change. Used to prevent us
	---affecting the histories ourselves when navigating.
	is_self_moving = false,

	---@see WinHistOptions
	max_history_height = 100,
}

---@class WinHistOptions
---@field max_history_height integer Maximum amount of buffers to store per window.

---Registers present and future windows and tracks their buffer accesses.
---@param opts WinHistOptions
function M.setup(opts)
	if opts ~= nil then
		if opts.max_history_height then
			M.max_history_height = opts.max_history_height
		end
	end

	-- Register current windows
	local windows = vim.api.nvim_list_wins()

	for _, window in ipairs(windows) do
		M._add_window(window)
	end

	-- Register future windows
	vim.api.nvim_create_autocmd('WinNew', {
		callback = function()
			local window = vim.api.nvim_get_current_win()
			M._add_window(window)
		end,
	})

	vim.api.nvim_create_autocmd('WinClosed', {
		callback = function(args)
			local window = tonumber(args.match)
			if window == nil then
				return
			end

			M._remove_window(window)
		end,
	})

	-- Track buffer access
	vim.api.nvim_create_autocmd('BufWinEnter', {
		callback = function(args)
			local window = vim.api.nvim_get_current_win()
			local buffer = args.buf

			if not M.is_self_moving then
				M._hist_push(window, buffer)
			end

			M.is_self_moving = false
		end,
	})
end

---Navigates to the previous valid buffer in the current window, if there
---is one. This navigation will not affect the history.
function M.previous()
	local window = vim.api.nvim_get_current_win()
	local history = M.histories[window]

	while history.idx > 1 do
		history.idx = history.idx - 1
		local head_buf = M._hist_head(history)

		if vim.api.nvim_buf_is_valid(head_buf) then
			M.is_self_moving = true
			vim.api.nvim_win_set_buf(window, head_buf)
			break
		end
	end
end

---Navigates to the next valid buffer in the current window, if there is
---one. This navigation will not affect the history.
function M.next()
	local window = vim.api.nvim_get_current_win()
	local history = M.histories[window]

	while history.idx < #history.buffers do
		history.idx = history.idx + 1
		local head_buf = M._hist_head(history)

		if vim.api.nvim_buf_is_valid(head_buf) then
			M.is_self_moving = true
			vim.api.nvim_win_set_buf(window, head_buf)
			break
		end
	end
end

---Prints the histories, for troubleshooting.
function M.dump()
	vim.print(M.histories)
end

---@param history History
---@return integer buffer
function M._hist_head(history)
	return history.buffers[history.idx]
end

---@param window integer
---@param buffer integer
function M._hist_push(window, buffer)
	if M.histories[window] == nil then
		M._add_window(window)
	end

	-- If reloading the same buffer, don't do anything
	local history = M.histories[window]
	if M._hist_head(history) == buffer then
		return
	end

	-- Discard the future, if there is any
	for i = history.idx + 1, #history.buffers do
		history.buffers[i] = nil
	end

	-- Respect `max_history_height`
	while #history.buffers >= M.max_history_height do
		table.remove(history.buffers, 1)
	end

	history.buffers[#history.buffers + 1] = buffer
	history.idx = history.idx + 1
end

---@param window integer
function M._add_window(window)
	local buf = vim.api.nvim_win_get_buf(window)

	if M.histories[window] == nil then
		M.histories[window] = { buffers = { buf }, idx = 1 }
	end
end

---@param window integer
function M._remove_window(window)
	if M.histories[window] ~= nil then
		M.histories[window] = nil
	end
end

return M
