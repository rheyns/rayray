#pragma once
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

// Pass scalar values across Zig 0.8's C ABI. Its ARM64 code generation does
// not pass ImVec2 floating-point aggregates correctly to C++ functions.
void rrIgSetNextWindowPos(float x, float y, int cond, float pivot_x, float pivot_y);
void rrIgSetNextWindowSize(float width, float height, int cond);
void rrIgSetNextWindowSizeConstraints(float min_width, float min_height,
                                    float max_width, float max_height);
bool rrIgButton(const char* label, float width, float height);
bool rrIgSelectable(const char* label, bool selected, int flags, float width, float height);

#ifdef __cplusplus
}
#endif
