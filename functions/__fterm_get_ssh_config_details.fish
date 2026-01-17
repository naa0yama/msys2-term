#!/usr/bin/env fish

function __fterm_get_ssh_config_details --description 'Get non-default SSH config for logging'
	builtin set --local ssh_cmd "$(__fterm_get_ssh_cmd)"
	builtin set --local config_args (__fterm_get_ssh_config_args)
	builtin set --local target "$argv[1]"

	# Set HOME for Windows OpenSSH to resolve Include paths correctly
	builtin set --local original_home "$HOME"
	if builtin set --query MSYSTEM; and builtin set --query USERPROFILE
		builtin set --export HOME "$(cygpath -m "$USERPROFILE")"
	end

	# Extract important non-default options
	command "$ssh_cmd" $config_args -G "$target" 2>/dev/null | awk '
		/^proxyjump / && $2 != "none" { print "ProxyJump: " $2 }
		/^proxycommand / && $2 != "none" { $1=""; print "ProxyCommand:" $0 }
		/^identityfile / { print "IdentityFile: " $2 }
		/^identitiesonly / { print "IdentitiesOnly: " $2 }
		/^forwardagent / && $2 == "yes" { print "ForwardAgent: yes" }
		/^localforward / { print "LocalForward: " $2 " " $3 }
		/^remoteforward / { print "RemoteForward: " $2 " " $3 }
		/^dynamicforward / && $2 != "none" { print "DynamicForward: " $2 }
	'

	# Restore original HOME
	if builtin test -n "$original_home"
		builtin set --export HOME "$original_home"
	end
end
