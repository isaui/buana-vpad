# -*- mode: python ; coding: utf-8 -*-

from PyInstaller.utils.hooks import collect_all, collect_submodules, collect_data_files
import os
import sys

def get_requirements():
    with open('requirements.txt', 'r') as f:
        return [line.strip().split('==')[0] for line in f if line.strip() and not line.startswith('#')]

# Path ke virtual environment
venv_path = 'wheels/Lib/site-packages'

block_cipher = None

# Collect packages from requirements.txt and add their paths
requirements = get_requirements()
print(f"Found requirements: {requirements}")

additional_datas = []
missing_packages = []

# Tambahkan path untuk setiap package dari requirements.txt
for req in requirements:
    package_path = os.path.join(venv_path, req)
    if os.path.exists(package_path):
        additional_datas.append((package_path, req))
        print(f"Added package: {req} from {package_path}")
    else:
        # Coba cari dengan nama lowercase
        package_path = os.path.join(venv_path, req.lower())
        if os.path.exists(package_path):
            additional_datas.append((package_path, req.lower()))
            print(f"Added package (lowercase): {req} from {package_path}")
        else:
            missing_packages.append(req)
            print(f"Warning: Could not find path for {req}")

if missing_packages:
    print(f"\nMissing packages: {missing_packages}")

# Define all required Qt plugins
qt_plugins = [
    'platforms',
    'styles',
    'imageformats',
]

# Collect Qt plugins
qt_plugins_binaries = []
for plugin in qt_plugins:
    plugin_path = os.path.join(venv_path, 'PyQt6', 'Qt6', 'plugins', plugin)
    if os.path.exists(plugin_path):
        qt_plugins_binaries.append((plugin_path, os.path.join('PyQt6', 'Qt6', 'plugins', plugin)))
        print(f"Added Qt plugin: {plugin}")

a = Analysis(
    ['main.py'],
    pathex=[venv_path],
    binaries=qt_plugins_binaries,
    datas=[
        ('src', 'src'),
        (os.path.join(venv_path, 'vgamepad'), 'vgamepad'),
        (os.path.join(venv_path, 'qasync'), 'qasync'),
        (os.path.join(venv_path, 'PyQt6'), 'PyQt6'),
    ] + additional_datas,
    hiddenimports=[
        'qasync',
        'uvicorn',
        'fastapi',
        'vgamepad',
        'python_multipart',
        'PyQt6.sip',
        'PyQt6.QtCore',
        'PyQt6.QtWidgets',
        'PyQt6.QtGui',
    ] + requirements,
    excludes=[
        'matplotlib',
        'numpy',
        'PIL',
        'pandas',
        'scipy',
        'tkinter',
        'PyQt6.QtSql',
        'PyQt6.QtMultimedia',
        'PyQt6.QtNetwork',
        'PyQt6.QtOpenGL',
        'PyQt6.QtPrintSupport',
        'PyQt6.QtXml',
    ],
    noarchive=False
)

print("\nCollecting and removing duplicate binaries...")

# Remove duplicate binaries that are already in datas
removed_binaries = []
for b in a.binaries.copy():
    for d in a.datas:
        if b[1].endswith(d[0]):
            a.binaries.remove(b)
            removed_binaries.append(b[0])
            break

if removed_binaries:
    print(f"Removed duplicate binaries: {removed_binaries}")

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.datas,
    name='BuanaVPad',
    debug=False,
    strip=False,
    upx=True,
    runtime_tmpdir=None,
    console=False,
    icon='src/gui/logo/logo.ico'
)