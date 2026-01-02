#!/usr/bin/env fish

function fish_greeting
	# Get version from /etc/fssh-release
	builtin set --local version "dev"
	if builtin test -f /etc/fssh-release
		builtin set --local tag (command grep '^BUILD_TAG=' /etc/fssh-release | string replace 'BUILD_TAG="' '' | string replace '"' '')
		if builtin test -n "$tag"
			builtin set version "$tag"
		else
			builtin set --local sha (command grep '^BUILD_SHA=' /etc/fssh-release | string replace 'BUILD_SHA="' '' | string replace '"' '')
			if builtin test -n "$sha"
				builtin set version (string sub --length 7 "$sha")
			end
		end
	end

	set_color brblue
	builtin echo "╭──────────────────────────────────────╮"
	builtin echo "│       msys2-term / fssh terminal     │"
	builtin printf "│%37s │\n" "$version"
	builtin echo "╰──────────────────────────────────────╯"
	set_color normal
	builtin echo ""

	# Check for pacman updates
	builtin set --local pacman_updates (command pacman -Qu 2>/dev/null | count)
	if builtin test "$pacman_updates" -gt 0
		set_color yellow
		builtin echo "📦 $pacman_updates package update(s) available: pacman -Syu"
		set_color normal
	end

	# Check for Fisher plugin updates via GitHub API
	# Configuration:
	#   set -U FSSH_FISHER_UPDATE_CHECK 0       # Disable update check
	#   set -U FSSH_FISHER_UPDATE_INTERVAL 259200  # Check interval in seconds (default: 3 days)
	__fssh_check_fisher_updates

	builtin echo ""
end
