#!/usr/bin/env bash

# Switch to fish shell (only for login shells)
if shopt -q login_shell; then
	exec fish --login
fi
