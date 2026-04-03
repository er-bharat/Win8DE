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
# ⚠️ Shared warnings & sanitizers config (Linux only)
# --------------------------------------------------
option(ENABLE_STRICT_BUILD "Treat warnings as errors" ON)
option(ENABLE_SANITIZERS "Enable sanitizers" OFF)

function(apply_strict_flags target)
    # Only GCC/Clang on Linux
    if (CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")

        target_compile_options(${target} PRIVATE
            -Wall -Wextra -Wpedantic
            -Wshadow -Wconversion -Wsign-conversion
            -Wnull-dereference -Wdouble-promotion -Wformat=2
            -Wold-style-cast -Woverloaded-virtual -Wnon-virtual-dtor
            -Wduplicated-cond -Wduplicated-branches -Wlogical-op -Wuseless-cast
            -Wcast-align -Wcast-qual -Wfloat-equal -Wundef -Wswitch-enum
            -Wzero-as-null-pointer-constant
            -Wno-unused-parameter
            -Wno-missing-field-initializers
        )

        if (ENABLE_STRICT_BUILD)
            target_compile_options(${target} PRIVATE -Werror)
        endif()

        if (ENABLE_SANITIZERS)
            target_compile_options(${target} PRIVATE
                -fsanitize=address,undefined -fno-omit-frame-pointer)
            target_link_options(${target} PRIVATE
                -fsanitize=address,undefined)
        endif()
    endif()
endfunction()

apply_strict_flags(winbt) 
