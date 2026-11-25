@echo off
REM Build Leonida (git.nite07.com/nite/leonida) from your own copy, with the first-run-UI runtime.
REM Prereqs: Python 3.12+, Vulkan SDK, VS 2022 C++ tools, llvm-mc with AMDGPU (LLVM_MC), dotnet 8.
REM Edit the five paths below, then run from any terminal:
REM   cmd /c path\to\build.cmd

setlocal
REM === EDIT THESE ===
set "REPO=C:\src\leonida"                          REM checkout of the live tree
set "GAME=C:\your\package"                         REM folder with MicrosoftGame.Config and the .rpf files
set "OUT=D:\gta 6"                                 REM port + work files (work wants ~30 GB for shaders)
set "LLVM_MC=%USERPROFILE%\.leonida\llvm-mc\llvm-mc.exe"
set "VULKAN_SDK=C:\VulkanSDK\1.4.363.0"
REM === END EDITS ===

set "PATH=%VULKAN_SDK%\Bin;C:\Users\%USERNAME%\AppData\Local\Programs\Python\Python312;C:\Program Files\dotnet;%PATH%"
REM Pin the GPU the runtime and tests use (substring of the device name; see LEONIDA_VK_DEVICE).
set "LEONIDA_VK_DEVICE="
set "LEONIDA_SKIP_PREREQ_INSTALL=1"

call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" >nul 2>&1

REM 1) runtime: Vulkan required, SDL3 fetched so the GameInput shim builds
cmake -S "%REPO%\runtime" -B "%OUT%\build" -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo ^
      -DLEONIDA_REQUIRE_VULKAN=ON -DLEONIDA_D3D12_SHIM_TESTS=ON -DLEONIDA_SDL3_FETCH=ON ^
      > "%OUT%\cmake.log" 2>&1 || (echo CMAKE FAILED, see %OUT%\cmake.log & exit /b 1)
cmake --build "%OUT%\build" --target gta6rt >> "%OUT%\cmake.log" 2>&1 || (echo RUNTIME BUILD FAILED & exit /b 1)

REM 2) package check, shader translation, runtime stage
cd /d "%REPO%"
py -3.12 -I make_game.py --game "%GAME%" --work "%OUT%\work" --out "%OUT%" ^
   --runtime-build "%OUT%\build" --stages check,shaders,runtime --jobs 16 --no-tui ^
   > "%OUT%\build.log" 2>&1
echo EXIT=%ERRORLEVEL% >> "%OUT%\build.log"

REM 3) a mesh-compute variant for GPUs without VK_EXT_mesh_shader (Intel iGPU class);
REM    use separate Intel folders and probe the Intel device without an NVIDIA driver filter
REM py -3.12 -I make_game.py --game "%GAME%" --work "%OUT%-intel\work" --out "%OUT%-intel" ^
REM    --runtime-build "%OUT%\build" --stages shaders --mesh-compute --jobs 16 --no-tui

REM 4) launch (offline by construction: the Winsock/WinHTTP shims)
REM "%OUT%\gta6rt.exe" --first-run-ui "%GAME%\game_scarlett_master.exe"
