#!/usr/bin/env fish

function __fterm_debug --description 'Output debug message if FTERM_DEBUG is enabled'
	if builtin set --query FTERM_DEBUG; and builtin test "$FTERM_DEBUG" = true
		set_color brblack >&2
		builtin echo "[DEBUG] $argv" >&2
		set_color normal >&2
	end
end
