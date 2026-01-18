#!/usr/bin/env fish

function __fterm_get_matched_agent_keys --description 'Get agent keys matching IdentityFile'
	builtin set --local target_host "$argv[1]"
	__fterm_debug "=== __fterm_get_matched_agent_keys called ==="
	__fterm_debug "target_host: $target_host"

	builtin set --local ssh_add_cmd "ssh-add"
	if builtin set --query __fssh_ssh_add_cmd
		builtin set ssh_add_cmd "$__fssh_ssh_add_cmd"
	end
	__fterm_debug "ssh_add_cmd: $ssh_add_cmd"

	builtin set --local ssh_cmd "$(__fterm_get_ssh_cmd)"
	builtin set --local config_args (__fterm_get_ssh_config_args)
	__fterm_debug "ssh_cmd: $ssh_cmd, config_args: $config_args"

	# Set HOME for Windows OpenSSH
	builtin set --local original_home "$HOME"
	if builtin set --query MSYSTEM; and builtin set --query USERPROFILE
		builtin set --export HOME "$(cygpath -m "$USERPROFILE")"
		__fterm_debug "HOME changed for Windows: $HOME"
	end

	builtin set --local identity_files (command "$ssh_cmd" $config_args -G "$target_host" 2>/dev/null | awk '/^identityfile / { print $2 }')
	__fterm_debug "identity_files: $identity_files"

	builtin set --local ssh_keygen_cmd "ssh-keygen"
	if builtin set --query __fssh_ssh_keygen_cmd
		builtin set ssh_keygen_cmd "$__fssh_ssh_keygen_cmd"
	end
	__fterm_debug "ssh_keygen_cmd: $ssh_keygen_cmd"

	builtin set --local agent_output ("$ssh_add_cmd" -l 2>/dev/null)
	builtin set --local agent_status $status
	__fterm_debug "ssh-add -l status: $agent_status"
	__fterm_debug "agent_output: $agent_output"

	if builtin test $agent_status -eq 0; and builtin test -n "$agent_output"
		for id_file in $identity_files
			builtin set --local expanded_file (string replace "~" "$HOME" "$id_file")
			__fterm_debug "Checking id_file: $id_file -> expanded: $expanded_file"
			if builtin test -f "$expanded_file"
				builtin set --local id_fingerprint ("$ssh_keygen_cmd" -lf "$expanded_file" 2>/dev/null | awk '{print $2}')
				__fterm_debug "id_fingerprint for $expanded_file: $id_fingerprint"
				if builtin test -n "$id_fingerprint"
					for agent_key in $agent_output
						__fterm_debug "Comparing agent_key: $agent_key with fingerprint: $id_fingerprint"
						if string match -q "*$id_fingerprint*" "$agent_key"
							__fterm_debug "MATCH FOUND: $agent_key"
							builtin echo "$agent_key (from: $id_file)"
						end
					end
				end
			else
				__fterm_debug "File not found: $expanded_file"
			end
		end
	else
		__fterm_debug "ssh-add check failed or no keys in agent"
	end

	# Restore HOME
	if builtin test -n "$original_home"
		builtin set --export HOME "$original_home"
	end
end
