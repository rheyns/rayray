const std = @import("std");
const Builder = std.Build;

fn pathJoin(b: *Builder, root: []const u8, suffix: []const u8) []const u8 {
    return std.fs.path.join(b.allocator, &[_][]const u8{ root, suffix }) catch unreachable;
}

pub fn build(b: *Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Select debug, safe, fast, or small with -Doptimize.
    const mode = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "rayray",
        .root_module = b.createModule(.{
            .root_source_file = b.path("main.zig"),
            .target = target,
            .optimize = mode,
            .link_libc = true,
            .link_libcpp = true,
        }),
    });
    const mod = exe.root_module;
    const bindings = b.addTranslateC(.{
        .root_source_file = b.path("extern/bindings.h"),
        .target = target,
        .optimize = mode,
    });
    // This old generated cimgui header hardcodes 16-bit indices, while the
    // renderer and C++ build use 32-bit indices. Generate matching bindings.
    const headers = b.addWriteFiles();
    _ = headers.add("cimgui/cimgui.h", std.mem.replaceOwned(u8, b.allocator, @embedFile("vendor/cimgui/cimgui.h"), "typedef unsigned short ImDrawIdx;", "typedef unsigned int ImDrawIdx;") catch @panic("OOM"));
    bindings.addIncludePath(headers.getDirectory());
    bindings.addIncludePath(b.path("vendor"));
    bindings.addIncludePath(b.path("."));
    mod.addImport("c", bindings.createModule());

    // Libraries!
    const arm_macos = target.result.os.tag == .macos and target.result.cpu.arch == .aarch64;
    if (arm_macos) {
        // Homebrew's native Apple Silicon prefix is not in Zig's default
        // header or library search paths.
        const brew = b.graph.environ_map.get("HOMEBREW_PREFIX") orelse "/opt/homebrew";
        mod.addIncludePath(.{ .cwd_relative = pathJoin(b, brew, "include") });
        bindings.addIncludePath(.{ .cwd_relative = pathJoin(b, brew, "include") });
        mod.addIncludePath(.{ .cwd_relative = pathJoin(b, brew, "include/freetype2") });
        bindings.addIncludePath(.{ .cwd_relative = pathJoin(b, brew, "include/freetype2") });
        mod.addLibraryPath(.{ .cwd_relative = pathJoin(b, brew, "lib") });
        // Use Homebrew's shared libraries, including their transitive dependencies.
        mod.addObjectFile(.{ .cwd_relative = pathJoin(b, brew, "lib/libpng.dylib") });
        // Homebrew's `glfw3` name selects the static archive.
        mod.linkSystemLibrary("glfw", .{});
        mod.linkSystemLibrary("freetype", .{});
        mod.addLibraryPath(.{ .cwd_relative = pathJoin(b, brew, "opt/shaderc/lib") });
        mod.addIncludePath(.{ .cwd_relative = pathJoin(b, brew, "opt/shaderc/include") });
        bindings.addIncludePath(.{ .cwd_relative = pathJoin(b, brew, "opt/shaderc/include") });
    } else {
        mod.linkSystemLibrary("png", .{});
        mod.linkSystemLibrary("glfw3", .{});
        mod.linkSystemLibrary("freetype2", .{});
        mod.addLibraryPath(b.path("vendor/shaderc/lib"));
        mod.addIncludePath(b.path("vendor/shaderc/include/"));
        bindings.addIncludePath(b.path("vendor/shaderc/include/"));
    }

    mod.addLibraryPath(b.path("vendor/wgpu"));
    mod.linkSystemLibrary("wgpu_native", .{});
    mod.addIncludePath(b.path("vendor")); // "wgpu/wgpu.h" is the wgpu header

    mod.linkSystemLibrary("shaderc_combined", .{});

    mod.addIncludePath(b.path(".")); // for "extern/rayray.h"

    const c_args = [_][]const u8{
        "-O3",
        "-DGLFW_INCLUDE_NONE",
        "-Wno-dynamic-class-memaccess",
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
    mod.addCSourceFiles(.{ .files = &imgui_files, .flags = &c_args });

    b.installArtifact(exe);

    if (target.result.os.tag.isDarwin()) {
        mod.addFrameworkPath(.{ .cwd_relative = "/System/Library/Frameworks" });
        mod.linkFramework("Foundation", .{});
        mod.linkFramework("AppKit", .{});
    }

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    run_cmd.addPassthruArgs();

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
