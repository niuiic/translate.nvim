local core = require("niuiic-core")
local static = require("translate.static")
local input_mod = require("translate.input")
local output_mod = require("translate.output")

local fail_notify = function()
	vim.notify("Translate failed", vim.log.levels.ERROR, {
		title = "Translate",
	})
end

---@diagnostic disable-next-line:unused-local
local on_err = function(err, data)
	fail_notify()
end

local job_handle
local win_handle

---@param cmd string
---@param args Array<string>
---@param output Array<"float_win" | "notify" | "clipboard" | "insert">
local trans = function(cmd, args, output)
	if job_handle ~= nil and job_handle.running() == true then
		job_handle.terminate()
	end

	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local winnr = vim.api.nvim_get_current_win()

	local on_exit = function(err, data)
		if err ~= nil or data == nil or data == "" then
			fail_notify()
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
	end

	job_handle = core.job.spawn(cmd, args, {}, on_exit, on_err)
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
				local text = input_mod.get_visual_selection()
				trans(value.command, value.args(text), value.output)
			end, {
				range = 0,
			})
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
