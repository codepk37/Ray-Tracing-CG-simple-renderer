#.rst:
#
# This module defines CMake functions to build Python extension modules and
# stand-alone executables.
#
# The following variables are defined:
# ::
#
#   PYTHON_PREFIX                     - absolute path to the current Python
#                                       distribution's prefix
#   PYTHON_SITE_PACKAGES_DIR          - absolute path to the current Python
#                                       distribution's site-packages directory
#   PYTHON_RELATIVE_SITE_PACKAGES_DIR - path to the current Python
#                                       distribution's site-packages directory
#                                       relative to its prefix
#   PYTHON_SEPARATOR                  - separator string for file path
#                                       components.  Equivalent to ``os.sep`` in
#                                       Python.
#   PYTHON_PATH_SEPARATOR             - separator string for PATH-style
#                                       environment variables.  Equivalent to
#                                       ``os.pathsep`` in Python.
#   PYTHON_EXTENSION_MODULE_SUFFIX    - suffix of the compiled module. For example, on
#                                       Linux, based on environment, it could be ``.cpython-35m-x86_64-linux-gnu.so``.
#
#
#
# The following functions are defined:
#
# .. cmake:command:: python_extension_module
#
# For libraries meant to be used as Python extension modules, either dynamically
# loaded or directly linked.  Amend the configuration of the library target
# (created using ``add_library``) with additional options needed to build and
# use the referenced library as a Python extension module.
#
#   python_extension_module(<Target>
#                           [LINKED_MODULES_VAR <LinkedModVar>]
#                           [FORWARD_DECL_MODULES_VAR <ForwardDeclModVar>]
#                           [MODULE_SUFFIX <ModuleSuffix>])
#
# Only extension modules that are configured to be built as MODULE libraries can
# be runtime-loaded through the standard Python import mechanism.  All other
# modules can only be included in standalone applications that are written to
# expect their presence.  In addition to being linked against the libraries for
# these modules, such applications must forward declare their entry points and
# initialize them prior to use.  To generate these forward declarations and
# initializations, see ``python_modules_header``.
#
# If ``<Target>`` does not refer to a target, then it is assumed to refer to an
# extension module that is not linked at all, but compiled along with other
# source files directly into an executable.  Adding these modules does not cause
# any library configuration modifications, and they are not added to the list of
# linked modules.  They still must be forward declared and initialized, however,
# and so are added to the forward declared modules list.
#
# If the associated target is of type ``MODULE_LIBRARY``, the LINK_FLAGS target
# property is used to set symbol visibility and export only the module init function.
# This applies to GNU and MSVC compilers.
#
# Options:
#
# ``LINKED_MODULES_VAR <LinkedModVar>``
#   Name of the variable referencing a list of extension modules whose libraries
#   must be linked into the executables of any stand-alone applications that use
#   them.  By default, the global property ``PY_LINKED_MODULES_LIST`` is used.
#
# ``FORWARD_DECL_MODULES_VAR <ForwardDeclModVar>``
#   Name of the variable referencing a list of extension modules whose entry
#   points must be forward declared and called by any stand-alone applications
#   that use them.  By default, the global property
#   ``PY_FORWARD_DECL_MODULES_LIST`` is used.
#
# ``MODULE_SUFFIX <ModuleSuffix>``
#   Suffix appended to the python extension module file.
#   The default suffix is retrieved using ``sysconfig.get_config_var("SO")"``,
#   if not available, the default is then ``.so`` on unix and ``.pyd`` on
#   windows.
#   Setting the variable ``PYTHON_EXTENSION_MODULE_SUFFIX`` in the caller
#   scope defines the value used for all extensions not having a suffix
#   explicitly specified using ``MODULE_SUFFIX`` parameter.
#
#
# .. cmake:command:: python_standalone_executable
#
#   python_standalone_executable(<Target>)
#
# For standalone executables that initialize their own Python runtime
# (such as when building source files that include one generated by Cython with
# the --embed option).  Amend the configuration of the executable target
# (created using ``add_executable``) with additional options needed to properly
# build the referenced executable.
#
#
# .. cmake:command:: python_modules_header
#
# Generate a header file that contains the forward declarations and
# initialization routines for the given list of Python extension modules.
# ``<Name>`` is the logical name for the header file (no file extensions).
# ``<HeaderFilename>`` is the actual destination filename for the header file
# (e.g.: decl_modules.h).
#
#   python_modules_header(<Name> [HeaderFilename]
#                         [FORWARD_DECL_MODULES_LIST <ForwardDeclModList>]
#                         [HEADER_OUTPUT_VAR <HeaderOutputVar>]
#                         [INCLUDE_DIR_OUTPUT_VAR <IncludeDirOutputVar>])
#
# without the extension is used as the logical name.  If only ``<Name>`` is
#
# If only ``<Name>`` is provided, and it ends in the ".h" extension, then it
# is assumed to be the ``<HeaderFilename>``.  The filename of the header file
# provided, and it does not end in the ".h" extension, then the
# ``<HeaderFilename>`` is assumed to ``<Name>.h``.
#
# The exact contents of the generated header file depend on the logical
# ``<Name>``.  It should be set to a value that corresponds to the target
# application, or for the case of multiple applications, some identifier that
# conveyes its purpose.  It is featured in the generated multiple inclusion
# guard as well as the names of the generated initialization routines.
#
# The generated header file includes forward declarations for all listed
# modules, as well as implementations for the following class of routines:
#
# ``int <Name>_<Module>(void)``
#   Initializes the python extension module, ``<Module>``.  Returns an integer
#   handle to the module.
#
# ``void <Name>_LoadAllPythonModules(void)``
#   Initializes all listed python extension modules.
#
# ``void CMakeLoadAllPythonModules(void);``
#   Alias for ``<Name>_LoadAllPythonModules`` whose name does not depend on
#   ``<Name>``.  This function is excluded during preprocessing if the
#   preprocessing macro ``EXCLUDE_LOAD_ALL_FUNCTION`` is defined.
#
# ``void Py_Initialize_Wrapper();``
#   Wrapper arpund ``Py_Initialize()`` that initializes all listed python
#   extension modules.  This function is excluded during preprocessing if the
#   preprocessing macro ``EXCLUDE_PY_INIT_WRAPPER`` is defined.  If this
#   function is generated, then ``Py_Initialize()`` is redefined to a macro
#   that calls this function.
#
# Options:
#
# ``FORWARD_DECL_MODULES_LIST <ForwardDeclModList>``
#   List of extension modules for which to generate forward declarations of
#   their entry points and their initializations.  By default, the global
#   property ``PY_FORWARD_DECL_MODULES_LIST`` is used.
#
# ``HEADER_OUTPUT_VAR <HeaderOutputVar>``
#   Name of the variable to set to the path to the generated header file.  By
#   default, ``<Name>`` is used.
#
# ``INCLUDE_DIR_OUTPUT_VAR <IncludeDirOutputVar>``
#   Name of the variable to set to the path to the directory containing the
#   generated header file.  By default, ``<Name>_INCLUDE_DIRS`` is used.
#
# Defined variables:
#
# ``<HeaderOutputVar>``
#   The path to the generated header file
#
# ``<IncludeDirOutputVar>``
#   Directory containing the generated header file
#
#
# Example usage
# ^^^^^^^^^^^^^
#
# .. code-block:: cmake
#
#    find_package(PythonInterp)
#    find_package(PythonLibs)
#    find_package(PythonExtensions)
#    find_package(Cython)
#    find_package(Boost COMPONENTS python)
#
#    # Simple Cython Module -- no executables
#    add_cython_target(_module.pyx)
#    add_library(_module MODULE ${_module})
#    python_extension_module(_module)
#
#    # Mix of Cython-generated code and C++ code using Boost Python
#    # Stand-alone executable -- no modules
#    include_directories(${Boost_INCLUDE_DIRS})
#    add_cython_target(main.pyx CXX EMBED_MAIN)
#    add_executable(main boost_python_module.cxx ${main})
#    target_link_libraries(main ${Boost_LIBRARIES})
#    python_standalone_executable(main)
#
#    # stand-alone executable with three extension modules:
#    # one statically linked, one dynamically linked, and one loaded at runtime
#    #
#    # Freely mixes Cython-generated code, code using Boost-Python, and
#    # hand-written code using the CPython API.
#
#    # module1 -- statically linked
#    add_cython_target(module1.pyx)
#    add_library(module1 STATIC ${module1})
#    python_extension_module(module1
#                            LINKED_MODULES_VAR linked_module_list
#                            FORWARD_DECL_MODULES_VAR fdecl_module_list)
#
#    # module2 -- dynamically linked
#    include_directories(${Boost_INCLUDE_DIRS})
#    add_library(module2 SHARED boost_module2.cxx)
#    target_link_libraries(module2 ${Boost_LIBRARIES})
#    python_extension_module(module2
#                            LINKED_MODULES_VAR linked_module_list
#                            FORWARD_DECL_MODULES_VAR fdecl_module_list)
#
#    # module3 -- loaded at runtime
#    add_cython_target(module3a.pyx)
#    add_library(module3 MODULE ${module3a} module3b.cxx)
#    target_link_libraries(module3 ${Boost_LIBRARIES})
#    python_extension_module(module3
#                            LINKED_MODULES_VAR linked_module_list
#                            FORWARD_DECL_MODULES_VAR fdecl_module_list)
#
#    # application executable -- generated header file + other source files
#    python_modules_header(modules
#                          FORWARD_DECL_MODULES_LIST ${fdecl_module_list})
#    include_directories(${modules_INCLUDE_DIRS})
#
#    add_cython_target(mainA)
#    add_cython_target(mainC)
#    add_executable(main ${mainA} mainB.cxx ${mainC} mainD.c)
#
#    target_link_libraries(main ${linked_module_list} ${Boost_LIBRARIES})
#    python_standalone_executable(main)
#
#=============================================================================
# Copyright 2011 Kitware, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#=============================================================================

