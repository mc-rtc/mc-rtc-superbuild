mc_rtc superbuild
==

This project is a superbuild project for mc_rtc and related projects.

It will build all mc_rtc dependencies, mc_rtc itself and downstream projects. You can also extend the project locally or clone extensions to build your own projects.

Requirements
--

- [CMake >= 3.20](https://cmake.org/download/)
- [Git](https://git-scm.com/)
- [Visual Studio 2019 and later](https://visualstudio.microsoft.com/) (Windows)

### Bootstraping

You can fullfill the requirements above by invoking our bootstraping script:

- on Debian like distributions: `./utils/bootstrap-linux.sh`
- on macOS: `./utils/bootstrap-macos.sh`

Usage
--

```shell
git clone https://github.com/mc-rtc/mc-rtc-superbuild
cmake -S mc-rtc-superbuild -B .
cmake --build . --config RelWithDebInfo
```

By default, this will:

1. Install all required system dependencies
2. Clone each project in the `src/${PROJECT}` folder or the appropriate catkin worskapace
3. Build each project in the `build/${PROJECT}` folder

Extensions
--

You can add extensions to the superbuild system by cloning extensions projects into the `extensions` folder, see for example the [lipm-walking-controller-superbuild](https://github.com/mc-rtc/lipm-walking-controller-superbuild) project.

```shell
cd mc-rtc-superbuild/extensions
git clone https://github.com/mc-rtc/lipm-walking-controller-superbuild
cd ../../
# Will build mc_rtc and then the lipm-walking-controller project and its dependencies
cmake --build . --config RelWithDebInfo
```

Options
--

The following CMake options can be passed:

| Options | Default | Description |
| :---    | :-----: | :---        |
| `WITH_ROS_SUPPORT` | `ON` (Linux)\n`OFF` (others) | Build mc_rtc with the ROS plugin, install ROS if necessary |
| `WITH_LSSOL` | `OFF` | Enable the LSSOL QP solver, you must have access to the eigen-lssol package |
| `UPDATE_ALL` | `ON` | Update all packages when the super-project is built. If this is off you can select a subset of packages to update anyway |
| `INSTALL_DOCUMENTATION` | `OFF` | Generate and install projects documentation on your local machine |
| `CLONE_ONLY` | `OFF` | Only clone (or update) the packages |
| `MC_RTC_SUPERBUILD_VERBOSE` | `OFF` | Output more information about the build actions |
| `MC_RTC_SUPERBUILD_SET_ENVIRONMENT` | `ON` | (Windows only) Changes the PATH variable |
| `BUILD_BENCHMARKS` | `OFF` | Build mc_rtc benchmarks |
| `INSTALL_SYSTEM_DEPENDENCIES` | `ON` | Install system-level dependencies, do not disable unless you known these requirements are fullfilled |
| `PYTHON_BINDING` | `ON` | Build mc_rtc Python bindings |
| `PYTHON_BINDING_USER_INSTALL` | `ON`(Windows)\n `OFF` (others) | Install the Python bindings in user space |
| `PYTHON_BINDING_FORCE_PYTHON2` | `OFF` | Force usage of  python2 instead of python |
| `PYTHON_BINDING_FORCE_PYTHON3` | `OFF` | Force usage of  python3 instead of python |
| `PYTHON_BINDING_BUILD_PYTHON2_AND_PYTHON3` | `OFF` | Build Python 2 and Python 3 bindings |
| `SOURCE_DESTINATION` | | If defined, projects will be cloned into this folder otherwise the `src` sub-folder in the superproject build directory is chosen |
| `BUILD_DESTINATION` | | If defined, projects will be build in this folder otherwise the `build` sub-folder in the superproject build directory is chosen |
