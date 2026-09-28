const std = @import("std");
const Builder = std.build.Builder;

fn pathJoin(b: *Builder, root: []const u8, suffix: []const u8) []const u8 {
    return std.fs.path.join(b.allocator, &[_][]const u8{ root, suffix }) catch unreachable;
}

pub fn build(b: *Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("rayray", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);

    // Libraries!
    const arm_macos = target.getOsTag() == .macos and target.getCpuArch() == .aarch64;
    if (arm_macos) {
        // Homebrew's native Apple Silicon prefix is not in Zig's default
        // header or library search paths.
        const brew = b.env_map.get("HOMEBREW_PREFIX") orelse "/opt/homebrew";
        exe.addIncludeDir(pathJoin(b, brew, "include"));
        exe.addIncludeDir(pathJoin(b, brew, "include/freetype2"));
        exe.addLibPath(pathJoin(b, brew, "lib"));
        // Use Homebrew's dylib explicitly. The old Zig linker can select the
        // static archive for `-lpng` and does not resolve its zlib dependency.
        exe.addObjectFile(pathJoin(b, brew, "lib/libpng.dylib"));
        // Homebrew's `glfw3` name selects its static archive, which leaves
        // Objective C symbols unresolved with Zig's older macOS linker.
        exe.linkSystemLibrary("glfw");
        exe.linkSystemLibrary("freetype");
        exe.addLibPath(pathJoin(b, brew, "opt/shaderc/lib"));
        exe.addIncludeDir(pathJoin(b, brew, "opt/shaderc/include"));
    } else {
        exe.linkSystemLibrary("png");
        exe.linkSystemLibrary("glfw3");
        exe.linkSystemLibrary("freetype2");
        exe.addLibPath("vendor/shaderc/lib");
        exe.addIncludeDir("vendor/shaderc/include/");
    }
    exe.linkSystemLibrary("stdc++"); // needed for shaderc

    exe.addLibPath("vendor/wgpu");
    exe.linkSystemLibrary("wgpu_native");
    exe.addIncludeDir("vendor"); // "wgpu/wgpu.h" is the wgpu header

    exe.linkSystemLibrary("shaderc_combined");

    exe.addIncludeDir("."); // for "extern/rayray.h"

    const c_args = [_][]const u8{
        "-O3",
        "-DImDrawIdx=uint32_t",
        "-Ivendor/cimgui/imgui",
        // Force C linkage for imgui_impl_glfw.cpp
        "-DIMGUI_IMPL_API=extern \"C\"",
    };
    const imgui_files = [_][]const u8{
        "extern/imgui_bridge.cpp",
        "vendor/cimgui/cimgui.cpp",
        "vendor/cimgui/imgui/imgui.cpp",
        "vendor/cimgui/imgui/imgui_draw.cpp",
        "vendor/cimgui/imgui/imgui_demo.cpp",
        "vendor/cimgui/imgui/imgui_widgets.cpp",
        "vendor/cimgui/imgui/examples/imgui_impl_glfw.cpp",
        "vendor/cimgui/imgui/misc/freetype/imgui_freetype.cpp",
        "vendor/cimgui_ft/cimgui_ft.cpp",
    };
    exe.addCSourceFiles(&imgui_files, &c_args);

    exe.install();

    if (exe.target.isDarwin()) {
        exe.addFrameworkDir("/System/Library/Frameworks");
        exe.linkFramework("Foundation");
        exe.linkFramework("AppKit");
    }

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
