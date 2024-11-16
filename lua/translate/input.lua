local M = {}

function M._get_selection(cb)
	local input = vim.iter(require("omega").get_selection() or {}):join("\n")
	cb(input)
end

function M._input(cb)
	vim.ui.input({}, function(input)
		cb(input)
	end)
end

function M._get_clipboard(cb)
	local input = vim.fn.getreg("+")
	cb(input)
end

function M.get_input_method(type)
	local input_methods = {
		selection = M._get_selection,
		clipboard = M._get_clipboard,
		input = M._input,
	}

	return input_methods[type] or M._input
end

return M
