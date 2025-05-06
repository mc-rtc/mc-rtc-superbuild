FROM ubuntu:noble as build
RUN userdel -r ubuntu
ARG EMAIL="devcontainer@mc-rtc-superbuild.com"
ARG NAME="mc_rtc devcontainer"

RUN export DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Paris
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Allow to keep apt cache between builds
RUN rm -f /etc/apt/apt.conf.d/docker-clean

# Install sudo
RUN  --mount=type=cache,target=/var/cache/apt \
  apt-get update \
 && apt-get install -y --no-install-recommends sudo ccache ripgrep rsync curl wget zsh gnupg2 gpg-agent openssh-server clangd \
 && rm -rf /var/lib/apt/lists/*

# Create ubuntu user with sudo privileges
RUN useradd -ms /bin/zsh vscode && \
    usermod -aG sudo vscode \
    # New added for disable sudo password
    && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
    && echo "User vscode (uid=`id -u vscode`:gid=`id -g vscode`) created with passwordless sudo privileges"

USER vscode

# Explicitely set ccache directory
# This ensures that ccache will always look here even if tools change the default cache location with XDG_CACHE_HOME (e.g nvim-remote)
ENV CCACHE_DIR=/home/vscode/.cache/ccache
ENV CYTHON_CACHE_DIR=/home/vscode/.cython

RUN --mount=type=cache,uid=1000,gid=1000,target=/home/vscode/.cache/ccache \
  if [ "$(ls -A ~/.cache/ccache)" ]; then \
    echo "Found ccache cache in the docker build cache, using it"; \
    du -h ~/.cache/ccache; \
    ccache -z; \
    ccache -sv; \
  else \
    echo "ccache mount directory is empty"; \
  fi

# Use cython cache (only for caching pyx to c conversion)
RUN --mount=type=cache,uid=1000,gid=1000,target=/home/vscode/.cython \
  if [ "$(ls -A ~/.cython)" ]; then \
    echo "Found cython cache, using it"; \
  else \
    echo "cython mount directory is empty"; \
  fi

# Add mc-rtc-superbuild to the build context
# Note that in theory this could be copied into a separate directory as the runtime workspace
# However due to generated config headers containing install source paths for mc_rtc
# It is better to keep it in the same folder in order to increase ccache hit rate
COPY --chown=vscode:vscode ../../.. /home/vscode/superbuild
WORKDIR /home/vscode/superbuild

RUN --mount=type=cache,target=/var/cache/apt \
  sudo chown -R vscode ~/.cache \
  && ./utils/bootstrap-linux.sh \
  && sudo apt-get install -y --no-install-recommends ccache gdb \
  && git config --global user.email "${EMAIL}" && git config --global user.name "${NAME}" \
  && sudo rm -rf /var/lib/apt/lists/*

# Configure CMake will install all APT/PIP dependencies (keep downloaded packages in mounted APT cache)
# Build everything to populate cache:
# - ccache in mounted cache ~/.cache/ccache
# - cython in ~/.cython
RUN --mount=type=cache,target=/var/cache/apt \
  --mount=type=cache,uid=1000,gid=1000,target=/home/vscode/.cache/pip \
  --mount=type=cache,uid=1000,gid=1000,target=/home/vscode/.cache/ccache \
  --mount=type=cache,uid=1000,gid=1000,target=/home/vscode/.cython \
  ccache -z \
  # FIXME: as of now mc_rtc does not build in devcontainer
  # && cmake --preset relwithdebinfo \
  # && cmake --build --preset relwithdebinfo \
  && echo "Removing temporary build artefacts from the image" \
  && rm -rf /home/vscode/superbuild \
  && rm /home/vscode/.gitconfig \
  && ccache -sv \
  && sudo rm -rf /var/lib/apt/lists/*

# Copy ccache/cython folder into the docker image's build cache.
# This enables reuse on the next build of this image
RUN --mount=type=cache,uid=1000,gid=1000,target=/home/vscode/.cache/ccache \
  ccache -z \
  && echo "Copying ccache /home/vscode/.cache/ccache to the temporary image folder /home/vscode/.cache/docker-ccache" \
  && cp -r /home/vscode/.cache/ccache /tmp/ccache

RUN echo "Moving the generated ccache cache to the image folder /home/vscode/.cache/ccache so that it can be used at runtime" \
  && sudo chown -R vscode ~/.cache \
  && ls -al ~/.cache \
  && mv /tmp/ccache /home/vscode/.cache/ccache

RUN --mount=type=cache,uid=1000,gid=1000,target=/home/vscode/.cython \
  echo "Copying cython cache /home/vscode/.cython to the temporary image folder /home/vscode/.cache/cython-cache" \
  && cp -r /home/vscode/.cython /home/vscode/.cache/cython-cache

RUN echo "Moving the generated cython cache to the image folder /home/vscode/.cache/cython so that it can be used at runtime" \
  && mv /home/vscode/.cache/cython-cache /home/vscode/.cython

RUN echo "Checking cache contents" \
  && ls /home/vscode/.cache/ccache \
  && ls /home/vscode/.cython

# oh-my-zsh & plugins
RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v1.2.1/zsh-in-docker.sh)" -- \
    -t 'bira' \
    -p git \
    && echo 'source $HOME/superbuild/.devcontainer/entrypoint.sh' >> /home/vscode/.zshrc

FROM ubuntu:22.04
COPY --from=build / /
LABEL org.opencontainers.image.source=https://github.com/mc-rtc/mc-rtc-superbuild
LABEL org.opencontainers.image.description="Development environment for mc-rtc-superbuild from source"
LABEL org.opencontainers.image.licenses=BSD-2
ENTRYPOINT ["/usr/bin/zsh", "-c"]
