FROM ubuntu:jammy as build
# Choices are devcontainer, standalone
ARG BUILD_VERSION="devcontainer"
ARG CMAKE_PRESET="relwithdebinfo"

ARG APT_PACKAGES_STANDALONE="sudo gnupg2 gpg-agent openssh-server wget curl ca-certificates git"
ARG APT_PACKAGES_DEVCONTAINER="sudo gnupg2 gpg-agent openssh-server wget curl ca-certificates ccache ripgrep rsync clangd git"
ARG EMAIL="devcontainer@mc-rtc-superbuild.com"
ARG NAME="mc_rtc devcontainer"
ENV UBUNTU_VERSION="jammy"

RUN echo "Building with args" \
 && echo "CMAKE_PRESET=${CMAKE_PRESET}" \
 && echo "UBUNTU_VERSION=${UBUNTU_VERSION}" \
 && echo "APT_PACKAGES_STANDALONE=${APT_PACKAGES_STANDALONE}" \
 && echo "APT_PACKAGES_DEVCONTAINER=${APT_PACKAGES_DEVCONTAINER}"


RUN export DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Paris
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Allow to keep apt cache between builds
RUN rm -f /etc/apt/apt.conf.d/docker-clean

# Install basic dependencies 
RUN --mount=type=cache,target=/var/cache/apt \
  apt-get update \
  && \
  if [ "$BUILD_VERSION" = "devcontainer" ]; then \
    apt-get install -y --no-install-recommends ${APT_PACKAGES_DEVCONTAINER}; \
  else \
    apt-get install -y --no-install-recommends ${APT_PACKAGES_STANDALONE}; \
  fi


# Create ubuntu user with sudo privileges
RUN useradd -ms /bin/zsh vscode && \
    usermod -aG sudo vscode \
    # New added for disable sudo password
    && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
    && echo "User vscode (uid=`id -u vscode`:gid=`id -g vscode`) created with passwordless sudo privileges"

# Check ssh-agent forwarding
RUN --mount=type=ssh \
  echo "Check ssh agent forwarding (root)" \
  && ssh-add -l

USER vscode

# Check ssh-agent forwarding for the non-root vscode user
# See https://github.com/moby/buildkit/issues/763
RUN --mount=type=ssh,uid=1000 \
  echo "Check ssh agent forwarding (non-root vscode user)" \
  && ssh-add -l

RUN mkdir -p ~/.ssh && echo "\nHost github.com\n    ForwardAgent yes\nHost gite.lirmm.fr\n    ForwardAgent yes" >> ~/.ssh/config
RUN ssh-keyscan github.com >> ~/.ssh/known_hosts
RUN ssh-keyscan gite.lirmm.fr >> ~/.ssh/known_hosts
RUN cat ~/.ssh/config

WORKDIR /tmp
RUN --mount=type=ssh,uid=1000 \
  git clone git@gite.lirmm.fr:mc-hrp4/hrp4_mj_description.git

RUN --mount=type=ssh,uid=1000 \
  git clone git@github.com:isri-aist/hrp4_description.git

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
  && git config --global user.email "${EMAIL}" && git config --global user.name "${NAME}" \
  && sudo rm -rf /var/lib/apt/lists/*

# CMake configure will install all APT/PIP dependencies (keep downloaded packages in mounted APT cache)
RUN --mount=type=cache,target=/var/cache/apt \
  --mount=type=ssh,uid=1000 \
  cmake --preset ${CMAKE_PRESET} \
  && cmake --build --preset ${CMAKE_PRESET} --target clone \
  && cmake --build --preset ${CMAKE_PRESET}

# Cleanup files to leave in the container
RUN \
  if [ "BUILD_VERSION" = "devcontainer" ]; then \
    rm -rf ~/superbuild \
    && rm -rf ~/workspace \
    && rm ~/.gitconfig; \
  else \
    rm ~/.gitconfig \
    && rm -rf ~/workspace/devel \
    && rm -rf ~/workspace/build; \
  fi; \
  sudo rm -rf /var/lib/apt/lists/*

RUN --mount=type=cache,uid=1000,gid=1000,target=${CCACHE_BUILD_DIR} \
  if [ "BUILD_VERSION" = "devcontainer" ]; then \
    echo "Moving the generated ccache cache to the image folder ${CCACHE_IMAGE_DIR} so that it can be used at runtime" \
    && mkdir -p ${CCACHE_IMAGE_DIR} \
    && sudo chown vscode ${CCACHE_IMAGE_DIR} \
    && cp -r ${CCACHE_BUILD_DIR}/* ${CCACHE_IMAGE_DIR}; \
  fi

ENV CCACHE_DIR=${CCACHE_IMAGE_DIR}
RUN if [ "BUILD_VERSION" = "devcontainer" ]; then \
    echo "Checking cache contents"; \
    ccache -sv; \
  fi

# oh-my-zsh & plugins
RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v1.2.1/zsh-in-docker.sh)" -- \
    -t 'bira' \
    -p git \
    && echo 'source $HOME/superbuild/.devcontainer/entrypoint.sh' >> ~/.zshrc \
    && echo 'source $HOME/workspace/install/setup_mc_rtc.sh.sh' >> ~/.zshrc

FROM ubuntu:jammy
COPY --from=build / /
LABEL org.opencontainers.image.source=https://github.com/mc-rtc/mc-rtc-superbuild
LABEL org.opencontainers.image.description="Release Docker for running the CDADance demo (install only)"
LABEL org.opencontainers.image.licenses=BSD-2
# entrypoint.sh will sync this default image cache with the local folder cache upon starting the container
# This is done to allow updating the cache while working within the container
ENV UBUNTU_VERSION="jammy"
ENTRYPOINT ["/usr/bin/zsh", "-c"]
