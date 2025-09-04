# Copyright 2025 CNRS-UM LIRMM, CNRS-AIST JRL
#
# This Dockerfile is responsible for creating standalone/devcontainer docker images from a mc-rtc-superbuild repository.
#
# There are three main build targets, controlled by the --target argument:
# - standalone-release:
#     this mode installs mc-rtc-superbuild and keeps only the install folder and catkin workspaces in the image.
#     this is intended for releases, and the user will typically provide their own entrypoint.sh script to run
#     a specific controller/simulator/tool upon execution. The default entrypoint is meant as an interactive zsh terminal
#
# - standalone-devel:
#     this mode keeps everything (sources, build, install, ccache) for full development capabilities.
#     Creates a large image (~20Gb) with complete reproducibility of the build environment.
#     Built incrementally from standalone-release stage for efficiency.
#
# - devcontainer:
#     contains the tools needed to work with mc-rtc, pre-builds the whole superbuild to generate a ccache compilation
#     cache that can then be used at runtime to speed up compilation (a few minutes for the first full build).
#     This is intended to be built by a devcontainer.json file to add additional tools into the image
#
# BUILD_VERSION controls the build stage behavior:
# - BUILD_VERSION=standalone: builds all components needed for both standalone-release and standalone-devel
# - BUILD_VERSION=devcontainer: builds components optimized for devcontainer usage
#
# Example usage:
#
# Build standalone-release (minimal image):
# $ docker build --ssh default . \
#        --file .github/devcontainer/Dockerfile \
#        --target standalone-release \
#        --build-arg BUILD_VERSION=standalone \
#        --build-arg CMAKE_PRESET=relwithdebinfo \
#        --build-arg UBUNTU_VERSION=jammy \
#        -t mc-rtc-superbuild-standalone-release
#
# Build standalone-devel (full development image):
# $ docker build --ssh default . \
#        --file .github/devcontainer/Dockerfile \
#        --target standalone-devel \
#        --build-arg BUILD_VERSION=standalone \
#        --build-arg CMAKE_PRESET=relwithdebinfo \
#        --build-arg UBUNTU_VERSION=jammy \
#        -t mc-rtc-superbuild-standalone-devel
#
# Build devcontainer (ccache-optimized image):
# $ docker build --ssh default . \
#        --file .github/devcontainer/Dockerfile \
#        --target devcontainer \
#        --build-arg BUILD_VERSION=devcontainer \
#        --build-arg CMAKE_PRESET=relwithdebinfo \
#        --build-arg UBUNTU_VERSION=jammy \
#        -t mc-rtc-superbuild-devcontainer
#
# Efficient multi-variant builds (shares build cache):
# $ docker build --ssh default . \
#        --file .github/devcontainer/Dockerfile \
#        --target standalone-release \
#        --build-arg BUILD_VERSION=standalone \
#        --build-arg UBUNTU_VERSION=jammy \
#        -t mc-rtc-superbuild-standalone-release
# $ docker build --ssh default . \
#        --file .github/devcontainer/Dockerfile \
#        --target standalone-devel \
#        --build-arg BUILD_VERSION=standalone \
#        --build-arg UBUNTU_VERSION=jammy \
#        -t mc-rtc-superbuild-standalone-devel
#
# To build private repositories, you need to have ssh-agent forwarding configured.
# You can add the following to your bashrc:
# # Run the ssh-agent
# eval $(ssh-agent -s)
# # Register the private key with the agent
# ssh-add ~/.ssh/id_rsa
#
# and you need to provide '--ssh default' argument to docker when building the image

ARG UBUNTU_VERSION="jammy"
ARG BUILD_VERSION="devcontainer"
ARG CMAKE_PRESET="relwithdebinfo"
ARG CCACHE_IMAGE_DIR=/home/vscode/.cache/ccache
ARG SUPERBUILD_DIR="/home/vscode/superbuild"
ARG WORKSPACE_DIR="/home/vscode/workspace"
ARG WORKSPACE_INSTALL_DIR="/home/vscode/workspace/install"
ARG WORKSPACE_DEVEL_DIR="/home/vscode/workspace/devel"
ARG WORKSPACE_BUILD_DIR="/home/vscode/workspace/build"
ARG IMAGE_SOURCE_REPO="mc-rtc/mc-rtc-superbuild" # for LABEL org.opencontainers.image.source
ARG MC_RTC_CONTROLLER_CONFIG=""








