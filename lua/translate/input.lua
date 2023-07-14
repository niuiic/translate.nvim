---@param cb fun(input :string)
local user_input = function(cb)
	vim.ui.input({}, function(input)
		if input == nil then
			return
		end
		cb(input)
	end)
end

local read_clipboard = function()
	return vim.fn.getreg("+")
end

return {
	user_input = user_input,
	read_clipboard = read_clipboard,
}
