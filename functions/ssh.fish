#!/usr/bin/env fish

function ssh --description 'SSH with logging support'
	__fterm_debug "=== SSH function called ==="
	__fterm_debug "argv: $argv"
	__fterm_debug "__fssh_ssh_cmd: $__fssh_ssh_cmd"
	__fterm_debug "__fssh_ssh_config: $__fssh_ssh_config"
	__fterm_debug "__fssh_ssh_add_cmd: $__fssh_ssh_add_cmd"

	# Skip tmux check for dry-run options (they don't need logging)
	if not __fssh_ssh_is_dry_run $argv
		# Ensure running inside tmux for logging
		if not __fterm_ensure_tmux ssh $argv
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

	# Determine which ssh-add to use
	builtin set --local ssh_add_cmd "ssh-add"
	if builtin set --query __fssh_ssh_add_cmd
		builtin set ssh_add_cmd "$__fssh_ssh_add_cmd"
	end
	__fterm_debug "ssh-add command: $ssh_add_cmd"

	# Check SSH agent connection
	# timeout is required because gpg4win (gpg-agent) can freeze, which would freeze the terminal
	if not timeout --foreground --kill-after=5 3 "$ssh_add_cmd" -l >/dev/null 2>&1
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

	# Get target host (last argument)
	builtin set --local target_host "$argv[-1]"
	__fterm_debug "target_host: $target_host"

	# Get connection info: user, host, port
	builtin set --local conn_info (string split \t -- (__fssh_ssh_get_connection_info "$target_host"))
	builtin set --local ssh_user "$conn_info[1]"
	builtin set --local ssh_host "$conn_info[2]"
	builtin set --local ssh_port "$conn_info[3]"
	builtin set --local ssh_info "$ssh_user@$ssh_host:$ssh_port"

	__fterm_debug "Connection info - user: $ssh_user, host: $ssh_host, port: $ssh_port"

	# Generate log file path (only for actual connections, not dry-run)
	# Format: YYYYMMDDTHHMMSS_{session}-{window}{pane}_{user}@{host}-{port}.log
	builtin set --local log_file ""
	builtin set --local is_dry_run 0
	if __fssh_ssh_is_dry_run $argv
		builtin set is_dry_run 1
		__fterm_debug "Dry-run mode detected, logging disabled"
	else if type --query tmux; and builtin set --query TMUX
		builtin set --local date_path "$(date '+%Y/%m/%d')"
		builtin set --local timestamp_file "$(date '+%Y%m%dT%H%M%S')"
		builtin set --local pane_info "$(tmux display-message -p "#{session_name}-#{window_index}#{pane_index}")"
		builtin set log_file "$FTERM_LOG_DIR_PREFIX$date_path/"$timestamp_file"_"$pane_info"_$ssh_user@$ssh_host-$ssh_port.log"

		__fterm_debug "log_file: $log_file"

		# Start logging
		__fterm_start_logging "$log_file" "$target_host" "$ssh_info"
	else
		set_color yellow
		builtin echo "[WARN ] tmux not available or not in tmux session, logging disabled"
		set_color normal
		__fterm_debug "tmux not available or not in tmux session, logging disabled"
	end

	# Show splash
	__fssh_ssh_status_splash "$ssh_info" "$log_file" "$target_host" $argv

	# Execute SSH
	builtin set --local ssh_cmd "$(__fterm_get_ssh_cmd)"
	builtin set --local config_args (__fterm_get_ssh_config_args)

	# Set HOME for Windows OpenSSH to resolve Include paths correctly
	builtin set --local original_home "$HOME"
	if builtin set --query MSYSTEM; and builtin set --query USERPROFILE
		builtin set --export HOME "$(cygpath -m "$USERPROFILE")"
	end

	__fterm_debug "Executing: $ssh_cmd $config_args $argv"

	command "$ssh_cmd" $config_args $argv

	# Restore original HOME
	if builtin test -n "$original_home"
		builtin set --export HOME "$original_home"
	end

	# Output disconnection info
	set_color blue
	builtin echo ""
	builtin echo "#= >> Disconnected << =========================================================="
	builtin echo "#=    Timestamp     | $(date +%Y-%m-%dT%H:%M:%S%z)"
	builtin echo "#=    Logfile       | $log_file"
	builtin echo "#= ============================================================================="
	set_color normal

	# Stop logging and cleanup (only if not dry-run)
	if test "$is_dry_run" -eq 0; and type --query tmux; and builtin set --query TMUX
		command tmux select-pane -P 'default'
		__fterm_stop_logging "$log_file"
	end

	__fterm_debug "=== SSH function completed ==="
end
