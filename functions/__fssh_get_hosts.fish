#!/usr/bin/env fish

function __fssh_get_hosts --description 'Get SSH hosts from config Include chain'
	builtin set --local ssh_home (__fssh_get_ssh_home)
	builtin set --local config_file "$ssh_home/config"

	__fterm_debug "__fssh_get_hosts: ssh_home=$ssh_home, config_file=$config_file"

	# Skip if config file doesn't exist
	if not builtin test -f "$config_file"
		__fterm_debug "__fssh_get_hosts: config file not found: $config_file"
		return
	end

	# Reset visited files tracker
	builtin set --erase __fssh_visited_files

	# Get all included config files
	builtin set --local config_files (__fssh_get_included_files "$config_file" "$ssh_home")

	# Cleanup visited files tracker
	builtin set --erase __fssh_visited_files

	__fterm_debug "__fssh_get_hosts: config_files count: "(builtin count $config_files)
	__fterm_debug "__fssh_get_hosts: config_files: $config_files"

	# Parse Host entries from all config files (exclude wildcards)
	for file in $config_files
		if builtin test -f "$file"
			while builtin read --local line
				# Match Host directive (must start at beginning of line, not Match)
				if builtin string match --quiet --regex '^Host\s+' "$line"
					# Extract hosts after "Host"
					builtin set --local hosts (builtin string replace --regex '^Host\s+' '' "$line")
					# Split by whitespace and filter out wildcards
					for host in (builtin string split --no-empty ' ' "$hosts")
						# Skip wildcards (containing * or ?)
						if builtin string match --quiet --regex '[*?]' "$host"
							continue
						end
						builtin echo "$host"
					end
				end
			end <"$file"
		end
	end | command sort --unique
end
