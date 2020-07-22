
include(CMakePackageConfigHelpers)
include(GNUInstallDirs)

# daq_setup_environment

# This macro should be called immediately after the DAQ module is
# included in your DUNE DAQ project's CMakeLists.txt file; it ensures
# that DUNE DAQ projects all have a common build environment.

macro(daq_setup_environment)

  set(CMAKE_CXX_STANDARD 17)
  set(CMAKE_CXX_EXTENSIONS OFF)
  set(CMAKE_CXX_STANDARD_REQUIRED ON)

  set(BUILD_SHARED_LIBS ON)

  # Include directories within CMAKE_SOURCE_DIR and CMAKE_BINARY_DIR should take precedence over everything else
  set(CMAKE_INCLUDE_DIRECTORIES_PROJECT_BEFORE ON)

  # All code for the project should be able to see the project's public include directory
  include_directories( ${CMAKE_SOURCE_DIR}/include )

  # Needed for clang-tidy (called by our linters) to work
  set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

  # Want find_package() to be able to locate packages we've installed in the 
  # local development area via daq_install(), defined later in this file

  set(CMAKE_PREFIX_PATH ${CMAKE_CURRENT_SOURCE_DIR}/../install )

  add_compile_options( -g -pedantic -Wall -Wextra )

  enable_testing()

endmacro()


function( point_build_to output_dir )

  set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/${PROJECT_NAME}/${output_dir} PARENT_SCOPE)
  set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/${PROJECT_NAME}/${output_dir} PARENT_SCOPE)
  set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/${PROJECT_NAME}/${output_dir} PARENT_SCOPE)

endfunction()

function(add_unit_test testname)

  add_executable( ${testname} unittest/${testname}.cxx )
  target_link_libraries( ${testname} ${ARGN} ${Boost_UNIT_TEST_FRAMEWORK_LIBRARY})
  target_compile_definitions(${testname} PRIVATE "BOOST_TEST_DYN_LINK=1")
  add_test(NAME ${testname} COMMAND ${testname})

endfunction()

# daq_install
# This function should be called with a signature like the following:
#
# daq_install(VERSION <version> TARGETS <target1> <target2> ...)
#

# ...where <version> should be formatted like
#  integer-dot-integer-dot-integer (e.g., 1.2.3) and <target1>
#  <target2> ... is the list of targets in your project which you want
#  installed. Conventionally this would be targets from your src/ and
#  apps/ subdirectories, and not include your test apps.

function(daq_install) 

  cmake_parse_arguments(DAQ_INSTALL "" VERSION TARGETS ${ARGN} )

  set(CMAKE_INSTALL_PREFIX ${CMAKE_CURRENT_SOURCE_DIR}/../install/${PROJECT_NAME} CACHE PATH "No comment" FORCE)

  set(exportset ${PROJECT_NAME}Targets)
  set(cmakedestination ${CMAKE_INSTALL_LIBDIR}/${PROJECT_NAME}/cmake)

  install(TARGETS ${DAQ_INSTALL_TARGETS} EXPORT ${exportset} )
  install(EXPORT ${exportset} FILE ${exportset}.cmake NAMESPACE ${PROJECT_NAME}:: DESTINATION ${cmakedestination} )

  install(DIRECTORY include/${PROJECT_NAME} DESTINATION ${CMAKE_INSTALL_INCLUDEDIR} FILES_MATCHING PATTERN "*.h??")

  set(versionfile        ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake)
  set(configfiletemplate ${CMAKE_CURRENT_SOURCE_DIR}/${PROJECT_NAME}Config.cmake.in)
  set(configfile         ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake)

  write_basic_package_version_file(${versionfile} VERSION $DAQ_INSTALL_VERSION COMPATIBILITY ExactVersion)

  if (EXISTS ${configfiletemplate})
    configure_package_config_file(${configfiletemplate} ${configfile} INSTALL_DESTINATION ${cmakedestination})
  else()
     message(FATAL_ERROR "Error: unable to find needed file ${configfiletemplate} for ${PROJECT_NAME} installation")
  endif()

  install(FILES ${versionfile} ${configfile} DESTINATION ${cmakedestination})

endfunction()
