# Copyright 2025 CNRS-UM LIRMM, CNRS-AIST JRL
#
# This Dockerfile is responsible for creating standalone/devcontainer docker images from a mc-rtc-superbuild repository.
#
# There are two main build-modes, controlled by BUILD_VERSION argument:
# - devcontainer:
#     contains the tools needed to work with mc-rtc, pre-builds the whole superbuild to generate a ccache compilation
#     cache that can then be used at runtime to speed up compilation (a few minutes for the first full build).
#     This is intended to be built by a devcontainer.json file to add additional tools into the image
#
# - standalone:
#     this mode installs mc-rtc-superbuild and keeps only the install folder in the image.
#     this is intended for releases, and the user will typically provide his own entrypoint.sh script to run
#     a specific controller/simulator/tool upon execution. The default entrypoint is meant as an interactive zsh terminal
#
# In addition to these two default modes, it is possible to override some arguments to influence what is generated in the final image.
# For instance one can create a standalone version that keeps the sources/build/install folder within the image
# $ podman build --ssh default . \
#        --file .github/devcontainer/Dockerfile \
#        --build-args BUILD_VERSION=devcontainer \
#        --build-args KEEP_SOURCES=true \
#        --build-args KEEP_BUILD=true \
#        --build-args KEEP_INSTALL=true \
#        --build-args KEEP_SOURCES=true \
#        --build-args KEEP_CCACHE=true \
#        -t mc-rtc-superbuild-snapshot-devcontainer

# This will generate a very large image (~20Gb) that contains a snapshot of the full environment needed to reproduce the superbuild.
#
# For a standard standalone release:
# $ podman build --ssh default . \
#        --file .github/devcontainer/Dockerfile \
#        --build-args BUILD_VERSION=standalone \
#        --build-args CUSTOM_ENTRYPOINT=</path/to/an/entrypoint/file> \ # the entrypoint file should be in the build context
#        -t mc-rtc-superbuild-standalone
#
# To build private repositories, you need to have ssh-agent forwarding configured. You can add the following to your bashrc:
# # Run the ssh-agent
# eval $(ssh-agent -s)
# # Register the private key with the agent
# ssh-add ~/.ssh/id_rsa
#
# and you need to provide '--ssh default' argument to podman/docker when building the image

ARG UBUNTU_VERSION="jammy"

# First stage build mc-rtc-superbuild and generates ccache
FROM ubuntu:$UBUNTU_VERSION as build

ARG UBUNTU_VERSION="jammy"
# Choices are devcontainer, standalone
ARG BUILD_VERSION="devcontainer"
ARG CMAKE_PRESET="relwithdebinfo"
# - KEEP_SOURCE=""      : do the default action for the  BUILD_VERSION (do not keep sources)
# - KEEP_SOURCE="false" : do not keep sources
# - KEEP_SOURCE="true"  : keep sources regardless of BUILD_VERSION
ARG KEEP_SOURCES=""
# Same as KEEP_SOURCES but for the build folder
ARG KEEP_BUILD=""
ARG KEEP_CCACHE=""
# Same as KEEP_SOURCES but for the install folder
ARG KEEP_INSTALL=""
ARG SSH_KNOWN_HOSTS="github.com gite.lirmm.fr"
# Build time cache directory to speed up sucessive rebuilds of this image
# This is kept into the docker cache
ARG CCACHE_BUILD_DIR=/tmp/ccache
# When KEEP_CCACHE=true, the ccache cache generated in CCACHE_BUILD_DIR is copied to the CCACHE_IMAGE_DIR for fast initial build times when using this image
ARG CCACHE_IMAGE_DIR=/home/vscode/.cache/ccache
# During build phase, use build time ccache directory (mounted in docker build cache)
ENV CCACHE_DIR=${CCACHE_BUILD_DIR}
ARG ZSH_THEME="bira"


ARG APT_PACKAGES_STANDALONE="sudo gnupg2 gpg-agent openssh-server openssh-client wget curl ca-certificates git ccache"
ARG APT_PACKAGES_DEVCONTAINER="sudo gnupg2 gpg-agent openssh-server wget curl ca-certificates ripgrep rsync clangd git ccache"
ARG EMAIL="devcontainer@mc-rtc-superbuild.com"
ARG NAME="mc_rtc devcontainer"

ENV UBUNTU_VERSION="$UBUNTU_VERSION"
ENV SUPERBUILD_DIR="/home/vscode/superbuild"
ENV WORKSPACE_DIR="/home/vscode/workspace"
ENV WORKSPACE_INSTALL_DIR="/home/vscode/workspace/install"
ENV WORKSPACE_DEVEL_DIR="/home/vscode/workspace/devel"
ENV WORKSPACE_BUILD_DIR="/home/vscode/workspace/build"

RUN export DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Paris
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone;


