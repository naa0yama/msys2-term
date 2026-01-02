#!/usr/bin/env fish

# Inherit completions from the original ssh command
complete --command ssh --wraps 'command ssh'

# Add custom host completions from FSSH_SSH_CONF_DIR
complete --command ssh --no-files --arguments '(__fssh_get_hosts)' --description 'SSH host'
