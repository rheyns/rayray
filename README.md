# rayray
A tiny GPU raytracer!

(more details on the [project homepage](https://www.mattkeeter.com/projects/rayray))

![Cornell Box](https://www.mattkeeter.com/projects/rayray/renders/cornell@2x.png)

![Ray tracing in one weekend](https://www.mattkeeter.com/projects/rayray/renders/rtiow@2x.png)

## Features
- Diffuse, metal, and glass materials
- The only three shapes that matter:
    - Spheres
    - Planes (both infinite and finite)
    - Cylinders (both infinite and capped)
- Any shape can be a light!
- Antialiasing with sub-pixel sampling
- Will **crash your entire computer** if you render too many rays per frame
  (thanks, GPU drivers)

## Implementation
- Built on the bones of [Futureproof](https://mattkeeter.com/projects/futureproof)
- Written in [Zig](https://ziglang.org)
- Using [WebGPU](https://gpuweb.github.io/gpuweb/) for graphics
  via [`wgpu-native`](https://github.com/gfx-rs/wgpu-native)
- Shaders compiled from GLSL to SPIR-V with [`shaderc`](https://github.com/google/shaderc)
- Minimal GUI using [Dear ImGUI](https://github.com/ocornut/imgui),
  with a custom [Zig + WebGPU backend](https://github.com/mkeeter/rayray/blob/master/src/gui/backend.zig)
- Vaguely based on [_Ray Tracing in One Weekend_](https://raytracing.github.io/books/RayTracingInOneWeekend.html),
  with a data-driven design to run on the GPU.

## Building on Apple Silicon

This branch targets **Zig 0.17.0-dev.2313+5b9147ed5** on native ARM64 macOS.
There is no final 0.17.0 release yet; use this exact development build, also
recorded in `.zigversion`. Older Zig releases cannot compile this branch.

Install Homebrew dependencies and initialize the pinned ImGui submodules:

```sh
brew install glfw libpng freetype shaderc
git submodule update --init --recursive
```

Keep the compiler inside the project so the build does not depend on a temporary
directory:

```sh
mkdir -p .tools
curl -fL 'https://ziglang.org/builds/zig-aarch64-macos-0.17.0-dev.2313+5b9147ed5.tar.xz' -o .tools/zig-0.17.0-dev.2313.tar.xz
# Expected SHA-256: 9e2abc63ea4db5df046aa3088e1b660faca39c83da3bda544c734c65af5365c9
shasum -a 256 .tools/zig-0.17.0-dev.2313.tar.xz
tar -xf .tools/zig-0.17.0-dev.2313.tar.xz -C .tools
```

With Rust/Cargo installed, build the pinned native WebGPU library once, then
build and run rayray from the project directory:

```sh
make -C vendor wgpu
.tools/zig-aarch64-macos-0.17.0-dev.2313+5b9147ed5/zig build
./zig-out/bin/rayray
# Render the default Cornell Box to out.png and exit:
./zig-out/bin/rayray -n 1024
```

For an optimized build with safety checks, add `-Doptimize=safe`. The default
is `debug`; `fast` and `small` are also available. `zig build run -- -n 1024`
builds and runs with arguments when the pinned compiler is on your `PATH`.
Run from the project directory so runtime shader includes can be found.
Use `./zig-out/bin/rayray -s` for spectral rendering, then select **Scene → Prism**
to see dispersion. **Edit → Show editor** opens the camera, shape, and material
controls. A render requested with `-n` continues even when the window loses focus.

C bindings are generated with `translate-c`. The build corrects the pinned
cimgui header's index typedef to match the renderer's 32-bit index buffers,
without modifying the submodule. The scalar ImGui bridge and Metal resize fix
are retained. Worker threads are joined before shutdown, and the ImGui allocator
keeps a stable context for its callbacks.

The build uses Homebrew at `/opt/homebrew` (or `HOMEBREW_PREFIX` when set).
Keep `vendor/wgpu/libwgpu_native.dylib` alongside the project: the executable
loads it relative to `zig-out/bin`. The compiler, dependencies, executable and
render output can all remain in this directory across reboots; generated files
are ignored by Git.

The window uses `GLFW_NO_API` because WebGPU owns its Metal layer. Creating an
OpenGL context as well lets Cocoa overwrite the displayed content on resize.
To check the resize path, launch the interactive app, resize it wider, then
taller, and restore its original size. The scene and GUI should stay visible,
with sampling restarting at each new size.

## Upstream project status
![Project unsupported](https://img.shields.io/badge/project-unsupported-red.svg)

This is a personal / toy project,
and I don't plan to support it on anything other than my laptop
(macOS 10.13, `zig-macos-x86_64-0.8.0-dev.1125`,
and `wgpu-native` built from source).

I'm unlikely to fix any issues,
although I will optimistically merge small-to-medium PRs that fix bugs
or add support for more platforms.

That being said, I'm generally friendly,
so feel free to open issues and ask questions;
just don't set your expectations too high!

If you'd like to add major features, please fork the project;
I'd be happy to link to any forks which achieve critical momemtum!

## License
Licensed under either of

 * [Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0)
 * [MIT license](http://opensource.org/licenses/MIT)

at your option.

## Contribution
Unless you explicitly state otherwise, any contribution intentionally submitted
for inclusion in the work by you, as defined in the Apache-2.0 license, shall be
dual licensed as above, without any additional terms or conditions.
