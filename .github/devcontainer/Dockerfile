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

# GLOBAL args:
# - available in all build stages
# - Each ARG instruction should be re-declared in each stage that wishes to use it
#   ex: ARG UBUNTU_VERSION
# - ARGS are not available as env variable. To make them available they need to be declared as ENV
#   ex: ENV UBUNTU_VERSION=${UBUNTU_VERSION}
ARG UBUNTU_VERSION="jammy"
ARG BUILD_VERSION="devcontainer"
ARG CMAKE_PRESET="relwithdebinfo"
# When KEEP_CCACHE=true, the ccache cache generated in CCACHE_BUILD_DIR is copied to the CCACHE_IMAGE_DIR for fast initial build times when using this image
ARG CCACHE_IMAGE_DIR=/home/vscode/.cache/ccache
ARG SUPERBUILD_DIR="/home/vscode/superbuild"
ARG WORKSPACE_DIR="/home/vscode/workspace"
ARG WORKSPACE_INSTALL_DIR="/home/vscode/workspace/install"
ARG WORKSPACE_DEVEL_DIR="/home/vscode/workspace/devel"
ARG WORKSPACE_BUILD_DIR="/home/vscode/workspace/build"

# First stage build mc-rtc-superbuild and generates ccache
FROM ubuntu:$UBUNTU_VERSION as build

ARG UBUNTU_VERSION
ARG BUILD_VERSION
ARG CMAKE_PRESET
ARG CCACHE_IMAGE_DIR
ARG SUPERBUILD_DIR
ARG WORKSPACE_DIR
ARG WORKSPACE_INSTALL_DIR
ARG WORKSPACE_DEVEL_DIR
ARG WORKSPACE_BUILD_DIR

# Choices are devcontainer, standalone
ENV BUILD_VERSION=$BUILD_VERSION
ENV CMAKE_PRESET=$CMAKE_PRESET
# - KEEP_SOURCE=""      : do the default action for the  BUILD_VERSION (do not keep sources)
# - KEEP_SOURCE="false" : do not keep sources
# - KEEP_SOURCE="true"  : keep sources regardless of BUILD_VERSION
ARG KEEP_SOURCES=""
ENV KEEP_SOURCES=$KEEP_SOURCES
# Same as KEEP_SOURCES but for the build folder
ARG KEEP_BUILD=""
ENV KEEP_BUILD=$KEEP_BUILD
ARG KEEP_CCACHE=""
ENV KEEP_CCACHE=$KEEP_CCACHE
# Same as KEEP_SOURCES but for the install folder
ARG KEEP_INSTALL=""
ENV KEEP_INSTALL=KEEP_INSTALL
ARG SSH_KNOWN_HOSTS="github.com gite.lirmm.fr"
ENV SSH_KNOWN_HOSTS=${SSH_KNOWN_HOSTS}
# Build time cache directory to speed up sucessive rebuilds of this image
# This is kept into the docker cache
ARG CCACHE_BUILD_DIR=/tmp/ccache
ENV CCACHE_BUILD_DIR=$CCACHE_BUILD_DIR
ENV CCACHE_IMAGE_DIR=$CCACHE_IMAGE_DIR
# During build phase, use build time ccache directory (mounted in docker build cache)
ENV CCACHE_DIR=${CCACHE_BUILD_DIR}
ARG BUILD_SUPERBUILD="true"
ENV BUILD_SUPERBUILD=${BUILD_SUPERBUILD}

ARG ZSH_THEME="bira"

ARG APT_PACKAGES_STANDALONE="sudo gnupg2 gpg-agent openssh-server openssh-client wget curl ca-certificates git ccache"
ARG APT_PACKAGES_DEVCONTAINER="sudo gnupg2 gpg-agent openssh-server wget curl ca-certificates ripgrep rsync clangd git ccache"
ARG EMAIL="devcontainer@mc-rtc-superbuild.com"
ENV EMAIL=$EMAIL
ARG NAME="mc_rtc devcontainer"
ENV NAME=$NAME

ENV SUPERBUILD_DIR=${SUPERBUILD_DIR}
ENV WORKSPACE_DIR=${WORKSPACE_DIR}
ENV WORKSPACE_INSTALL_DIR=${WORKSPACE_INSTALL_DIR}
ENV WORKSPACE_DEVEL_DIR=${WORKSPACE_DEVEL_DIR}
ENV WORKSPACE_BUILD_DIR=${WORKSPACE_BUILD_DIR}

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

# CMake configure will install all APT/PIP dependencies (keep downloaded packages in mounted APT cache)
RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,uid=1000,gid=1000,target=${CCACHE_BUILD_DIR} \
    --mount=type=ssh,uid=1000 \
    .github/devcontainer/build_superbuild.sh

# oh-my-zsh & plugins
RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v1.2.1/zsh-in-docker.sh)" -- \
    -t $ZSH_THEME \
    -p git;

# Clean up APT cache and temporary files
RUN \
    sudo rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    sudo apt-get clean && \
    # Remove docs, man pages, and locales (optional)
    sudo rm -rf /usr/share/doc/* /usr/share/man/* /usr/share/locale/*

# Second stage: copy final files generated in the 'build' stage
FROM ubuntu:$UBUNTU_VERSION as final
COPY --from=build / /
LABEL org.opencontainers.image.source=https://github.com/mc-rtc/mc-rtc-superbuild
LABEL org.opencontainers.image.description="Development environment for mc-rtc-superbuild (ubuntu $UBUNTU_VERSION, preset $CMAKE_PRESET, $BUILD_VERSION)"
LABEL org.opencontainers.image.licenses=BSD-2

ARG UBUNTU_VERSION
ARG CCACHE_IMAGE_DIR
ARG SUPERBUILD_DIR
ARG WORKSPACE_DIR
ARG WORKSPACE_INSTALL_DIR
ARG WORKSPACE_DEVEL_DIR
ARG WORKSPACE_BUILD_DIR

ENV UBUNTU_VERSION=${UBUNTU_VERSION}
ENV CCACHE_IMAGE_DIR=$CCACHE_IMAGE_DIR
ENV SUPERBUILD_DIR=${SUPERBUILD_DIR}
ENV WORKSPACE_DIR=${WORKSPACE_DIR}
ENV WORKSPACE_INSTALL_DIR=${WORKSPACE_INSTALL_DIR}
ENV WORKSPACE_DEVEL_DIR=${WORKSPACE_DEVEL_DIR}
ENV WORKSPACE_BUILD_DIR=${WORKSPACE_BUILD_DIR}

ARG CUSTOM_ENTRYPOINT=""
ENV CUSTOM_ENTRYPOINT=$CUSTOM_ENTRYPOINT

# Change CCACHE_DIR to its final location in the image
# entrypoint.sh will sync this default image cache with the mounted local folder cache upon starting the container
ARG CCACHE_IMAGE_DIR
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
