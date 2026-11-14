@echo off
REM Build a single-file SearchHop.exe. Run from this directory.
REM Prerequisite: pip install -r requirements.txt
cd /d "%~dp0"

REM numpy / PIL are pulled in transitively by CustomTkinter's optional CTkImage
REM but SearchHop never uses them (the switch is drawn with tkinter.PhotoImage).
REM Excluding them removes ~30 MB of dead weight (incl. the OpenBLAS DLL).
REM --noupx: no binary compression, per the "don't compress" requirement.
pyinstaller --noconfirm --onefile --windowed --noupx --name SearchHop ^
  --icon "assets/icon.ico" ^
  --collect-all customtkinter ^
  --exclude-module numpy --exclude-module PIL --exclude-module Pillow ^
  --add-data "default_config.json;." ^
  --add-data "assets/icon.ico;assets" ^
  app.py
if errorlevel 1 (
    echo.
    echo [SearchHop] Build failed. Make sure you ran: pip install -r requirements.txt
    exit /b 1
)

echo.
echo [SearchHop] Build complete: dist\SearchHop.exe
echo [SearchHop] config.json will be generated next to the exe on first run.