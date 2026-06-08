# Flutter SDK + Dart + Android SDK + git baked in (cirruslabs images live on GHCR)
FROM ghcr.io/cirruslabs/flutter:stable

# --- Node 20 (for Claude Code CLI) + dev CLI tools ---
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y --no-install-recommends \
        nodejs \
        gh \
        ripgrep \
        fd-find \
        jq \
        ca-certificates \
        openssh-server \
        tmux \
    # fd ships as `fdfind` on Debian/Ubuntu; expose the usual `fd` name
    && ln -sf "$(command -v fdfind)" /usr/local/bin/fd \
    # yq (mikefarah) — not packaged reliably, grab the static binary
    && curl -fsSL https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 \
        -o /usr/local/bin/yq \
    && chmod +x /usr/local/bin/yq \
    && rm -rf /var/lib/apt/lists/*

# --- supercronic (non-root cron for Docker) ---
RUN curl -fsSL https://github.com/aptible/supercronic/releases/latest/download/supercronic-linux-amd64 \
    -o /usr/local/bin/supercronic \
    && chmod +x /usr/local/bin/supercronic

# --- Claude Code CLI ---
RUN npm install -g @anthropic-ai/claude-code

# --- non-root user (Claude refuses --dangerously-skip-permissions as root) ---
# base image already occupies UID/GID 1000, so use 1001 to avoid collision
ARG UID=1001
ARG GID=1001
RUN groupadd -g ${GID} dev 2>/dev/null || true \
    && useradd -m -u ${UID} -g ${GID} -s /bin/bash dev \
    && mkdir -p /workspace /home/dev/.pub-cache /home/dev/.claude /home/dev/.gradle /home/dev/.local/bin \
    && chown -R dev:dev /workspace /home/dev \
    # let non-root user use the baked-in Flutter SDK
    && git config --system --add safe.directory /sdks/flutter \
    && git config --system --add safe.directory /workspace \
    && chown -R dev:dev /sdks/flutter

# baked-in seed for Claude settings; entrypoint merges it into the
# (volume-mounted) ~/.claude/settings.json at container start
COPY --chown=dev:dev claude-settings.seed.json /opt/claude/settings.seed.json
COPY --chown=dev:dev orchestrators.crontab /opt/claude/orchestrators.crontab
COPY --chown=dev:dev entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Pre-install NDK required by Flutter 3.44+ (28.2.13676358) so agents don't hit
# the read-only /opt/android-sdk-linux at build time and OOM trying /tmp fallback.
RUN sdkmanager "ndk;28.2.13676358"

USER dev
WORKDIR /workspace
ENV PATH="/home/dev/.local/bin:/home/dev/.pub-cache/bin:${PATH}"

# --- rtk (Rust Token Killer) — installs to ~/.local/bin ---
RUN curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bash"]
