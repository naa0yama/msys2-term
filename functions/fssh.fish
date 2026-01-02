#!/usr/bin/env fish

function fssh --description 'Select SSH host from config with fzf'
	if not builtin test -d "$FSSH_SSH_CONF_DIR"
		set_color yellow
		builtin echo "Directory not found: $FSSH_SSH_CONF_DIR"
		set_color normal
		return 1
	end

	builtin set --local hostname_list (
		__fssh_get_hosts |
		fzf --height 60% \
			--prompt="SSH Host> " \
			--preview "rg -i -I -p -A 10 -e '^Host\s+.*\b{}\b' $FSSH_SSH_CONF_DIR"
	)

	if builtin test -n "$hostname_list"
		commandline "ssh $hostname_list"
	end
end
