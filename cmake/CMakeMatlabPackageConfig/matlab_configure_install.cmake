# matlab_configure_install.cmake
# Copyright 2018-2019
# Author: Mark J. Olah
# Email: (mjo@cs.unm DOT edu)
#
# Sets up a ${PACKAGE_NAME}config-matlab.cmake file for passing Matlab configuration to dependencies via the CMake packaging system.
# Installs Matlab code and startup${PACKAGE_NAME}.m file for Matlab integration, which is able to run dependent startup.m file
# from DEPENDENCY_STARTUP_M_LOCATIONS
#
# Configures a build-tree export which enables editing of the sources .m files in-repository. [EXPORT_BUILD_TREE True]
#
#
# Options:
# Single Argument Keywords:
#  CONFIG_DIR - [Default: ${CMAKE_BINARY_DIR}] Path within build directory to make configured files before installation.
#                                              Also serves as the exported build directory for build-tree exports
#  PACKAGE_CONFIG_TEMPLATE -  The template for the main ${PROJECT_NAME}Config.cmake Package Config file. [Default: do not install a main ${PROJECT_NAME}Config.cmake.]
#  PACKAGE_CONFIG_MATLAB_TEMPLATE -  The template for the matlab portion of the package config.
#         [Default: Look for Templates/PackageConfig-matlab.cmake.in]
#  CONFIG_INSTALL_DIR - [Default: lib/cmake/${PROJECT_NAME}] Relative path from ${CMAKE_INSTALL_PREFIX} at which to install PackageConfig.cmake files
#  MATLAB_SRC_DIR - [Default: matlab] relative to ${CMAKE_SOURCE_DIR}
#  STARTUP_M_TEMPLATE - [Default: ../[Templates|templates]/startupPackage.m.in
#  STARTUP_M_FILE - [Default: startup${PROJECT_NAME}.m
#  MATLAB_CODE_INSTALL_DIR - [Default: lib/${PACKAGE_NAME}/matlab] Should be relative to CMAKE_INSTALL_PREFIX
#  EXPORT_BUILD_TREE - bool. [optional] [Default: False] - Enable the export of the build tree. And configuration of startup<PACKAGE_NAME>.cmake
#                        script that can be used from the build tree.  For development.
# Multi-Argument Keywords:
#  DEPENDENCY_STARTUP_M_LOCATIONS - Paths for .m files that this package depends on.  Should be relative to CMAKE_INSTALL_PREFIX,
#                                  or absolute for files outside the install prefix
#
# Controlling CMake option variables (these are CMake variables not parsed function arguments):
#  OPT_MATLAB_INSTALL_DISTRIBUTION_STARTUP - If true copy the startup#{PROJECT_NAME}.m file to the root of INSTALL_PREFIX.
#           This should be set only if this is the primary package for a distributable Matlab directory.  Having the startup file at root level
#           makes it easier for users to find it.  This option should be disabled if installing to a system prefix or to user's home directory.

set(_matlab_configure_install_PATH ${CMAKE_CURRENT_LIST_DIR})
function(matlab_configure_install)
    set(options)
    set(oneValueArgs CONFIG_DIR PACKAGE_CONFIG_TEMPLATE PACKAGE_CONFIG_MATLAB_TEMPLATE CONFIG_INSTALL_DIR
                     MATLAB_SRC_DIR STARTUP_M_TEMPLATE STARTUP_M_FILE
                     MATLAB_CODE_INSTALL_DIR EXPORT_BUILD_TREE)
    set(multiValueArgs DEPENDENCY_STARTUP_M_LOCATIONS)
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}"  ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "Unknown keywords given to install_smarter_package_version_file(): \"${_SVF_UNPARSED_ARGUMENTS}\"")
    endif()
    if(NOT ARG_CONFIG_DIR)
        set(ARG_CONFIG_DIR ${CMAKE_BINARY_DIR})
    endif()

