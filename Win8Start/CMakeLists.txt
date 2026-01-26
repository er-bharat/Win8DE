cmake_minimum_required(VERSION 3.16)
project(Win8Start LANGUAGES CXX C)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Enable Qt6 automatic features
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# ----------------------------
# Find Qt6 packages
# ----------------------------
find_package(Qt6 REQUIRED COMPONENTS
    Core
    Gui
    Widgets
    Quick
    QuickControls2
    QuickLayouts
    Concurrent
    DBus
)

# ----------------------------
# LayerShellQt
# ----------------------------
find_package(LayerShellQt REQUIRED)

# ----------------------------
# Wayland
# ----------------------------
find_package(PkgConfig REQUIRED)
pkg_check_modules(WAYLAND REQUIRED wayland-client)

include_directories(
    ${WAYLAND_INCLUDE_DIRS}
    ${CMAKE_CURRENT_SOURCE_DIR}  # for protocol header
)
link_directories(${WAYLAND_LIBRARY_DIRS})

# ----------------------------
# Sources
# ----------------------------
set(SOURCES
    main.cpp
    windowwatcher.cpp
    windowwatcher.h
    resources.qrc
    wlr-foreign-toplevel-management-unstable-v1-client-protocol.c
)

# Make sure protocol C file is compiled as C
set_source_files_properties(
    wlr-foreign-toplevel-management-unstable-v1-client-protocol.c
    PROPERTIES LANGUAGE C
)

# ----------------------------
# Executable
# ----------------------------
add_executable(Win8Start ${SOURCES})

# ----------------------------
# Link libraries
# ----------------------------
target_link_libraries(Win8Start
    PRIVATE
        Qt6::Core
        Qt6::Gui
        Qt6::Widgets
        Qt6::Quick
        Qt6::QuickControls2
        Qt6::QuickLayouts
        Qt6::DBus
        Qt6::Concurrent
        LayerShellQt::Interface
        ${WAYLAND_LIBRARIES}
        pthread
)

# ----------------------------
# Set runtime output directory
# ----------------------------
set_target_properties(Win8Start PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}
)
