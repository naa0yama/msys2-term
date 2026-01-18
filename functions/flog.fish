#!/usr/bin/env fish

function flog --description 'Select and view fterm log files'
	if not builtin set --query FTERM_LOG_DIR_PREFIX; or not builtin test -d "$FTERM_LOG_DIR_PREFIX"
		builtin echo "flog: FTERM_LOG_DIR_PREFIX is not set or directory does not exist" >&2
		return 1
	end

	builtin set --local find_cmd "find '$FTERM_LOG_DIR_PREFIX' -type f \\( -name '*.log' -o -name '*.log.gz' \\) 2>/dev/null | sort --reverse"
	builtin set --local search_cmd "rg --search-zip --color=always --line-number --no-heading --smart-case -- {q} '$FTERM_LOG_DIR_PREFIX' 2>/dev/null || true"

	builtin set --local log_file_path (
		command find "$FTERM_LOG_DIR_PREFIX" -type f \( -name "*.log" -o -name "*.log.gz" \) 2>/dev/null | command sort --reverse | \
		command fzf \
			--prompt="[File] > " \
			--exact --height=90% --reverse --border --ansi \
			--header="ctrl-s: Search mode | ctrl-j/k: Preview scroll" \
			--preview='f={}; if [[ $f == *.gz ]]; then zcat "$f" 2>/dev/null | head --lines=500; else head --lines=500 "$f" 2>/dev/null; fi' \
			--preview-window='right:60%:wrap' \
			--bind="ctrl-j:preview-down,ctrl-k:preview-up" \
			--bind="ctrl-d:preview-page-down,ctrl-u:preview-page-up" \
			--bind="ctrl-s:change-prompt([Search] > )+disable-search+reload($search_cmd)+rebind(change)+change-preview-window(hidden)+change-header(ctrl-f: File mode | Type to search content)" \
			--bind="ctrl-f:change-prompt([File] > )+enable-search+reload($find_cmd)+unbind(change)+change-preview-window(right:60%:wrap)+change-header(ctrl-s: Search mode | ctrl-j/k: Preview scroll)" \
			--bind="change:reload:sleep 0.1; $search_cmd" \
			--bind="start:unbind(change)" \
			--delimiter=: --nth=1
	)

	if builtin test -n "$log_file_path"
		# Extract file path from search result (format: filepath:line:content)
		if builtin string match --quiet "*.log:*" "$log_file_path"; or builtin string match --quiet "*.log.gz:*" "$log_file_path"
			builtin set log_file_path (builtin echo "$log_file_path" | command sed --regexp-extended 's/(\.log|\.log\.gz):.*/\1/')
		end

		if builtin string match --quiet "*.gz" "$log_file_path"
			builtin commandline "zcat '$log_file_path' | less"
		else
			builtin commandline "less '$log_file_path'"
		end
	end
end
