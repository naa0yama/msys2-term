#!/usr/bin/env fish

# Fuzzy Term (fterm): Configuration and MSYS2 setup

# Debug mode: set FTERM_DEBUG=true to enable debug output
# Example: set --global FTERM_DEBUG true

# Debug output function (inline for conf.d, before functions are loaded)
function __fterm_debug_init --description 'Debug output for init phase'
	if builtin set --query FTERM_DEBUG; and builtin test "$FTERM_DEBUG" = true
		set_color brblack >&2
		builtin echo "[DEBUG:init] $argv" >&2
		set_color normal >&2
	end
end

# Default configuration (override these in your config.fish)
# MSYS2: use Windows userprofile, otherwise use $HOME
if builtin set --query MSYSTEM; and builtin set --query USERPROFILE
	builtin set --local win_home "$(cygpath -u "$USERPROFILE")"
	builtin set --query FSSH_SSH_CONF_DIR;		or builtin set --global FSSH_SSH_CONF_DIR "$win_home/.ssh/conf.d/envs"
	builtin set --query FTERM_LOG_DIR_PREFIX;	or builtin set --global FTERM_LOG_DIR_PREFIX "$win_home/.dotfiles/logs/tmux/"
	__fterm_debug_init "MSYS2 detected: MSYSTEM=$MSYSTEM"
	__fterm_debug_init "USERPROFILE=$USERPROFILE"
	__fterm_debug_init "win_home=$win_home"
else
	builtin set --query FSSH_SSH_CONF_DIR;		or builtin set --global FSSH_SSH_CONF_DIR "$HOME/.ssh/conf.d/envs"
	builtin set --query FTERM_LOG_DIR_PREFIX;	or builtin set --global FTERM_LOG_DIR_PREFIX "$HOME/.dotfiles/logs/tmux/"
	__fterm_debug_init "Non-MSYS2 environment"
end
builtin set --query FTERM_SSH_WIN_DIR;			or builtin set --global FTERM_SSH_WIN_DIR "/c/Program Files/OpenSSH"
builtin set --query FTERM_SSH_WIN_GIT_DIR;		or builtin set --global FTERM_SSH_WIN_GIT_DIR "/c/Program Files/Git/cmd"

__fterm_debug_init "FSSH_SSH_CONF_DIR=$FSSH_SSH_CONF_DIR"
__fterm_debug_init "FTERM_LOG_DIR_PREFIX=$FTERM_LOG_DIR_PREFIX"
__fterm_debug_init "FTERM_SSH_WIN_DIR=$FTERM_SSH_WIN_DIR"
__fterm_debug_init "FTERM_SSH_WIN_GIT_DIR=$FTERM_SSH_WIN_GIT_DIR"

# Fisher plugin install event
function _fssh_install --on-event fssh_install
	# Initialize SSH directories
	__fssh_init_ssh_dirs

	# Dependency check
	builtin set --local deps ansifilter awk curl find fzf gzip rg ssh ssh-add tmux zcat
	builtin set --local missing

	for cmd in $deps
		if not type --query "$cmd"
			builtin set --append missing "$cmd"
		end
	end

	if builtin test (count $missing) -gt 0
		set_color yellow
		builtin echo "[fssh] Missing commands: $missing"
		builtin echo "[fssh] Some features may not work without these."
		set_color normal
	else
		set_color green
		builtin echo "[fssh] All dependencies found."
		set_color normal
	end
end

# Fisher plugin uninstall event
function _fssh_uninstall --on-event fssh_uninstall
	builtin set --erase __fssh_ssh_cmd
	builtin set --erase __fssh_scp_cmd
	builtin set --erase __fssh_ssh_add_cmd
	builtin set --erase __fssh_ssh_keygen_cmd
	builtin set --erase __fssh_ssh_config
	builtin set --erase FTERM_DEBUG
	builtin set --erase FTERM_FISHER_UPDATE_CHECK
	builtin set --erase FTERM_FISHER_UPDATE_INTERVAL
end

# MSYS2 environment detection and SSH configuration
if builtin set --query MSYSTEM
	# Set SSH command path for MSYS2
	if builtin test -x "$FTERM_SSH_WIN_DIR/ssh.exe"
		builtin set --global --export __fssh_ssh_cmd "$FTERM_SSH_WIN_DIR/ssh.exe"
		builtin set --global --export __fssh_scp_cmd "$FTERM_SSH_WIN_DIR/scp.exe"
		builtin set --global --export __fssh_ssh_add_cmd "$FTERM_SSH_WIN_DIR/ssh-add.exe"
		builtin set --global --export __fssh_ssh_keygen_cmd "$FTERM_SSH_WIN_DIR/ssh-keygen.exe"

		# Windows SSH config path (use cygpath -m for mixed path - forward slashes work on Windows)
		builtin set --global --export __fssh_ssh_config "$(cygpath -m "$USERPROFILE/.ssh/config")"

		__fterm_debug_init "__fssh_ssh_cmd=$__fssh_ssh_cmd"
		__fterm_debug_init "__fssh_scp_cmd=$__fssh_scp_cmd"
		__fterm_debug_init "__fssh_ssh_add_cmd=$__fssh_ssh_add_cmd"
		__fterm_debug_init "__fssh_ssh_keygen_cmd=$__fssh_ssh_keygen_cmd"
		__fterm_debug_init "__fssh_ssh_config=$__fssh_ssh_config"

		function ssh-add --wraps="$__fssh_ssh_add_cmd" --description "alias ssh-add"
			"$__fssh_ssh_add_cmd" $argv
		end
		function ssh-keygen --wraps="$__fssh_ssh_keygen_cmd" --description "alias ssh-keygen"
			"$__fssh_ssh_keygen_cmd" $argv
		end
		__fterm_debug_init "Functions created: ssh-add, ssh-keygen (scp is defined in functions/scp.fish)"
	else
		__fterm_debug_init "Windows OpenSSH not found at $FTERM_SSH_WIN_DIR/ssh.exe"
	end

	# Git for Windows
	if builtin test -x "$FTERM_SSH_WIN_GIT_DIR/git.exe"
		function git --wraps="$FTERM_SSH_WIN_GIT_DIR/git.exe" --description "alias git"
			"$FTERM_SSH_WIN_GIT_DIR/git.exe" $argv
		end
		__fterm_debug_init "Function created: git -> $FTERM_SSH_WIN_GIT_DIR/git.exe"
	else
		__fterm_debug_init "Git for Windows not found at $FTERM_SSH_WIN_GIT_DIR/git.exe"
	end
end

# Cleanup init debug function
functions --erase __fterm_debug_init
