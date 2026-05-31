# Flutter SDK + Dart + Android SDK + git baked in (cirruslabs images live on GHCR)
FROM ghcr.io/cirruslabs/flutter:stable

# --- Node 20 (for Claude Code CLI) ---
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# --- Claude Code CLI ---
RUN npm install -g @anthropic-ai/claude-code

# --- non-root user (Claude refuses --dangerously-skip-permissions as root) ---
# base image already occupies UID/GID 1000, so use 1001 to avoid collision
ARG UID=1001
ARG GID=1001
RUN groupadd -g ${GID} dev 2>/dev/null || true \
    && useradd -m -u ${UID} -g ${GID} -s /bin/bash dev \
    && mkdir -p /workspace /home/dev/.pub-cache /home/dev/.claude /home/dev/.gradle \
    && chown -R dev:dev /workspace /home/dev \
    # let non-root user use the baked-in Flutter SDK
    && git config --system --add safe.directory /sdks/flutter \
    && chown -R dev:dev /sdks/flutter

USER dev
WORKDIR /workspace
ENV PATH="/home/dev/.pub-cache/bin:${PATH}"

CMD ["bash"]
