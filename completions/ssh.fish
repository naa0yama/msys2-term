#!/usr/bin/env fish

# Custom host completions from FSSH_SSH_CONF_DIR
complete --command ssh --no-files --arguments '(__fssh_get_hosts)' --description 'SSH host'

# Common SSH options (avoid --wraps recursion issue)
complete --command ssh --short-option p --long-option port --description 'Port to connect to' --require-parameter
complete --command ssh --short-option i --description 'Identity file' --require-parameter --force-files
complete --command ssh --short-option l --long-option login_name --description 'Login name' --require-parameter
complete --command ssh --short-option o --description 'SSH option' --require-parameter
complete --command ssh --short-option F --description 'Config file' --require-parameter --force-files
complete --command ssh --short-option J --description 'Jump host' --require-parameter
complete --command ssh --short-option L --description 'Local port forward' --require-parameter
complete --command ssh --short-option R --description 'Remote port forward' --require-parameter
complete --command ssh --short-option D --description 'Dynamic port forward' --require-parameter
complete --command ssh --short-option N --description 'No remote command'
complete --command ssh --short-option T --description 'Disable pseudo-terminal'
complete --command ssh --short-option t --description 'Force pseudo-terminal'
complete --command ssh --short-option v --description 'Verbose mode'
complete --command ssh --short-option q --description 'Quiet mode'
complete --command ssh --short-option C --description 'Enable compression'
complete --command ssh --short-option X --description 'Enable X11 forwarding'
complete --command ssh --short-option Y --description 'Enable trusted X11 forwarding'
complete --command ssh --short-option A --description 'Enable agent forwarding'
complete --command ssh --short-option G --description 'Print configuration'
