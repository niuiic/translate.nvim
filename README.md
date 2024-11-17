# translate.nvim

Highly configurable translation plugin for neovim.

[More neovim plugins](https://github.com/niuiic/awesome-neovim-plugins)

## Feature

- multiple input methods
- multiple output methods
- invoke any translation engine via shell command
- async job: never block your work

<img src="https://github.com/niuiic/assets/blob/main/translate.nvim/usage.gif" />

## Dependencies

- [niuiic/omega.nvim](https://github.com/niuiic/omega.nvim)

## Usage

```lua
local function trans_to_zh()
	require("translate").translate({
		get_command = function(input)
			return {
				"trans",
				"-e",
				"bing",
				"-b",
				":zh",
				input,
			}
		end,
        -- input | clipboard | selection
		input = "selection",
        -- open_float | notify | copy | insert | replace
		output = { "open_float" },
		resolve_result = function(result)
			if result.code ~= 0 then
				return nil
			end

			return string.match(result.stdout, "(.*)\n")
		end,
	})
end

local function trans_to_en()
	require("translate").translate({
		get_command = function(input)
			return {
				"trans",
				"-e",
				"bing",
				"-b",
				":en",
				input,
			}
		end,
		input = "selection",
		output = { "replace" },
		resolve_result = function(result)
			if result.code ~= 0 then
				return nil
			end

			return string.match(result.stdout, "(.*)\n")
		end,
	})
end
```
