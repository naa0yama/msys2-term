#!/usr/bin/env fish

function __fterm_stop_logging --description 'Stop tmux pane logging'
	builtin set --local log_file "$argv[1]"

	__fterm_debug "Stopping logging: $log_file"

	# Stop pipe-pane
	command tmux pipe-pane

	# Set pane logging state
	builtin set --local pane_id "$(tmux display-message -p "#{session_name}_#{window_index}_#{pane_index}")"
	command tmux set-option -gq "@$pane_id" "not logging"

	# Append disconnect timestamp
	if builtin test -n "$log_file"; and builtin test -f "$log_file"
		builtin echo "[$(date +%Y-%m-%dT%H:%M:%S%z)] === Session Disconnected ===" >> "$log_file"
	end

	__fterm_debug "Logging stopped for pane: $pane_id"
end
