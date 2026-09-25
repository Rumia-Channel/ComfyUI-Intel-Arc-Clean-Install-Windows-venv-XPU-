"""Windows-safe Python/XPU diagnostics, invoked as a script rather than python -c.

Passing quoted Python literals through Windows PowerShell 5.1's native argument
handling can remove quotation marks. Keep Python code in this file instead.
"""
import sys


def check_python():
    print("Python:", sys.version.split()[0])
    if sys.maxsize <= 2**32 or sys.version_info[:2] not in ((3, 11), (3, 12)):
        print("ERROR: Use 64-bit Python 3.11 or 3.12.", file=sys.stderr)
        return 3
    return 0


def check_xpu():
    try:
        import torch
        print("PyTorch:", torch.__version__)
    except Exception as exc:
        print("ERROR: Cannot import PyTorch: {}".format(exc), file=sys.stderr)
        return 5

    try:
        available = hasattr(torch, "xpu") and torch.xpu.is_available()
        print("XPU available:", available)
        print("GPU:", torch.xpu.get_device_name(0) if available else "not detected")
        return 0 if available else 4
    except Exception as exc:
        print("ERROR: XPU detection failed: {}".format(exc), file=sys.stderr)
        return 5


if __name__ == "__main__":
    if len(sys.argv) != 2 or sys.argv[1] not in ("python", "xpu"):
        print("Usage: verify_environment.py [python|xpu]", file=sys.stderr)
        sys.exit(2)
    sys.exit(check_python() if sys.argv[1] == "python" else check_xpu())
