local uv = vim.loop

---@param cmd string
---@param args Array<string>
---@param on_exit fun(err:string, data:string)
---@param on_err fun(err:string, data:string)
local spawn = function(cmd, args, on_exit, on_err)
	local stderr = uv.new_pipe()
	local stdout = uv.new_pipe()
	local job_running = true
	local handle
	handle = uv.spawn(cmd, {
		args = args,
		stdio = { nil, stdout, stderr },
	}, function()
		stdout:read_stop()
		stdout:close()
		stderr:read_stop()
		stderr:close()
		handle:close()
		job_running = false
	end)
	uv.read_start(
		stdout,
		vim.schedule_wrap(function(err, data)
			if job_running then
				on_exit(err, data)
			end
		end)
	)
	uv.read_start(
		stderr,
		vim.schedule_wrap(function(err, data)
			if job_running then
				on_err(err, data)
			end
		end)
	)
end

return {
	spawn = spawn,
}
