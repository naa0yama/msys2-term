#!/usr/bin/env fish

# Custom host completions from FSSH_SSH_CONF_DIR
complete --command ssh --no-files --arguments '(__fssh_get_hosts)' --description 'SSH host'

# SSH options (based on: ssh [-46AaCfGgKkMNnqsTtVvXxYy] [-B bind_interface] [-b bind_address]
#              [-c cipher_spec] [-D [bind_address:]port] [-E log_file]
#              [-e escape_char] [-F configfile] [-I pkcs11] [-i identity_file]
#              [-J destination] [-L address] [-l login_name] [-m mac_spec]
#              [-O ctl_cmd] [-o option] [-P tag] [-p port] [-R address]
#              [-S ctl_path] [-W host:port] [-w local_tun[:remote_tun]]
#              [-Q query_option])

# Options without arguments
complete --command ssh --short-option 4 --description 'Use IPv4 only'
complete --command ssh --short-option 6 --description 'Use IPv6 only'
complete --command ssh --short-option A --description 'Enable agent forwarding'
complete --command ssh --short-option a --description 'Disable agent forwarding'
complete --command ssh --short-option C --description 'Enable compression'
complete --command ssh --short-option f --description 'Go to background before command execution'
complete --command ssh --short-option G --description 'Print configuration and exit'
complete --command ssh --short-option g --description 'Allow remote hosts to connect to local forwarded ports'
complete --command ssh --short-option K --description 'Enable GSSAPI authentication'
complete --command ssh --short-option k --description 'Disable GSSAPI credential forwarding'
complete --command ssh --short-option M --description 'Master mode for connection sharing'
complete --command ssh --short-option N --description 'Do not execute remote command'
complete --command ssh --short-option n --description 'Redirect stdin from /dev/null'
complete --command ssh --short-option q --description 'Quiet mode'
complete --command ssh --short-option s --description 'Request subsystem invocation'
complete --command ssh --short-option T --description 'Disable pseudo-terminal allocation'
complete --command ssh --short-option t --description 'Force pseudo-terminal allocation'
complete --command ssh --short-option V --description 'Display version and exit'
complete --command ssh --short-option v --description 'Verbose mode'
complete --command ssh --short-option X --description 'Enable X11 forwarding'
complete --command ssh --short-option x --description 'Disable X11 forwarding'
complete --command ssh --short-option Y --description 'Enable trusted X11 forwarding'
complete --command ssh --short-option y --description 'Send log to syslog instead of stderr'

# Options with arguments
complete --command ssh --short-option B --description 'Bind to interface' --require-parameter
complete --command ssh --short-option b --description 'Bind to address' --require-parameter
complete --command ssh --short-option c --description 'Cipher specification' --require-parameter
complete --command ssh --short-option D --description 'Dynamic port forwarding (SOCKS proxy)' --require-parameter
complete --command ssh --short-option E --description 'Append log to file' --require-parameter --force-files
complete --command ssh --short-option e --description 'Escape character' --require-parameter
complete --command ssh --short-option F --description 'Configuration file' --require-parameter --force-files
complete --command ssh --short-option I --description 'PKCS#11 shared library' --require-parameter --force-files
complete --command ssh --short-option i --description 'Identity file' --require-parameter --force-files
complete --command ssh --short-option J --description 'Jump host (ProxyJump)' --require-parameter
complete --command ssh --short-option L --description 'Local port forwarding' --require-parameter
complete --command ssh --short-option l --description 'Login name' --require-parameter
complete --command ssh --short-option m --description 'MAC specification' --require-parameter
complete --command ssh --short-option O --description 'Control multiplexed connection' --require-parameter
complete --command ssh --short-option o --description 'SSH option' --require-parameter
complete --command ssh --short-option P --description 'Tag for connection' --require-parameter
complete --command ssh --short-option p --description 'Port to connect to' --require-parameter
complete --command ssh --short-option Q --description 'Query supported algorithms' --require-parameter
complete --command ssh --short-option R --description 'Remote port forwarding' --require-parameter
complete --command ssh --short-option S --description 'Control socket path' --require-parameter --force-files
complete --command ssh --short-option W --description 'Forward stdin/stdout to host:port' --require-parameter
complete --command ssh --short-option w --description 'Tunnel device forwarding' --require-parameter
