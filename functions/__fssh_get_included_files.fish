#!/usr/bin/env fish

function __fssh_get_included_files --description 'Recursively get files from SSH config Include directives'
	# Arguments: [config_file] [ssh_home]
	builtin set --local config_file "$argv[1]"
	builtin set --local ssh_home "$argv[2]"

	# Default ssh_home if not provided
	if builtin test -z "$ssh_home"
		builtin set ssh_home (__fssh_get_ssh_home)
	end

	# Default config_file if not provided
	if builtin test -z "$config_file"
		builtin set config_file "$ssh_home/config"
	end

	__fterm_debug "__fssh_get_included_files: config_file=$config_file, ssh_home=$ssh_home"

	# Skip if config file doesn't exist
	if not builtin test -f "$config_file"
		__fterm_debug "__fssh_get_included_files: config file not found: $config_file"
		return
	end

	# Track visited files to prevent infinite loops
	if not builtin set --query __fssh_visited_files
		builtin set --global __fssh_visited_files
	end

	# Check if already visited
	if builtin contains "$config_file" $__fssh_visited_files
		__fterm_debug "__fssh_get_included_files: already visited: $config_file"
		return
	end
	builtin set --append __fssh_visited_files "$config_file"

	# Output current file
	builtin echo "$config_file"

	# Parse Include directives
	while builtin read --local line
		# Skip comments and empty lines
		if builtin string match --quiet --regex '^\s*#' "$line"
			continue
		end
		if builtin string match --quiet --regex '^\s*$' "$line"
			continue
		end

		# Match Include directive (case-insensitive, must start at beginning of line)
		if builtin string match --quiet --regex --ignore-case '^Include\s+' "$line"
			# Extract the patterns after "Include"
			builtin set --local patterns_str (builtin string replace --regex --ignore-case '^Include\s+' '' "$line")
			# Trim trailing whitespace
			builtin set patterns_str (builtin string trim "$patterns_str")

			__fterm_debug "__fssh_get_included_files: found Include: $patterns_str"

			# Split by whitespace to support multiple paths (e.g., "Include path1 path2 path3")
			for single_pattern in (builtin string split --no-empty ' ' "$patterns_str")
				# Skip empty patterns
				if builtin test -z "$single_pattern"
					continue
				end

				__fterm_debug "__fssh_get_included_files: processing pattern: $single_pattern"

				# Resolve path
				builtin set --local resolved_pattern
				if builtin string match --quiet '~*' "$single_pattern"
					# Starts with ~ -> expand to home
					if builtin set --query MSYSTEM; and builtin set --query USERPROFILE
						builtin set resolved_pattern (builtin string replace '~' "$(cygpath -u "$USERPROFILE")" "$single_pattern")
					else
						builtin set resolved_pattern (builtin string replace '~' "$HOME" "$single_pattern")
					end
				else if builtin string match --quiet '/*' "$single_pattern"
					# Absolute path
					builtin set resolved_pattern "$single_pattern"
				else
					# Relative path -> relative to ssh_home
					builtin set resolved_pattern "$ssh_home/$single_pattern"
				end

				__fterm_debug "__fssh_get_included_files: resolved pattern: $resolved_pattern"

				# Expand glob pattern
				builtin set --local expanded_files
				# Use eval to expand glob, suppress errors for non-matching patterns
				builtin eval "set expanded_files $resolved_pattern" 2>/dev/null

				__fterm_debug "__fssh_get_included_files: expanded files: $expanded_files"

				# Recursively process each included file
				for included_file in $expanded_files
					if builtin test -f "$included_file"
						__fssh_get_included_files "$included_file" "$ssh_home"
					end
				end
			end
		end
	end <"$config_file"
end
