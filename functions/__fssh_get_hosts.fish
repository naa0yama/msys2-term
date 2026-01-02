#!/usr/bin/env fish

function __fssh_get_hosts --description 'Get SSH hosts from FSSH_SSH_CONF_DIR'
	# Skip if directory doesn't exist
	builtin test -d "$FSSH_SSH_CONF_DIR"; or return

	# Parse Host entries from config files (exclude wildcards)
	find "$FSSH_SSH_CONF_DIR" -type f -name "*.conf" -print0 2>/dev/null |
		xargs -0 awk '/^Host / {
			for (i=2; i<=NF; i++) {
				if ($i !~ /[*?]/) {
					print $i
				}
			}
		}' 2>/dev/null | sort -u
end
