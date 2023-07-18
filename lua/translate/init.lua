local core = require("core")
local static = require("translate.static")
local input_mod = require("translate.input")
local output_mod = require("translate.output")

local win_handle
local running
local job_handle

local fail_notify = function()
	vim.notify("Translate failed", vim.log.levels.ERROR, {
		title = "Translate",
	})
end

local on_err = function()
	fail_notify()
	running = false
end

---@param cmd string
---@param args string[]
---@param output ("float_win" | "notify" | "clipboard" | "insert")[]
local trans = function(cmd, args, output)
	if running then
		job_handle.terminate()
	end

	running = true

	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local winnr = vim.api.nvim_get_current_win()

	local on_output = function(err, data)
		if err ~= nil or data == nil or data == "" then
			fail_notify()
			running = false
			return
		end
		local pos = {
			row = cursor_pos[1],
			col = cursor_pos[2],
		}
		data = string.gsub(data, "\n", "")
		for _, value in ipairs(output) do
			if value == "float_win" then
				win_handle = output_mod.output_in_float_win(data, winnr, pos)
			elseif value == "notify" then
				output_mod.output_notify(data)
			elseif value == "clipboard" then
				output_mod.output_to_clipboard(data)
			elseif value == "insert" then
				output_mod.output_insert(data, pos)
			end
		end
		running = false
	end

	job_handle = core.job.spawn(cmd, args, {}, nil, on_err, on_output)
end

vim.api.nvim_create_autocmd("CursorMoved", {
	pattern = "*",
	callback = function()
		if static.config.output.float.close_on_cursor_move and win_handle ~= nil and win_handle.win_opening() then
			local cur_win = vim.api.nvim_get_current_win()
			if cur_win ~= win_handle.winnr then
				win_handle.close_win()
			end
		end
	end,
})

local create_user_command = function(config)
	for _, value in ipairs(config.translate) do
		if value.input == "selection" then
			vim.api.nvim_create_user_command(value.cmd, function()
				local text = core.text.selection()
				core.text.cancel_selection()
				trans(value.command, value.args(text), value.output)
			end, {})
		elseif value.input == "input" then
			vim.api.nvim_create_user_command(value.cmd, function()
				input_mod.user_input(function(text)
					trans(value.command, value.args(text), value.output)
				end)
			end, {})
		elseif value.input == "clipboard" then
			vim.api.nvim_create_user_command(value.cmd, function()
				local text = input_mod.read_clipboard()
				if text == nil then
					vim.notify("no content in clipboard", vim.log.levels.ERROR, {
						title = "Translate",
					})
					return
				end
				trans(value.command, value.args(text), value.output)
			end, {})
		end
	end
end

local setup = function(new_config)
	static.config = vim.tbl_deep_extend("force", static.config, new_config or {})
	create_user_command(static.config)
	vim.keymap.set("n", static.config.output.float.enter_key, function()
		if win_handle ~= nil then
			vim.api.nvim_set_current_win(win_handle.winnr)
		end
	end, {})
end

return {
	setup = setup,
}
