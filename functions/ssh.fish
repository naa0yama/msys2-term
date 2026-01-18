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
	# Format: YYYYMMDDTHHMMSS_{session}-{window}{pane}_ssh_{user}@{host}.log
	builtin set --local log_file ""
	builtin set --local is_dry_run 0
	if __fssh_ssh_is_dry_run $argv
		builtin set is_dry_run 1
		__fterm_debug "Dry-run mode detected, logging disabled"
	else if type --query tmux; and builtin set --query TMUX
		builtin set --local date_path "$(command date '+%Y/%m/%d')"
		builtin set --local timestamp_file "$(command date '+%Y%m%dT%H%M%S')"
		builtin set --local pane_info "$(command tmux display-message -p "#{session_name}-#{window_index}#{pane_index}")"
		# Use user@target_host if @ not already in target_host
		if string match -q '*@*' -- "$target_host"
			builtin set log_file "$FTERM_LOG_DIR_PREFIX$date_path/"$timestamp_file"_"$pane_info"_ssh_$target_host.log"
		else
			builtin set log_file "$FTERM_LOG_DIR_PREFIX$date_path/"$timestamp_file"_"$pane_info"_ssh_$ssh_user@$target_host.log"
		end

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
		builtin set --export HOME "$(command cygpath -m "$USERPROFILE")"
	end

	__fterm_debug "Executing: $ssh_cmd $config_args $argv"

	# Set tmux pane title before connection
	if type --query tmux; and builtin set --query TMUX
		command tmux set-window-option automatic-rename off
		command tmux select-pane -T "ssh:$ssh_user@$target_host"
	end

	command "$ssh_cmd" $config_args $argv

	# Restore original HOME
	if builtin test -n "$original_home"
		builtin set --export HOME "$original_home"
	end

	# Output disconnection info
	set_color blue
	builtin echo ""
	builtin echo "#= >> Disconnected << =========================================================="
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

	__fterm_debug "=== SSH function completed ==="
end
