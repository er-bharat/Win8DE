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
    QuickControls2
)

find_package(LayerShellQt REQUIRED)


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
)

# ----------------------------
# Compile flags
# ----------------------------
target_compile_options(Win8Running PRIVATE
    -Wall
    -Wextra
    -Wpedantic
)

# ----------------------------
# Copy compile_commands.json for ccls
# ----------------------------
add_custom_command(
    TARGET Win8Running POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        ${CMAKE_BINARY_DIR}/compile_commands.json
        ${CMAKE_SOURCE_DIR}/compile_commands.json
    COMMENT "Copying compile_commands.json to source directory for ccls"
)
