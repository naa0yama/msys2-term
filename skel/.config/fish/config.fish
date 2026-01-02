#!/usr/bin/env fish

#- -----------------------------------------------------------------------------
#- MSYS2 dedicated settings
#- -----------------------------------------------------------------------------
if set -q MSYSTEM
	# OpenSSH
	alias        ssh='/c/Program\ Files/OpenSSH/ssh.exe'
	alias    ssh-add='/c/Program\ Files/OpenSSH/ssh-add.exe'
	alias ssh-keygen='/c/Program\ Files/OpenSSH/ssh-keygen.exe'

	# Git
	alias        git='/c/Program\ Files/Git/cmd/git.exe'
end