find_package(PythonInterp REQUIRED)
find_package(PythonLibs)
include(targetLinkLibrariesWithDynamicLookup)

set(_command "
import distutils.sysconfig
import itertools
import os
import os.path
import site
import sys

result = None
rel_result = None
candidate_lists = []

try:
    candidate_lists.append((distutils.sysconfig.get_python_lib(),))
except AttributeError: pass

try:
    candidate_lists.append(site.getsitepackages())
except AttributeError: pass

try:
    candidate_lists.append((site.getusersitepackages(),))
except AttributeError: pass

candidates = itertools.chain.from_iterable(candidate_lists)

for candidate in candidates:
    rel_candidate = os.path.relpath(
      candidate, sys.prefix)
    if not rel_candidate.startswith(\"..\"):
        result = candidate
        rel_result = rel_candidate
        break

ext_suffix_var = 'SO'
if sys.version_info[:2] >= (3, 5):
    ext_suffix_var = 'EXT_SUFFIX'

sys.stdout.write(\";\".join((
    os.sep,
    os.pathsep,
    sys.prefix,
    result,
    rel_result,
    distutils.sysconfig.get_config_var(ext_suffix_var)
)))
")

execute_process(COMMAND "${PYTHON_EXECUTABLE}" -c "${_command}"
                OUTPUT_VARIABLE _list
                RESULT_VARIABLE _result)

