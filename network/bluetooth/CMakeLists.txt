cmake_minimum_required(VERSION 3.16)
project(winbt LANGUAGES CXX)

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
set(CMAKE_AUTORCC ON)   # If you use resources.qrc
set(CMAKE_AUTOUIC ON)

find_package(Qt6 REQUIRED COMPONENTS
    Core
    Gui
    Qml
    Quick
    DBus
)

# LayerShellQt (optional, for Linux panel-style behavior)
find_package(LayerShellQt REQUIRED)

# --------------------------------------------------
# Build target
# --------------------------------------------------
qt_add_executable(winbt
    main.cpp
    resources.qrc  # optional if you have QML/resources
)

target_link_libraries(winbt PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::DBus
    LayerShellQt::Interface  # optional if using panels/overlays
)

target_compile_features(winbt PRIVATE cxx_std_17)

# --------------------------------------------------
# Copy compile_commands.json to project root
# --------------------------------------------------
add_custom_target(copy_compile_commands ALL
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        ${CMAKE_BINARY_DIR}/compile_commands.json
        ${CMAKE_SOURCE_DIR}/compile_commands.json
)