# First stage: build mc-rtc-superbuild and generates ccache
FROM ubuntu:$UBUNTU_VERSION as build
ARG UBUNTU_VERSION
ENV UBUNTU_VERSION=$UBUNTU_VERSION
ARG BUILD_VERSION
ENV BUILD_VERSION=$BUILD_VERSION
ARG CMAKE_PRESET
ENV CMAKE_PRESET=$CMAKE_PRESET
ARG CCACHE_IMAGE_DIR
ENV CCACHE_IMAGE_DIR=$CCACHE_IMAGE_DIR
ARG SUPERBUILD_DIR
ENV SUPERBUILD_DIR=$SUPERBUILD_DIR
ARG WORKSPACE_DIR
ENV WORKSPACE_DIR=$WORKSPACE_DIR
ARG WORKSPACE_INSTALL_DIR
ENV WORKSPACE_INSTALL_DIR=$WORKSPACE_INSTALL_DIR
ARG WORKSPACE_DEVEL_DIR
ENV WORKSPACE_DEVEL_DIR=$WORKSPACE_DEVEL_DIR
ARG WORKSPACE_BUILD_DIR
ENV WORKSPACE_BUILD_DIR=$WORKSPACE_BUILD_DIR
ARG MC_RTC_CONTROLLER_CONFIG

# Choices are devcontainer, standalone-release, standalone-devel
ARG KEEP_SOURCES=""
ENV KEEP_SOURCES=$KEEP_SOURCES
ARG KEEP_BUILD=""
ENV KEEP_BUILD=$KEEP_BUILD
ARG KEEP_CCACHE=""
ENV KEEP_CCACHE=$KEEP_CCACHE
ARG KEEP_INSTALL=""
ENV KEEP_INSTALL=$KEEP_INSTALL
ARG SSH_KNOWN_HOSTS="github.com gite.lirmm.fr"
ENV SSH_KNOWN_HOSTS=${SSH_KNOWN_HOSTS}
ARG CCACHE_BUILD_DIR=/tmp/ccache
ENV CCACHE_BUILD_DIR=$CCACHE_BUILD_DIR
ENV CCACHE_IMAGE_DIR=$CCACHE_IMAGE_DIR
ENV CCACHE_DIR=${CCACHE_BUILD_DIR}
ARG BUILD_SUPERBUILD="true"
ENV BUILD_SUPERBUILD=${BUILD_SUPERBUILD}

ARG ZSH_THEME="bira"
ARG APT_PACKAGES_COMMON="sudo gnupg2 gpg-agent openssh-server wget curl ca-certificates git ccache xclip ripgrep zsh"
ARG APT_PACKAGES_STANDALONE="${APT_PACKAGES_COMMON} neovim"
ARG APT_PACKAGES_DEVCONTAINER="${APT_PACKAGES_COMMON} rsync clangd"
ARG EMAIL="devcontainer@mc-rtc-superbuild.com"
ENV EMAIL=$EMAIL
ARG NAME="mc_rtc devcontainer"
ENV NAME=$NAME

ENV SUPERBUILD_DIR=${SUPERBUILD_DIR}
ENV WORKSPACE_DIR=${WORKSPACE_DIR}
ENV WORKSPACE_INSTALL_DIR=${WORKSPACE_INSTALL_DIR}
ENV WORKSPACE_DEVEL_DIR=${WORKSPACE_DEVEL_DIR}
ENV WORKSPACE_BUILD_DIR=${WORKSPACE_BUILD_DIR}

ENV DEBIAN_FRONTEND=noninteractive
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


# # Test SSH mount with default shell (bash)
# RUN --mount=type=ssh \
#     echo "SSH_AUTH_SOCK: $SSH_AUTH_SOCK" && \
#     ssh-add -l
#
# # Set zsh as the default shell for RUN commands
# SHELL ["/bin/zsh", "-c"]
#
# # Test SSH mount with zsh shell
# RUN --mount=type=ssh \
#     echo "SSH_AUTH_SOCK: $SSH_AUTH_SOCK" && \
#     ssh-add -l

# Workaround screen refresh issues with neovim/ncurses
ENV TERM="xterm-256color"
RUN \
   if [ "$UBUNTU_VERSION" = "noble" ]; then \
     apt install --no-install-recommends -y libtinfo6 ncurses-term; \
   else \
     apt install --no-install-recommends -y libtinfo5 ncurses-term; \
   fi