RUN echo "Building with ARGS:" \
 && echo "CMAKE_PRESET=$CMAKE_PRESET" \
 && echo "BUILD_VERSION=$BUILD_VERSION" \
 && echo "KEEP_SOURCES=$KEEP_SOURCES" \
 && echo "KEEP_BUILD=$KEEP_BUILD" \
 && echo "KEEP_CCACHE=$KEEP_CCACHE" \
 && echo "KEEP_INSTALL=$KEEP_INSTALL" \
 && echo "UBUNTU_VERSION=$UBUNTU_VERSION" \
 && echo "APT_PACKAGES_STANDALONE=$APT_PACKAGES_STANDALONE" \
 && echo "APT_PACKAGES_DEVCONTAINER=$APT_PACKAGES_DEVCONTAINER"

RUN echo "Building with ENV:" \
  && export

# Allow to keep apt cache between builds
RUN rm -f /etc/apt/apt.conf.d/docker-clean;

# Install basic dependencies
RUN --mount=type=cache,target=/var/cache/apt \
  apt-get update \
  && \
  if [ "$BUILD_VERSION" = "devcontainer" ]; then \
    apt-get install -y --no-install-recommends ${APT_PACKAGES_DEVCONTAINER}; \
  else \
    apt-get install -y --no-install-recommends ${APT_PACKAGES_STANDALONE}; \
  fi

# Workaround screeen refresh issues with neovim/ncurses
# Often recommended when using screen/tmux
ENV TERM="screen-256color"
RUN \
  if [ "$UBUNTU_VERSION" = "noble" ]; then \
    apt install --no-install-recommends -y libtinfo6 ncurses-term; \
  else \
    apt install --no-install-recommends -y libtinfo5 ncurses-term; \
  fi


# Create ubuntu user with sudo privileges
RUN useradd -ms /bin/zsh vscode && \
    usermod -aG sudo vscode \
    # New added for disable sudo password
    && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
    && echo "User vscode (uid=`id -u vscode`:gid=`id -g vscode`) created with passwordless sudo privileges";

# Check ssh-agent forwarding
RUN --mount=type=ssh \
  echo "Check ssh agent forwarding (root)"; \
  if [ -n "$SSH_AUTH_SOCK" ]; then \
    echo "ssh-forwarding is not available"; \
  else \
    ssh-add -l; \
  fi

USER vscode

# Check ssh-agent forwarding for the non-root vscode user
# See https://github.com/moby/buildkit/issues/763
RUN --mount=type=ssh,uid=1000 \
  echo "Check ssh agent forwarding (non-root vscode user)"; \
  if [ -n "$SSH_AUTH_SOCK" ]; then \
    echo "ssh-forwarding is not available"; \
  else \
    ssh-add -l; \
  fi

# Configure ssh-forwarding
# NOTE: to use ssh-forwarding you need to use
# RUN --mount=type=ssh,uid=1000 \
RUN mkdir -p ~/.ssh; \
  for host in $SSH_KNOWN_HOSTS; do \
    echo "\nHost $host\n    ForwardAgent yes" >> ~/.ssh/config \
    && ssh-keyscan $host >> ~/.ssh/known_hosts; \
  done; \
  cat ~/.ssh/config;

# Check ccache
RUN --mount=type=cache,uid=1000,gid=1000,target=${CCACHE_BUILD_DIR} \
  if [ "$(ls -A ${CCACHE_BUILD_DIR})" ]; then \
    echo "CCACHE: Found existing ccache cache in the docker build cache, using it"; \
    ccache -z; \
    ccache -sv; \
  else \
    echo "CCACHE: ccache mount directory is empty, it will be populated during the superbuild build step"; \
  fi

# Add mc-rtc-superbuild to the build context
# It is better to keep it in the same folder in order to increase ccache hit rate
COPY --chown=vscode:vscode ../../.. ${SUPERBUILD_DIR}
WORKDIR ${SUPERBUILD_DIR}

# Copy entrypoint into the image
RUN \
  cp $SUPERBUILD_DIR/.devcontainer/docker-entrypoint.sh ~/.docker-entrypoint.sh

