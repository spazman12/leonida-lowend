# Leonida on low-end GPUs — build notes and scripts

Progress log for building and running [Leonida](https://git.nite07.com/nite/leonida) — the static
recompilation of GTA VI's Xbox Series build to native Windows/Vulkan — on a mid/low-end laptop, with the
end goal of making it work on hardware **without** high-end GPUs.

Everything here runs from **your own copy** of the game. This repository contains **no game data**: no
archives, no executable, no shaders, no extracted assets, no traces that quote game files.

## The machine

| | |
|---|---|
| CPU | Intel i7-13700H (14C/20T) — needs the runtime's Zen 2 instruction emulation (SSE4a, CLZERO, MONITORX, CLWB) |
| RAM | 32 GB |
| GPU | NVIDIA RTX 4050 Laptop (Vulkan 1.4, 32-wide subgroups) + Intel Iris Xe (Vulkan 1.4) |
| OS | Windows 11 |

## What we did

1. **Found the live tree.** The well-known mirrors (`ProjectLeonidaL/leonida`, `ubiquitarianism/leonida`)
   are stale 44-commit continuations. Development actually happens at
   **`git.nite07.com/nite/leonida`** (self-hosted Git, 12,900+ commits, full history restored from the
   original `ItsNotRexed/Leonida`). Its `main` boots through the launch movie, first-run pages and the
   landing prompt, runs the story load to its end and enters the world phase — no world frame verified yet.
   See its `README.md`, `docs/first_run_ui.md` and `docs/linux_proton.md`.
2. **Built the toolchain** (all on Windows, no WSL):
   - Python 3.12.10, .NET 8 SDK, Vulkan SDK 1.4.363 via winget
   - VS 2022 Build Tools with the C++ x64 workload (already present)
   - `llvm-mc` with the AMDGPU target: LLVM 21.1.8 built from source with the project's own
     `scripts/build_llvm_mc.ps1` (the official Windows LLVM release ships no `llvm-mc`; 30 min on 16 jobs),
     installed to `~\.leonida\llvm-mc\llvm-mc.exe` and exported as `LLVM_MC`
   - Verified with a gfx1013 smoke test: `v_add_f32 v0, v1, v2` encodes to `[0x01,0x05,0x00,0x06]`
   - SPIR-V toolchain round-trip (`spirv-as` → `spirv-val`, Vulkan 1.2) verified clean
3. **Verified the package** against the project's own `game/xbox-1.0.2.1.json` manifest: 108/108 files,
   0 size mismatches. Version check is size-only by default; `--full-check` hashes all ~224 GB.
4. **Built the runtime** from the live tree with CMake + Ninja:
   `cmake -S runtime -B build -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo -DLEONIDA_REQUIRE_VULKAN=ON
   -DLEONIDA_D3D12_SHIM_TESTS=ON -DLEONIDA_SDL3_FETCH=ON` then `cmake --build build --target gta6rt`.
   SDL3 is fetched automatically, which builds the GameInput controller shim (our first build without it
   silently skipped controller support).
5. **Ran the loader checks against the retail exe** (from the previous-generation tree, same exe):
   - `--dry-run`: 5 modules mapped, **0 unimplemented imports** (exe 299,257 `.pdata` functions)
   - `--init`: 4 `DllMain`s + 4 TLS callbacks, no exceptions
6. **Started the full build** (`check,shaders,runtime`) from the live tree into `D:\gta 6` with
   `scripts/build.cmd`. All 26,503 programs carve; translation runs 16-wide.

## Low-end GPU plan

The project's own device-adaptive fallbacks are the mechanism, and the work folder keeps translation
variants side by side so one build serves many GPUs:

| GPU class | What makes it work |
|---|---|
| RTX 4050-class (32-wide subgroups) | `--wave64-emulate` (on automatically: the probe saw maxSubgroupSize 32) |
| Intel Iris Xe / iGPU-class | `--mesh-compute` variant (Intel's Windows Vulkan driver crashes on native mesh draws — BUILD-2202) — **planned as a second translation pass after the base one lands** |
| GPUs without `VK_EXT_mesh_shader` at all | same `--mesh-compute` variant, which emits compute shaders |
| GPUs with low `maxPushConstantsSize` | `--pc-tail-ubo` (automatic when the runtime probe reports < 144 bytes) |
| Missing barycentric / maintenance8 / float-controls features | `--bary-fallback`, `--texel-offset-fallback`, `--no-float-controls` (per-device, automatic) |

The runtime picks the variant per device at run time (`LEONIDA_VK_DEVICE` pins a GPU on multi-GPU
machines; we export `LEONIDA_VK_DEVICE=4050` so the Intel iGPU is never chosen by enumeration order).

## Launching (from `docs/first_run_ui.md`)

```powershell
& "D:\gta 6\gta6rt.exe" --first-run-ui "C:\path\to\game_scarlett_master.exe"
```

The profile selects Vulkan, a 2 GiB graphics address arena, on-demand pipelines, console root-argument
layout, frame pacing and the keyboard gamepad. The Winsock shim permits loopback only and the WinHTTP
shim refuses outbound requests, so the run stays offline by construction.

## Status

- [x] Toolchain built and verified
- [x] Package verified against manifest
- [x] Runtime built (with GameInput/SDL3)
- [x] `--dry-run` / `--init` clean
- [ ] Base translation (26,503 programs) — running
- [ ] `--mesh-compute` variant for iGPU-class GPUs
- [ ] `--first-run-ui` boot on the 4050
- [ ] Same on the Iris Xe (mesh-compute variant)
- [ ] World frame

## See also

- Upstream (live): <https://git.nite07.com/nite/leonida>
- The project's rules: no game data in repos, no keys/decryption, nothing online
- Asset-side toolkit list: <https://portwatch-vi.xyz/> (RPF9 explorers, texture codecs, format notes)

## Credits

- **[@spazman12](https://github.com/spazman12)** — machine setup, build runs, verification, and direction.
- **Claude (DeepAI Code)** — AI assistant: code reading, scripting, triage and drafting. All work was
  AI-assisted and human-run; commits are authored by @spazman12 with the assistant disclosed in messages.
- Leonida by its authors (ItsNotRexed and the continuation's contributors) — the port, the tools, the docs.

Future upstream contributions will follow the project's own process: claim in the coordination issue first,
state that the work was AI-assisted, and say what was tested and on which GPU and driver.

## License / attribution

Notes and scripts here are MIT. Leonida is GPLv3+ by its authors (ItsNotRexed and contributors;
continuation at git.nite07.com/nite/leonida). Grand Theft Auto and related marks belong to their owners;
this is unaffiliated fan work.
