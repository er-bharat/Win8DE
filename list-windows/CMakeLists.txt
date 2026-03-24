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
# Warnings & tooling
# ----------------------------
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

option(ENABLE_STRICT_BUILD "Treat warnings as errors" ON)
option(ENABLE_SANITIZERS "Enable sanitizers" OFF)

if (CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")

    # ---- C++ warnings ----
    target_compile_options(list-windows PRIVATE
        $<$<COMPILE_LANGUAGE:CXX>:
            -Wall -Wextra -Wpedantic
            -Wshadow -Wconversion -Wsign-conversion
            -Wnull-dereference -Wdouble-promotion -Wformat=2
            -Wold-style-cast -Woverloaded-virtual -Wnon-virtual-dtor
            -Wduplicated-cond -Wduplicated-branches -Wlogical-op -Wuseless-cast
            -Wno-unused-parameter -Wno-missing-field-initializers
        >
    )

    # ---- C warnings (clean subset) ----
    target_compile_options(list-windows PRIVATE
        $<$<COMPILE_LANGUAGE:C>:
            -Wall -Wextra -Wpedantic
            -Wshadow
            -Wno-unused-parameter
        >
    )

    if (ENABLE_STRICT_BUILD)
        target_compile_options(list-windows PRIVATE -Werror)
    endif()

    if (ENABLE_SANITIZERS)
        target_compile_options(list-windows PRIVATE
            -fsanitize=address,undefined -fno-omit-frame-pointer)
        target_link_options(list-windows PRIVATE
            -fsanitize=address,undefined)
    endif()

endif()
