cmake_minimum_required(VERSION 3.18)
project(Win8OSD LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Quick Qml Network)
find_package(LayerShellQt REQUIRED)

# 🟦 Client
qt_add_executable(Win8OSD-client
    Win8OSD-client.cpp
)

target_link_libraries(Win8OSD-client
    PRIVATE Qt6::Core Qt6::Network
)

# 🟩 Server (QML + GUI)
qt_add_executable(Win8OSD-server
    Win8OSD-server.cpp
    resources.qrc
)

target_link_libraries(Win8OSD-server
    PRIVATE
        Qt6::Core
        Qt6::Gui
        Qt6::Quick
        Qt6::Qml
        Qt6::Network
        LayerShellQt::Interface
)
