#!/usr/bin/env fish

function __fssh_debug --description 'Output debug message if FSSH_DEBUG is enabled'
	if builtin set --query FSSH_DEBUG; and builtin test "$FSSH_DEBUG" = true
		set_color brblack
		builtin echo "[DEBUG] $argv"
		set_color normal
	end
end
