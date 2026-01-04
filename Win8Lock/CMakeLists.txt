cmake_minimum_required(VERSION 3.16)
project(Win8Lock LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick)
find_library(PAM_LIBRARY pam REQUIRED)

# LayerShellQt include and link
find_path(LAYERSHELLQT_INCLUDE_DIR LayerShellQt/window.h)
find_library(LAYERSHELLQT_LIBRARY NAMES LayerShellQtInterface)

include_directories(${LAYERSHELLQT_INCLUDE_DIR})

add_executable(Win8Lock
    main.cpp
    lockmanager.cpp
    lockmanager.h
    resources.qrc
)

target_link_libraries(Win8Lock PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    ${LAYERSHELLQT_LIBRARY}
    ${PAM_LIBRARY}
)
