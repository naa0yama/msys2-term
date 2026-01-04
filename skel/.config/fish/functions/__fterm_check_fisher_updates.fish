#!/usr/bin/env fish

function __fterm_check_fisher_updates --description 'Check for Fisher plugin updates via GitHub API'
	# Skip if Fisher is not installed
	if not functions --query fisher
		return
	end

	# Skip if disabled (set -U FTERM_FISHER_UPDATE_CHECK 0)
	if builtin set --query FTERM_FISHER_UPDATE_CHECK; and builtin test "$FTERM_FISHER_UPDATE_CHECK" = 0
		return
	end

	builtin set --local cache_dir ~/.cache/fterm
	builtin set --local cache_file "$cache_dir/fisher_update_cache"
	builtin set --local now (command date +%s)

	# Default: 3 days = 259200 seconds
	builtin set --local check_interval 259200
	if builtin set --query FTERM_FISHER_UPDATE_INTERVAL
		builtin set check_interval "$FTERM_FISHER_UPDATE_INTERVAL"
	end

	command mkdir --parents "$cache_dir"

	# Check if we need to fetch from API
	builtin set --local should_fetch 1
	builtin set --local cached_updates 0

	if builtin test -f "$cache_file"
		builtin set --local cache_data (command cat "$cache_file")
		builtin set --local last_check (builtin echo "$cache_data" | command head --lines=1)
		builtin set cached_updates (builtin echo "$cache_data" | command tail --lines=1)

		if builtin test (math "$now - $last_check") -lt "$check_interval"
			builtin set should_fetch 0
		end
	end

	if builtin test "$should_fetch" -eq 1
		# Fetch updates in background to not block shell startup
		__fterm_fetch_fisher_updates &
		disown

		# Show cached result if available
		if builtin test "$cached_updates" -gt 0
			set_color yellow
			builtin echo "🐟 $cached_updates plugin update(s) available: fisher update"
			set_color normal
		end
	else
		# Show cached result
		if builtin test "$cached_updates" -gt 0
			set_color yellow
			builtin echo "🐟 $cached_updates plugin update(s) available: fisher update"
			set_color normal
		end
	end
end

function __fterm_fetch_fisher_updates --description 'Fetch Fisher plugin updates from GitHub API'
	builtin set --local cache_dir ~/.cache/fterm
	builtin set --local cache_file "$cache_dir/fisher_update_cache"
	builtin set --local commits_file "$cache_dir/fisher_commits"
	builtin set --local now (command date +%s)

	# Read fish_plugins
	if not builtin test -f ~/.config/fish/fish_plugins
		return
	end

	builtin set --local updates_available 0

	for plugin in (command cat ~/.config/fish/fish_plugins)
		# Skip empty lines
		builtin test -z "$plugin"; and continue

		# Parse owner/repo (handle plugins with paths like owner/repo/path)
		builtin set --local parts (string split / "$plugin")
		if builtin test (count $parts) -lt 2
			continue
		end
		builtin set --local owner "$parts[1]"
		builtin set --local repo "$parts[2]"

		# Get latest commit SHA from GitHub API
		builtin set --local api_url "https://api.github.com/repos/$owner/$repo/commits/HEAD"
		builtin set --local response (command curl --silent --fail --header "User-Agent: naa0yama/fssh" "$api_url" 2>/dev/null)
		if builtin test $status -ne 0
			continue
		end

		builtin set --local remote_sha (builtin echo "$response" | string match --regex '"sha":\s*"([a-f0-9]+)"' | command head --lines=2 | command tail --lines=1)
		if builtin test -z "$remote_sha"
			continue
		end

		# Get cached SHA
		builtin set --local cached_sha ""
		if builtin test -f "$commits_file"
			builtin set cached_sha (command grep "^$owner/$repo:" "$commits_file" | string replace "$owner/$repo:" "")
		end

		# Compare
		if builtin test -n "$cached_sha"; and builtin test "$cached_sha" != "$remote_sha"
			builtin set updates_available (math $updates_available + 1)
		end

		# Update cache (remove old entry, add new)
		if builtin test -f "$commits_file"
			command grep --invert-match "^$owner/$repo:" "$commits_file" > "$commits_file.tmp" 2>/dev/null
			command mv "$commits_file.tmp" "$commits_file" 2>/dev/null
		end
		builtin echo "$owner/$repo:$remote_sha" >> "$commits_file"
	end

	# Save check result
	builtin echo "$now" > "$cache_file"
	builtin echo "$updates_available" >> "$cache_file"
end
