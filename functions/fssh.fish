#!/usr/bin/env fish

function fssh --description 'Select SSH host from config with fzf'
	# Set only if FZF_DEFAULT_OPTS is undefined
	set --local __fssh_fzf_opts_was_unset 0
	if not set --query FZF_DEFAULT_OPTS
		set __fssh_fzf_opts_was_unset 1
		set --export FZF_DEFAULT_OPTS '--exact --height 40% --reverse --border'
	end

	if not builtin test -d "$FSSH_SSH_CONF_DIR"
		set_color yellow
		builtin echo "Directory not found: $FSSH_SSH_CONF_DIR"
		set_color normal
		if test "$__fssh_fzf_opts_was_unset" -eq 1
			set --erase FZF_DEFAULT_OPTS
		end
		return 1
	end

	builtin set --local hostname_list (
		__fssh_get_hosts |
		fzf --height 60% \
			--prompt="SSH Host> " \
			--preview "rg -i -I -p -A 10 -e '^Host\s+.*\b{}\b' $FSSH_SSH_CONF_DIR"
	)

	if test "$__fssh_fzf_opts_was_unset" -eq 1
		set --erase FZF_DEFAULT_OPTS
	end

	if builtin test -n "$hostname_list"
		commandline "ssh $hostname_list"
	end
end
