# mc_rtc development in devcontainers

Devcontainers are provided along with `mc-rtc-superbuild` and can be used to develop `mc_rtc` projects in an isolated environement.

This can be useful if:
- You wish to leave your host system intact and have a clean environement to work in.
- You wish to have an environment pre-configured with all tools required to efficiently work with the framework.
- You often work with multiple superbuild setups for different projects and need a separate environment for each.
- You wish to deploy multiple superbuild setups on-board the robot computer.
- You wish to test on a different system than your host machine.

All devcontainer images come pre-built in Github Container Registry: https://ghcr.io/jrl-umi3218/mc-rtc-superbuild.
All pre-built images contain:
- Pre-installed dependencies for all default superbuild projects
- A pre-generated ccache to speed up compilation. A fresh build of `mc-rtc-superbuild` should only take a few minutes.
- A nice oh-my-zsh configuration with useful plugins (git, teminal history, etc.)
- A reasonable default configuration for vscode (see vscode section)

Additionally, `mc-rtc-superbuild` comes with pre-configured `CMakePresets.json` that make working with the superbuild easier (see [building](#building) section).


Available images can be pulled from `ghcr.io/arntanguy/mc-rtc-superbuild:<tag>`:

| Image | Description |
| ----- | ----------- |
| jammy | Ubuntu 22.04 |
| noble | Ubuntu 24.04 |
| bookworm | Debian Bookworm |

## Setting up the devcontainer

You can take advantage of these devcontainers in the following ways:
- By using [DevPod](https://devpod.sh/) to manage your devcontainers. This is the most flexible way as it allows to easily use the devcontainer from both the terminal/vscode/neovim/...
- By using VSCode directly. This is slightly easier, but will only work from within VSCode.

### General setup

This section contains common instructions that are needed no matter how you intend to use the provided devcontainers.

- Install docker from https://docs.docker.com/engine/install/ubuntu/
- The devcontainers will automatically forward your ssh-agent socket to the devcontainer, so that you can use your ssh keys from within the devcontainer. For this to work, you need to add the following to your `~/.bashrc`:
```bash
# For ssh-forwarding, we need to
# - Run the ssh-agent
# - Register the private key with the agent
eval $(ssh-agent -s)
ssh-add ~/.ssh/id_rsa # replace with the private key(s) you wish to share with the container
```

### Using DevPod CLI

The easiest way to use the devcontainer from the terminal is to use [Devpod](https://devpod.sh/).

- [Install DevPod CLI](https://devpod.sh/docs/getting-started/install#install-devpod-cli)
- Add docker to devpod providers:
  ```
  devpod provider add docker
  ```
- If you intend to use signed commits within the container, then you also need to share your GNUPG key with the devcontainer. To do so, add the following to your `~/.devpod/config.yaml`
```yaml
contexts:
  default:
    defaultProvider: docker
    options:
      GPG_AGENT_FORWARDING:
        userProvided: true
        value: "true"
```
- Create you devpod workspace
  ```
  cd <mc-rtc-superbuild>
  devpod up . --devcontainer-path ./devcontainer/jammy/devcontainer.json --ide=none
  ```
- Connect to the devcontainer using ssh
  ```
  ssh mc-rtc-superbuild.devpod
  ```

Note that using devpod, you can also take advantage of VSCode by using `--ide=vscode`. When working with multiple devcontainers, you can use the `--id` flag to specify a name.

#### Neovim

For neovim users, you can use the [remote-nvim.nvim](https://github.com/amitds1997/remote-nvim.nvim) plugin.

### VSCode

- Clone `mc-rtc-superbuild`
- Open the cloned folder in VSCode
- VSCode will prompt you to install recommended extensions, in particular the `Devcontainer` extension
- Once done, VSCode will prompt you to re-open the current folder in a devcontainer, select the image you wish.
- VSCode will re-open the workspace within the devcontainer. In the bottom left corner of VSCode window, you should see the name of the image you selected.


## Working within the devcontainer

Once your devcontainer workspace has been created, be it with VSCode or Devpod, you can now work within the devcontainer as you would on your host system.

### Building

You can now build from the terminal, or use VSCode's "CMake Tools" extension to select your desired build preset.
Note that default presets will:
- clone all projects in `./devel`
- build all projects in `./build/<build type>`
- install all projects in `./install/<build type>`

```bash
# Setup cmake and install all dependencies if necessary
cmake --preset relwithdebinfo
```

Note that all default dependencies of mc-rtc-superbuild come pre-installed in the container images, so this will install nothing.

```bash
# Build all projects
cmake --build --preset relwithdebinfo
```

Since the container images come with a pre-generated [ccache](https://ccache.dev/), this will be fairly quick (a few minutes).

## Running

To use `mc_rtc`, you need to setup the environment variables for the local installation of `mc_rtc`.
This can be done by sourcing the following file:

```
source ./install/relwithdebinfo/setup_mc_rtc.sh
```


## Advanced

#### Generating core dump files (Ubuntu)

When debugging large programs, it is often more efficient to run it as you would always do, and upon crash have the kernel generate a "core dump" file.
This files contains runtime information about the state of your program, and can be used by debbuggers such as `gdb` to inspect the state of your program when it crashed.

On Ubuntu, by default, core dump files are managed by `apport` and disabled for non-official packages.
The easiest way to generate them is by disabling `apport` and manually specifying a location for the core files.

First diable apport
```bash
sudo service apport stop # temporarely disable apport
sudo nano /etc/default/apport
```

and set

```
enabled=0
```

Note that this disables default crash reporting of ubuntu, so you will no longer have the (annoying) crash report windows.

Now, configure where the kernel will generate core dumps.

```
echo 'core.%e' | sudo tee /proc/sys/kernel/core_pattern
```

Note that the above configuration will generate a `core.<executable_name>` file in your current directory. You may preferer instead to create a specific directory to store core dump files, in which case you will also need to mount it in your devcontainer file. You can also use more elaborate patterns such as 'core.%t.%e.%p'.

To make it persistent upon reboot, create a `/etc/sysctl.d/60-core-pattern.conf` file with the following content:
```
kernel.core_pattern = core.%e
```

One last thing, you need to increase the max file size that the system is allowed to generate. In /etc/security/limits.conf add:

```
* soft core unlimited
* hard core unlimited
```

This disable the limits for all users. If you prefer you can disable limits for a specific user instead.
To apply it immediately, use

```bash
sudo ulimit -c unlimited
```

You can now test your setup by running:
```bash
sleep 10 &; killall -SIGSEGV sleep
```

You should now have a core.sleep file in your current directory. You can use this file to debug the crash:

```
gdb sleep core.sleep
```
