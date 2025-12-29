#!/usr/bin/env python3
"""
InfraForge Installer (Artifact-based via GitHub Tags)
Free · Local · Open · Forever

Usage:
  infraforge-installer v0.9.0

What this does:
- Downloads a tagged InfraForge release (.tar.gz)
- Extracts it into /usr/local/InfraForge
- Creates /usr/local/bin/infraforge symlink
- Runtime is 100% offline
"""

import os
import sys
import subprocess
import tempfile
import urllib.request
from pathlib import Path

# ---------------- CONFIG ----------------

ORG = "InfraForgeLabs"
REPO = "InfraForge"

INSTALL_DIR = Path("/usr/local/InfraForge")
BIN_LINK = Path("/usr/local/bin/infraforge")

REQUIRED_PATHS = [
    "bin/infraforge",
    "lib/core/common.sh",
    "lib/scripts",
]

# ---------------- UTILS ----------------

def info(msg: str):
    print(f"✔ {msg}")

def fatal(msg: str):
    print(f"❌ {msg}", file=sys.stderr)
    sys.exit(1)

def require_root():
    if os.geteuid() != 0:
        fatal("Run as root: sudo ~/.local/bin/infraforge-installer <tag>")

# ---------------- VALIDATION ----------------

def validate_repo(root: Path):
    for rel in REQUIRED_PATHS:
        if not (root / rel).exists():
            fatal(f"Invalid InfraForge artifact: missing {rel}")

# ---------------- CORE LOGIC ----------------

def download_release(tag: str, dest: Path):
    url = f"https://github.com/{ORG}/{REPO}/archive/refs/tags/{tag}.tar.gz"
    info(f"Downloading InfraForge release {tag}")
    try:
        urllib.request.urlretrieve(url, dest)
    except Exception as e:
        fatal(f"Failed to download release archive: {e}")

def main():
    require_root()

    if len(sys.argv) != 2:
        fatal("Usage: infraforge-installer <tag>   (example: v0.9.0)")

    tag = sys.argv[1]

    if INSTALL_DIR.exists():
        fatal(
            "InfraForge already installed at /usr/local/InfraForge\n"
            "Remove it first to reinstall."
        )

    with tempfile.TemporaryDirectory(prefix=".infraforge-tmp-", dir="/usr/local") as tmp:
        tmp_path = Path(tmp)
        archive = tmp_path / "infraforge.tar.gz"

        # 1️⃣ Download artifact
        download_release(tag, archive)

        # 2️⃣ Extract archive
        info("Extracting InfraForge")
        subprocess.run(
            ["tar", "xzf", str(archive), "-C", str(tmp_path)],
            check=True
        )

        # 3️⃣ Detect extracted directory (ROBUST FIX)
        extracted_dirs = list(tmp_path.glob(f"{REPO}-*"))
        if len(extracted_dirs) != 1:
            fatal("Unexpected archive layout")

        extracted = extracted_dirs[0]

        # 4️⃣ Validate contents
        validate_repo(extracted)

        # 5️⃣ Atomic install
        info("Finalizing install")
        extracted.rename(INSTALL_DIR)

    # 6️⃣ Symlink LAST (success indicator)
    if BIN_LINK.exists() or BIN_LINK.is_symlink():
        BIN_LINK.unlink()

    os.symlink(INSTALL_DIR / "bin/infraforge", BIN_LINK)

    info("InfraForge installed successfully")
    info("Run: infraforge --help")
    info("All generators run fully offline")

# ---------------- ENTRY ----------------

if __name__ == "__main__":
    main()
