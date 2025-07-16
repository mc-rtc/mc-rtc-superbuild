# mc_rtc development in devcontainers

Devcontainers are provided along with `mc-rtc-superbuild` and can be used to develop `mc_rtc` projects in an isolated environement.

This can be useful if:
- You wish to leave your host system intact and have a clean environement to work in.
- You wish to have an environment pre-configured with all tools required to efficiently work with the framework.
- You often work with multiple superbuild setups for different projects and need a separate environment for each.
- You wish to deploy multiple superbuild setups on-board the robot computer.
- You wish to test on a different system than your host machine.

All devcontainer images come pre-built in Github Container Registry: https://ghcr.io/mc-rtc/mc-rtc-superbuild.
All pre-built images contain:
- Pre-installed dependencies for all default superbuild projects
- A pre-generated ccache to speed up compilation. A fresh build of `mc-rtc-superbuild` should only take a few minutes.
- A nice oh-my-zsh configuration with useful plugins (git, teminal history, etc.)
- A reasonable default configuration for vscode (see vscode section)

Additionally, `mc-rtc-superbuild` comes with pre-configured `CMakePresets.json` that make working with the superbuild easier (see [building](#building) section).


Available images can be pulled from `ghcr.io/mc-rtc/mc-rtc-superbuild:<tag>`:

| Image | Description | Image URI | Local mount folder | Mounts to (devcontainer) |
| :--- | :--- | :--- | :--- | :--- |
| jammy | Ubuntu 22.04 | ghcr.io/mc-rtc/mc-rtc-superbuild:jammy | `$HOME/docker-ws/mc-rtc-superbuild-jammy` | `$HOME/workspace` |
| noble | Ubuntu 24.04 | ghcr.io/mc-rtc/mc-rtc-superbuild:noble | `$HOME/docker-ws/mc-rtc-superbuild-noble` | `$HOME/workspace` |

By default the devcontainer will attempt to mount the "local mount folder" path specified above to store all files that need to persist after the container has been stopped. In particular, this is where all source code will be stored.

## Setting up the devcontainer

You can take advantage of these devcontainers in the following ways:
- By using VSCode with the devcontainer extension. If you are already used to using VSCode, this is by far the easiest option.
- Manually by using [DevPod](https://devpod.sh/) or [devcontainer cli](https://github.com/devcontainers/cli) to manage your devcontainers. This is the most flexible way as it allows to easily use the devcontainer from both the terminal/vscode/neovim/...

### General setup

This section contains common instructions that are needed no matter how you intend to use the provided devcontainers.

- Install docker from https://docs.docker.com/engine/install/ubuntu/
- clone `mc-rtc-superbuild`
```bash
git clone git@github.com:mc-rtc/mc-rtc-superbuild.git
```
- Adjust the devcontainer settings to your liking in `.devcontainer/<distro>/devcontainer.json`. In general the default settings will be sufficient. If you wish to do so, you can select a different mount point in the `mounts` property.
- The devcontainers are configured to automatically forward your `ssh-agent`/`gpg-agent` socket to the devcontainer, so that you can use your ssh keys from within the devcontainer. For this to work, you need to add the following to your `~/.bashrc`:

```bash
# For ssh-forwarding, we need to
# - Run the ssh-agent
# - Register the private key with the agent
eval $(ssh-agent -s)
ssh-add ~/.ssh/id_rsa # replace with the private key(s) you wish to share with the container
```

### VSCode

<details>
  <summary>If you wish to use the provided devcontainers within VSCode, please read this section:</summary>

Using devcontainers in vscode is simple.

- Open the cloned folder in VSCode
- VSCode will prompt you to install recommended extensions, in particular the `Devcontainer` extension
- Once done, VSCode will prompt you to re-open the current folder in a devcontainer, select the image you wish.
- VSCode will install a vscode server within the docker environment, then re-open the workspace within the devcontainer. In the bottom left corner of VSCode window, you should see the name of the image you selected. Note that from this point on, any file you modify is either a file of the container itself (that will be deleted once the container stops) or one in the specified mount folder(s) (by default

To go further, please read [Developing inside a Container](https://code.visualstudio.com/docs/devcontainers/containers) from the official VSCode documenation.
</details>

### Using DevPod CLI

<details>
<summary>If you wish to use the provided devcontainers from the CLI, please follow this section:</summary>

To use the provided devcontainers from the terminal, you can use [Devpod CLI](https://devpod.sh/).

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
  devpod up . --devcontainer-path .devcontainer/jammy/devcontainer.json --ide=none
  ```
- Connect to the devcontainer using ssh
  ```
  ssh mc-rtc-superbuild.devpod
  ```

Note that using devpod, you can also take advantage of VSCode by using `--ide=vscode`. When working with multiple devcontainers, you can use the `--id` flag to specify a name.

</details>


#### Neovim

<details>
  <summary>If you wish to use the provided devcontainers within Neovim, please read this section:</summary>

  For neovim users, you can use the [remote-nvim.nvim](https://github.com/amitds1997/remote-nvim.nvim) plugin.
</details>

## Working within the devcontainer

Once your devcontainer workspace has been created, be it with VSCode or Devpod, you can now work within the devcontainer as you would on your host system.

### Mounted folders

By default the following folders are mounted within the container:
- `/home/vscode/superbuild` : A mount point for the local `mc-rtc-superbuild` folder from which you created the container
- `/home/vscode/workspace` : A mount point to a local developement workspace. By default `$HOME/docker-ws/mc-rtc-superbuild-<distro>`. Within this folder mc-rtc-superbuild will create:
  - `devel/` : all source code managed by `mc-rtc-superbuild`
  - `build/projects` : a build directory for each project managed by `mc-rtc-superbuild`
  - `build/superbuild` : the build directory of `mc-rtc-superbuild` itself. This is used to track which projects need to be cloned/updated/built
  - `.ccache/` : A pre-populated compilation cache is included within the docker image. Upon startup of the container, this cache is copied to the `.ccache/` folder. `mc-rtc-superbuild` configures `cmake` to make use of this cache to speed up compilation. Since the cache is now stored on your local machine, any subsequent changes to the code will benefit from this cache.


### Building with `mc-rtc-superbuild`

`mc-rtc-superbuild` is mounted to the `/home/vscode/superbuild` folder within the container. To simplify building`CMakePresets.json` are provided. The default preset `relwithdebinfo` will:
- Clone all projects to `/home/vscode/workspace/devel`
- Configure: since all dependencies have already been installed within the container this will simply set-up cmake build files (in `/home/vscode/workspace/build`)
- Build: The default build preset will build all projects (build folder: `/home/vscode/workspace/build/<project>`). Since ccache compilation cache has been pre-populated from the container image, this will only take a few minutes. All projects are installed in `/home/vscode/workspace/install`.

<details>
  <summary>Build with vscode</summary>
  To build within vscode simply select one of the provided presets (`relwithdebinfo`) within the `CMakeTools` extensions in your leftmost vertical panel. Then configure and build the project.
</details>

<details>
  <summary>Build within the terminal<summary>
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
</details>

<details>
  <summary>Custom build</summary>

  To customize the build process, create a `CMakeUserPresets.json` file that inherits from one of the default presets, and set up your preferred build options (build folders, cmake arguments, build type, etc)

  For example:
  ```json
  {
    "version": 10,
    "$schema": "https://cmake.org/cmake/help/latest/_downloads/3e2d73bff478d88a7de0de736ba5e361/schema.json",
    "configurePresets": [
        {
            "name": "nanobind",
            "displayName": "RelWithDebInfo (nanobind/noble)",
            "inherits": [
                "relwithdebinfo-noble"
            ],
            "cacheVariables": {
                "PYTHON_BINDING": "OFF",
                "NANOBIND_BINDINGS": "ON"
            }
        }
    ],
    "buildPresets": [
        {
            "name": "nanobind",
            "displayName": "RelWithDebInfo (nanobind)",
            "configurePreset": "nanobind",
            "configuration": "RelWithDebInfo",
            "targets": [
                "install"
            ]
        }
    ]
  }
  ```

  As always, you can also add additional projects to the superbuild in the `extensions/` folder.
</details>


### Running

To use `mc_rtc`, you need to setup the environment variables for the local installation of `mc_rtc`.
This can be done by sourcing the following file:

```
source /home/vscode/workspace/install/setup_mc_rtc.sh
```


## Advanced

#### Generating core dump files (Ubuntu)

When debugging large programs, it is often more efficient to run it as you would always do, and upon crash have the kernel generate a "core dump" file.
This files contains runtime information about the state of your program, and can be used by debbuggers such as `gdb` to inspect the state of your program when it crashed.

On Ubuntu, by default, core dump files are managed by `apport` and disabled for non-official packages.
The easiest way to generate them is by disabling `apport` and manually specifying a location for the core files.

First disable apport
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
