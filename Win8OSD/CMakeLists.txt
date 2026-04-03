cmake_minimum_required(VERSION 3.18)
project(Win8OSD LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Quick Qml Network)
find_package(LayerShellQt REQUIRED)

# 🟦 Client
qt_add_executable(Win8OSD-client
    Win8OSD-client.cpp
)

target_link_libraries(Win8OSD-client
    PRIVATE Qt6::Core Qt6::Network
)

# 🟩 Server (QML + GUI)
qt_add_executable(Win8OSD-server
    Win8OSD-server.cpp
    resources.qrc
)

target_link_libraries(Win8OSD-server
    PRIVATE
        Qt6::Core
        Qt6::Gui
        Qt6::Quick
        Qt6::Qml
        Qt6::Network
        LayerShellQt::Interface
)

# --------------------------------------------------
# ccls / clangd support
# --------------------------------------------------
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# --------------------------------------------------
# ⚠️ Shared warnings & sanitizers config (Linux only)
# --------------------------------------------------
option(ENABLE_STRICT_BUILD "Treat warnings as errors" ON)
option(ENABLE_SANITIZERS "Enable sanitizers" OFF)

function(apply_strict_flags target)
    # Only GCC/Clang on Linux
    if (CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")

        target_compile_options(${target} PRIVATE
            -Wall -Wextra -Wpedantic
            -Wshadow -Wconversion -Wsign-conversion
            -Wnull-dereference -Wdouble-promotion -Wformat=2
            -Wold-style-cast -Woverloaded-virtual -Wnon-virtual-dtor
            -Wduplicated-cond -Wduplicated-branches -Wlogical-op -Wuseless-cast
            -Wcast-align -Wcast-qual -Wfloat-equal -Wundef -Wswitch-enum
            -Wzero-as-null-pointer-constant
            -Wno-unused-parameter
            -Wno-missing-field-initializers
        )

        if (ENABLE_STRICT_BUILD)
            target_compile_options(${target} PRIVATE -Werror)
        endif()

        if (ENABLE_SANITIZERS)
            target_compile_options(${target} PRIVATE
                -fsanitize=address,undefined -fno-omit-frame-pointer)
            target_link_options(${target} PRIVATE
                -fsanitize=address,undefined)
        endif()
    endif()
endfunction()

apply_strict_flags(Win8OSD-server) 
apply_strict_flags(Win8OSD-client) 
