cmake_minimum_required(VERSION 3.18)
project(Win8Wall LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_AUTOMOC ON)   # Only needed if you have Q_OBJECT classes
set(CMAKE_AUTORCC ON)   # Needed for qt6_add_resources

find_package(Qt6 REQUIRED COMPONENTS Core Gui Quick)
find_package(LayerShellQt REQUIRED)

qt_add_executable(Win8Wall
    main.cpp
)

qt6_add_resources(Win8Wall
    PREFIX "/"
    FILES main.qml
)

target_link_libraries(Win8Wall
    PRIVATE Qt6::Core Qt6::Gui Qt6::Quick LayerShellQt::Interface
)
