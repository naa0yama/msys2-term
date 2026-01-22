#!/usr/bin/env fish

function __fssh_check_syntax --description 'Check SSH config syntax using ssh -G'
	__fterm_debug "=== __fssh_check_syntax called ==="

	builtin set --local config_args (__fterm_get_ssh_config_args)

	# Set HOME for Windows OpenSSH
	builtin set --local original_home "$HOME"
	if builtin set --query MSYSTEM; and builtin set --query USERPROFILE
		builtin set --export HOME "$(command cygpath -m "$USERPROFILE")"
	end

	# Use a dummy host to check overall config syntax
	# ssh -G will parse all config files even for non-existent hosts
	builtin set --local syntax_output (__fterm_run_ssh_cmd ssh $config_args -G "syntax.check.dummy.host" 2>&1)
	builtin set --local syntax_status $status

	# Restore HOME
	if builtin test -n "$original_home"
		builtin set --export HOME "$original_home"
	end

	__fterm_debug "syntax check status: $syntax_status"

	if builtin test "$syntax_status" -ne 0
		set_color red
		builtin echo "[ERROR] SSH config syntax error detected"
		# Show error lines
		builtin echo "$syntax_output" | command grep -i -E '(error|bad|unknown|invalid)' | while builtin read --local line
			builtin echo "        $line"
		end
		set_color normal
		return 1
	end

	__fterm_debug "Syntax check passed"
	return 0
end
