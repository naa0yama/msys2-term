#!/usr/bin/env fish

# msys2-term: Configuration and MSYS2 setup

# Default configuration (override these in your config.fish)
# MSYS2: use Windows userprofile, otherwise use $HOME
if builtin set --query MSYSTEM; and builtin set --query USERPROFILE
	builtin set --local win_home (cygpath -u "$USERPROFILE")
	builtin set --query FSSH_SSH_CONF_DIR;		or builtin set --global FSSH_SSH_CONF_DIR "$win_home/.ssh/conf.d/envs"
	builtin set --query FSSH_LOG_DIR_PREFIX;	or builtin set --global FSSH_LOG_DIR_PREFIX "$win_home/.dotfiles/logs/tmux/"
else
	builtin set --query FSSH_SSH_CONF_DIR;		or builtin set --global FSSH_SSH_CONF_DIR "$HOME/.ssh/conf.d/envs"
	builtin set --query FSSH_LOG_DIR_PREFIX;	or builtin set --global FSSH_LOG_DIR_PREFIX "$HOME/.dotfiles/logs/tmux/"
end
builtin set --query FSSH_WIN_SSH_DIR;			or builtin set --global FSSH_WIN_SSH_DIR "/c/Program Files/OpenSSH"
builtin set --query FSSH_WIN_GIT_DIR;			or builtin set --global FSSH_WIN_GIT_DIR "/c/Program Files/Git/cmd"

# Dependency check on install
function _msys2_term_install --on-event msys2-term_install
	builtin set --local deps ansifilter awk find fzf rg ssh ssh-add tmux
	builtin set --local missing

	for cmd in $deps
		if not type --query $cmd
			builtin set --append missing $cmd
		end
	end

	if builtin test (count $missing) -gt 0
		set_color yellow
		builtin echo "[msys2-term] Missing commands: $missing"
		builtin echo "[msys2-term] Some features may not work without these."
		set_color normal
	else
		set_color green
		builtin echo "[msys2-term] All dependencies found."
		set_color normal
	end
end

function _msys2_term_uninstall --on-event msys2-term_uninstall
	builtin set --erase __fssh_ssh_cmd
	builtin set --erase __fssh_ssh_add_cmd
	builtin set --erase __fssh_ssh_keygen_cmd
	builtin set --erase __fssh_ssh_config
end

# MSYS2 environment detection and SSH configuration
if builtin set --query MSYSTEM
	# Set SSH command path for MSYS2
	if builtin test -x "$FSSH_WIN_SSH_DIR/ssh.exe"
		builtin set --global --export __fssh_ssh_cmd "$FSSH_WIN_SSH_DIR/ssh.exe"
		builtin set --global --export __fssh_ssh_add_cmd "$FSSH_WIN_SSH_DIR/ssh-add.exe"
		builtin set --global --export __fssh_ssh_keygen_cmd "$FSSH_WIN_SSH_DIR/ssh-keygen.exe"

		# Windows SSH config path (Windows path format for ssh.exe -F option)
		builtin set --global --export __fssh_ssh_config (cygpath -w "$USERPROFILE/.ssh/config")

		alias ssh-add="$__fssh_ssh_add_cmd"
		alias ssh-keygen="$__fssh_ssh_keygen_cmd"
	end

	# Git for Windows
	if builtin test -x "$FSSH_WIN_GIT_DIR/git.exe"
		alias git="$FSSH_WIN_GIT_DIR/git.exe"
	end
end
