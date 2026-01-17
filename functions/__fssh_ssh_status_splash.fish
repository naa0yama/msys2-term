#!/usr/bin/env fish

function __fssh_ssh_status_splash --description 'SSH status splash'
	builtin set --local timestamp "$(date +%Y-%m-%dT%H:%M:%S%z)"
	builtin set --local ssh_info "$argv[1]"
	builtin set --local log_file "$argv[2]"
	builtin set --local target_host "$argv[3]"
	# argv[4..] are the original ssh args

	builtin echo "#= ============================================================================="
	builtin echo "#= | | ___   __ _   | Config Name         $target_host"
	builtin echo "#= | |/ _ \\ / _  |  | User@HostName:Port  $ssh_info"
	builtin echo "#= | | (_) | (_| |  | Timestamp           $timestamp"
	builtin echo "#= |_|\\___/ \\__, |  | Command \$argv       $argv[4..-1]"
	builtin echo "#=          |___/   |"
	builtin echo "#= $log_file"
	builtin echo "#= -----------------------------------------------------------------------------"
	builtin echo "#="

	# Show SSH Config
	builtin set --local config_details (__fterm_get_ssh_config_details "$target_host")
	if builtin test -n "$config_details"
		builtin echo "#= --- SSH Config ---"
		for line in $config_details
			builtin echo "#=   $line"
		end
	end

	# Show Matched Agent Keys
	builtin set --local matched_keys (__fterm_get_matched_agent_keys "$target_host")
	if builtin test -n "$matched_keys"
		builtin echo "#= --- Matched Agent Keys ---"
		for key in $matched_keys
			builtin echo "#=   $key"
		end
	end

	if builtin test -n "$config_details" -o -n "$matched_keys"
		builtin echo "#= ============================================================================"
	end
	builtin echo ""
end
