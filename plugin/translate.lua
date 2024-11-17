vim.api.nvim_create_autocmd("CursorMoved", {
	callback = function()
		require("translate.output").close_float_wins()
	end,
})
