#!/usr/bin/env fish

function scp --description 'SCP with logging support'
	__fterm_debug "=== SCP function called ==="
	__fterm_debug "argv: $argv"
	__fterm_debug "__fssh_scp_cmd: $__fssh_scp_cmd"
	__fterm_debug "__fssh_ssh_config: $__fssh_ssh_config"
	__fterm_debug "__fssh_ssh_add_cmd: $__fssh_ssh_add_cmd"

	# Skip tmux check for dry-run options (they don't need logging)
	if not __fssh_scp_is_dry_run $argv
		# Ensure running inside tmux for logging
		if not __fterm_ensure_tmux scp $argv
			return $status
		end
	end

	# Load SSH environment if exists
	if builtin set --query SSH_ENV; and builtin test -f "$SSH_ENV"
		set_color blue
		builtin echo "[INFO ] Loading ssh environment: $SSH_ENV ..."
		set_color normal
		builtin source "$SSH_ENV" >/dev/null
		__fterm_debug "Loaded SSH_ENV: $SSH_ENV"
	end

	# Check SSH agent connection
	# __fterm_run_ssh_cmd includes timeout (gpg-agent can freeze, which would freeze the terminal)
	if not __fterm_run_ssh_cmd ssh-add -l >/dev/null
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
	__fterm_debug "remote_hosts: $remote_hosts"

	# Build user@host format for each host (add user from config if not specified)
	builtin set --local hosts_with_user
	for host in $remote_hosts
		if string match -q '*@*' -- "$host"
			builtin set --append hosts_with_user "$host"
		else
			# Get user from ssh config
			builtin set --local conn_info (string split \t -- (__fssh_ssh_get_connection_info "$host"))
			builtin set --local ssh_user "$conn_info[1]"
			if builtin test -n "$ssh_user"
				builtin set --append hosts_with_user "$ssh_user@$host"
			else
				builtin set --append hosts_with_user "$host"
			end
		end
	end
	builtin set --local hosts_str (string join ' ' -- $hosts_with_user)
	__fterm_debug "hosts_with_user: $hosts_str"

	# Generate log file path (only for actual connections, not dry-run)
	# Format: YYYYMMDDTHHMMSS_{session}-{window}{pane}_scp_{user}@{hosts}.log
	builtin set --local log_file ""
	builtin set --local is_dry_run 0
	if __fssh_scp_is_dry_run $argv
		builtin set is_dry_run 1
		__fterm_debug "Dry-run mode detected, logging disabled"
	else if type --query tmux; and builtin set --query TMUX
		builtin set --local date_path "$(command date '+%Y/%m/%d')"
		builtin set --local timestamp_file "$(command date '+%Y%m%dT%H%M%S')"
		builtin set --local pane_info "$(command tmux display-message -p "#{session_name}-#{window_index}#{pane_index}")"
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
	builtin set --local config_args (__fterm_get_ssh_config_args)

	# Set HOME for Windows OpenSSH to resolve Include paths correctly
	builtin set --local original_home "$HOME"
	if builtin set --query MSYSTEM; and builtin set --query USERPROFILE
		builtin set --export HOME "$(command cygpath -m "$USERPROFILE")"
	end

	__fterm_debug "Executing: $scp_cmd $config_args $argv"

	# Set tmux pane title before transfer
	if type --query tmux; and builtin set --query TMUX
		command tmux set-window-option automatic-rename off
		command tmux select-pane -T "scp:$hosts_str"
	end

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
		builtin echo "#= >> Transfer Complete << ====================================================="
	else
		set_color red
		builtin echo ""
		builtin echo "#= >> Transfer Failed (exit: $scp_status) << ============================================="
	end
	builtin echo "#=    Timestamp     | $(command date +%Y-%m-%dT%H:%M:%S%z)"
	builtin echo "#=    Logfile       | $log_file"
	builtin echo "#= ============================================================================="
	set_color normal

	# Stop logging and cleanup (only if not dry-run)
	if test "$is_dry_run" -eq 0; and type --query tmux; and builtin set --query TMUX
		command tmux select-pane -P 'default'
		command tmux select-pane -T "fish"
		command tmux set-window-option automatic-rename on
		__fterm_stop_logging "$log_file"
	end

	__fterm_debug "=== SCP function completed ==="
	return $scp_status
end
