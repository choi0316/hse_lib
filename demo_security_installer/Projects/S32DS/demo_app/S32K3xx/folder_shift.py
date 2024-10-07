import os
import shutil
import sys
from pathlib import Path
# src is the current directory from where batch script is running 
# build directory specific to SOC

src = Path().absolute()
dst = (src.parent.parent / 'bin' / str(src)[-7:])

print(f"Copying output artifacts from {src} to {dst}")
shutil.copytree(src,dst,dirs_exist_ok=True)