# Create ubuntu user with sudo privileges
# Rename ubuntu user to vscode (noble)
# Create a new vscode user (jammy)
RUN \
  if [ "$UBUNTU_VERSION" = "noble" ]; then \
    usermod -l vscode ubuntu \
    && usermod -d /home/vscode -m vscode \
    && groupmod -n vscode ubuntu; \
  else \
    useradd -u 1000 -ms /bin/zsh vscode; \
  fi; \
  usermod -aG sudo vscode \
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
RUN --mount=type=ssh,uid=1000 \
   echo "Check ssh agent forwarding (non-root vscode user)"; \
   if [ -n "$SSH_AUTH_SOCK" ]; then \
     echo "ssh-forwarding is not available"; \
   else \
     ssh-add -l; \
   fi

# Configure ssh-forwarding
RUN mkdir -p ~/.ssh; \
   for host in $SSH_KNOWN_HOSTS; do \
     echo "\nHost $host\n    ForwardAgent yes" >> ~/.ssh/config \
     && ssh-keyscan $host >> ~/.ssh/known_hosts; \
   done; \
   cat ~/.ssh/config;

# Add mc-rtc-superbuild to the build context
COPY --chown=vscode:vscode ../../.. ${SUPERBUILD_DIR}
WORKDIR ${SUPERBUILD_DIR}

# Copy entrypoint into the image
RUN cp $SUPERBUILD_DIR/.devcontainer/docker-entrypoint.sh ~/.docker-entrypoint.sh && \
    cp $SUPERBUILD_DIR/.devcontainer/entrypoint.sh ~/.entrypoint.sh

# CMake configure will install all APT/PIP dependencies (keep downloaded packages in mounted APT cache)
RUN --mount=type=cache,target=/var/cache/apt \
     --mount=type=ssh,uid=1000 \
     .github/devcontainer/build_superbuild.sh

# mc_rtc configuration copy if MC_RTC_CONTROLLER_CONFIG is set and file exists
RUN mkdir -p ~/.config/mc_rtc && \
    if [ -n "$MC_RTC_CONTROLLER_CONFIG" ] && [ -f "$SUPERBUILD_DIR/$MC_RTC_CONTROLLER_CONFIG" ]; then \
      cp "$SUPERBUILD_DIR/$MC_RTC_CONTROLLER_CONFIG" ~/.config/mc_rtc/mc_rtc.yaml && \
      echo "Copied mc_rtc controller configuration file from $MC_RTC_CONTROLLER_CONFIG to ~/.config/mc_rtc/mc_rtc.yaml"; \
    else \
      echo "MC_RTC_CONTROLLER_CONFIG is not set or the file does not exist, skipping copy of mc_rtc configuration"; \
    fi

# oh-my-zsh & plugins
RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v1.2.1/zsh-in-docker.sh)" -- \
     -t $ZSH_THEME \
     -p git \
     -p https://github.com/zsh-users/zsh-autosuggestions \
     -p https://github.com/zsh-users/zsh-syntax-highlighting.git \
     && cp $SUPERBUILD_DIR/.devcontainer/.zshrc ~/.zshrc

