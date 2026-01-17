#!/usr/bin/env fish

function __fssh_ssh_is_dry_run --description 'Check if SSH args contain non-connecting options'
	# Options that don't make actual connections: -G, -V, -Q
	for arg in $argv
		switch $arg
			case -G -V -Q --help
				return 0
		end
	end
	return 1
end
