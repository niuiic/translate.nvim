local M = {}

-- % get_selection %
function M._get_selection(cb)
	local input = vim.iter(require("omega").get_selection() or {}):join("\n")
	cb(input)
end

-- % input %
function M._input(cb)
	vim.ui.input({}, function(input)
		cb(input)
	end)
end

-- % get_clipboard %
function M._get_clipboard(cb)
	local input = vim.fn.getreg("+")
	cb(input)
end

-- % get_input_method %
function M.get_input_method(type)
	local input_methods = {
		selection = M._get_selection,
		clipboard = M._get_clipboard,
		input = M._input,
	}

	return input_methods[type] or M._input
end

return M
