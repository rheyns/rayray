#include "imgui.h"
#include "imgui_bridge.h"

static_assert(sizeof(ImDrawIdx) == 4, "WebGPU GUI rendering requires 32-bit ImDrawIdx");

void rrIgSetNextWindowPos(float x, float y, int cond, float pivot_x, float pivot_y) {
    ImGui::SetNextWindowPos(ImVec2(x, y), cond, ImVec2(pivot_x, pivot_y));
}

void rrIgSetNextWindowSize(float width, float height, int cond) {
    ImGui::SetNextWindowSize(ImVec2(width, height), cond);
}

void rrIgSetNextWindowSizeConstraints(float min_width, float min_height,
                                    float max_width, float max_height) {
    ImGui::SetNextWindowSizeConstraints(ImVec2(min_width, min_height),
                                       ImVec2(max_width, max_height));
}

bool rrIgButton(const char* label, float width, float height) {
    return ImGui::Button(label, ImVec2(width, height));
}

bool rrIgSelectable(const char* label, bool selected, int flags, float width, float height) {
    return ImGui::Selectable(label, selected, flags, ImVec2(width, height));
}
