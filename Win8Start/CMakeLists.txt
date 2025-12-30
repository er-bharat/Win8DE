cmake_minimum_required(VERSION 3.16)
project(Win8Start LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# Find Qt packages including Widgets
find_package(Qt6 REQUIRED COMPONENTS Core Gui Widgets Quick QuickControls2 QuickLayouts)

# LayerShellQt (for Linux panel behavior)
find_package(LayerShellQt REQUIRED)

# Source files
set(SOURCES
    main.cpp
    resources.qrc
)

# Executable
add_executable(Win8Start ${SOURCES})

# Link libraries
target_link_libraries(Win8Start
    PRIVATE Qt6::Core
            Qt6::Gui
            Qt6::Widgets
            Qt6::Quick
            Qt6::QuickControls2
            Qt6::QuickLayouts
            Qt6::Concurrent
            LayerShellQt::Interface
)

# Set runtime output directory
set_target_properties(Win8Start PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}
)
