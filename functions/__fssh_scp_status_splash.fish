#!/usr/bin/env fish

function __fssh_scp_status_splash --description 'SCP status splash'
	builtin set --local timestamp "$(date +%Y-%m-%dT%H:%M:%S%z)"
	builtin set --local hosts "$argv[1]"
	builtin set --local log_file "$argv[2]"
	# argv[3..] are the original scp args

	builtin echo "#= ============================================================================="
	builtin echo "#=  ___  ___ _ __    | Remote Host(s)      $hosts"
	builtin echo "#= / __|/ __| '_ \\   | Timestamp           $timestamp"
	builtin echo "#= \\__ \\ (__| |_) |  | Command \$argv       $argv[3..-1]"
	builtin echo "#= |___/\\___|  __/   |"
	builtin echo "#=          |_|      |"
	builtin echo "#= $log_file"
	builtin echo "#= -----------------------------------------------------------------------------"
	builtin echo "#="

	# Show SSH Config for each host
	for host in (string split ' ' -- "$hosts")
		if builtin test -n "$host"
			builtin set --local config_details (__fterm_get_ssh_config_details "$host")
			if builtin test -n "$config_details"
				builtin echo "#= --- SSH Config ($host) ---"
				for line in $config_details
					builtin echo "#=   $line"
				end
			end

			# Show Matched Agent Keys
			builtin set --local matched_keys (__fterm_get_matched_agent_keys "$host")
			if builtin test -n "$matched_keys"
				builtin echo "#= --- Matched Agent Keys ($host) ---"
				for key in $matched_keys
					builtin echo "#=   $key"
				end
			end
		end
	end

	builtin echo "#= ============================================================================="
	builtin echo ""
end
