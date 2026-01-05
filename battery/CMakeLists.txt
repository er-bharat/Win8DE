cmake_minimum_required(VERSION 3.16)
project(battery-daemon LANGUAGES CXX)

# --------------------------------------------------
# ccls / clangd support
# --------------------------------------------------
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# --------------------------------------------------
# Qt setup
# --------------------------------------------------
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt6 REQUIRED COMPONENTS
    Gui
    Qml
    Quick
    DBus
)
# LayerShellQt (for Linux panel behavior)
find_package(LayerShellQt REQUIRED)
# --------------------------------------------------
# Build target
# --------------------------------------------------
add_executable(battery-daemon
    main.cpp        # ✅ add QML file
    resources.qrc
)

target_link_libraries(battery-daemon
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::DBus
    LayerShellQt::Interface
)

target_compile_features(battery-daemon PRIVATE cxx_std_17)

# --------------------------------------------------
# Copy compile_commands.json to project root
# --------------------------------------------------

