FROM gergondet/pbuilder:noble-amd64-jazzy
ARG EMAIL="devcontainer@mc-rtc-superbuild.com"
ARG NAME="mc_rtc devcontainer"

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends python3-venv 

# Git now forces you to have an email
RUN git config --global user.email "${EMAIL}" && git config --global user.name "${NAME}"

# RUN useradd -ms /bin/bash dev 
# USER dev
# WORKDIR /home/dev

ENTRYPOINT ["/bin/bash", "-c"]
