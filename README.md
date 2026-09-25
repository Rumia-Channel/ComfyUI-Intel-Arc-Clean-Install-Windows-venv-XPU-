# ComfyUI on Intel Arc / Core Ultra (Windows, venv, PyTorch XPU)

Installer and maintenance scripts for native **PyTorch XPU** on Windows. This fork retains the familiar `.bat` and `.ps1` entry points and routes them through `ComfyUI-XPU.ps1` so both interfaces install the same dependencies.

**Updated installation policy (September 2026):** stable PyTorch XPU by default, optional nightly wheels; official ComfyUI Manager enabled via `manager_requirements.txt` and `--enable-manager`; ComfyUI-GGUF installed without patching upstream files. Installation on specific Intel GPU/driver combinations has **not** been verified by CI or on physical Windows hardware in this change.

## Requirements

- Windows 10/11 64-bit and a compatible Intel GPU with a current [Intel graphics driver](https://www.intel.com/content/www/us/en/download/785597/intel-arc-iris-xe-graphics-windows.html).
- **64-bit Python 3.12 or 3.11** on PATH; [Git for Windows](https://git-scm.com/download/win); PowerShell 5.1+ (included with Windows).
- Sufficient free storage for PyTorch, ComfyUI, custom nodes and your models. Disk and VRAM requirements depend on the workflow. Intel Arc A/B GPUs and some Core Ultra iGPUs may be suitable, but support varies by device and driver; the installer checks `torch.xpu.is_available()` instead of assuming support from the GPU name.
- Visual Studio C++ Build Tools are **not** required for standard XPU inference or GGUF installation. Building experimental Windows Triton XPU from source is a separate, advanced project.

## Quick start

In a Command Prompt, clone **this fork** and run the full installer:

```bat
git clone https://github.com/Rumia-Channel/ComfyUI-Intel-Arc-Clean-Install-Windows-venv-XPU-.git
cd ComfyUI-Intel-Arc-Clean-Install-Windows-venv-XPU-
Install.bat
START_ComfyUI.bat
```

By default ComfyUI is installed in `C:\ComfyUI`, and the app listens at http://127.0.0.1:8188. To choose a path containing spaces:

```bat
Install.bat "D:\AI Models\ComfyUI"
START_ComfyUI.bat "D:\AI Models\ComfyUI"
```

`Install.bat` installs ComfyUI, official Manager dependencies, PyTorch XPU and the four custom-node repositories below. `INSTALL_ComfyUI_Intel_Arc_XPU.bat` installs only the core and Manager dependencies; use `INSTALL_Custom_Nodes.bat` afterward if desired.

Run `UPDATE_ComfyUI.bat` to update ComfyUI, PyTorch XPU, official Manager dependencies and the custom nodes. Run `REPAIR_PyTorch_XPU.bat` to force-reinstall the XPU wheels **inside the ComfyUI virtual environment only**.

All these entry points accept the install folder as the first argument; their PowerShell counterparts accept `-InstallPath`.

## Stable vs nightly

Stable XPU is the default, using the official wheel index:

```text
https://download.pytorch.org/whl/xpu
```

For preview wheels, run the PowerShell interface explicitly:

```powershell
.\ComfyUI-XPU.ps1 -Mode Install -Nightly -InstallPath 'D:\AI\ComfyUI'
.\ComfyUI-XPU.ps1 -Mode Update -Nightly -InstallPath 'D:\AI\ComfyUI'
```

`-Nightly` uses `https://download.pytorch.org/whl/nightly/xpu`. It does not imply that a nightly is faster or more compatible than stable. If you intentionally want to continue without an available XPU, add `-AllowCpu`; otherwise the installer exits with an error instead of silently reporting GPU success.

To pass optional flags to ComfyUI, use:

```powershell
.\ComfyUI-XPU.ps1 -Mode Start -ComfyArgs @('--lowvram','--preview-method','auto')
```

No performance flags or custom output directory are imposed by default. For large models on a smaller GPU, consider `--lowvram`; do not assume it is optimal on every device.

## Custom nodes and Manager

The script clones/updates:

- [ComfyUI-GGUF](https://github.com/city96/ComfyUI-GGUF), including its Python requirements (`gguf`, etc.).
- [ComfyUI-VideoHelperSuite](https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite).
- [ComfyUI-Impact-Pack](https://github.com/ltdrdata/ComfyUI-Impact-Pack).
- [rgthree-comfy](https://github.com/rgthree/rgthree-comfy).

The official ComfyUI Manager is installed from ComfyUI's own `manager_requirements.txt`, then launched with `--enable-manager`. We deliberately do not clone the legacy Manager extension again. Existing legacy custom-node folders are not deleted; consult the official Manager migration guidance if you already installed that extension.

## Data safety and maintenance

- Existing `models`, `user`, `input`, `output`, `custom_nodes` and the virtual environment are not deleted or recreated on update.
- Git checkouts are updated with `git pull --ff-only`. If tracked files have local edits, the script stops instead of resetting or force-overwriting them. Untracked files are not deleted.
- Updates to Python dependencies and custom nodes can change behavior; **back up your workflows and environment before upgrading**. If an installation fails halfway through, inspect the error and rerun after resolving it; the script does not implement a full transactional rollback.
- Run from a Command Prompt to keep error output visible. Only run trusted scripts and dependencies. Close ComfyUI before updating.

## About the old GGUF Triton patch

`INSTALL_GGUF_Triton_Patch.bat` and `INSTALL_GGUF_Triton_Patch.ps1` now display a retirement notice and **do not modify ComfyUI-GGUF**. The earlier patch file remains in `patches/` only as historical material. The upstream installer removed its patch workflow, and [Intel's Windows Triton XPU guide](https://github.com/intel/intel-xpu-backend-for-triton/blob/main/.github/WINDOWS.md) still calls its support experimental and describes compiling components from source. Installing `pytorch-triton-xpu` from an arbitrary package index or applying a stale patch is not a safe default.

GGUF quantized model support does **not** require a custom Triton patch. No fixed "6-11x speedup" or model-generation timing is promised; performance depends on actual GPU, kernels, model, driver and workload.

## Verification and references

After installing, from a Command Prompt:

```bat
C:\ComfyUI\comfyui_venv\Scripts\python.exe -c "import torch; print(torch.__version__); print(torch.xpu.is_available()); print(torch.xpu.get_device_name(0) if torch.xpu.is_available() else 'NO XPU')"
```

For a non-default install path, replace `C:\ComfyUI` accordingly.

- [Official PyTorch XPU installation (stable and nightly)](https://github.com/pytorch/pytorch/blob/main/docs/source/notes/get_start_xpu.md)
- [Official ComfyUI README and Manager setup](https://github.com/Comfy-Org/ComfyUI)
- [Intel XPU Backend for Triton on Windows](https://github.com/intel/intel-xpu-backend-for-triton/blob/main/.github/WINDOWS.md)

MIT license: see [LICENSE](LICENSE). Original installer credit: [ai-joe-git](https://github.com/ai-joe-git/ComfyUI-Intel-Arc-Clean-Install-Windows-venv-XPU-).
