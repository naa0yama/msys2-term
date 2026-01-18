#!/usr/bin/env fish

function __fterm_format_duration --description 'Format duration in seconds to human readable format (eg. 3d 23h30m49s)'
	builtin set --local total_seconds "$argv[1]"

	if builtin test -z "$total_seconds"
		builtin echo "0s"
		return
	end

	builtin set --local days (math "floor($total_seconds / 86400)")
	builtin set --local hours (math "floor(($total_seconds % 86400) / 3600)")
	builtin set --local minutes (math "floor(($total_seconds % 3600) / 60)")
	builtin set --local seconds (math "$total_seconds % 60")

	builtin set --local result ""

	if builtin test $days -gt 0
		builtin set result "$days""d "
	end

	if builtin test $days -gt 0 -o $hours -gt 0
		builtin set result "$result""$hours""h"
	end

	if builtin test $days -gt 0 -o $hours -gt 0 -o $minutes -gt 0
		builtin set result "$result""$minutes""m"
	end

	builtin set result "$result""$seconds""s"

	builtin echo "$result"
end
