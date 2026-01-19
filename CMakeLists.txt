cmake_minimum_required(VERSION 3.16...3.26)

project(stream-audio-isolator VERSION 1.0.0)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_C_STANDARD 11)

# Add option to build without OBS (for testing)
option(BUILD_STANDALONE "Build standalone test version" OFF)
option(OBS_INCLUDE_ONLY "Use OBS headers without find_package" OFF)

if(NOT BUILD_STANDALONE)
    if(OBS_INCLUDE_ONLY)
        # Manual OBS header setup (for CI builds)
        find_path(LIBOBS_INCLUDE_DIR obs-module.h
            HINTS ENV LIBOBS_INCLUDE_DIR ${CMAKE_PREFIX_PATH}
            PATH_SUFFIXES libobs
        )
        if(NOT LIBOBS_INCLUDE_DIR)
            message(FATAL_ERROR "OBS headers not found! Set LIBOBS_INCLUDE_DIR")
        endif()
        message(STATUS "OBS headers found: ${LIBOBS_INCLUDE_DIR}")
    else()
        # Find OBS using package config
        find_package(libobs REQUIRED)
        find_package(obs-frontend-api REQUIRED)
    endif()
endif()

# Find ONNX Runtime
find_path(ONNXRUNTIME_INCLUDE_DIR onnxruntime_c_api.h
    HINTS ENV ONNXRUNTIME_DIR
    PATH_SUFFIXES include
)

find_library(ONNXRUNTIME_LIBRARY
    NAMES onnxruntime
    HINTS ENV ONNXRUNTIME_DIR
    PATH_SUFFIXES lib
)

# Add plugin sources
add_library(stream-audio-isolator MODULE)

target_sources(stream-audio-isolator PRIVATE
    src/plugin-main.c
    src/audio-isolator-filter.c
    src/engines/sherpa-engine.c
    src/engines/hstasnet-engine.c
    src/engines/clearervoice-engine.c
    src/engines/spleeterrt-engine.c
    src/utils/audio-buffer.c
)

target_include_directories(stream-audio-isolator PRIVATE
    ${CMAKE_SOURCE_DIR}/src
    ${ONNXRUNTIME_INCLUDE_DIR}
)

if(NOT BUILD_STANDALONE)
    if(OBS_INCLUDE_ONLY)
        # Add OBS headers manually
        target_include_directories(stream-audio-isolator PRIVATE
            ${LIBOBS_INCLUDE_DIR}
        )
        # Link only ONNX (OBS will load plugin as module)
        target_link_libraries(stream-audio-isolator
            ${ONNXRUNTIME_LIBRARY}
        )
    else()
        # Link OBS libraries normally
        target_link_libraries(stream-audio-isolator
            OBS::libobs
            ${ONNXRUNTIME_LIBRARY}
        )
    endif()
else()
    # Standalone build (for testing engines without OBS)
    target_link_libraries(stream-audio-isolator
        ${ONNXRUNTIME_LIBRARY}
    )
endif()

# Set plugin properties
set_target_properties(stream-audio-isolator PROPERTIES
    OUTPUT_NAME "stream-audio-isolator"
    FOLDER "plugins"
    PREFIX ""
)

# Platform-specific settings
if(WIN32)
    target_compile_definitions(stream-audio-isolator PRIVATE
        _CRT_SECURE_NO_WARNINGS
    )
endif()

if(APPLE)
    set_target_properties(stream-audio-isolator PROPERTIES
        BUNDLE TRUE
        BUNDLE_EXTENSION plugin
    )
endif()

# Installation
if(NOT BUILD_STANDALONE)
    # Install plugin binary
    install(TARGETS stream-audio-isolator
        LIBRARY DESTINATION obs-plugins/64bit
        RUNTIME DESTINATION obs-plugins/64bit
    )

    # Install data files (locale)
    install(DIRECTORY data/
        DESTINATION data/obs-plugins/stream-audio-isolator
    )

    # Install ONNX models directory (models will be downloaded on-demand)
    install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/models/
        DESTINATION data/obs-plugins/stream-audio-isolator/models
        OPTIONAL
    )

    # Install ONNX Runtime DLL on Windows
    if(WIN32 AND ONNXRUNTIME_LIBRARY)
        get_filename_component(ONNX_DIR "${ONNXRUNTIME_LIBRARY}" DIRECTORY)
        install(FILES "${ONNX_DIR}/../bin/onnxruntime.dll"
            DESTINATION obs-plugins/64bit
            OPTIONAL
        )
    endif()
endif()

# Print configuration
message(STATUS "Stream Audio Isolator Configuration:")
message(STATUS "  Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "  Standalone build: ${BUILD_STANDALONE}")
if(ONNXRUNTIME_INCLUDE_DIR AND ONNXRUNTIME_LIBRARY)
    message(STATUS "  ONNX Runtime found: ${ONNXRUNTIME_LIBRARY}")
else()
    message(WARNING "  ONNX Runtime NOT found! Set ONNXRUNTIME_DIR environment variable")
endif()
