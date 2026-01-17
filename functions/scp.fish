#!/usr/bin/env fish

function __fssh_get_scp_cmd --description 'Get SCP command path'
	if builtin set --query __fssh_scp_cmd
		builtin echo "$__fssh_scp_cmd"
	else
		builtin echo scp
	end
end

function __fssh_scp_is_dry_run --description 'Check if SCP args contain non-connecting options'
	# SCP has no equivalent to ssh -G, but we check for help-like options
	for arg in $argv
		switch $arg
			case --help -h
				return 0
		end
	end
	return 1
end

function __fssh_scp_extract_hosts --description 'Extract remote hosts from SCP arguments'
	# SCP arguments can be: local_path, host:path, user@host:path
	# Returns unique list of hosts (config names)
	builtin set --local hosts

	for arg in $argv
		# Skip options and their arguments
		if string match -qr '^-' -- "$arg"
			continue
		end

		# Check if argument contains : (remote path indicator)
		if string match -qr ':' -- "$arg"
			# Extract host part (before :)
			builtin set --local host_part (string replace -r ':.*$' '' -- "$arg")
			# Remove user@ if present
			builtin set --local host (string replace -r '^.*@' '' -- "$host_part")
			if not contains "$host" $hosts
				builtin set --append hosts "$host"
			end
		end
	end

	builtin printf '%s\n' $hosts
end

function __fssh_scp_status_splash --description 'SCP status splash'
	builtin set --local timestamp "$(date +%Y-%m-%dT%H:%M:%S%z)"
	builtin set --local hosts "$argv[1]"
	builtin set --local log_file "$argv[2]"
	# argv[3..] are the original scp args

	builtin echo "#= ======================================================================"
	builtin echo "#=  ___  ___ _ __    | Remote Host(s)      $hosts"
	builtin echo "#= / __|/ __| '_ \\   | Timestamp           $timestamp"
	builtin echo "#= \\__ \\ (__| |_) |  | Command \$argv       $argv[3..-1]"
	builtin echo "#= |___/\\___|  __/   |"
	builtin echo "#=          |_|      |"
	builtin echo "#= $log_file"
	builtin echo "#= ----------------------------------------------------------------------"
	builtin echo "#="

	# Show SSH Config for each host
	for host in (string split ' ' -- "$hosts")
		if builtin test -n "$host"
			builtin set --local config_details (__fssh_get_ssh_config_details "$host")
			if builtin test -n "$config_details"
				builtin echo "#= --- SSH Config ($host) ---"
				for line in $config_details
					builtin echo "#=   $line"
				end
			end

			# Show Matched Agent Keys
			builtin set --local matched_keys (__fssh_get_matched_agent_keys "$host")
			if builtin test -n "$matched_keys"
				builtin echo "#= --- Matched Agent Keys ($host) ---"
				for key in $matched_keys
					builtin echo "#=   $key"
				end
			end
		end
	end

	builtin echo "#= ======================================================================"
	builtin echo ""
end

