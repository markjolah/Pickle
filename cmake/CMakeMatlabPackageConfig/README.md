# CMakeMatlabPackageConfig
CMake modules to configure and install Matlab projects and dependencies.

 * Installs a `startup<PkgName>.m` file to add matlab code path and call dependency startup scripts.
 * Sets up build-tree and install-tree CMake Package config files.
    * Build tree exports set path directly to source file, so edits are directly applied to source for development.
 * Integrates with [MexIFace](http://markjolah.github.io/MexIFace) CMake packages and build system.

## LICENSE

* Copyright: 2019
* Author: Mark J. Olah
* Email: (mjo@cs.unm DOT edu)
* LICENSE: Apache 2.0.  See [LICENSE](LICENSE) file.
