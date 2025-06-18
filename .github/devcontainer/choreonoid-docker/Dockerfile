FROM ubuntu:jammy as build
ARG EMAIL="devcontainer@mc-rtc-superbuild.com"
ARG NAME="mc_rtc devcontainer"
RUN export DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Paris
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone


# Configure ssh-forwarding
# NOTE: to use ssh-forwarding you need to use
# RUN --mount=type=ssh,uid=1000 \
RUN \
  apt-get update && apt-get install -y --no-install-recommends openssh-client openssh-server \
  && mkdir -p ~/.ssh \
  && echo "\nHost github.com\n    ForwardAgent yes\nHost gite.lirmm.fr\n    ForwardAgent yes" >> ~/.ssh/config \
  && ssh-keyscan github.com >> ~/.ssh/known_hosts \
  && ssh-keyscan gite.lirmm.fr >> ~/.ssh/known_hosts \
  && cat ~/.ssh/config;

# Check ssh-agent forwarding
RUN --mount=type=ssh \
  echo "Check ssh agent forwarding"; \
  if [ -n "$SSH_AUTH_SOCK" ]; then \
    echo "ssh-forwarding is not available"; \
  else \
    ssh-add -l; \
  fi

# Add mc-rtc-superbuild to the build context
COPY ../../../ /root/superbuild
WORKDIR /root/superbuild
RUN cp /root/superbuild/.github/devcontainer/choreonoid-docker/entrypoint.sh /root/entrypoint.sh \
 && chmod +x /root/entrypoint.sh


RUN ./utils/bootstrap-linux.sh \
  && sudo apt-get install -y --no-install-recommends openssh-client \
  && git config --global user.email "${EMAIL}" && git config --global user.name "${NAME}" \
  && sudo rm -rf /var/lib/apt/lists/*


RUN --mount=type=ssh cmake --preset choreonoid-system \
  && cmake --build --preset choreonoid-system \
  && rm -rf /root/superbuild

# Minimize image size
FROM ubuntu:22.04
COPY --from=build / /
LABEL org.opencontainers.image.source=https://github.com/isri-aist/mc-rtc-superbuild-private-ci
LABEL org.opencontainers.image.description="choreonoid simulator with mc_udp and private robots from isri-aist and LIRMM (RHPS1, HRP-*, etc)"
LABEL org.opencontainers.image.licenses=BSD-2
ENTRYPOINT ["/root/entrypoint.sh"]