RUN --mount=type=cache,target=/var/cache/apt \
  ./utils/bootstrap-linux.sh \
  && git config --global user.email "$EMAIL" && git config --global user.name "$NAME" \
  && sudo rm -rf /var/lib/apt/lists/*

# CMake configure will install all APT/PIP dependencies (keep downloaded packages in mounted APT cache)
RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,uid=1000,gid=1000,target=${CCACHE_BUILD_DIR} \
    --mount=type=ssh,uid=1000 \
  # Check if there is an existing ccache from a previous build
  echo "CCACHE: Clean stats" \
  && ccache -z \
  && echo "CCACHE: Checking ccache stats:" \
  && ccache -sv \
  && echo "CCACHE: Checking ccache size:" \
  && du -hs $CCACHE_DIR \
  # Configure the chosen superbuild preset
  && echo "SUPERBUILD: Configuring superbuild with preset $CMAKE_PRESET" \
  && cmake --preset $CMAKE_PRESET \
  # Build the whole superbuild
  && echo "SUPERBUILD: Building the superbuild" \
  && cmake --build --preset $CMAKE_PRESET \
  # Cleanup files to leave in the container
  # Set default values for IS_KEEP_* depending on BUILD_VERSION
  && if [ "${BUILD_VERSION}" = "devcontainer" ]; then \
    IS_KEEP_SOURCES="${KEEP_SOURCES:-false}"; \
    IS_KEEP_BUILD="${KEEP_BUILD:-false}"; \
    IS_KEEP_INSTALL="${KEEP_INSTALL:-false}"; \
    IS_KEEP_CCACHE="${KEEP_CCACHE:-true}"; \
  else \
    IS_KEEP_SOURCES="${KEEP_SOURCES:-false}"; \
    IS_KEEP_BUILD="${KEEP_BUILD:-false}"; \
    IS_KEEP_INSTALL="${KEEP_INSTALL:-true}"; \
    IS_KEEP_CCACHE="${KEEP_CCACHE:-false}"; \
  fi \
  && if [ "$IS_KEEP_SOURCES" = "false" ]; then \
    echo "CLEAN: Removing sources in ${WORKSPACE_DEVEL_DIR}" \
    && rm -rf ${WORKSPACE_DEVEL_DIR}; \
    echo "CLEAN: Removing superbuild in ${SUPERBUILD_DIR}" \
    && rm -rf ${SUPERBUILD_DIR}; \
  fi \
  && if [ "$IS_KEEP_BUILD" = "false" ]; then \
    echo "CLEAN: Removing build in ${WORKSPACE_BUILD_DIR}" \
    && rm -rf ${WORKSPACE_BUILD_DIR}; \
  fi \
  && if [ "$IS_KEEP_INSTALL" = "false" ]; then \
    echo "CLEAN: Removing install in ${WORKSPACE_INSTALL_DIR}" \
    && rm -rf ${WORKSPACE_INSTALL_DIR}; \
  fi \
  && if [ -z "$(ls -A $WORKSPACE_DIR)" ]; then \
    echo "CLEAN: Removing the empty $WORKSPACE_DIR folder" \
    && rmdir $WORKSPACE_DIR; \
  fi \
  && echo "CCACHE: Checking ccache contents after build:" \
  && ccache -sv; \
  if [ "$IS_KEEP_CCACHE" = "true" ]; then \
    echo "CCACHE: Moving the generated ccache cache to the image folder $CCACHE_IMAGE_DIR so that it can be used at runtime" \
    && mkdir -p $CCACHE_IMAGE_DIR \
    && sudo chown vscode $CCACHE_IMAGE_DIR \
    && cp -r $CCACHE_BUILD_DIR/* $CCACHE_IMAGE_DIR; \
  fi \
  # Further cleanup
  && rm ~/.gitconfig \
  && sudo rm -rf /var/lib/apt/lists/*;

# oh-my-zsh & plugins
RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v1.2.1/zsh-in-docker.sh)" -- \
    -t $ZSH_THEME \
    -p git;

# Second stage: copy final files generated in the 'build' stage
FROM ubuntu:$UBUNTU_VERSION as final
COPY --from=build / /
LABEL org.opencontainers.image.source=https://github.com/mc-rtc/mc-rtc-superbuild
LABEL org.opencontainers.image.description="Development environment for mc-rtc-superbuild (ubuntu $UBUNTU_VERSION, preset $CMAKE_PRESET, $BUILD_VERSION)"
LABEL org.opencontainers.image.licenses=BSD-2
ARG CUSTOM_ENTRYPOINT=""
ARG BUILD_VERSION
ARG CCACHE_IMAGE_DIR
# entrypoint.sh will sync this default image cache with the mounted local folder cache upon starting the container
# This is done to allow updating the cache while working within the container
ENV UBUNTU_VERSION="$UBUNTU_VERSION"
ENV BUILD_VERSION=$BUILD_VERSION
# Change CCACHE_DIR to its final location in the image
ENV CCACHE_DIR=$CCACHE_IMAGE_DIR

USER vscode
WORKDIR /home/vscode

RUN echo "Building with args:" \
 && echo "CUSTOM_ENTRYPOINT=$CUSTOM_ENTRYPOINT"; \
 echo "Building with env:" \
 && export

COPY --chown=vscode:vscode ${CUSTOM_ENTRYPOINT} /home/vscode/.docker-custom-entrypoint.sh
RUN \
  if [ -f "~/.docker-custom-entrypoint.sh" ]; then \
    echo "ENTRYPOINT: Using custom entrypoint: $CUSTOM_ENTRYPOINT located in ~/.docker-custom-entrypoint.sh"; \
    # && cp $CUSTOM_ENTRYPOINT ~/.docker-custom-entrypoint.sh; \
  fi

ENTRYPOINT ["/home/vscode/.docker-entrypoint.sh"]
