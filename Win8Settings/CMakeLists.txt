cmake_minimum_required(VERSION 3.16)
project(Win8Settings LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Enable automoc, autorcc, autouic
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# Find Qt6 packages
find_package(Qt6 REQUIRED COMPONENTS
    Core
    Gui
    Widgets
    Quick
    QuickControls2
    QuickLayouts
    Concurrent
)

# LayerShellQt (for Wayland panel placement)
find_package(LayerShellQt REQUIRED)

# Source files
set(SOURCES
    main.cpp
    resources.qrc
)

# Create executable
add_executable(Win8Settings ${SOURCES})

# Link libraries
target_link_libraries(Win8Settings
    PRIVATE
        Qt6::Core
        Qt6::Gui
        Qt6::Widgets
        Qt6::Quick
        Qt6::QuickControls2
        Qt6::QuickLayouts
        Qt6::Concurrent
        LayerShellQt::Interface
)

# Runtime output directory
set_target_properties(Win8Settings PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}
)
