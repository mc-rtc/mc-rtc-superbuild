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
 && apt-get install -y --no-install-recommends sudo gnupg2 gpg-agent openssh-server \
 && rm -rf /var/lib/apt/lists/*

# Create ubuntu user with sudo privileges
RUN useradd -ms /bin/zsh vscode && \
    usermod -aG sudo vscode \
    # New added for disable sudo password
    && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
    && echo "User vscode (uid=`id -u vscode`:gid=`id -g vscode`) created with passwordless sudo privileges"

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
  cmake --preset cdadance-demo \
  && cmake --build --preset cdadance-demo \
  && rm ~/.gitconfig \
  && rm -rf ~/workspace/devel \
  && rm -rf ~/workspace/build \
  && sudo rm -rf /var/lib/apt/lists/*

# Switch back to the official remote when https://github.com/deluan/zsh-in-docker/pull/28 is merged
# oh-my-zsh & plugins
RUN sh -c "$(curl -L https://raw.githubusercontent.com/balancedscorpion/zsh-in-docker/new_user/zsh-in-docker.sh)" -- \
    -t 'bira' \
    -p git \
    -u vscode \
    && echo 'source $HOME/superbuild/.devcontainer/entrypoint.sh' >> ~/.zshrc \
    && echo 'source $HOME/workspace/install/setup_mc_rtc.sh.sh' >> ~/.zshrc

FROM ubuntu:jammy
COPY --from=build / /
LABEL org.opencontainers.image.source=https://github.com/mc-rtc/mc-rtc-superbuild
LABEL org.opencontainers.image.description="Release devcontainer for running the CDADance demo (install only)"
LABEL org.opencontainers.image.licenses=BSD-2
# entrypoint.sh will sync this default image cache with the local folder cache upon starting the container
# This is done to allow updating the cache while working within the container
ENV UBUNTU_VERSION="jammy"
ENTRYPOINT ["/usr/bin/zsh", "-c"]
