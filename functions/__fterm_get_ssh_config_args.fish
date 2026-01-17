#!/usr/bin/env fish

function __fterm_get_ssh_config_args --description 'Get SSH config args for Windows OpenSSH'
	# Returns list: -F and path as separate elements (each line becomes a list item)
	if builtin set --query __fssh_ssh_config
		builtin echo -- -F
		builtin echo -- "$__fssh_ssh_config"
	end
end
