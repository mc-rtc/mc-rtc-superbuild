FROM ubuntu:jammy as build
ARG CMAKE_PRESET="relwithdebinfo"

ARG EMAIL="devcontainer@mc-rtc-superbuild.com"
ARG NAME="mc_rtc devcontainer"
ENV UBUNTU_VERSION="jammy"

RUN echo "Building with args" \
 && echo "CMAKE_PRESET=${CMAKE_PRESET}" \
 && echo "UBUNTU_VERSION=${UBUNTU_VERSION}"

RUN export DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Paris
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Allow to keep apt cache between builds
RUN rm -f /etc/apt/apt.conf.d/docker-clean

# Install basic dependencies 
RUN  --mount=type=cache,target=/var/cache/apt \
 apt-get update \
 && apt-get install -y --no-install-recommends sudo gnupg2 gpg-agent openssh-server wget curl ca-certificates \
 && rm -rf /var/lib/apt/lists/*

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

# RUN mkdir -p ~/.ssh && echo -e "\nHost github.com\n    ForwardAgent yes" >> ~/.ssh/config

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
  && cmake --build --preset ${CMAKE_PRESET} \
  && rm ~/.gitconfig \
  && rm -rf ~/workspace/devel \
  && rm -rf ~/workspace/build \
  && sudo rm -rf /var/lib/apt/lists/*

# Switch back to the official remote when https://github.com/deluan/zsh-in-docker/pull/28 is merged
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
