#!/usr/bin/env fish

function __fssh_ensure_tmux --description 'Ensure running inside tmux session'
	# argv[1] is the command name (ssh or scp)
	# argv[2..] are the original arguments
	builtin set --local cmd_name "$argv[1]"
	builtin set --local cmd_args $argv[2..-1]

	# Check if tmux is available
	if not type --query tmux
		set_color red
		builtin echo "[ERROR] tmux is not installed. Logging requires tmux."
		set_color normal
		return 1
	end

	# Check if already inside tmux
	if builtin set --query TMUX
		return 0
	end

	# Not inside tmux - need to enter tmux session
	set_color yellow
	builtin echo "[WARN ] Not running inside tmux. Logging requires tmux session."
	builtin echo "[INFO ] Entering tmux session 'login-session'..."
	set_color normal

	# Escape arguments for safe passing to tmux send-keys
	builtin set --local escaped_args (string escape -- $cmd_args)
	builtin set --local full_cmd "$cmd_name $escaped_args"

	# Check if login-session exists
	if tmux has-session -t login-session 2>/dev/null
		# Attach to existing session and send command
		builtin echo "[INFO ] Attaching to existing 'login-session'..."
		tmux attach-session -t login-session \; send-keys "$full_cmd" Enter
	else
		# Create new session and send command
		builtin echo "[INFO ] Creating new 'login-session'..."
		tmux new-session -s login-session \; send-keys "$full_cmd" Enter
	end

	# After returning from tmux, exit this function
	# The actual command will be executed inside tmux
	return 1
end