function scp --description 'SCP with logging support'
	__fterm_debug "=== SCP function called ==="
	__fterm_debug "argv: $argv"
	__fterm_debug "__fssh_scp_cmd: $__fssh_scp_cmd"
	__fterm_debug "__fssh_ssh_config: $__fssh_ssh_config"
	__fterm_debug "__fssh_ssh_add_cmd: $__fssh_ssh_add_cmd"

	# Load SSH environment if exists
	if builtin set --query SSH_ENV; and builtin test -f "$SSH_ENV"
		set_color blue
		builtin echo "[INFO ] Loading ssh environment: $SSH_ENV ..."
		set_color normal
		builtin source "$SSH_ENV" >/dev/null
		__fterm_debug "Loaded SSH_ENV: $SSH_ENV"
	end

	# Determine which ssh-add to use
	builtin set --local ssh_add_cmd "ssh-add"
	if builtin set --query __fssh_ssh_add_cmd
		builtin set ssh_add_cmd "$__fssh_ssh_add_cmd"
	end
	__fterm_debug "ssh-add command: $ssh_add_cmd"

	# Check SSH agent connection
	# timeout is required because gpg4win (gpg-agent) can freeze, which would freeze the terminal
	if not timeout --foreground --kill-after=5 3 "$ssh_add_cmd" --list >/dev/null 2>&1
		set_color red
		builtin echo "[ERROR] ssh-add connection failed."
		set_color normal
		__fterm_debug "ssh-add check failed"
		return 1
	else
		set_color blue
		builtin echo "[INFO ] ssh-add connection successful."
		set_color normal
		__fterm_debug "ssh-add check passed"
	end

	# Extract remote hosts from arguments
	builtin set --local remote_hosts (__fssh_scp_extract_hosts $argv)
	builtin set --local hosts_str (string join ' ' -- $remote_hosts)
	__fterm_debug "remote_hosts: $hosts_str"

	# Generate log file path (only for actual connections, not dry-run)
	# Format: YYYYMMDDTHHMMSS_{session}-{window}{pane}_scp_{hosts}.log
	builtin set --local log_file ""
	builtin set --local is_dry_run 0
	if __fssh_scp_is_dry_run $argv
		builtin set is_dry_run 1
		__fterm_debug "Dry-run mode detected, logging disabled"
	else if type --query tmux; and builtin set --query TMUX
		builtin set --local date_path "$(date '+%Y/%m/%d')"
		builtin set --local timestamp_file "$(date '+%Y%m%dT%H%M%S')"
		builtin set --local pane_info "$(tmux display-message -p "#{session_name}-#{window_index}#{pane_index}")"
		# Sanitize hosts for filename (replace spaces with _)
		builtin set --local hosts_filename (string replace --all ' ' '_' -- "$hosts_str")
		builtin set log_file "$FTERM_LOG_DIR_PREFIX$date_path/"$timestamp_file"_"$pane_info"_scp_$hosts_filename.log"

		__fterm_debug "log_file: $log_file"

		# Start logging
		__fterm_start_logging "$log_file" "$remote_hosts[1]" "scp"
	else
		set_color yellow
		builtin echo "[WARN ] tmux not available or not in tmux session, logging disabled"
		set_color normal
		__fterm_debug "tmux not available or not in tmux session, logging disabled"
	end

	# Show splash
	__fssh_scp_status_splash "$hosts_str" "$log_file" $argv

	# Execute SCP
	builtin set --local scp_cmd "$(__fssh_get_scp_cmd)"
	builtin set --local config_args (__fssh_get_ssh_config_args)

	# Set HOME for Windows OpenSSH to resolve Include paths correctly
	builtin set --local original_home "$HOME"
	if builtin set --query MSYSTEM; and builtin set --query USERPROFILE
		builtin set --export HOME "$(cygpath -m "$USERPROFILE")"
	end

	__fterm_debug "Executing: $scp_cmd $config_args $argv"

	command "$scp_cmd" $config_args $argv
	builtin set --local scp_status $status

	# Restore original HOME
	if builtin test -n "$original_home"
		builtin set --export HOME "$original_home"
	end

	# Output completion info
	if builtin test $scp_status -eq 0
		set_color green
		builtin echo ""
		builtin echo "#= >> Transfer Complete << ============================================="
	else
		set_color red
		builtin echo ""
		builtin echo "#= >> Transfer Failed (exit: $scp_status) << =========================="
	end
	builtin echo "#=    Timestamp     | $(date +%Y-%m-%dT%H:%M:%S%z)"
	builtin echo "#=    Logfile       | $log_file"
	builtin echo "#= ======================================================================"
	set_color normal

	# Stop logging and cleanup (only if not dry-run)
	if test "$is_dry_run" -eq 0; and type --query tmux; and builtin set --query TMUX
		command tmux select-pane -P 'default'
		__fterm_stop_logging "$log_file"
	end

	__fterm_debug "=== SCP function completed ==="
	return $scp_status
end
