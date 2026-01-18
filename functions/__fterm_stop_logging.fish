#!/usr/bin/env fish

function __fterm_stop_logging --description 'Stop tmux pane logging'
	builtin set --local log_file "$argv[1]"

	__fterm_debug "Stopping logging: $log_file"

	# Stop pipe-pane
	command tmux pipe-pane

	# Set pane logging state
	builtin set --local pane_id "$(tmux display-message -p "#{session_name}_#{window_index}_#{pane_index}")"
	command tmux set-option -gq "@$pane_id" "not logging"

	# Append disconnect timestamp and compress log file
	if builtin test -n "$log_file"; and builtin test -f "$log_file"
		builtin echo "[$(command date +%Y-%m-%dT%H:%M:%S%z)] === Session Disconnected ===" >> "$log_file"

		# Compress log file with gzip
		__fterm_debug "Compressing log file: $log_file"
		if command gzip --force "$log_file" 2>/dev/null
			__fterm_debug "Log file compressed: $log_file.gz"
		else
			__fterm_debug "Failed to compress log file: $log_file"
		end
	end

	__fterm_debug "Logging stopped for pane: $pane_id"
end
