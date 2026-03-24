cmake_minimum_required(VERSION 3.16)
project(winnm LANGUAGES CXX)

# --------------------------------------------------
# ccls / clangd support
# --------------------------------------------------
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# --------------------------------------------------
# Qt setup
# --------------------------------------------------
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)   # needed because we use resources.qrc
set(CMAKE_AUTOUIC ON)

find_package(Qt6 REQUIRED COMPONENTS
    Core        # ⚠️ ALWAYS include Core (very important)
    Gui
    Qml
    Quick
    DBus
    Concurrent
)

# LayerShellQt (for Linux panel behavior)
find_package(LayerShellQt REQUIRED)

# --------------------------------------------------
# Build target
# --------------------------------------------------
qt_add_executable(winnm
    main.cpp
    resources.qrc
)

target_link_libraries(winnm PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::DBus
    Qt6::Concurrent 
    LayerShellQt::Interface
)

target_compile_features(winnm PRIVATE cxx_std_17)

# --------------------------------------------------
# Copy compile_commands.json to project root
# (great for clangd / ccls)
# --------------------------------------------------
add_custom_target(copy_compile_commands ALL
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        ${CMAKE_BINARY_DIR}/compile_commands.json
        ${CMAKE_SOURCE_DIR}/compile_commands.json
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

apply_strict_flags(winnm) 
