# CMakeList.txt: sunnet 的 CMake 项目，在此处包括源代码并定义
# 项目特定的逻辑。
#
cmake_minimum_required (VERSION 3.8)
add_definitions(-std=c++11)
project ("sunnet")
include_directories("include")
# 将源代码添加到此项目的可执行文件。
add_executable (sunnet "src/Sunnet.cpp" "src/main.cpp" "include/Worker.h" "src/Worker.cpp" "include/Sunnet.h" "include/Msg.h" "include/Service.h" "src/Service.cpp" "include/SocketWorker.h" "src/SocketWorker.cpp" "include/Conn.h")
find_package(Threads)
target_link_libraries(sunnet ${CMAKE_THREAD_LIBS_INIT})
# TODO: 如有需要，请添加测试并安装目标。