#     if(NOT ARG_PACKAGE_CONFIG_TEMPLATE)
#         find_file(_MATLAB_CONFIGURE_INSTALL_PACKAGE_CONFIG_TEMPLATE PackageConfig.cmake.in
#                 PATHS ${CMAKE_SOURCE_DIR}/Templates/PackageConfig.cmake.in  NO_DEFAULT_PATH NO_CMAKE_FIND_ROOT_PATH)
#         mark_as_advanced(_MATLAB_CONFIGURE_INSTALL_PACKAGE_CONFIG_TEMPLATE)
#         if(_MATLAB_CONFIGURE_INSTALL_PACKAGE_CONFIG_MATLAB_TEMPLATE)
#             set(ARG_PACKAGE_CONFIGTEMPLATE ${_MATLAB_CONFIGURE_INSTALL_PACKAGE_CONFIG_TEMPLATE})
#         endif()
#     endif()

    if(NOT ARG_PACKAGE_CONFIG_MATLAB_TEMPLATE)
        find_file(_MATLAB_CONFIGURE_INSTALL_PACKAGE_CONFIG_MATLAB_TEMPLATE PackageConfig-matlab.cmake.in
                PATHS ${_matlab_configure_install_PATH}/Templates  NO_DEFAULT_PATH NO_CMAKE_FIND_ROOT_PATH)
        mark_as_advanced(_MATLAB_CONFIGURE_INSTALL_PACKAGE_CONFIG_MATLAB_TEMPLATE)
        if(NOT _MATLAB_CONFIGURE_INSTALL_PACKAGE_CONFIG_MATLAB_TEMPLATE)
            message(FATAL_ERROR "Unable to find PackageConfig-matlab.cmake.in. Cannot configure exports.")
        else()
            set(ARG_PACKAGE_CONFIG_MATLAB_TEMPLATE ${_MATLAB_CONFIGURE_INSTALL_PACKAGE_CONFIG_MATLAB_TEMPLATE})
        endif()
    endif()

    if(NOT ARG_CONFIG_INSTALL_DIR)
        set(ARG_CONFIG_INSTALL_DIR lib/${PROJECT_NAME}/cmake) #Where to install project Config.cmake and ConfigVersion.cmake files
    endif()

    if(NOT ARG_MATLAB_SRC_DIR)
        set(ARG_MATLAB_SRC_DIR ${CMAKE_SOURCE_DIR}/matlab)
    endif()

    if(NOT ARG_STARTUP_M_TEMPLATE)
        find_file(_MATLAB_CONFIGURE_INSTALL_STARTUP_M_TEMPLATE startupPackage.m.in
                PATHS ${_matlab_configure_install_PATH}/Templates NO_DEFAULT_PATH NO_CMAKE_FIND_ROOT_PATH)
        mark_as_advanced(_MATLAB_CONFIGURE_INSTALL_STARTUP_M_TEMPLATE)
        if(NOT _MATLAB_CONFIGURE_INSTALL_STARTUP_M_TEMPLATE)
            message(FATAL_ERROR "Unable to find startupPackage.m.in. Cannot configure exports.")
        else()
            set(ARG_STARTUP_M_TEMPLATE ${_MATLAB_CONFIGURE_INSTALL_STARTUP_M_TEMPLATE})
        endif()
    endif()

    if(NOT ARG_STARTUP_M_FILE)
        set(ARG_STARTUP_M_FILE startup${PROJECT_NAME}.m)
    endif()

    if(NOT ARG_MATLAB_CODE_INSTALL_DIR)
        set(ARG_MATLAB_CODE_INSTALL_DIR lib/${PROJECT_NAME}/matlab)
    elseif(IS_ABSOLUTE ARG_MATLAB_CODE_INSTALL_DIR)
        file(RELATIVE_PATH ARG_MATLAB_CODE_INSTALL_DIR ${CMAKE_INSTALL_PREFIX} ${ARG_MATLAB_CODE_INSTALL_DIR})
    endif()

    if(NOT ARG_BUILD_TREE_STARTUP_M_LOCATION)
        set(ARG_BUILD_TREE_STARTUP_M_LOCATION ${CMAKE_BINARY_DIR}/startup${PACKAGE_NAME}.m)
    endif()
    if(NOT ARG_DEPENDENCY_STARTUP_M_LOCATIONS)
        set(ARG_DEPENDENCY_STARTUP_M_LOCATIONS)
    endif()
    list(APPEND ARG_DEPENDENCY_STARTUP_M_LOCATIONS ${MexIFace_MATLAB_STARTUP_M})

    # Set different names for build-tree and install-tree files
    set(ARG_PACKAGE_CONFIG_FILE ${PROJECT_NAME}Config-matlab.cmake)
    if(OPT_EXPORT_BUILD_TREE AND NOT DEFINED ARG_EXPORT_BUILD_TREE)
        set(ARG_EXPORT_BUILD_TREE True)
    endif()
    set(ARG_STARTUP_M_INSTALL_TREE_FILE ${ARG_STARTUP_M_FILE}.install_tree)
    if(ARG_EXPORT_BUILD_TREE)
        set(ARG_PACKAGE_CONFIG_INSTALL_TREE_FILE ${PROJECT_NAME}Config-matlab.cmake.install_tree) #Generated <Package>Config.cmake Version meant for the install tree but name mangled to prevent use in build tree
    else()
        set(ARG_PACKAGE_CONFIG_INSTALL_TREE_FILE ${ARG_PACKAGE_CONFIG_FILE}) #Generated <Package>Config.cmake Version meant for the install tree but name mangled to prevent use in build tree
    endif()

    #Install Matlab source
    if(BUILD_TESTING AND (NOT DEFINED OPT_INSTALL_TESTING OR OPT_INSTALL_TESTING))
        set(_EXCLUDE) #
    else()
        set(_EXCLUDE REGEX "\\+Test" EXCLUDE)
    endif()
    install(DIRECTORY matlab/ DESTINATION ${ARG_MATLAB_CODE_INSTALL_DIR} COMPONENT Runtime ${_EXCLUDE})
    unset(_EXCLUDE)

    include(CMakePackageConfigHelpers)
    if(ARG_PACKAGE_CONFIG_TEMPLATE)
        #Main ${PROJECT_NAME}Config.cmake package config file (includes the ${PROJECT_NAME}@Config-matlab.cmake file)
        configure_package_config_file(${ARG_PACKAGE_CONFIG_TEMPLATE} ${ARG_CONFIG_DIR}/${PROJECT_NAME}Config.cmake
                                    INSTALL_DESTINATION ${ARG_CONFIG_INSTALL_DIR})
        install(FILES ${ARG_CONFIG_DIR}/${PROJECT_NAME}Config.cmake  DESTINATION ${ARG_CONFIG_INSTALL_DIR} COMPONENT Development)
    endif()

    #install-tree export config ${PROJECT_NAME}Config-matlab.cmake
    if(IS_ABSOLUTE ARG_CONFIG_INSTALL_DIR)
        set(ABSOLUTE_CONFIG_INSTALL_DIR ${ARG_CONFIG_INSTALL_DIR})
    else()
        set(ABSOLUTE_CONFIG_INSTALL_DIR ${CMAKE_INSTALL_PREFIX}/${ARG_CONFIG_INSTALL_DIR})
    endif()
    set(_MATLAB_CODE_DIR ${ARG_MATLAB_CODE_INSTALL_DIR}) #Set relative to install prefix for configure_package_config_file
    set(_MATLAB_STARTUP_M ${ARG_MATLAB_CODE_INSTALL_DIR}/${ARG_STARTUP_M_FILE})
    configure_package_config_file(${ARG_PACKAGE_CONFIG_MATLAB_TEMPLATE} ${ARG_CONFIG_DIR}/${ARG_PACKAGE_CONFIG_INSTALL_TREE_FILE}
                                    INSTALL_DESTINATION ${ARG_CONFIG_INSTALL_DIR}
                                    PATH_VARS _MATLAB_CODE_DIR _MATLAB_STARTUP_M
                                    NO_CHECK_REQUIRED_COMPONENTS_MACRO)
    install(FILES ${ARG_CONFIG_DIR}/${ARG_PACKAGE_CONFIG_INSTALL_TREE_FILE} RENAME ${ARG_PACKAGE_CONFIG_FILE}
            DESTINATION ${ARG_CONFIG_INSTALL_DIR} COMPONENT Development)

    #startup.m install-tree
    set(_MATLAB_CODE_DIR ".") # Relative to startup<PACKAGE_NAME>.m file startup.m
    set(_STARTUP_M_INSTALL_DIR ${ARG_MATLAB_CODE_INSTALL_DIR}) #Install dir relative to install prefix
    #Remap install time dependent startup.m locations to be relative to startup@PACKAGE_NAME@.m location
    set(_DEPENDENCY_STARTUP_M_LOCATIONS)
    message("GOT ARG_DEPENDENCY_STARTUP_M_LOCATIONS:${ARG_DEPENDENCY_STARTUP_M_LOCATIONS}")
    file(RELATIVE_PATH _install_rpath "/${ARG_MATLAB_CODE_INSTALL_DIR}" "/")
    foreach(location IN LISTS ARG_DEPENDENCY_STARTUP_M_LOCATIONS)
        string(REGEX REPLACE "^${CMAKE_INSTALL_PREFIX}/" "${_install_rpath}" location ${location})
        list(APPEND _DEPENDENCY_STARTUP_M_LOCATIONS ${location})
    endforeach()
    configure_file(${ARG_STARTUP_M_TEMPLATE} ${ARG_CONFIG_DIR}/${ARG_STARTUP_M_INSTALL_TREE_FILE})
    install(FILES ${ARG_CONFIG_DIR}/${ARG_STARTUP_M_INSTALL_TREE_FILE} RENAME ${ARG_STARTUP_M_FILE}
            DESTINATION ${ARG_MATLAB_CODE_INSTALL_DIR} COMPONENT Runtime)
    if(OPT_MATLAB_INSTALL_DISTRIBUTION_STARTUP)
        #Install a copy of the startup at the root of install-tree for convenience of end MATLAB users
        install(FILES ${ARG_CONFIG_DIR}/${ARG_STARTUP_M_INSTALL_TREE_FILE} RENAME ${ARG_STARTUP_M_FILE}
                DESTINATION "." COMPONENT Runtime)
    endif()
    unset(_MATLAB_INSTALLED_MEX_PATH)

    if(ARG_EXPORT_BUILD_TREE)
        #build-tree export
        file(RELATIVE_PATH _MATLAB_CODE_DIR ${CMAKE_BINARY_DIR} ${ARG_MATLAB_SRC_DIR}) #Relative to CMAKE_BINARY_DIR
        set(_MATLAB_STARTUP_M ${ARG_CONFIG_DIR}/${ARG_STARTUP_M_FILE})
        if(ARG_EXPORT_BUILD_TREE)
            #build-tree export config @PACKAGE_NAME@Config-matlab.cmake
            configure_package_config_file(${ARG_PACKAGE_CONFIG_MATLAB_TEMPLATE} ${ARG_PACKAGE_CONFIG_FILE}
                                        INSTALL_DESTINATION ${ARG_CONFIG_DIR}
                                        INSTALL_PREFIX ${ARG_CONFIG_DIR}
                                        PATH_VARS _MATLAB_CODE_DIR _MATLAB_STARTUP_M
                                        NO_CHECK_REQUIRED_COMPONENTS_MACRO)
        endif()

        #startup.m build-tree
        set(_STARTUP_M_INSTALL_DIR) #Set to empty in build tree export to signal to startup.m that it is run from build tree
        #Remap build time dependent startup.m locations to be relative to startup@PACKAGE_NAME@.m location
        set(_DEPENDENCY_STARTUP_M_LOCATIONS)
        foreach(location IN LISTS ARG_DEPENDENCY_STARTUP_M_LOCATIONS)
            file(RELATIVE_PATH location ${CMAKE_BINARY_DIR} ${location})
            list(APPEND _DEPENDENCY_STARTUP_M_LOCATIONS ${location})
        endforeach()
        configure_file(${ARG_STARTUP_M_TEMPLATE} ${ARG_CONFIG_DIR}/${ARG_STARTUP_M_FILE})
    endif()
endfunction()

