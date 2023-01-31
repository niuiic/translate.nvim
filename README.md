# translate.nvim

Highly configurable translation plugin for neovim.

## Feature

- multiple output
  - float_win: output in float window
  - clipboard: copy to clipboard
  - insert: insert at current cursor position
  - notify: notify with vim.notify
- multiple translate engine: invoke any translation engine via shell command
- async job: never block your work

<img src="https://github.com/niuiic/assets/blob/main/translate.nvim/usage.gif" />

## Dependencies

- [niuiic/niuiic-core.nvim](https://github.com/niuiic/niuiic-core.nvim)

## Config

- default config

```lua
{
	output = {
		float = {
			max_width = 40,
			max_height = 5,
			close_on_cursor_move = true,
			enter_key = "T",
		},
	},
	translate = {},
}
```

- example

```lua
require("translate").setup({
	output = {
		float = {
			-- max_width of float window
			max_width = 40,
			-- max_height of float window
			max_height = 5,
			-- whether close float window on cursor move
			close_on_cursor_move = true,
			-- key to enter float window
			enter_key = "T",
		},
	},
	translate = {
		{
			-- use :TransToZH to start this job
			cmd = "TransToZH",
			-- shell command
			-- translate-shell is used here
			command = "trans",
			-- shell command args
			args = function(trans_source)
				-- trans_source is the text you want to translate
				return {
					"-b",
					"-e",
					"google",
					-- use proxy
					-- "-x",
					-- "http://127.0.0.1:10025",
					"-t",
					"zh-CN",
					-- you can filter translate source here
					trans_source,
				}
			end,
			-- how to get translate source
			-- selection | input | clipboard
			input = "selection",
			-- how to output translate result
			-- float_win | notify | clipboard | insert
			output = { "float_win" },
		},
		{
			cmd = "TransToEN",
			command = "trans",
			args = function(trans_source)
				return {
					"-b",
					"-e",
					"google",
					"-t",
					"en",
					trans_source,
				}
			end,
			input = "input",
			output = { "notify", "clipboard" },
		},
	},
})
```

- keymap

Notice: if input = "selection", `<c-u>` is required when set keymap.

```lua
vim.keymap.set("v", "<C-t>", ":<c-u>TransToZH<CR>", { silent = true })
vim.keymap.set("n", "<space>T", "<cmd>TransToEN<CR>")
```
