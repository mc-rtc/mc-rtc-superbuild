mc_rtc superbuild
==

This project is a superbuild project for mc_rtc and related projects.

It will clone, update, build, install all of mc_rtc dependencies, mc_rtc itself and downstream projects. You can also extend the project locally or clone extensions to build your own projects.

There are two ways to use the superbuild:
- **Recommended:** Within isolated devcontainers (docker images). This will leave your host system intact, and come with a convenient environment pre-configured to efficiently work with the framework. For building within devcontainers, please refer to [doc/devcontainer.md](doc/devcontainer.md)
- Or locally on your host machine. Note that system dependencies (apt, pip, ROS, etc.) will be installed globally on your machine. For building with this method, keep reading this page.


Requirements
--

- [CMake >= 3.20](https://cmake.org/download/)
- [Git](https://git-scm.com/)
- [Visual Studio 2019 and later](https://visualstudio.microsoft.com/) (Windows)


### Installing the requirements (bootstrapping)

You can fullfill the requirements above by invoking our bootstraping script:

```sh
git clone https://github.com/mc-rtc/mc-rtc-superbuild
```

- on Debian like distributions: `./mc-rtc-superbuild/utils/bootstrap-linux.sh`
- on macOS: `./mc-rtc-superbuild/utils/bootstrap-macos.sh`

Usage
--

First, make sure you have configured `git`:
```sh
git config --global user.name "Full Name"
git config --global user.email "your.email@provider.com"
```

Then configure and run the superbuild as follows:

```shell
# Run the bootstrap script in mc-rtc-superbuild/utils folder if required
cmake -S mc-rtc-superbuild -B mc-rtc-superbuild/build -DSOURCE_DESTINATION=${HOME}/devel/src -DBUILD_DESTINATION=${HOME}/devel/build
cmake --build mc-rtc-superbuild/build --target install --config RelWithDebInfo
```

This will:

1. Install all required system dependencies
2. Create a meta-repository at `SOURCE_DESTINATION` (the folder must be empty or already created by another superbuild instance)
3. Add Git submodules for each of the projects in the meta-repository
4. Build each project in the `${BUILD_DESTINATION}/${PROJECT}` folder and install it in the provided `${CMAKE_INSTALL_PREFIX}`

You can then use the projects that were built and cloned by the superbuild as you would use projects you built and clone yourself. If you modify some projects, the superbuild will pick up on it and rebuild its dependents.

#### Note

On Linux and macOS, all commands of the form `cmake --build ${FOLDER} --config RelWithDebInfo --target ${TARGET}` can also be run by `make ${TARGET}` in `${FOLDER}`. In particular, you can start a build by simply doing `make` in the build folder.

You should avoid running something like `make -jN`. This will build up to `N` projects in parallel but each project will run its own parallelized build and that will likely be too much for your machine RAM or CPU.

Separate clone and build
==

If you want to clone everything before attempting the first build you can use the `clone` target:

```shell
git clone https://github.com/mc-rtc/mc-rtc-superbuild
cmake -S mc-rtc-superbuild -B mc-rtc-superbuild/build -DSOURCE_DESTINATION=${HOME}/devel/src -DBUILD_DESTINATION=${HOME}/devel/build
cd mc-rtc-superbuild/build
cmake --build . --config RelWithDebInfo --target clone
cmake --build . --config RelWithDebInfo
```

Update the repositories
==

You can run the `update` target to pull all the projects:
```shell
cmake --build . --config RelWithDebInfo --target update
```

Or invididually pull some of the projects and their dependencies:
```shell
cmake --build . --config RelWithDebInfo --target update-mc_rtc
```

Update mc-rtc-superbuild and extensions
==

You can run the `self-update` target to update mc-rtc-superbuild and all the cloned extensions:
```shell
cmake --build . --config RelWithDebInfo --target self-update
```


Uninstall projects
==

You can run the `uninstall` target to uninstall all the projects at once:
```shell
cmake --build . --target uninstall
```
It might require `sudo` if you install to a non-writable prefix (e.g. `/usr/local`)

You cam also uninstall a specific project:
```shell
cmake --build . --target uninstall-mc_rtc
```


Extensions
--

You can add extensions to the superbuild system by cloning extensions projects into the `extensions` folder, see for example the [lipm-walking-controller-superbuild](https://github.com/mc-rtc/lipm-walking-controller-superbuild) for an example centered around a single project.

```shell
cd mc-rtc-superbuild/extensions
git clone https://github.com/mc-rtc/lipm-walking-controller-superbuild
cd ../build/
# Will build mc_rtc and then the lipm-walking-controller project and its dependencies
cmake --build . --config RelWithDebInfo
```

You can also check out [superbuild-extensions](https://github.com/mc-rtc/superbuild-extensions) for commonly availabe extensions. Please refer to this repository for usage instructions.

Options
--

The following CMake options can be passed:

| Options | Default | Description |
| :---    | :-----: | :---        |
| `WITH_ROS_SUPPORT` | `ON` (Linux)<br/>`OFF` (others) | Build mc_rtc with the ROS plugin, install ROS if necessary |
| `WITH_LSSOL` | `OFF` | Enable the LSSOL QP solver, you must have access to the eigen-lssol package |
| `INSTALL_DOCUMENTATION` | `OFF` | Generate and install projects documentation on your local machine |
| `MC_RTC_SUPERBUILD_VERBOSE` | `OFF` | Output more information about the build actions |
| `VERBOSE_TEST_OUTPUT` | `OFF` | Output more information during testing |
| `MC_RTC_SUPERBUILD_SET_ENVIRONMENT` | `ON` | (Windows only) Changes the PATH variable |
| `BUILD_BENCHMARKS` | `OFF` | Build mc_rtc benchmarks |
| `INSTALL_SYSTEM_DEPENDENCIES` | `ON` | Install system-level dependencies, do not disable unless you known these requirements are fullfilled |
| `PYTHON_BINDING` | `ON` | Build mc_rtc Python bindings |
| `PYTHON_BINDING_USER_INSTALL` | `ON`(Windows)<br/> `OFF` (others) | Install the Python bindings in user space |
| `PYTHON_BINDING_FORCE_PYTHON2` | `OFF` | Force usage of  python2 instead of python |
| `PYTHON_BINDING_FORCE_PYTHON3` | `OFF` | Force usage of  python3 instead of python |
| `PYTHON_BINDING_BUILD_PYTHON2_AND_PYTHON3` | `OFF` | Build Python 2 and Python 3 bindings |
| `SOURCE_DESTINATION` | | If defined, projects will be cloned into this folder otherwise the `src` sub-folder in the superproject build directory is chosen |
| `BUILD_DESTINATION` | | If defined, projects will be build in this folder otherwise the `build` sub-folder in the superproject build directory is chosen |
| `LINK_BUILD_AND_SRC` | `ON` | Create a `build` symbolic link to the build folder in the source folder and a `to-src` symbolic link to the source folder in the build folder |
| `BUILD_LINK_SUFFIX` | | If defined, this is happened to the `build` symbolic link created by `LINK_BUILD_AND_SRC` |
| `LINK_COMPILE_COMMANDS` | `ON` | Create a symbolic link to the `compile_commands.json` file generated by CMake inside the source folder |
| `USE_MC_RTC_APT_MIRROR` | `OFF` | Use mc_rtc apt mirror to install some projects (only available on Ubuntu LTS) |
| `USE_MC_RTC_APT_MIRROR_STABLE` | `OFF` | Use the stable mirror rather than the head mirror |

Adding your own projects
--

You can:
- Add new `AddProject` declaration to the main `CMakeLists.txt` of this repository (look for `PERSONAL_PROJECTS` in that file to find the correct location)
- Create a new extension under the `extensions` folder:
```shell
mkdir -p extensions/local
editor extensions/local/CMakeLists.txt
```
- Create a simple `.cmake` under the `extensions` folder with your projects:
```shell
touch extensions/local.cmake
editor extensions/local.cmake
```

The remainder is an introduction of the functions offered by superbuild to specify your own project.

AddProject
==

`AddProject` specifies a new project, here is a simple example:

```cmake
AddProject(lipm_walking_controller
  GITHUB mehdi-benallegue/lipm_walking_controller
  GIT_TAG origin/rebase_stabilizer_ana
  DEPENDS copra mc_state_observation mc_plugin_footstep_plan_msgs
)
```

Here:
- `GITHUB` is a git source (see `AddGitSource` for available options and how to extend them)
- `GIT_TAG` is the branch or tag that we use for this repository. It defaults to `origin/main`. When `GIT_TAG` starts with `origin/` it is interpreted as a branch otherwise it is interpreted as a tag
- `DEPENDS` are other projects that are depended upon

Other options for `AddProject` are:
- `SUBFOLDER <folder>`: clone the repository in a subfolder of `SOURCE_DESTINATION`
- `CLONE_ONLY`: do not perform any build step, only clone the repository
- `SKIP_TEST`: do not run or build unit tests
- `NO_NINJA`: use CMake's default generator rather than ninja
- `NO_SOURCE_MONITOR`: disable source monitoring. By default, superbuild will monitor the source folder to force the rebuild of packages and their dependents when change happens. Some projects systematically trigger rebuilds under this monitor and this option disable it. Rebuilds then have to be triggered manually via the `force-${NAME}` target.
- `SKIP_SYMBOLIC_LINKS`: disable the creation of symbolic links. By default, on supported platforms, superbuild creates a link between the source folder and the build folder as well as a link from the source folder to the CMake's generated `compile_commands.json`. This option disables the behavior.
- `INSTALL_PREFIX`: override the provided `CMAKE_INSTALL_PREFIX`

For advanced usage, other options supported by [ExternalProject_Add](https://cmake.org/cmake/help/latest/module/ExternalProject.html) are also supported by `AddProject`.

In particular, `CMAKE_ARGS`, `CONFIGURE_COMMAND`, `BUILD_COMMAND` and `INSTALL_COMMAND` can be used to control the build.


CreateCatkinWorkspace
==

** `CreateCatkinWorkspace(ID <id> DIR <dir> {CATKIN_MAKE|CATKIN_BUILD} [CATKIN_BUILD_ARGS <args>...])` **


Declare a catkin workspace:
- `<id>` must be unique throughout the superbuild and its extensions
- `<dir>` is a directory (relative to `SOURCE_DESTINATION`) where the workspace is created
- `CATKIN_MAKE`/`CATKIN_BUILD` whether to build the workspace with `catkin_make` or `catkin build`
- `<args>` are passed as build arguments to `catkin build` when it is used

AddCatkinProject
==

** `AddCatkinProject(<name> WORKSPACE <id> [<options>]...)`

Adds a catkin project into the provided workspace. The git repository is provided through the same way as with `AddProject`.

If `WITH_ROS_SUPPORT` is `OFF` then this is treated like `AddProject`

AddPackageToCatkinSkiplist
==

** `AddPackageToCatkinSkiplist(<id> <package>)`

Adds the given package to the catkin build's skiplist


AddGitSource
==

** `AddGitSource(<id> <uri>)` **

Adds a new git source to superbuild:
- `<id>` unique id that can be used in subsequent `AddProject` commands
- `<uri>` corresponding Git URI (such that repository stubs can be appended to form full URIs)

superbuild knows the following source:
- `GITHUB` which is `https://github.com/`
- `GITHUB_PRIVATE` which is `git@github.com:`
- `GITE` which is `git@gite.lirmm.fr:`
- `GIT_REPOSITORY` which is empty, allowing one to put arbitrary fully qualified Git URI

AddProjectPlugin
==

** `AddProjectPlugin(<name> <project> [SUBFOLDER <folder>] [LINK_NAME <name>] [<options>]...)` **

Clone the project inside the provided `SUBFOLDER` of `<project>`. Other options are passed to `AddProject` but `CLONE_ONLY` is always enabled.

By default, the project is cloned in an hidden folder (due to submodule limitations) and linked inside the specified project's source directory as `${SUBFOLDER}/${NAME}`. `LINK_NAME` can override this behavior and create the link to `${SUBFOLDER}/${LINK_NAME}`.

AptInstall
==


** `AptInstall(<package> ...)` **

Wrapper around the `apt` command to install system packages. The function does nothing on non-Debian-based systems. Otherwise it installs the provided packages that are missing.

The packages specified by calling these commands will be installed together at the end of the configuration process. If the packages are required immediately you can use `AptInstallNow`.

RequireExtension
==

**`RequireExtension(FOLDER ...)`**

This allows an extension to require another extension and make sure this extension is included before the one being processed.

Supported arguments are the one of [`FetchContent_Declare`](https://cmake.org/cmake/help/latest/module/FetchContent.html)
