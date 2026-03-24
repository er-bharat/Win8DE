cmake_minimum_required(VERSION 3.14)
project(Win8Running)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

# ----------------------------
# Export compile commands for ccls
# ----------------------------
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# ----------------------------
# Qt6
# ----------------------------
find_package(Qt6 REQUIRED COMPONENTS
    Core
    Gui
    Qml
    Quick
    # Widgets
    QuickControls2
)

find_package(LayerShellQt REQUIRED)

# Find Qt packages including Widgets

# ----------------------------
# Executable
# ----------------------------
add_executable(Win8Running
    main.cpp
    resources.qrc
)

# ----------------------------
# Link Qt libraries
# ----------------------------
target_link_libraries(Win8Running
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    LayerShellQt::Interface
    # Qt6::Widgets
)

# ----------------------------
# Warnings & tooling
# ----------------------------
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

option(ENABLE_STRICT_BUILD "Treat warnings as errors" ON)
option(ENABLE_SANITIZERS "Enable sanitizers" OFF)

if (CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    target_compile_options(Win8Running PRIVATE
        -Wall -Wextra -Wpedantic
        -Wshadow -Wconversion -Wsign-conversion
        -Wnull-dereference -Wdouble-promotion -Wformat=2
        -Wold-style-cast -Woverloaded-virtual -Wnon-virtual-dtor
        -Wduplicated-cond -Wduplicated-branches -Wlogical-op -Wuseless-cast
        -Wno-unused-parameter -Wno-missing-field-initializers
    )

    if (ENABLE_STRICT_BUILD)
        target_compile_options(Win8Running PRIVATE -Werror)
    endif()

    if (ENABLE_SANITIZERS)
        target_compile_options(Win8Running PRIVATE -fsanitize=address,undefined -fno-omit-frame-pointer)
        target_link_options(Win8Running PRIVATE -fsanitize=address,undefined)
    endif()
endif()


