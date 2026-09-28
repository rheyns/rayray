#define GLFW_INCLUDE_NONE
#include <GLFW/glfw3.h>
#include <png.h>
#include <dlfcn.h>
#include "wgpu/wgpu.h"
#include <shaderc/shaderc.h>
#define CIMGUI_DEFINE_ENUMS_AND_STRUCTS
#include "cimgui/cimgui.h"
#include "cimgui/generator/output/cimgui_impl.h"
#include "cimgui_ft/cimgui_ft.h"
#include "extern/imgui_bridge.h"
#include "extern/rayray.h"
#ifdef __APPLE__
#include <objc/message.h>
#endif
