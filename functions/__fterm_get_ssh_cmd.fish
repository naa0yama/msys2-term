#!/usr/bin/env fish

function __fterm_get_ssh_cmd --description 'Get SSH command path'
	if builtin set --query __fssh_ssh_cmd
		builtin echo "$__fssh_ssh_cmd"
	else
		builtin echo ssh
	end
end
