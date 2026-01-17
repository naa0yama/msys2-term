#!/usr/bin/env fish

function __fssh_scp_extract_hosts --description 'Extract remote hosts from SCP arguments'
	# SCP arguments can be: local_path, host:path, user@host:path
	# Returns unique list of hosts (config names)
	builtin set --local hosts

	for arg in $argv
		# Skip options and their arguments
		if string match -qr '^-' -- "$arg"
			continue
		end

		# Check if argument contains : (remote path indicator)
		if string match -qr ':' -- "$arg"
			# Extract host part (before :)
			builtin set --local host_part (string replace -r ':.*$' '' -- "$arg")
			# Remove user@ if present
			builtin set --local host (string replace -r '^.*@' '' -- "$host_part")
			if not contains "$host" $hosts
				builtin set --append hosts "$host"
			end
		end
	end

	builtin printf '%s\n' $hosts
end
