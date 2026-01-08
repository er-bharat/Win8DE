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
    Widgets
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
    Qt6::Widgets
)

# ----------------------------
# Compile flags
# ----------------------------
target_compile_options(Win8Running PRIVATE
    -Wall
    -Wextra
    -Wpedantic
)