# Clean up APT cache and temporary files
RUN \
     sudo rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
     sudo apt-get clean && \
     sudo rm -rf /usr/share/doc/* /usr/share/man/* /usr/share/locale/*

WORKDIR /home/vscode
# ==================
# end of build stage
# ==================








# Base stage: System packages and basic user setup
FROM ubuntu:$UBUNTU_VERSION as base
ARG UBUNTU_VERSION
ENV UBUNTU_VERSION=${UBUNTU_VERSION}
ARG CCACHE_IMAGE_DIR
ENV CCACHE_DIR=$CCACHE_IMAGE_DIR
ARG SUPERBUILD_DIR
ENV SUPERBUILD_DIR=${SUPERBUILD_DIR}
ARG WORKSPACE_DIR
ENV WORKSPACE_DIR=${WORKSPACE_DIR}
ARG WORKSPACE_INSTALL_DIR
ENV WORKSPACE_INSTALL_DIR=${WORKSPACE_INSTALL_DIR}
ARG WORKSPACE_DEVEL_DIR
ENV WORKSPACE_DEVEL_DIR=${WORKSPACE_DEVEL_DIR}
ARG WORKSPACE_BUILD_DIR
ENV WORKSPACE_BUILD_DIR=${WORKSPACE_BUILD_DIR}
ARG CMAKE_PRESET
ENV CMAKE_PRESET=${CMAKE_PRESET}
ENV TERM="xterm-256color"

# Copy system-level changes and user setup
# about 1.8Gb
COPY --from=build /usr /usr
# For ROS
COPY --from=build /opt /opt
COPY --from=build /etc /etc
# about 100Mb
COPY --from=build /var /var
COPY --chown=vscode:vscode --from=build /home/vscode/.zshrc /home/vscode/.zshrc
COPY --chown=vscode:vscode --from=build /home/vscode/.docker-entrypoint.sh /home/vscode/.docker-entrypoint.sh
COPY --chown=vscode:vscode --from=build /home/vscode/.entrypoint.sh /home/vscode/.entrypoint.sh
COPY --chown=vscode:vscode --from=build /home/vscode/.oh-my-zsh /home/vscode/.oh-my-zsh
COPY --chown=vscode:vscode --from=build /home/vscode/.config/mc_rtc /home/vscode/.config
# =================
# end of base stage
# =================









# Standalone-release stage: Minimal files (install + catkin workspaces)
FROM base as standalone-release
ARG IMAGE_SOURCE_REPO

ARG UBUNTU_VERSION
ENV UBUNTU_VERSION=${UBUNTU_VERSION}
ARG CMAKE_PRESET
ENV CMAKE_PRESET=${CMAKE_PRESET}
ARG CCACHE_IMAGE_DIR
ENV CCACHE_DIR=$CCACHE_IMAGE_DIR
ARG CUSTOM_ENTRYPOINT=""
ENV CUSTOM_ENTRYPOINT=$CUSTOM_ENTRYPOINT
ARG WORKSPACE_DIR
ENV WORKSPACE_DIR=${WORKSPACE_DIR}
ARG WORKSPACE_INSTALL_DIR
ENV WORKSPACE_INSTALL_DIR=${WORKSPACE_INSTALL_DIR}
ARG WORKSPACE_DEVEL_DIR
ENV WORKSPACE_DEVEL_DIR=${WORKSPACE_DEVEL_DIR}
ENV TERM="xterm-256color"

# about 1.5Gb
COPY --chown=vscode:vscode --from=build ${WORKSPACE_INSTALL_DIR} ${WORKSPACE_INSTALL_DIR}
# About 800Mb
COPY --chown=vscode:vscode --from=build ${WORKSPACE_DEVEL_DIR}/catkin_ws/install ${WORKSPACE_DEVEL_DIR}/catkin_ws/install
# Depends on the robots involved, can be up to several Gb (e.g with RHPS1)
COPY --chown=vscode:vscode --from=build ${WORKSPACE_DEVEL_DIR}/catkin_data_ws/install ${WORKSPACE_DEVEL_DIR}/catkin_data_ws/install

# Remove catkin worksapces if they are empty
RUN [ -z "$(ls -A ${WORKSPACE_DEVEL_DIR}/catkin_ws/install)" ] && rmdir ${WORKSPACE_DEVEL_DIR}/catkin_ws/install || true
RUN [ -z "$(ls -A ${WORKSPACE_DEVEL_DIR}/catkin_data_ws/install)" ] && rmdir ${WORKSPACE_DEVEL_DIR}/catkin_data_ws/install || true

LABEL org.opencontainers.image.source="https://github.com/${IMAGE_SOURCE_REPO}"
LABEL org.opencontainers.image.description="Development environment for $IMAGE_SOURCE_REPO (ubuntu $UBUNTU_VERSION, preset: $CMAKE_PRESET, build version: $BUILD_VERSION)"
LABEL org.opencontainers.image.licenses=BSD-2


USER vscode
WORKDIR /home/vscode

RUN echo "Building standalone-release with args:" \
  && echo "CUSTOM_ENTRYPOINT=$CUSTOM_ENTRYPOINT" \
  && echo "CMAKE_PRESET=$CMAKE_PRESET" \
  && echo "UBUNTU_VERSION=$UBUNTU_VERSION"

RUN if [ -n "$CUSTOM_ENTRYPOINT" ] && [ -f "$SUPERBUILD_DIR/$CUSTOM_ENTRYPOINT" ]; then \
      cp "$SUPERBUILD_DIR/$CUSTOM_ENTRYPOINT" /home/vscode/.docker-custom-entrypoint.sh; \
      echo "ENTRYPOINT: Copying custom entrypoint: $CUSTOM_ENTRYPOINT located in ~/.docker-custom-entrypoint.sh"; \
    fi

ENTRYPOINT ["/home/vscode/.docker-entrypoint.sh"]
# ===============================
# end of standalone-release stage
# ===============================





# Standalone-devel stage: All development files
FROM standalone-release as standalone-devel
ARG CCACHE_IMAGE_DIR
ARG IMAGE_SOURCE_REPO


ARG UBUNTU_VERSION
ENV UBUNTU_VERSION=${UBUNTU_VERSION}
ARG BUILD_VERSION
ENV BUILD_VERSION=${BUILD_VERSION}
ARG CMAKE_PRESET
ENV CMAKE_PRESET=${CMAKE_PRESET}
ARG SUPERBUILD_DIR
ENV SUPERBUILD_DIR=$SUPERBUILD_DIR
ARG WORKSPACE_DIR
ENV WORKSPACE_DIR=$WORKSPACE_DIR
ARG WORKSPACE_INSTALL_DIR
ENV WORKSPACE_INSTALL_DIR=$WORKSPACE_INSTALL_DIR
ARG WORKSPACE_DEVEL_DIR
ENV WORKSPACE_DEVEL_DIR=$WORKSPACE_DEVEL_DIR
ARG WORKSPACE_BUILD_DIR
ENV WORKSPACE_BUILD_DIR=$WORKSPACE_BUILD_DIR
ENV TERM="xterm-256color"

# negligible
COPY --chown=vscode:vscode --from=build ${SUPERBUILD_DIR} ${SUPERBUILD_DIR}
# Huge, ~6Gb with rhps1
COPY --chown=vscode:vscode --from=build ${WORKSPACE_DEVEL_DIR} ${WORKSPACE_DEVEL_DIR}
# Huge, ~5Gb. Do we need to include it?
COPY --chown=vscode:vscode --from=build ${WORKSPACE_BUILD_DIR} ${WORKSPACE_BUILD_DIR}
# ~1.5Gb
COPY --chown=vscode:vscode --from=build ${CCACHE_IMAGE_DIR} ${CCACHE_IMAGE_DIR}

LABEL org.opencontainers.image.source="https://github.com/${IMAGE_SOURCE_REPO}"
LABEL org.opencontainers.image.description="Development environment for $IMAGE_SOURCE_REPO (ubuntu $UBUNTU_VERSION, preset: $CMAKE_PRESET, build version: $BUILD_VERSION)"
LABEL org.opencontainers.image.licenses=BSD-2

RUN echo "Building standalone-devel with args:" \
  && echo "CMAKE_PRESET=$CMAKE_PRESET" \
  && echo "UBUNTU_VERSION=$UBUNTU_VERSION"
# ===============================
# end of standalone-devel stage
# ===============================





# Devcontainer stage: Only ccache for fast builds
FROM base as devcontainer
ARG IMAGE_SOURCE_REPO
ARG CCACHE_IMAGE_DIR

ARG CUSTOM_ENTRYPOINT=""
ARG UBUNTU_VERSION
ARG BUILD_VERSION
ARG CMAKE_PRESET
ARG SUPERBUILD_DIR
ARG WORKSPACE_DIR
ARG WORKSPACE_INSTALL_DIR
ARG WORKSPACE_DEVEL_DIR
ARG WORKSPACE_BUILD_DIR

ENV CUSTOM_ENTRYPOINT=$CUSTOM_ENTRYPOINT
ENV CCACHE_DIR=$CCACHE_IMAGE_DIR
ENV UBUNTU_VERSION=${UBUNTU_VERSION}
ENV BUILD_VERSION=${BUILD_VERSION}
ENV CMAKE_PRESET=${CMAKE_PRESET}
ENV SUPERBUILD_DIR=$SUPERBUILD_DIR
ENV WORKSPACE_DIR=$WORKSPACE_DIR
ENV WORKSPACE_INSTALL_DIR=$WORKSPACE_INSTALL_DIR
ENV WORKSPACE_DEVEL_DIR=$WORKSPACE_DEVEL_DIR
ENV WORKSPACE_BUILD_DIR=$WORKSPACE_BUILD_DIR
ENV TERM="xterm-256color"

COPY --chown=vscode:vscode --from=build ${CCACHE_IMAGE_DIR} ${CCACHE_IMAGE_DIR}

LABEL org.opencontainers.image.source="https://github.com/${IMAGE_SOURCE_REPO}"
LABEL org.opencontainers.image.description="Development environment for $IMAGE_SOURCE_REPO (ubuntu $UBUNTU_VERSION, preset: $CMAKE_PRESET, build version: $BUILD_VERSION)"
LABEL org.opencontainers.image.licenses=BSD-2

USER vscode
WORKDIR /home/vscode

RUN echo "Building devcontainer with args:" \
  && echo "CUSTOM_ENTRYPOINT=$CUSTOM_ENTRYPOINT" \
  && echo "CMAKE_PRESET=$CMAKE_PRESET" \
  && echo "UBUNTU_VERSION=$UBUNTU_VERSION"

ENTRYPOINT ["/home/vscode/.docker-entrypoint.sh"]
# ===============================
# end of devcontainer stage
# ===============================
