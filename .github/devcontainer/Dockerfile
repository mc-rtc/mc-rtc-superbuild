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
# Same as KEEP_SOURCES but for the install folder
ARG KEEP_INSTALL=""
ARG ZSH_THEME="bira"

ARG APT_PACKAGES_STANDALONE="sudo gnupg2 gpg-agent openssh-server openssh-client wget curl ca-certificates git ccache"
ARG APT_PACKAGES_DEVCONTAINER="sudo gnupg2 gpg-agent openssh-server wget curl ca-certificates ccache ripgrep rsync clangd git ccache"
ARG EMAIL="devcontainer@mc-rtc-superbuild.com"
ARG NAME="mc_rtc devcontainer"

ENV UBUNTU_VERSION="$UBUNTU_VERSION"

RUN export DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Paris
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone;


RUN echo "Building with ARGS:" \
 && echo "CMAKE_PRESET=$CMAKE_PRESET" \
 && echo "CMAKE_PRESET=$CMAKE_PRESET" \
 && echo "KEEP_SOURCES=$KEEP_SOURCES" \
 && echo "KEEP_BUILD=$KEEP_BUILD" \
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
RUN mkdir -p ~/.ssh \
  && echo "\nHost github.com\n    ForwardAgent yes\nHost gite.lirmm.fr\n    ForwardAgent yes" >> ~/.ssh/config \
  && ssh-keyscan github.com >> ~/.ssh/known_hosts \
  && ssh-keyscan gite.lirmm.fr >> ~/.ssh/known_hosts \
  && cat ~/.ssh/config;

# Build time cache directory to speed up sucessive rebuilds of this image
ENV CCACHE_BUILD_DIR=/tmp/ccache
# The ccache cache generated in CCACHE_BUILD_DIR is copied to the CCACHE_IMAGE_DIR for fast initial build times when using this image
ENV CCACHE_IMAGE_DIR=/home/vscode/.cache/ccache

# Use build time ccache directory (mounted in docker build cache)
ENV CCACHE_DIR=${CCACHE_BUILD_DIR}

# Check ccache
RUN --mount=type=cache,uid=1000,gid=1000,target=${CCACHE_BUILD_DIR} \
  if [ "$(ls -A ${CCACHE_BUILD_DIR})" ]; then \
    echo "Found existing ccache cache in the docker build cache, using it"; \
    ccache -z; \
    ccache -sv; \
  else \
    echo "ccache mount directory is empty, it will be populated during the superbuild build step"; \
  fi

# Add mc-rtc-superbuild to the build context
# It is better to keep it in the same folder in order to increase ccache hit rate
COPY --chown=vscode:vscode ../../.. /home/vscode/superbuild
WORKDIR /home/vscode/superbuild

RUN --mount=type=cache,target=/var/cache/apt \
  ./utils/bootstrap-linux.sh \
  && git config --global user.email "$EMAIL" && git config --global user.name "$NAME" \
  && sudo rm -rf /var/lib/apt/lists/*

# CMake configure will install all APT/PIP dependencies (keep downloaded packages in mounted APT cache)
RUN --mount=type=cache,target=/var/cache/apt \
  --mount=type=ssh,uid=1000 \
  cmake --preset $CMAKE_PRESET \
  && cmake --build --preset $CMAKE_PRESET --target clone \
  && cmake --build --preset $CMAKE_PRESET; \
  # Cleanup files to leave in the container
  # Set default values for IS_KEEP_* depending on BUILD_VERSION
  if [ "${BUILD_VERSION}" = "devcontainer" ]; then \
    IS_KEEP_SOURCES="${KEEP_SOURCES:-false}"; \
    IS_KEEP_BUILD="${KEEP_BUILD:-false}"; \
    IS_KEEP_INSTALL="${KEEP_INSTALL:-false}"; \
  else \
    IS_KEEP_SOURCES="${KEEP_SOURCES:-false}"; \
    IS_KEEP_BUILD="${KEEP_BUILD:-false}"; \
    IS_KEEP_INSTALL="${KEEP_INSTALL:-true}"; \
  fi; \
  if [ "$IS_KEEP_SOURCES" = "false" ]; then \
    echo "Removing sources in ~/workspace/devel" \
    && rm -rf ~/workspace/devel; \
  fi; \
  if [ "$IS_KEEP_BUILD" = "false" ]; then \
    echo "Removing build in ~/workspace/build" \
    && rm -rf ~/workspace/build; \
  fi; \
  if [ "$IS_KEEP_INSTALL" = "false" ]; then \
    echo "Removing install in ~/workspace/build" \
    && rm -rf ~/workspace/install; \
  fi; \
  if [ -d "~/workspace" ]; then \
    rmdir ~/workspace; \
  fi; \
  rm ~/.gitconfig \
  && sudo rm -rf /var/lib/apt/lists/*;

RUN --mount=type=cache,uid=1000,gid=1000,target=${CCACHE_BUILD_DIR} \
  if [ "BUILD_VERSION" = "devcontainer" ]; then \
    echo "Moving the generated ccache cache to the image folder $CCACHE_IMAGE_DIR so that it can be used at runtime" \
    && mkdir -p $CCACHE_IMAGE_DIR \
    && sudo chown vscode $CCACHE_IMAGE_DIR \
    && cp -r $CCACHE_BUILD_DIR/* $CCACHE_IMAGE_DIR; \
  fi

ENV CCACHE_DIR=$CCACHE_IMAGE_DIR
RUN if [ "$BUILD_VERSION" = "devcontainer" ]; then \
    echo "Checking cache contents"; \
    ccache -sv; \
  fi

# oh-my-zsh & plugins
RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v1.2.1/zsh-in-docker.sh)" -- \
    -t $ZSH_THEME \
    -p git \
    && echo 'source $HOME/superbuild/.devcontainer/entrypoint.sh' >> ~/.zshrc \
    && echo 'source $HOME/workspace/install/setup_mc_rtc.sh.sh' >> ~/.zshrc;

FROM ubuntu:$UBUNTU_VERSION
COPY --from=build / /
LABEL org.opencontainers.image.source=https://github.com/mc-rtc/mc-rtc-superbuild
LABEL org.opencontainers.image.description="Development environment for mc-rtc-superbuild (ubuntu $UBUNTU_VERSION, preset $CMAKE_PRESET, $BUILD_VERSION)"
LABEL org.opencontainers.image.licenses=BSD-2
# entrypoint.sh will sync this default image cache with the mounted local folder cache upon starting the container
# This is done to allow updating the cache while working within the container
ENV UBUNTU_VERSION="$UBUNTU_VERSION"
ENTRYPOINT ["/home/vscode/.devcontainer/docker-entrypoint.sh", "-c"]
