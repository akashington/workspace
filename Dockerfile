FROM ubuntu:latest

ENV CONFIG_FILE=/home/development/configuration.json

RUN apt-get update && \
	apt-get install -y jq bash sudo git && \
	apt-get clean && rm -rf /var/lib/apt/lists/*

RUN useradd -ms /bin/bash development && \
	usermod -aG sudo development && \
	echo 'development ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

COPY --chown=development:development configuration.json /home/development/

RUN set -eux; \
	packages=$(jq -r '.packages[]' "$CONFIG_FILE"); \
	minimal_pkgs="jq bash sudo git"; \
	to_install=""; \
	for pkg in $packages; do \
		if ! dpkg -s "$pkg" >/dev/null 2>&1; then \
			to_install="$to_install $pkg"; \
		fi; \
	done; \
	if [ -n "$to_install" ]; then \
		apt-get update && apt-get install -y $to_install && apt-get clean && rm -rf /var/lib/apt/lists/*; \
	fi

WORKDIR /home/development

# Clone repositories listed in configuration.json
RUN set -eux; \
	repos_count=$(jq '.repositories | length' "$CONFIG_FILE"); \
	for i in $(seq 0 $((repos_count - 1))); do \
		url=$(jq -r ".repositories[$i].URL" "$CONFIG_FILE"); \
		dir=$(jq -r ".repositories[$i].directory" "$CONFIG_FILE"); \
		if [ ! -d "$dir/.git" ]; then \
			git clone "$url" "$dir"; \
		else \
			cd "$dir" && git pull; \
		fi; \
	done

# Run user-specified post-build commands
RUN set -eux; \
	if jq -e '."post-build-commands"' "$CONFIG_FILE" >/dev/null; then \
		cmd_count=$(jq '."post-build-commands" | length' "$CONFIG_FILE"); \
		for i in $(seq 0 $((cmd_count - 1))); do \
			cmd=$(jq -r '."post-build-commands"['"$i"']' "$CONFIG_FILE"); \
			echo "Running command as development user: $cmd"; \
			sudo -u development bash -c "$cmd"; \
		done; \
	fi

# Swap to development user
USER development

CMD ["bash", "-c", "vim; exec bash"]
