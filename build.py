import argparse
import subprocess
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description="使用 mcpp 构建 otfcc 库、工具和 DLL")
    parser.add_argument("--arch", choices=("x86", "x64"), default="x64")
    parser.add_argument("--profile", choices=("release", "dev"), default="release")
    parser.add_argument("--toolchain", help="覆盖 mcpp 当前 LLVM，例如 llvm@22.1.8")
    parser.add_argument("packages", nargs="*", choices=("otfcc", "deps", "tools", "dll"))
    args = parser.parse_args()
    target = "i686-windows-msvc" if args.arch == "x86" else "x86_64-windows-msvc"
    root = Path(__file__).resolve().parent
    # 分开构建独立产物，避免 mcpp 将 EXE 和 DLL 的静态依赖归入同一个构建图。
    for package in args.packages or ("deps", "otfcc", "tools", "dll"):
        command = ["mcpp", "build", "-p", package, "--target", target,
                   "--profile", args.profile, "--strict"]
        if args.toolchain:
            command.extend(("--toolchain", args.toolchain))
        subprocess.run(command, cwd=root, check=True)


if __name__ == "__main__":
    main()
