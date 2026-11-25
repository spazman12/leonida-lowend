# Progress log

Credited to **@spazman12** (build, runs, verification) with the AI assistant (Claude via DeepAI Code)
disclosed as AI-assisted on every step.

| When (UTC+1) | Milestone | Evidence (counts only, no game data) |
|---|---|---|
| Nov 24 13:14 | llvm-mc 21.1.8 (AMDGPU) built from source via the project's `build_llvm_mc.ps1` | 987/987 compile steps; gfx1013 smoke test encodes `v_add_f32` |
| Nov 24 23:44 | First build attempt from a stale mirror tree (`ProjectLeonidaL/leonida`, 44 commits) | runtime built; `--dry-run` 5 modules / 0 unimplemented; `--init` clean |
| Nov 25 07:40 | **Live tree identified**: `git.nite07.com/nite/leonida` (12,900+ commits, full history, boots through the story load into the world phase) | repo clone; README/`docs/first_run_ui.md`/`docs/linux_proton.md` |
| Nov 25 07:53 | Runtime rebuilt from the live tree with SDL3/GameInput (CMake, `LEONIDA_REQUIRE_VULKAN=ON -DLEONIDA_SDL3_FETCH=ON`) | 307/307 steps incl. SDL3-static |
| Nov 25 07:54 | Package check from the live tree | 108/108 manifest files, 0 size mismatches |
| Nov 25 08:02 | Disassembly (gfx1013) | 26,503 carved / unpacked, disasm running 16-wide |
| Nov 25 08:08 | Base translation (wave64-emulate, RTX 4050 probe) started | 16 shards |
| Nov 25 08:10 | `--mesh-compute` second pass armed (auto-starts after the base build) → the low-end GPU variant | stage2 watcher |

Planned next: first-run boot on the RTX 4050 (`--first-run-ui`), then the same on the Iris Xe with the
mesh-compute variant; results here first, then a PortWatch follow-up proposing a low-end verification note
(see issue 4lwayz/portwatch-vi#99).