list(GET _list 0 _item)
set(PYTHON_SEPARATOR "${_item}")
mark_as_advanced(PYTHON_SEPARATOR)

list(GET _list 1 _item)
set(PYTHON_PATH_SEPARATOR "${_item}")
mark_as_advanced(PYTHON_PATH_SEPARATOR)

list(GET _list 2 _item)
set(PYTHON_PREFIX "${_item}")
mark_as_advanced(PYTHON_PREFIX)

list(GET _list 3 _item)
set(PYTHON_SITE_PACKAGES_DIR "${_item}")
mark_as_advanced(PYTHON_SITE_PACKAGES_DIR)

list(GET _list 4 _item)
set(PYTHON_RELATIVE_SITE_PACKAGES_DIR "${_item}")
mark_as_advanced(PYTHON_RELATIVE_SITE_PACKAGES_DIR)

if(NOT DEFINED PYTHON_EXTENSION_MODULE_SUFFIX)
  list(GET _list 5 _item)
  set(PYTHON_EXTENSION_MODULE_SUFFIX "${_item}")
endif()

function(_set_python_extension_symbol_visibility _target)
  if(PYTHON_VERSION_MAJOR VERSION_GREATER 2)
    set(_modinit_prefix "PyInit_")
  else()
    set(_modinit_prefix "init")
  endif()
  if("${CMAKE_C_COMPILER_ID}" STREQUAL "MSVC")
    set_target_properties(${_target} PROPERTIES LINK_FLAGS
        "/EXPORT:${_modinit_prefix}${_target}"
    )
  elseif("${CMAKE_C_COMPILER_ID}" STREQUAL "GNU" AND NOT ${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
    set(_script_path
      ${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/${_target}-version-script.map
    )
    file(WRITE ${_script_path}
               "{global: ${_modinit_prefix}${_target}; local: *; };"
    )
    set_property(TARGET ${_target} APPEND_STRING PROPERTY LINK_FLAGS
        " -Wl,--version-script=\"${_script_path}\""
    )
  endif()
endfunction()

function(python_extension_module _target)
  set(one_ops LINKED_MODULES_VAR FORWARD_DECL_MODULES_VAR MODULE_SUFFIX)
  cmake_parse_arguments(_args "" "${one_ops}" "" ${ARGN})

  set(_lib_type "NA")
  if(TARGET ${_target})
    get_property(_lib_type TARGET ${_target} PROPERTY TYPE)
  endif()

  set(_is_non_lib TRUE)

  set(_is_static_lib FALSE)
  if(_lib_type STREQUAL "STATIC_LIBRARY")
      set(_is_static_lib TRUE)
      set(_is_non_lib FALSE)
  endif()

  set(_is_shared_lib FALSE)
  if(_lib_type STREQUAL "SHARED_LIBRARY")
      set(_is_shared_lib TRUE)
      set(_is_non_lib FALSE)
  endif()

  set(_is_module_lib FALSE)
  if(_lib_type STREQUAL "MODULE_LIBRARY")
      set(_is_module_lib TRUE)
      set(_is_non_lib FALSE)
  endif()

  if(_is_static_lib OR _is_shared_lib OR _is_non_lib)

    if(_is_static_lib OR _is_shared_lib)
      if(_args_LINKED_MODULES_VAR)
        set(${_args_LINKED_MODULES_VAR}
            ${${_args_LINKED_MODULES_VAR}} ${_target} PARENT_SCOPE)
      else()
        set_property(GLOBAL APPEND PROPERTY PY_LINKED_MODULES_LIST ${_target})
      endif()
    endif()

    if(_args_FORWARD_DECL_MODULES_VAR)
      set(${_args_FORWARD_DECL_MODULES_VAR}
          ${${_args_FORWARD_DECL_MODULES_VAR}} ${_target} PARENT_SCOPE)
    else()
      set_property(GLOBAL APPEND PROPERTY
                   PY_FORWARD_DECL_MODULES_LIST ${_target})
    endif()
  endif()

  if(NOT _is_non_lib)
    include_directories("${PYTHON_INCLUDE_DIRS}")
  endif()

  if(_is_module_lib)
    set_target_properties(${_target} PROPERTIES
                          PREFIX "${PYTHON_MODULE_PREFIX}")
  endif()

  if(_is_module_lib OR _is_shared_lib)
    if(_is_module_lib)

      if(NOT _args_MODULE_SUFFIX)
        set(_args_MODULE_SUFFIX "${PYTHON_EXTENSION_MODULE_SUFFIX}")
      endif()

      if(_args_MODULE_SUFFIX STREQUAL "" AND WIN32 AND NOT CYGWIN)
        set(_args_MODULE_SUFFIX ".pyd")
      endif()

      if(NOT _args_MODULE_SUFFIX STREQUAL "")
        set_target_properties(${_target}
          PROPERTIES SUFFIX ${_args_MODULE_SUFFIX})
      endif()
    endif()

    target_link_libraries_with_dynamic_lookup(${_target} ${PYTHON_LIBRARIES})

    if(_is_module_lib)
      _set_python_extension_symbol_visibility(${_target})
    endif()
  endif()
endfunction()

function(python_standalone_executable _target)
  include_directories(${PYTHON_INCLUDE_DIRS})
  target_link_libraries(${_target} ${PYTHON_LIBRARIES})
endfunction()

function(python_modules_header _name)
  set(one_ops FORWARD_DECL_MODULES_LIST
              HEADER_OUTPUT_VAR
              INCLUDE_DIR_OUTPUT_VAR)
  cmake_parse_arguments(_args "" "${one_ops}" "" ${ARGN})

  list(GET _args_UNPARSED_ARGUMENTS 0 _arg0)
  # if present, use arg0 as the input file path
  if(_arg0)
    set(_source_file ${_arg0})

  # otherwise, must determine source file from name, or vice versa
  else()
    get_filename_component(_name_ext "${_name}" EXT)

    # if extension provided, _name is the source file
    if(_name_ext)
      set(_source_file ${_name})
      get_filename_component(_name "${_source_file}" NAME_WE)

    # otherwise, assume the source file is ${_name}.h
    else()
      set(_source_file ${_name}.h)
    endif()
  endif()

  if(_args_FORWARD_DECL_MODULES_LIST)
    set(static_mod_list ${_args_FORWARD_DECL_MODULES_LIST})
  else()
    get_property(static_mod_list GLOBAL PROPERTY PY_FORWARD_DECL_MODULES_LIST)
  endif()

  string(REPLACE "." "_" _header_name "${_name}")
  string(TOUPPER ${_header_name} _header_name_upper)
  set(_header_name_upper "_${_header_name_upper}_H")
  set(generated_file ${CMAKE_CURRENT_BINARY_DIR}/${_source_file})

  set(generated_file_tmp "${generated_file}.in")
  file(WRITE ${generated_file_tmp}
       "/* Created by CMake. DO NOT EDIT; changes will be lost. */\n")

  set(_chunk "")
  set(_chunk "${_chunk}#ifndef ${_header_name_upper}\n")
  set(_chunk "${_chunk}#define ${_header_name_upper}\n")
  set(_chunk "${_chunk}\n")
  set(_chunk "${_chunk}#include <Python.h>\n")
  set(_chunk "${_chunk}\n")
  set(_chunk "${_chunk}#ifdef __cplusplus\n")
  set(_chunk "${_chunk}extern \"C\" {\n")
  set(_chunk "${_chunk}#endif /* __cplusplus */\n")
  set(_chunk "${_chunk}\n")
  set(_chunk "${_chunk}#if PY_MAJOR_VERSION < 3\n")
  file(APPEND ${generated_file_tmp} "${_chunk}")

  foreach(_module ${static_mod_list})
    file(APPEND ${generated_file_tmp}
         "PyMODINIT_FUNC init${PYTHON_MODULE_PREFIX}${_module}(void);\n")
  endforeach()

  file(APPEND ${generated_file_tmp} "#else /* PY_MAJOR_VERSION >= 3*/\n")

  foreach(_module ${static_mod_list})
    file(APPEND ${generated_file_tmp}
         "PyMODINIT_FUNC PyInit_${PYTHON_MODULE_PREFIX}${_module}(void);\n")
  endforeach()

  set(_chunk "")
  set(_chunk "${_chunk}#endif /* PY_MAJOR_VERSION >= 3*/\n\n")
  set(_chunk "${_chunk}#ifdef __cplusplus\n")
  set(_chunk "${_chunk}}\n")
  set(_chunk "${_chunk}#endif /* __cplusplus */\n")
  set(_chunk "${_chunk}\n")
  file(APPEND ${generated_file_tmp} "${_chunk}")

  foreach(_module ${static_mod_list})
    set(_import_function "${_header_name}_${_module}")
    set(_prefixed_module "${PYTHON_MODULE_PREFIX}${_module}")

    set(_chunk "")
    set(_chunk "${_chunk}int ${_import_function}(void)\n")
    set(_chunk "${_chunk}{\n")
    set(_chunk "${_chunk}  static char name[] = \"${_prefixed_module}\";\n")
    set(_chunk "${_chunk}  #if PY_MAJOR_VERSION < 3\n")
    set(_chunk "${_chunk}  return PyImport_AppendInittab(")
    set(_chunk "${_chunk}name, init${_prefixed_module});\n")
    set(_chunk "${_chunk}  #else /* PY_MAJOR_VERSION >= 3 */\n")
    set(_chunk "${_chunk}  return PyImport_AppendInittab(")
    set(_chunk "${_chunk}name, PyInit_${_prefixed_module});\n")
    set(_chunk "${_chunk}  #endif /* PY_MAJOR_VERSION >= 3 */\n")
    set(_chunk "${_chunk}}\n\n")
    file(APPEND ${generated_file_tmp} "${_chunk}")
  endforeach()

  file(APPEND ${generated_file_tmp}
       "void ${_header_name}_LoadAllPythonModules(void)\n{\n")
  foreach(_module ${static_mod_list})
    file(APPEND ${generated_file_tmp} "  ${_header_name}_${_module}();\n")
  endforeach()
  file(APPEND ${generated_file_tmp} "}\n\n")

  set(_chunk "")
  set(_chunk "${_chunk}#ifndef EXCLUDE_LOAD_ALL_FUNCTION\n")
  set(_chunk "${_chunk}void CMakeLoadAllPythonModules(void)\n")
  set(_chunk "${_chunk}{\n")
  set(_chunk "${_chunk}  ${_header_name}_LoadAllPythonModules();\n")
  set(_chunk "${_chunk}}\n")
  set(_chunk "${_chunk}#endif /* !EXCLUDE_LOAD_ALL_FUNCTION */\n\n")

  set(_chunk "${_chunk}#ifndef EXCLUDE_PY_INIT_WRAPPER\n")
  set(_chunk "${_chunk}static void Py_Initialize_Wrapper()\n")
  set(_chunk "${_chunk}{\n")
  set(_chunk "${_chunk}  ${_header_name}_LoadAllPythonModules();\n")
  set(_chunk "${_chunk}  Py_Initialize();\n")
  set(_chunk "${_chunk}}\n")
  set(_chunk "${_chunk}#define Py_Initialize Py_Initialize_Wrapper\n")
  set(_chunk "${_chunk}#endif /* !EXCLUDE_PY_INIT_WRAPPER */\n\n")

  set(_chunk "${_chunk}#endif /* !${_header_name_upper} */\n")
  file(APPEND ${generated_file_tmp} "${_chunk}")

  # with configure_file() cmake complains that you may not use a file created
  # using file(WRITE) as input file for configure_file()
  execute_process(COMMAND ${CMAKE_COMMAND} -E copy_if_different
                  "${generated_file_tmp}" "${generated_file}"
                  OUTPUT_QUIET ERROR_QUIET)

  set(_header_output_var ${_name})
  if(_args_HEADER_OUTPUT_VAR)
    set(_header_output_var ${_args_HEADER_OUTPUT_VAR})
  endif()
  set(${_header_output_var} ${generated_file} PARENT_SCOPE)

  set(_include_dir_var ${_name}_INCLUDE_DIRS)
  if(_args_INCLUDE_DIR_OUTPUT_VAR)
    set(_include_dir_var ${_args_INCLUDE_DIR_OUTPUT_VAR})
  endif()
  set(${_include_dirs_var} ${CMAKE_CURRENT_BINARY_DIR} PARENT_SCOPE)
endfunction()