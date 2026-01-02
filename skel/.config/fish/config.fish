#!/usr/bin/env fish

# Fisher auto-setup: install plugins on first launch
if not functions --query fisher
	if builtin test -f ~/.config/fish/fish_plugins
		command curl --silent --location https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher update
	end
end
