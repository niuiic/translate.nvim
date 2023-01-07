local config = require("translate.config")

local winnr
local bufnr
local in_win = false
local close_win = function()
	-- if window is not closed by function close_win, winnr will still exist but vim.api.nvim_win_close will fail
	pcall(vim.api.nvim_win_close, winnr, true)
	bufnr = nil
	winnr = nil
	in_win = false
end
local is_win_open = function()
	return winnr ~= nil
end

---@param args {width: number, height: number, row: number, col: number}
local open_float_win = function(args)
	if is_win_open() then
		close_win()
	end
	bufnr = vim.api.nvim_create_buf(false, true)
	local win_id = vim.fn.win_getid()
	winnr = vim.api.nvim_open_win(bufnr, false, {
		relative = "win",
		win = win_id,
		width = args.width,
		height = args.height,
		bufpos = {
			args.row,
			args.col,
		},
		border = "single",
		zindex = 1,
		style = "minimal",
	})
end

local enter_float_win = function()
	in_win = true
	pcall(vim.api.nvim_set_current_win, winnr)
end

vim.api.nvim_create_autocmd("CursorMoved", {
	pattern = "*",
	callback = function()
		if config.output.float.close_on_cursor_move and is_win_open() then
			if in_win then
				local cur_win = vim.api.nvim_get_current_win()
				if cur_win ~= winnr then
					in_win = false
				end
			else
				close_win()
			end
		end
	end,
})

---@param content string
---@param cursor_pos {row: number, col: number})
local output_in_float_win = function(content, cursor_pos)
	if content == nil then
		return
	end
	content = string.gsub(content, "\n", "")
	local str_len = vim.fn.strdisplaywidth(content)
	if str_len == 0 then
		return
	end
	local height, width
	local max_width = config.output.float.max_width
	local max_height = config.output.float.max_height
	if str_len <= max_width then
		height = 1
		width = str_len
	else
		width = max_width
		height = math.ceil(str_len / max_width)
		if height > max_height then
			height = max_height
		end
	end
	open_float_win({
		height = height,
		width = width,
		col = cursor_pos.col,
		row = cursor_pos.row - 1,
	})
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { content })
end

local output_notify = function(content)
	vim.notify(content, vim.log.levels.INFO, {
		title = "Translate",
	})
end

local output_to_clipboard = function(content)
	vim.fn.setreg("+", content)
end

---@param content string
---@param cursor_pos {row: number, col: number})
local output_insert = function(content, cursor_pos)
	local line = vim.api.nvim_buf_get_lines(0, cursor_pos.row - 1, cursor_pos.row, false)[1]
	local new_line = line:sub(0, cursor_pos.col + 1) .. content .. line:sub(cursor_pos.col + 2)
	vim.api.nvim_buf_set_lines(0, cursor_pos.row - 1, cursor_pos.row, false, { new_line })
end

return {
	output_in_float_win = output_in_float_win,
	output_notify = output_notify,
	output_to_clipboard = output_to_clipboard,
	output_insert = output_insert,
	enter_float_win = enter_float_win,
}
