cmake_minimum_required(VERSION 3.12)
project(QtIFWTest)

set(CMAKE_CXX_STANDARD 11)

# 版本号：可用 -DAPP_VERSION=1.1.0 等重写
if(NOT DEFINED APP_VERSION)
        set(APP_VERSION "1.0.0")
endif()

# 安装前缀：install-tmp/<version>
if(NOT DEFINED INSTALL_PREFIX)
        set(INSTALL_PREFIX "${CMAKE_SOURCE_DIR}/install-tmp/${APP_VERSION}")
endif()

message(STATUS "Building version: ${APP_VERSION}")
message(STATUS "Install prefix: ${INSTALL_PREFIX}")

set(COMP1 "com.vendor.root.component1")
set(COMP2 "com.vendor.root.component1.subcomponent1")

# 子组件1：共享库
add_library(helper SHARED subcomponent1/helper.cpp)
target_include_directories(helper PUBLIC subcomponent1)
target_compile_definitions(helper PRIVATE APP_VERSION="${APP_VERSION}")

# 主程序：app1
add_executable(app1 component1/main.cpp)
target_include_directories(app1 PRIVATE subcomponent1)
target_link_libraries(app1 PRIVATE helper)
target_compile_definitions(app1 PRIVATE APP_VERSION="${APP_VERSION}")

set_target_properties(app1 PROPERTIES
        INSTALL_RPATH "$ORIGIN"
)

# 安装规则
install(TARGETS app1
        DESTINATION "${INSTALL_PREFIX}/${COMP1}/data")
install(FILES "${CMAKE_SOURCE_DIR}/component1/example.data"
        DESTINATION "${INSTALL_PREFIX}/${COMP1}/data")

install(TARGETS helper LIBRARY
        DESTINATION "${INSTALL_PREFIX}/${COMP2}/data")
install(FILES "${CMAKE_SOURCE_DIR}/subcomponent1/helper.data"
        DESTINATION "${INSTALL_PREFIX}/${COMP2}/data")
