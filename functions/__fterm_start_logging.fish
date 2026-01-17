#!/usr/bin/env fish

function __fterm_start_logging --description 'Start tmux pane logging'
	builtin set --local log_file "$argv[1]"
	builtin set --local target_host "$argv[2]"
	builtin set --local ssh_info "$argv[3]"

	__fterm_debug "Starting logging to: $log_file"

	# Create directory
	command mkdir -p (dirname "$log_file")

	# Get and write non-default SSH config
	builtin set --local config_details (__fterm_get_ssh_config_details "$target_host")
	if builtin test -n "$config_details"
		builtin echo "=== SSH Config ===" >> "$log_file"
		for line in $config_details
			builtin echo "$line" >> "$log_file"
		end
	end

	# Get and write matched agent keys
	builtin set --local matched_keys (__fterm_get_matched_agent_keys "$target_host")
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

	__fterm_debug "Logging started for pane: $pane_id"
end
