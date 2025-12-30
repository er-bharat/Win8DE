cmake_minimum_required(VERSION 3.14)
project(WaylandWindowMonitor)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ----------------------------
# Export compile commands for ccls
# ----------------------------
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# ----------------------------
# Qt6
# ----------------------------
find_package(Qt6 REQUIRED COMPONENTS Core Network)
find_package(PkgConfig REQUIRED)

# ----------------------------
# Wayland
# ----------------------------
pkg_check_modules(WAYLAND REQUIRED wayland-client)

include_directories(
    ${WAYLAND_INCLUDE_DIRS}
    ${CMAKE_CURRENT_SOURCE_DIR}
)

# ----------------------------
# Executable
# ----------------------------
add_executable(list-windows
    main.cpp
    wlr-foreign-toplevel-management-unstable-v1-protocol.c
)

# ----------------------------
# Link libraries
# ----------------------------
target_link_libraries(list-windows
    ${WAYLAND_LIBRARIES}
    Qt6::Core
    Qt6::Network
)

# ----------------------------
# Optional: Set compile flags for better ccls parsing
# ----------------------------
target_compile_options(list-windows PRIVATE
    -Wall
    -Wextra
    -Wpedantic
)

# ----------------------------
# Automatically copy compile_commands.json to source dir
# ----------------------------
add_custom_command(
    TARGET list-windows POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        ${CMAKE_BINARY_DIR}/compile_commands.json
        ${CMAKE_SOURCE_DIR}/compile_commands.json
    COMMENT "Copying compile_commands.json to source directory for ccls"
)
