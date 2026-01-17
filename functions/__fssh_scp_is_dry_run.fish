#!/usr/bin/env fish

function __fssh_scp_is_dry_run --description 'Check if SCP args contain non-connecting options'
	# SCP has no equivalent to ssh -G, but we check for help-like options
	for arg in $argv
		switch $arg
			case --help -h
				return 0
		end
	end
	return 1
end
