#!/usr/bin/env fish

function __fssh_get_ssh_cmd --description 'Get SSH command path'
	if builtin set --query __fssh_ssh_cmd
		builtin echo "$__fssh_ssh_cmd"
	else
		builtin echo ssh
	end
end

function __fssh_get_ssh_config_args --description 'Get SSH config args for Windows OpenSSH'
	# Returns list: -F and path as separate elements (each line becomes a list item)
	if builtin set --query __fssh_ssh_config
		builtin echo -- -F
		builtin echo -- "$__fssh_ssh_config"
	end
end

function __fssh_get_connection_info --description 'Get user@host:port from ssh -G'
	builtin set --local ssh_cmd "$(__fssh_get_ssh_cmd)"
	builtin set --local config_args (__fssh_get_ssh_config_args)
	builtin set --local target "$argv[1]"

	__fssh_debug "ssh -G command: $ssh_cmd $config_args -G $target"

	# Set HOME for Windows OpenSSH to resolve Include paths correctly
	builtin set --local original_home "$HOME"
	if builtin set --query MSYSTEM; and builtin set --query USERPROFILE
		builtin set --export HOME "$(cygpath -m "$USERPROFILE")"
	end

	builtin set --local result (command "$ssh_cmd" $config_args -G "$target" 2>/dev/null | awk '
		/^user / { user=$2 }
		/^hostname / { host=$2 }
		/^port / { port=$2 }
		END {
			if (user && host && port) {
				printf "%s\t%s\t%s", user, host, port
			}
		}
	')

	# Restore original HOME
	if builtin test -n "$original_home"
		builtin set --export HOME "$original_home"
	end

	__fssh_debug "ssh -G result: $result"
	builtin echo "$result"
end

function __fssh_get_ssh_config_details --description 'Get non-default SSH config for logging'
	builtin set --local ssh_cmd "$(__fssh_get_ssh_cmd)"
	builtin set --local config_args (__fssh_get_ssh_config_args)
	builtin set --local target "$argv[1]"

	# Set HOME for Windows OpenSSH to resolve Include paths correctly
	builtin set --local original_home "$HOME"
	if builtin set --query MSYSTEM; and builtin set --query USERPROFILE
		builtin set --export HOME "$(cygpath -m "$USERPROFILE")"
	end

	# Extract important non-default options
	command "$ssh_cmd" $config_args -G "$target" 2>/dev/null | awk '
		/^proxyjump / && $2 != "none" { print "ProxyJump: " $2 }
		/^proxycommand / && $2 != "none" { $1=""; print "ProxyCommand:" $0 }
		/^identityfile / { print "IdentityFile: " $2 }
		/^identitiesonly / { print "IdentitiesOnly: " $2 }
		/^forwardagent / && $2 == "yes" { print "ForwardAgent: yes" }
		/^localforward / { print "LocalForward: " $2 " " $3 }
		/^remoteforward / { print "RemoteForward: " $2 " " $3 }
		/^dynamicforward / && $2 != "none" { print "DynamicForward: " $2 }
	'

	# Restore original HOME
	if builtin test -n "$original_home"
		builtin set --export HOME "$original_home"
	end
end

function __fssh_start_logging --description 'Start tmux pane logging'
	builtin set --local log_file "$argv[1]"
	builtin set --local target_host "$argv[2]"
	builtin set --local ssh_info "$argv[3]"

	__fssh_debug "Starting logging to: $log_file"

	# Create directory
	command mkdir -p (dirname "$log_file")

	# Get and write non-default SSH config
	builtin set --local config_details (__fssh_get_ssh_config_details "$target_host")
	if builtin test -n "$config_details"
		builtin echo "=== SSH Config ===" >> "$log_file"
		for line in $config_details
			builtin echo "$line" >> "$log_file"
		end
	end

	# Get and write matched agent keys
	builtin set --local matched_keys (__fssh_get_matched_agent_keys "$target_host")
	if builtin test -n "$matched_keys"
		builtin echo "=== Matched Agent Keys ===" >> "$log_file"
		for key in $matched_keys
			builtin echo "$key" >> "$log_file"
		end
	end

	# Add separator if any config was written
	if builtin test -n "$config_details" -o -n "$matched_keys"
		builtin echo "" >> "$log_file"
	end

	# Set pane logging state
	builtin set --local pane_id "$(tmux display-message -p "#{session_name}_#{window_index}_#{pane_index}")"
	command tmux set-option -gq "@$pane_id" "logging"

	# Start pipe-pane with timestamp prefix
	# Format: [YYYY-MM-DDTHH:MM:SS+ZZZZ] <line>
	command tmux pipe-pane "exec cat - | ansifilter | awk '{print strftime(\"[%Y-%m-%dT%H:%M:%S%z]\"), \$0; fflush()}' >> '$log_file'"

	__fssh_debug "Logging started for pane: $pane_id"
end

function __fssh_stop_logging --description 'Stop tmux pane logging'
	builtin set --local log_file "$argv[1]"

	__fssh_debug "Stopping logging: $log_file"

	# Stop pipe-pane
	command tmux pipe-pane

	# Set pane logging state
	builtin set --local pane_id "$(tmux display-message -p "#{session_name}_#{window_index}_#{pane_index}")"
	command tmux set-option -gq "@$pane_id" "not logging"

	# Append disconnect timestamp
	if builtin test -n "$log_file"; and builtin test -f "$log_file"
		builtin echo "[$(date +%Y-%m-%dT%H:%M:%S%z)] === Session Disconnected ===" >> "$log_file"
	end

	__fssh_debug "Logging stopped for pane: $pane_id"
end

function __fssh_is_dry_run --description 'Check if SSH args contain non-connecting options'
	# Options that don't make actual connections: -G, -V, -Q
	for arg in $argv
		switch $arg
			case -G -V -Q --help
				return 0
		end
	end
	return 1
end

function __fssh_get_matched_agent_keys --description 'Get agent keys matching IdentityFile'
	builtin set --local target_host "$argv[1]"

	builtin set --local ssh_add_cmd "ssh-add"
	if builtin set --query __fssh_ssh_add_cmd
		builtin set ssh_add_cmd "$__fssh_ssh_add_cmd"
	end

	builtin set --local ssh_cmd "$(__fssh_get_ssh_cmd)"
	builtin set --local config_args (__fssh_get_ssh_config_args)

	# Set HOME for Windows OpenSSH
	builtin set --local original_home "$HOME"
	if builtin set --query MSYSTEM; and builtin set --query USERPROFILE
		builtin set --export HOME "$(cygpath -m "$USERPROFILE")"
	end

	builtin set --local identity_files (command "$ssh_cmd" $config_args -G "$target_host" 2>/dev/null | awk '/^identityfile / { print $2 }')

	builtin set --local ssh_keygen_cmd "ssh-keygen"
	if builtin set --query __fssh_ssh_keygen_cmd
		builtin set ssh_keygen_cmd "$__fssh_ssh_keygen_cmd"
	end

	builtin set --local agent_output ($ssh_add_cmd -l 2>/dev/null)
	if builtin test $status -eq 0; and builtin test -n "$agent_output"
		for id_file in $identity_files
			builtin set --local expanded_file (string replace "~" "$HOME" "$id_file")
			if builtin test -f "$expanded_file"
				builtin set --local id_fingerprint ($ssh_keygen_cmd -lf "$expanded_file" 2>/dev/null | awk '{print $2}')
				if builtin test -n "$id_fingerprint"
					for agent_key in $agent_output
						if string match -q "*$id_fingerprint*" "$agent_key"
							builtin echo "$agent_key (from: $id_file)"
						end
					end
				end
			end
		end
	end

	# Restore HOME
	if builtin test -n "$original_home"
		builtin set --export HOME "$original_home"
	end
end

function __fssh_status_splash --description 'SSH status splash'
	builtin set --local timestamp "$(date +%Y-%m-%dT%H:%M:%S%z)"
	builtin set --local ssh_info "$argv[1]"
	builtin set --local log_file "$argv[2]"
	builtin set --local target_host "$argv[3]"
	# argv[4..] are the original ssh args

	builtin echo "#= ======================================================================"
	builtin echo "#= | | ___   __ _   | Config Name         $target_host"
	builtin echo "#= | |/ _ \\ / _  |  | User@HostName:Port  $ssh_info"
	builtin echo "#= | | (_) | (_| |  | Timestamp           $timestamp"
	builtin echo "#= |_|\\___/ \\__, |  | Command \$argv       $argv[4..-1]"
	builtin echo "#=          |___/   |"
	builtin echo "#= $log_file"
	builtin echo "#= ----------------------------------------------------------------------"
	builtin echo "#="

	# Show SSH Config
	builtin set --local config_details (__fssh_get_ssh_config_details "$target_host")
	if builtin test -n "$config_details"
		builtin echo "#= --- SSH Config ---"
		for line in $config_details
			builtin echo "#=   $line"
		end
	end

	# Show Matched Agent Keys
	builtin set --local matched_keys (__fssh_get_matched_agent_keys "$target_host")
	if builtin test -n "$matched_keys"
		builtin echo "#= --- Matched Agent Keys ---"
		for key in $matched_keys
			builtin echo "#=   $key"
		end
	end

	if builtin test -n "$config_details" -o -n "$matched_keys"
		builtin echo "#= ======================================================================"
	end
	builtin echo ""
end

function ssh --description 'SSH with logging support'
	__fssh_debug "=== SSH function called ==="
	__fssh_debug "argv: $argv"
	__fssh_debug "__fssh_ssh_cmd: $__fssh_ssh_cmd"
	__fssh_debug "__fssh_ssh_config: $__fssh_ssh_config"
	__fssh_debug "__fssh_ssh_add_cmd: $__fssh_ssh_add_cmd"

	# Load SSH environment if exists
	if builtin set --query SSH_ENV; and builtin test -f "$SSH_ENV"
		set_color blue
		builtin echo "[INFO ] Loading ssh environment: $SSH_ENV ..."
		set_color normal
		builtin source "$SSH_ENV" >/dev/null
		__fssh_debug "Loaded SSH_ENV: $SSH_ENV"
	end

	# Determine which ssh-add to use
	builtin set --local ssh_add_cmd "ssh-add"
	if builtin set --query __fssh_ssh_add_cmd
		builtin set ssh_add_cmd "$__fssh_ssh_add_cmd"
	end
	__fssh_debug "ssh-add command: $ssh_add_cmd"

	# Check SSH agent connection
	if not timeout --foreground --kill-after=5 3 $ssh_add_cmd -l >/dev/null 2>&1
		set_color red
		builtin echo "[ERROR] ssh-add connection failed."
		set_color normal
		__fssh_debug "ssh-add check failed"
		return 1
	else
		set_color blue
		builtin echo "[INFO ] ssh-add connection successful."
		set_color normal
		__fssh_debug "ssh-add check passed"
	end

	# Get target host (last argument)
	builtin set --local target_host "$argv[-1]"
	__fssh_debug "target_host: $target_host"

	# Get connection info: user, host, port
	builtin set --local conn_info (string split \t -- (__fssh_get_connection_info "$target_host"))
	builtin set --local ssh_user "$conn_info[1]"
	builtin set --local ssh_host "$conn_info[2]"
	builtin set --local ssh_port "$conn_info[3]"
	builtin set --local ssh_info "$ssh_user@$ssh_host:$ssh_port"

	__fssh_debug "Connection info - user: $ssh_user, host: $ssh_host, port: $ssh_port"

	# Generate log file path (only for actual connections, not dry-run)
	# Format: YYYYMMDDTHHMMSS_{session}-{window}{pane}_{user}@{host}-{port}.log
	builtin set --local log_file ""
	builtin set --local is_dry_run 0
	if __fssh_is_dry_run $argv
		builtin set is_dry_run 1
		__fssh_debug "Dry-run mode detected, logging disabled"
	else if type --query tmux; and builtin set --query TMUX
		builtin set --local date_path "$(date '+%Y/%m/%d')"
		builtin set --local timestamp_file "$(date '+%Y%m%dT%H%M%S')"
		builtin set --local pane_info "$(tmux display-message -p "#{session_name}-#{window_index}#{pane_index}")"
		builtin set log_file "$FSSH_LOG_DIR_PREFIX$date_path/"$timestamp_file"_"$pane_info"_$ssh_user@$ssh_host-$ssh_port.log"

		__fssh_debug "log_file: $log_file"

		# Start logging
		__fssh_start_logging "$log_file" "$target_host" "$ssh_info"
	else
		set_color yellow
		builtin echo "[WARN ] tmux not available or not in tmux session, logging disabled"
		set_color normal
		__fssh_debug "tmux not available or not in tmux session, logging disabled"
	end

	# Show splash
	__fssh_status_splash "$ssh_info" "$log_file" "$target_host" $argv

	# Execute SSH
	builtin set --local ssh_cmd "$(__fssh_get_ssh_cmd)"
	builtin set --local config_args (__fssh_get_ssh_config_args)

	# Set HOME for Windows OpenSSH to resolve Include paths correctly
	builtin set --local original_home "$HOME"
	if builtin set --query MSYSTEM; and builtin set --query USERPROFILE
		builtin set --export HOME "$(cygpath -m "$USERPROFILE")"
	end

	__fssh_debug "Executing: $ssh_cmd $config_args $argv"

	command "$ssh_cmd" $config_args $argv

	# Restore original HOME
	if builtin test -n "$original_home"
		builtin set --export HOME "$original_home"
	end

	# Output disconnection info
	set_color blue
	builtin echo ""
	builtin echo "#= >> Disconnected << ==================================================="
	builtin echo "#=    Timestamp     | $(date +%Y-%m-%dT%H:%M:%S%z)"
	builtin echo "#=    Logfile       | $log_file"
	builtin echo "#= ======================================================================"
	set_color normal

	# Stop logging and cleanup (only if not dry-run)
	if test "$is_dry_run" -eq 0; and type --query tmux; and builtin set --query TMUX
		command tmux select-pane -P 'default'
		__fssh_stop_logging "$log_file"
	end

	__fssh_debug "=== SSH function completed ==="
end
