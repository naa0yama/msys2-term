#!/usr/bin/env fish

function __fssh_get_scp_cmd --description 'Get SCP command path'
	if builtin set --query __fssh_scp_cmd
		builtin echo "$__fssh_scp_cmd"
	else
		builtin echo scp
	end
end
