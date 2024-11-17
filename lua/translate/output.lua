local M = {}

M._float_wins = {}

function M._open_float(output, context)
	local bufnr = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(output, M._get_newline()))
	local winnr = vim.api.nvim_open_win(bufnr, false, M._get_win_options(output, context))
	M._float_wins[winnr] = bufnr
end

function M.close_float_wins()
	for winnr, bufnr in pairs(M._float_wins) do
		pcall(function()
			vim.api.nvim_win_close(winnr, true)
			vim.api.nvim_buf_delete(bufnr, { force = true })
		end)
		M._float_wins[winnr] = nil
	end
end

function M._get_newline()
	local fileformat = vim.o.fileformat

	local newline
	if fileformat == "unix" then
		newline = "\n"
	elseif fileformat == "dos" then
		newline = "\r\n"
	elseif fileformat == "mac" then
		newline = "\r"
	else
		newline = "\n"
	end

	return newline
end

function M._get_win_options(output, context)
	local nvim_height = vim.api.nvim_win_get_height(context.winnr)
	local nvim_width = vim.api.nvim_win_get_width(context.winnr)
	local offset_cols = 0
	local offset_lines = 0
	local win_width = 0
	local win_height = 0
	local anchor = ""
	local max_win_width = 0
	local max_win_height = 0

	if context.cursor_pos.col < nvim_width - context.cursor_pos.col then
		anchor = "W"
		offset_cols = 1
		max_win_width = nvim_width - context.cursor_pos.col - 1
	else
		anchor = "E"
		offset_cols = -1
		max_win_width = context.cursor_pos.col - 1
	end

	if context.cursor_pos.lnum < nvim_height - context.cursor_pos.lnum then
		anchor = "N" .. anchor
		offset_lines = 1
		max_win_height = nvim_height - context.cursor_pos.lnum - 1
	else
		anchor = "S" .. anchor
		offset_lines = -1
		max_win_height = context.cursor_pos.lnum - 1
	end

	local lines = vim.split(output, M._get_newline())
	local max_line_length = 0
	local overflow_line_count = 0
	vim.iter(lines):each(function(line)
		local line_length = vim.fn.strwidth(line)
		if line_length > max_line_length then
			max_line_length = line_length
		end
		if line_length > max_win_width then
			overflow_line_count = overflow_line_count + math.ceil(line_length / max_win_width) - 1
		end
	end)

	if max_line_length > max_win_width then
		win_width = max_win_width
		win_height = #lines + overflow_line_count
		win_height = win_height > max_win_height and max_win_height or win_height
	else
		win_width = max_line_length
		win_height = #lines
	end

	return {
		relative = "cursor",
		anchor = anchor,
		width = win_width,
		height = win_height,
		row = offset_lines,
		col = offset_cols,
		zindex = 50,
		style = "minimal",
		border = "rounded",
		noautocmd = true,
	}
end

function M._notify(output)
	vim.notify(output, vim.log.levels.INFO, { title = "Translate" })
end

function M._copy(output)
	vim.fn.setreg("+", output)
end

function M._insert(output, context)
	M._apply_text_edits({
		{
			range = {
				start = {
					line = context.cursor_pos.lnum - 1,
					character = context.cursor_pos.col,
				},
				["end"] = {
					line = context.cursor_pos.lnum - 1,
					character = context.cursor_pos.col,
				},
			},
			newText = output,
		},
	}, context.bufnr)
end

function M._replace(output, context)
	local text_edits = {
		{
			range = {
				start = {
					line = context.selected_area.start_lnum - 1,
					character = context.selected_area.start_col,
				},
				["end"] = {
					line = context.selected_area.end_lnum - 1,
					character = context.selected_area.end_col,
				},
			},
			newText = output,
		},
	}
	print(vim.inspect(text_edits))

	M._apply_text_edits(text_edits, context.bufnr)
end

function M._apply_text_edits(text_edits, bufnr)
	vim.lsp.util.apply_text_edits(text_edits, bufnr, M._get_offset_encoding())
end

function M._get_offset_encoding()
	return vim.iter(vim.lsp.get_clients())
		:map(function(client)
			return client.offset_encoding
		end)
		:find(function(offset_encoding)
			return offset_encoding
		end) or "utf-16"
end

function M.get_output_method(type)
	local output_methods = {
		open_float = M._open_float,
		notify = M._notify,
		copy = M._copy,
		insert = M._insert,
		replace = M._replace,
	}
	return output_methods[type]
end

return M
