FROM mcr.microsoft.com/devcontainers/cpp:ubuntu-22.04
ARG EMAIL="devcontainer@mc-rtc-superbuild.com"
ARG NAME="mc_rtc devcontainer"
ARG UBUNTU_VERSION="jammy"
ARG BUILD_IN_DOCKER=true

RUN export DEBIAN_FRONTEND=noninteractive

# Allow to keep apt cache between builds
RUN rm -f /etc/apt/apt.conf.d/docker-clean

# Install latest cmake version
RUN wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | tee /usr/share/keyrings/kitware-archive-keyring.gpg >/dev/null \
 && echo 'deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ jammy main' | sudo tee /etc/apt/sources.list.d/kitware.list >/dev/null \
 && apt update \
 && rm /usr/share/keyrings/kitware-archive-keyring.gpg \
 && apt-get install -y --no-install-recommends kitware-archive-keyring \
 && apt-get update \
 && apt-get install -y --no-install-recommends cmake cmake-curses-gui

RUN --mount=type=cache,target=/var/cache/apt \
  apt-get -y install --no-install-recommends ccache python3-venv python3-pip ripgrep cmake cmake-curses-gui


# Add mc-rtc-superbuild to the build context
USER vscode
# Git now forces you to have an email
RUN git config --global user.email "${EMAIL}" && git config --global user.name "${NAME}"

# Explicitely set ccache directory
# This ensures that ccache will always look here even if tools change the default cache location with XDG_CACHE_HOME (e.g nvim-remote)
ENV CCACHE_DIR=/home/vscode/.cache/ccache

RUN --mount=type=cache,uid=1000,gid=1000,target=/home/vscode/.cache/ccache \
  if [ "$(ls -A ~/.cache/ccache)" ]; then \
    echo "Found ccache cache in the docker build cache, using it"; \
    ls -l ~/.cache/ccache; \
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


# Note that in theory this could be copied into a separate directory as the runtime workspace
# However due to generated config headers containing install source paths for mc_rtc
# It is better to keep it in the same folder in order to increase ccache hit rate
COPY --chown=vscode:vscode ../../.. /home/vscode/workspace/mc-rtc-superbuild
WORKDIR /home/vscode/workspace/mc-rtc-superbuild

# Configure CMake will install all APT/PIP dependencies (keep downloaded packages in mounted APT cache)
# TODO: mount pip cache
RUN --mount=type=cache,target=/var/cache/apt \
  --mount=type=cache,uid=1000,gid=1000,target=/home/vscode/.cache/pip \
  --mount=type=cache,uid=1000,gid=1000,target=/home/vscode/.cache/ccache \
  --mount=type=cache,uid=1000,gid=1000,target=/home/vscode/.cython \
  cmake --preset relwithdebinfo-jammy

# Build everything to populate cache:
# - ccache in mounted cache ~/.cache/ccache
# - cython in ~/.cython
RUN --mount=type=cache,target=/var/cache/apt \
  --mount=type=cache,uid=1000,gid=1000,target=/home/vscode/.cache/pip \
  --mount=type=cache,uid=1000,gid=1000,target=/home/vscode/.cache/ccache \
  --mount=type=cache,uid=1000,gid=1000,target=/home/vscode/.cython \
  ccache -z \
  && cmake --build --preset relwithdebinfo-jammy \
  && ccache -sv

# Copy ccache/cython folder into the docker image's build cache.
# This enables reuse on the next build of this image
RUN --mount=type=cache,uid=1000,gid=1000,target=/home/vscode/.cache/ccache \
  ccache -z \
  && echo "Copying ccache /home/vscode/.cache/ccache to the temporary image folder /home/vscode/.cache/docker-ccache" \
  && cp -r /home/vscode/.cache/ccache /home/vscode/.cache/docker-ccache

RUN echo "Moving the generated ccache cache to the image folder /home/vscode/.cache/ccache so that it can be used at runtime" \
  && mv /home/vscode/.cache/docker-ccache /home/vscode/.cache/ccache

RUN --mount=type=cache,uid=1000,gid=1000,target=/home/vscode/.cython \
  echo "Copying cython cache /home/vscode/.cython to the temporary image folder /home/vscode/.cache/cython-cache" \
  && cp -r /home/vscode/.cython /home/vscode/.cache/cython-cache

RUN echo "Moving the generated cython cache to the image folder /home/vscode/.cache/cython so that it can be used at runtime" \
  && mv /home/vscode/.cache/cython-cache /home/vscode/.cython

RUN echo "Checking cache contents" \
  && ls /home/vscode/.cache/ccache \
  && ls /home/vscode/.cython

RUN echo "Removing temporary build artefacts from the image" \
  && rm -rf /home/vscode/workspace/mc-rtc-superbuild

ENTRYPOINT ["/bin/bash", "-c"]
