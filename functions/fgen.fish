#!/usr/bin/env fish

function fgen --description 'Generate SSH config from template'
	# Get SSH home directory
	builtin set --local ssh_home (__fssh_get_ssh_home)
	builtin set --local envs_dir "$ssh_home/conf.d/envs"
	builtin set --local template_file "$HOME/.ssh/template.conf"

	# Create template if not exists
	if not builtin test -f "$template_file"
		set_color yellow
		builtin echo "[INFO ] Creating template file: $template_file"
		set_color normal

		builtin echo '# - ----------------------------------------------------------------------------
# - Hosts
# - ----------------------------------------------------------------------------
# - options                             parameters
Host org.env.bastion
	HostName			bastion.example.com

Host org.env.bastion-in-node1
	HostName			192.0.2.1
	ProxyJump			org.env.bastion


# - ----------------------------------------------------------------------------
# - Defaults
# - ----------------------------------------------------------------------------
# - options                             parameters
Host org.env.*
	User				naaoyama
	IdentitiesOnly			yes
	IdentityFile			~/.ssh/keys/public/org_env.pem
	Port				22
' >"$template_file"

		set_color green
		builtin echo "[INFO ] Template created. Please edit it before running fgen again."
		set_color normal
		builtin echo "        $template_file"
		return 0
	end

	# Prompt for organization
	builtin set --local org
	while builtin test -z "$org"
		builtin read --prompt-str "Organization (e.g., mycompany): " org
		if builtin test -z "$org"
			set_color yellow
			builtin echo "[WARN ] Organization cannot be empty"
			set_color normal
		end
	end

	# Prompt for environment
	builtin set --local env
	while builtin test -z "$env"
		builtin read --prompt-str "Environment (e.g., dev, stg, prod): " env
		if builtin test -z "$env"
			set_color yellow
			builtin echo "[WARN ] Environment cannot be empty"
			set_color normal
		end
	end

	# Create output directory
	builtin set --local output_dir "$envs_dir/$org"
	builtin set --local output_file "$output_dir/$env.conf"

	if not builtin test -d "$output_dir"
		command mkdir --parents "$output_dir"
		builtin echo "[INFO ] Created directory: $output_dir"
	end

	# Check if output file already exists
	if builtin test -f "$output_file"
		set_color yellow
		builtin echo "[WARN ] File already exists: $output_file"
		set_color normal
		builtin read --prompt-str "Overwrite? [y/N]: " confirm
		if not string match --quiet --ignore-case y "$confirm"
			builtin echo "[INFO ] Aborted"
			return 0
		end
	end

	# Generate config by replacing org and env placeholders
	# Replace "org.dev." with "<org>.<env>." and "org.env." with "<org>.<env>."
	# Also replace standalone "org_dev" patterns in paths
	command sed \
		-e "s/org\.dev\./$org.$env./g" \
		-e "s/org\.env\./$org.$env./g" \
		-e "s/org_dev/$org""_$env/g" \
		-e "s/org_env/$org""_$env/g" \
		"$template_file" >"$output_file"

	if builtin test $status -eq 0
		set_color green
		builtin echo "[INFO ] Generated: $output_file"
		set_color normal
		builtin echo ""
		builtin echo "Host prefix: $org.$env."
		builtin echo ""
		builtin echo "Preview:"
		command head --lines=20 "$output_file"
	else
		set_color red
		builtin echo "[ERROR] Failed to generate config"
		set_color normal
		return 1
	end
end
