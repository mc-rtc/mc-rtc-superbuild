FROM ubuntu:jammy as build
ARG EMAIL="devcontainer@mc-rtc-superbuild.com"
ARG NAME="mc_rtc devcontainer"
ENV UBUNTU_VERSION="jammy"

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

# Build time cache directory to speed up sucessive rebuilds of this image
ENV CCACHE_BUILD_DIR=/tmp/ccache
# The ccache cache generated in CCACHE_BUILD_DIR is copied to the CCACHE_IMAGE_DIR for fast initial build times
# when using this image
ENV CCACHE_IMAGE_DIR=/home/vscode/.cache/ccache

# Use build time ccache directory (mounted in docker build cache)
ENV CCACHE_DIR=${CCACHE_BUILD_DIR}

RUN --mount=type=cache,uid=1000,gid=1000,target=${CCACHE_BUILD_DIR} \
  if [ "$(ls -A ${CCACHE_BUILD_DIR})" ]; then \
    echo "Found ccache cache in the docker build cache, using it"; \
    du -h ${CCACHE_BUILD_DIR}; \
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
  && sudo apt-get install -y --no-install-recommends ccache gdb \
  && git config --global user.email "${EMAIL}" && git config --global user.name "${NAME}" \
  && sudo rm -rf /var/lib/apt/lists/*

RUN echo 'kill cache'
# CMake configure will install all APT/PIP dependencies (keep downloaded packages in mounted APT cache)
RUN --mount=type=cache,target=/var/cache/apt \
  --mount=type=cache,uid=1000,gid=1000,target=${CCACHE_BUILD_DIR} \
  ccache -z \
  && cmake --preset relwithdebinfo \
  && cmake --build --preset relwithdebinfo \
  && echo "Checking ccache:" \
  && ccache -sv \
  && echo "Removing temporary build artefacts from the image" \
  && rm -rf ~/superbuild \
  && rm -rf ~/workspace \
  && rm ~/.gitconfig \
  && sudo rm -rf /var/lib/apt/lists/*

RUN --mount=type=cache,uid=1000,gid=1000,target=${CCACHE_BUILD_DIR} \
  echo "Moving the generated ccache cache to the image folder ${CCACHE_IMAGE_DIR} so that it can be used at runtime" \
  && mkdir -p ${CCACHE_IMAGE_DIR} \
  && sudo chown vscode ${CCACHE_IMAGE_DIR} \
  && cp -r ${CCACHE_BUILD_DIR}/* ${CCACHE_IMAGE_DIR}

ENV CCACHE_DIR=${CCACHE_IMAGE_DIR}
RUN echo "Checking cache contents" \
  && ccache -sv

# Switch back to the official remote when https://github.com/deluan/zsh-in-docker/pull/28 is merged
# oh-my-zsh & plugins
RUN sh -c "$(curl -L https://raw.githubusercontent.com/balancedscorpion/zsh-in-docker/new_user/zsh-in-docker.sh)" -- \
    -t 'bira' \
    -p git \
    -u vscode \
    && echo 'source $HOME/superbuild/.devcontainer/entrypoint.sh' >> ~/.zshrc

FROM ubuntu:jammy
COPY --from=build / /
LABEL org.opencontainers.image.source=https://github.com/mc-rtc/mc-rtc-superbuild
LABEL org.opencontainers.image.description="Development environment for mc-rtc-superbuild from source (ubuntu jammy)"
LABEL org.opencontainers.image.licenses=BSD-2
# entrypoint.sh will sync this default image cache with the local folder cache upon starting the container
# This is done to allow updating the cache while working within the container
ENV CCACHE_DIR="/home/vscode/workspace/.ccache"
ENV UBUNTU_VERSION="jammy"
ENTRYPOINT ["/usr/bin/zsh", "-c"]
