#!/usr/bin/env fish

# Custom host completions from FSSH_SSH_CONF_DIR for scp
# Generates completions in the format: host: (for remote paths)
complete --command scp --arguments '(__fssh_get_hosts | string replace -r "\$" ":")' --description 'SSH host'

# SCP options (based on: scp [-346ABCOpqRrsTv] [-c cipher] [-D sftp_server_path]
#              [-F ssh_config] [-i identity_file] [-J destination] [-l limit]
#              [-o ssh_option] [-P port] [-S program] [-X sftp_option])

# Options without arguments
complete --command scp --short-option 3 --description 'Copy through local host'
complete --command scp --short-option 4 --description 'Use IPv4 only'
complete --command scp --short-option 6 --description 'Use IPv6 only'
complete --command scp --short-option A --description 'Enable agent forwarding'
complete --command scp --short-option B --description 'Batch mode (no password prompts)'
complete --command scp --short-option C --description 'Enable compression'
complete --command scp --short-option O --description 'Use legacy SCP protocol'
complete --command scp --short-option p --description 'Preserve modification times'
complete --command scp --short-option q --description 'Quiet mode'
complete --command scp --short-option R --description 'Remote to remote copy'
complete --command scp --short-option r --description 'Recursively copy directories'
complete --command scp --short-option s --description 'Use SFTP protocol'
complete --command scp --short-option T --description 'Disable strict filename checking'
complete --command scp --short-option v --description 'Verbose mode'

# Options with arguments
complete --command scp --short-option c --description 'Cipher to use' --require-parameter
complete --command scp --short-option D --description 'SFTP server path' --require-parameter --force-files
complete --command scp --short-option F --description 'SSH config file' --require-parameter --force-files
complete --command scp --short-option i --description 'Identity file' --require-parameter --force-files
complete --command scp --short-option J --description 'Jump host' --require-parameter
complete --command scp --short-option l --description 'Limit bandwidth (Kbit/s)' --require-parameter
complete --command scp --short-option o --description 'SSH option' --require-parameter
complete --command scp --short-option P --description 'Port to connect to' --require-parameter
complete --command scp --short-option S --description 'SSH program to use' --require-parameter --force-files
complete --command scp --short-option X --description 'SFTP option' --require-parameter
