cmake_minimum_required(VERSION 3.12)
project(libc_unzip_test)

set(CMAKE_CXX_STANDARD 17)

find_package(PkgConfig REQUIRED)
pkg_check_modules(LIBARCHIVE REQUIRED IMPORTED_TARGET libarchive)

add_executable(unzip_test src/main.cpp)
target_link_libraries(unzip_test PkgConfig::LIBARCHIVE)
