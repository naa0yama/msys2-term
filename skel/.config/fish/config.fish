#!/usr/bin/env fish

# Fisher auto-setup: install plugins on first launch
if not functions --query fisher
	if not set --query _fisher_installing
		if builtin test -f ~/.config/fish/fish_plugins
			set --export _fisher_installing 1
			command curl --silent --location https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher update
			set --erase _fisher_installing
		end
	end
end
