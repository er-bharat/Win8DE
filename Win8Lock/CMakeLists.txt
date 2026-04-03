cmake_minimum_required(VERSION 3.16)
project(Win8Lock LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick)
find_library(PAM_LIBRARY pam REQUIRED)

# LayerShellQt include and link
find_path(LAYERSHELLQT_INCLUDE_DIR LayerShellQt/window.h)
find_library(LAYERSHELLQT_LIBRARY NAMES LayerShellQtInterface)

include_directories(${LAYERSHELLQT_INCLUDE_DIR})

add_executable(Win8Lock
    main.cpp
    lockmanager.cpp
    lockmanager.h
    resources.qrc
)

target_link_libraries(Win8Lock PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    ${LAYERSHELLQT_LIBRARY}
    ${PAM_LIBRARY}
)


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

apply_strict_flags(Win8Lock) 

# --------------------------------------------------
# ccls / clangd support
# --------------------------------------------------
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

