FROM ubuntu:latest

ENV CONFIG_FILE=/home/development/configuration.json

# Update and install dependencies
RUN apt-get update && \
	apt-get install -y jq bash sudo git && \
	apt-get clean && rm -rf /var/lib/apt/lists/*

# Create the development user and add to sudo group
RUN useradd -ms /bin/bash development && \
	usermod -aG sudo development && \
	echo 'development ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Copy the configuration
COPY --chown=development:development configuration.json /home/development/

# Install user-specified packages
RUN bash -eux <<'EOF'
	packages=$(jq -r '.packages[]' "$CONFIG_FILE")
	minimal_pkgs="jq bash sudo git"
	to_install=""
	for pkg in $packages; do
		if ! dpkg -s "$pkg" >/dev/null 2>&1; then
			to_install="$to_install $pkg"
		fi
	done
	if [ -n "$to_install" ]; then
		apt-get update && apt-get install -y $to_install && apt-get clean && rm -rf /var/lib/apt/lists/*
	fi
EOF

WORKDIR /home/development

# Clone repositories listed in configuration.json
RUN bash -eux <<'EOF'
	repos_count=$(jq '.repositories | length' "$CONFIG_FILE")
	for i in $(seq 0 $((repos_count - 1))); do
		url=$(jq -r ".repositories[$i].URL" "$CONFIG_FILE")
		dir=$(jq -r ".repositories[$i].directory" "$CONFIG_FILE")
		if [ ! -d "$dir/.git" ]; then
			git clone "$url" "$dir"
		else
			cd "$dir" && git pull
		fi
	done
EOF

# Fix ownership of all files under /home/development
RUN chown -R development:development /home/development

# Run user-specified post-build commands
RUN bash -eux <<'EOF'
	if jq -e '."post-build-commands"' "$CONFIG_FILE" >/dev/null; then
		cmd_count=$(jq '."post-build-commands" | length' "$CONFIG_FILE")
		for i in $(seq 0 $((cmd_count - 1))); do
			cmd=$(jq -r '."post-build-commands"['"$i"']' "$CONFIG_FILE")
			echo "Running command as development user: $cmd"
			sudo -u development bash -c "$cmd"
		done
	fi
EOF

# Create entrypoint script to run startup command
RUN cat <<'EOF' > /usr/local/bin/docker-entrypoint.sh
#!/bin/bash
startup_cmd=$(jq -r '.["startup-command"]' /home/development/configuration.json)
if [ -z "$startup_cmd" ] || [ "$startup_cmd" = "null" ]; then
	echo "No startup-command found, defaulting to bash."
	exec bash
else
	echo "Running startup-command: $startup_cmd"
	exec bash -c "$startup_cmd"
fi
EOF

RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Swap to development user
USER development

# Use the entrypoint script as the container entrypoint
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]