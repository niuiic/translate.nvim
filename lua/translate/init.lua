local M = {
	_input = require("translate.input"),
	_output = require("translate.output"),
}

---@class translate.Options
---@field input string
---@field output string[]
---@field get_command fun(input: string): string[]
---@field get_opts (fun(input:string): vim.SystemOpts) | nil
---@field resolve_result (fun(result: vim.SystemCompleted): string | nil) | nil

---@class translate.Context
---@field bufnr number
---@field winnr number
---@field cursor_pos {lnum: number, col: number}
---@field selected_area omega.Area

---@param options translate.Options
function M.translate(options)
	options.get_opts = options.get_opts or function() end
	options.resolve_result = options.resolve_result or function(result)
		return result.stdout
	end

	local context = {
		bufnr = vim.api.nvim_get_current_buf(),
		winnr = vim.api.nvim_get_current_win(),
		cursor_pos = { lnum = vim.api.nvim_win_get_cursor(0)[1], col = vim.api.nvim_win_get_cursor(0)[2] },
		selected_area = require("omega").get_selected_area(),
	}

	M._input.get_input_method(options.input)(function(input)
		if vim.fn.mode() ~= "n" then
			require("omega").to_normal_mode()
		end

		vim.system(
			options.get_command(input),
			options.get_opts(input),
			vim.schedule_wrap(function(result)
				local output = options.resolve_result(result)
				if not output then
					vim.notify("No output", vim.log.levels.WARN, { title = "Translate" })
					return
				end
				vim.iter(options.output)
					:map(function(type)
						return M._output.get_output_method(type)
					end)
					:each(function(output_method)
						output_method(output, context)
					end)
			end)
		)
	end)
end

return M
