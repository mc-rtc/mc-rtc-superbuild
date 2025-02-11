FROM mcr.microsoft.com/devcontainers/cpp:ubuntu-22.04
ARG EMAIL="devcontainer@mc-rtc-superbuild.com"
ARG NAME="mc_rtc devcontainer"
ARG UBUNTU_VERSION="jammy"

RUN export DEBIAN_FRONTEND=noninteractive

# Install latest cmake version
RUN wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | tee /usr/share/keyrings/kitware-archive-keyring.gpg >/dev/null \
 && echo 'deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ jammy main' | sudo tee /etc/apt/sources.list.d/kitware.list >/dev/null \
 && apt update \
 && rm /usr/share/keyrings/kitware-archive-keyring.gpg \
 && apt-get install -y --no-install-recommends kitware-archive-keyring \
 && apt-get update \
 && apt-get install -y --no-install-recommends cmake

RUN apt-get -y install --no-install-recommends ccache python3-venv python3-pip ripgrep cmake


# Git now forces you to have an email
# TODO: remove this (leaving it now to preserve cache)
RUN git config --global user.email "${EMAIL}" && git config --global user.name "${NAME}"

# Add mc-rtc-superbuild to the build context
USER vscode
RUN echo "nuke cache"
RUN git config --global user.email "${EMAIL}" && git config --global user.name "${NAME}"
COPY --chown=vscode:vscode ../.. /home/vscode/build_context/mc-rtc-superbuild
WORKDIR /home/vscode/build_context/mc-rtc-superbuild
RUN ls
RUN echo "break cache"
# Configure CMake will install all dependencies
RUN cmake --preset relwithdebinfo-jammy
# Build everything to populate ccache 
RUN cmake --build --preset build-relwithdebinfo-jammy
RUN ccache -z
RUN rm -rf /home/vscode/build_context/mc-rtc-superbuild
COPY --chown=vscode:vscode ../.. /home/vscode/build_context/mc-rtc-superbuild
WORKDIR /home/vscode/build_context/mc-rtc-superbuild
RUN cmake --preset relwithdebinfo-jammy
RUN cmake --build --preset build-relwithdebinfo-jammy

ENTRYPOINT ["/bin/bash", "-c"]
