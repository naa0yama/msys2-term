#!/usr/bin/env fish

function __fssh_get_ssh_home --description 'Get SSH home directory path'
	builtin set --local ssh_home
	# MSYS2: use Windows userprofile, otherwise use $HOME
	if builtin set --query MSYSTEM; and builtin set --query USERPROFILE
		builtin set ssh_home "$(cygpath -u "$USERPROFILE")/.ssh"
	else
		builtin set ssh_home "$HOME/.ssh"
	end
	__fterm_debug "__fssh_get_ssh_home: $ssh_home"
	builtin echo "$ssh_home"
end
