#!/usr/bin/env fish

function __check --description 'MSYS2 check'
	for command in "fish" "tmux" "fzf" "rg"
		if ! type --query "$command"
			echo "command $command"
			type "$command"
			return 1
		end
	end
end

if set -q MSYSTEM
	# MSYS2 専用設定

	# OpenSSH
	alias        ssh='/c/Program\ Files/OpenSSH/ssh.exe'
	alias    ssh-add='/c/Program\ Files/OpenSSH/ssh-add.exe'
	alias ssh-keygen='/c/Program\ Files/OpenSSH/ssh-keygen.exe'

	# Git
	alias        git='/c/Program\ Files/Git/cmd/git.exe'
end
