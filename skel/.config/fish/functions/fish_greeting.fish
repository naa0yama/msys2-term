#!/usr/bin/env fish

function fish_greeting
	# Get version from /etc/fssh-release
	builtin set --local __fterm_version "dev"
	if builtin test -f /etc/fssh-release
		builtin set --local __fterm_tag (command grep '^BUILD_TAG=' /etc/fssh-release | string replace 'BUILD_TAG="' '' | string replace '"' '')
		if builtin test -n "$__fterm_tag"
			builtin set __fterm_version "$__fterm_tag"
		else
			builtin set --local __fterm_sha (command grep '^BUILD_SHA=' /etc/fssh-release | string replace 'BUILD_SHA="' '' | string replace '"' '')
			if builtin test -n "$__fterm_sha"
				builtin set __fterm_version (string sub --length 7 "$__fterm_sha")
			end
		end
	end

	set_color brblue
	builtin echo "╭──────────────────────────────────────╮"
	builtin echo "│       Fuzzy Term (fterm)             │"
	builtin printf "│%37s │\n" "$__fterm_version"
	builtin echo "╰──────────────────────────────────────╯"
	set_color normal
	builtin echo ""

	# Check for pacman updates
	builtin set --local __fterm_pacman_updates (command pacman -Qu 2>/dev/null | count)
	if builtin test "$__fterm_pacman_updates" -gt 0
		set_color yellow
		builtin echo "📦 $__fterm_pacman_updates package update(s) available: pacman -Syu"
		set_color normal
	end

	# Check for Fisher plugin updates via GitHub API
	# Configuration:
	#   set -U FTERM_FISHER_UPDATE_CHECK 0          # Disable update check
	#   set -U FTERM_FISHER_UPDATE_INTERVAL 259200  # Check interval in seconds (default: 3 days)
	__fterm_check_fisher_updates

	builtin echo ""
end
