local job = require("translate.job")
local input_mod = require("translate.input")
local config_mod = require("translate.config")
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

---@param cmd string
---@param args Array<string>
---@param output Array<"float_win" | "notify" | "clipboard" | "insert">
local trans = function(cmd, args, output)
	local cursor_pos = vim.api.nvim_win_get_cursor(0)

	local on_exit = function(err, data)
		if err ~= nil or data == "" then
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
				output_mod.output_in_float_win(data, pos)
			elseif value == "notify" then
				output_mod.output_notify(data)
			elseif value == "clipboard" then
				output_mod.output_to_clipboard(data)
			elseif value == "insert" then
				output_mod.output_insert(data, pos)
			end
		end
	end

	job.spawn(cmd, args, on_exit, on_err)
end

local create_user_command = function(config)
	for _, value in ipairs(config.translate) do
		if value.input == "selection" then
			vim.api.nvim_create_user_command(value.cmd, function()
				local text = input_mod.get_visual_selection()
				if value.filter then
					text = value.filter(text)
				end
				trans(value.command, value.args(text), value.output)
			end, {
				range = 0,
			})
		elseif value.input == "input" then
			vim.api.nvim_create_user_command(value.cmd, function()
				input_mod.user_input(function(text)
					if value.filter then
						text = value.filter(text)
					end
					trans(value.command, value.args(text), value.output)
				end)
			end, {})
		end
	end
end

local setup = function(new_config)
	config_mod = vim.tbl_deep_extend("force", config_mod, new_config or {})
	create_user_command(config_mod)
end

return {
	setup = setup,
}
