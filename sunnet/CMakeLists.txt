# CMakeList.txt: sunnet 的 CMake 项目，在此处包括源代码并定义
# 项目特定的逻辑。
#
cmake_minimum_required (VERSION 3.8)

project ("sunnet")

# 将源代码添加到此项目的可执行文件。
add_executable (sunnet "sunnet.cpp" "sunnet.h" "main.cpp" "Worker.h" "Worker.cpp" " Msg.h")
find_package(Threads REQUIRED)
target_link_libraries(sunnet Threads::Threads)
# TODO: 如有需要，请添加测试并安装目标。
