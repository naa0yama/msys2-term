#!/usr/bin/env fish

# Auto-start tmux on interactive login shell
if status is-login
	and status is-interactive
	and not builtin set --query TMUX
	and command --query tmux
	exec tmux new-session -A -s login-session
end

# Fisher auto-setup: install plugins on first launch
if not builtin functions --query fisher
	if not builtin set --query _fisher_installing
		if builtin test -f ~/.config/fish/fish_plugins
			builtin set --export _fisher_installing 1
			command curl --silent --location https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher update
			builtin set --erase _fisher_installing
		end
	end
end
