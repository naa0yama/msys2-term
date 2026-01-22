#!/usr/bin/env fish

function fssh --description 'Select SSH host from config with fzf'
	# Compress uncompressed log files (rescue for kill-pane/Ctrl-x scenarios)
	if builtin set --query FTERM_LOG_DIR_PREFIX; and builtin test -d "$FTERM_LOG_DIR_PREFIX"
		builtin set --local uncompressed_logs (command find "$FTERM_LOG_DIR_PREFIX" -type f -name "*.log" 2>/dev/null)
		builtin set --local log_count (count $uncompressed_logs)

		if builtin test $log_count -gt 0
			set_color yellow
			builtin echo "[INFO ] Found $log_count uncompressed log file(s). Compressing..."
			set_color normal

			builtin set --local compressed 0
			for log_file in $uncompressed_logs
				builtin set compressed (math $compressed + 1)
				builtin printf "\r[%d/%d] Compressing: %s" $compressed $log_count (basename "$log_file")
				command gzip --force "$log_file" 2>/dev/null
			end
			builtin echo ""

			set_color green
			builtin echo "[INFO ] Compression complete: $log_count file(s)"
			set_color normal
		end
	end

	# Set only if FZF_DEFAULT_OPTS is undefined
	builtin set --local __fssh_fzf_opts_was_unset 0
	if not builtin set --query FZF_DEFAULT_OPTS
		builtin set __fssh_fzf_opts_was_unset 1
		builtin set --export FZF_DEFAULT_OPTS '--exact --height 90% --reverse --border'
	end

	if not builtin test -d "$FSSH_SSH_CONF_DIR"
		set_color yellow
		builtin echo "Directory not found: $FSSH_SSH_CONF_DIR"
		set_color normal
		if builtin test "$__fssh_fzf_opts_was_unset" -eq 1
			builtin set --erase FZF_DEFAULT_OPTS
		end
		return 1
	end

	builtin set --local hostname_list (
		__fssh_get_hosts |
		fzf --height 60% \
			--prompt="SSH Host> " \
			--preview "rg -i -I -p -A 10 -e '^Host\s+.*\b{}\b' $FSSH_SSH_CONF_DIR"
	)

	if builtin test "$__fssh_fzf_opts_was_unset" -eq 1
		builtin set --erase FZF_DEFAULT_OPTS
	end

	if builtin test -n "$hostname_list"
		commandline "ssh $hostname_list"
	end
end
