#!/usr/bin/env fish

function __fssh_init_ssh_dirs --description 'Initialize SSH directories on first launch'
	# Determine SSH home directory
	# MSYS2: use Windows USERPROFILE, otherwise use $HOME
	builtin set --local ssh_home "$HOME"
	if builtin set --query MSYSTEM; and builtin set --query USERPROFILE
		builtin set ssh_home (cygpath --unix "$USERPROFILE")
	end

	builtin set --local ssh_dir "$ssh_home/.ssh"
	builtin set --local config_file "$ssh_dir/config"
	builtin set --local marker_file "$ssh_dir/.fssh_initialized"

	# Skip if already initialized
	if builtin test -f "$marker_file"
		return
	end

	# Create directories
	builtin set --local dirs \
		"$ssh_dir" \
		"$ssh_dir/conf.d" \
		"$ssh_dir/conf.d/cm" \
		"$ssh_dir/conf.d/envs" \
		"$ssh_dir/keys/private" \
		"$ssh_dir/keys/public"

	for dir in $dirs
		if not builtin test -d "$dir"
			command mkdir --parents "$dir"
			builtin echo "[fssh] Created: $dir"
		end
	end

	# Set permissions for keys directories
	command chmod 700 "$ssh_dir/keys/private" 2>/dev/null
	command chmod 755 "$ssh_dir/keys/public" 2>/dev/null

	# Create config file if not exists
	if not builtin test -f "$config_file"
		builtin echo "# SSH Config - managed by fssh
# Include environment-specific configs
Include conf.d/envs/*.conf

# ControlMaster settings
Host *
    ControlMaster auto
    ControlPath $ssh_dir/conf.d/cm/%C
    ControlPersist 10m
" > "$config_file"
		command chmod 600 "$config_file"
		builtin echo "[fssh] Created: $config_file"
	end

	# Create marker file
	command date +%Y-%m-%dT%H:%M:%S%z > "$marker_file"
	builtin echo "[fssh] SSH directories initialized"
end
