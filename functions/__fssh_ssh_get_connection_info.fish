#!/usr/bin/env fish

function __fssh_ssh_get_connection_info --description 'Get user@host:port from ssh -G'
	builtin set --local config_args (__fterm_get_ssh_config_args)
	builtin set --local target "$argv[1]"

	__fterm_debug "ssh -G command: ssh $config_args -G $target"

	# Set HOME for Windows OpenSSH to resolve Include paths correctly
	builtin set --local original_home "$HOME"
	if builtin set --query MSYSTEM; and builtin set --query USERPROFILE
		builtin set --export HOME "$(command cygpath -m "$USERPROFILE")"
	end

	builtin set --local result (__fterm_run_ssh_cmd ssh $config_args -G "$target" | command awk '
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

	__fterm_debug "ssh -G result: $result"
	builtin echo "$result"
end
