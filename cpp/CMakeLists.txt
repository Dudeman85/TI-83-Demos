cmake_minimum_required(VERSION 3.11)
project(cpp)
set(CMAKE_CXX_STANDARD 20)

add_executable(VarGen VarGen.cpp)

set(OpenCV_DIR "${CMAKE_SOURCE_DIR}/ext/opencv/build/x64/vc16/lib")
find_package(OpenCV REQUIRED)
add_executable(VideoConverter VideoConverter.cpp)
target_link_libraries(VideoConverter PRIVATE ${OpenCV_LIBS})