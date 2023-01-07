local get_visual_selection = function()
	local s_start = vim.fn.getpos("'<")
	local s_end = vim.fn.getpos("'>")
	local n_lines = math.abs(s_end[2] - s_start[2]) + 1
	local lines = vim.api.nvim_buf_get_lines(0, s_start[2] - 1, s_end[2], false)
	lines[1] = string.sub(lines[1], s_start[3], -1)
	if n_lines == 1 then
		lines[n_lines] = string.sub(lines[n_lines], 1, s_end[3] - s_start[3] + 1)
	else
		lines[n_lines] = string.sub(lines[n_lines], 1, s_end[3])
	end
	return table.concat(lines, "\n")
end

---@param cb fun(input :string)
local user_input = function(cb)
	vim.ui.input({}, function(input)
		if input == nil then
			return
		end
		cb(input)
	end)
end

return {
	get_visual_selection = get_visual_selection,
	user_input = user_input,
}
