#!/usr/bin/env fish

function __fterm_get_matched_agent_keys --description 'Get agent keys matching IdentityFile'
	builtin set --local target_host "$argv[1]"

	builtin set --local ssh_add_cmd "ssh-add"
	if builtin set --query __fssh_ssh_add_cmd
		builtin set ssh_add_cmd "$__fssh_ssh_add_cmd"
	end

	builtin set --local ssh_cmd "$(__fterm_get_ssh_cmd)"
	builtin set --local config_args (__fterm_get_ssh_config_args)

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

	builtin set --local agent_output ("$ssh_add_cmd" -l 2>/dev/null)
	if builtin test $status -eq 0; and builtin test -n "$agent_output"
		for id_file in $identity_files
			builtin set --local expanded_file (string replace "~" "$HOME" "$id_file")
			if builtin test -f "$expanded_file"
				builtin set --local id_fingerprint ("$ssh_keygen_cmd" -lf "$expanded_file" 2>/dev/null | awk '{print $2}')
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
