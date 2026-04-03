cmake_minimum_required(VERSION 3.18)
project(Win8Corner LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)

find_package(Qt6 REQUIRED COMPONENTS Core Quick Gui)
find_package(LayerShellQt REQUIRED)

# Enable AUTOMOC for Q_OBJECT processing
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

# Add executable
qt_add_executable(Win8Corner
    main.cpp
    resources.qrc
)


# --------------------------------------------------
# ccls / clangd support
# --------------------------------------------------
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)


# Link libraries
target_link_libraries(Win8Corner
    PRIVATE Qt6::Core Qt6::Quick Qt6::Gui LayerShellQt::Interface
)
