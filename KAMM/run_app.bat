@echo off
cd /d "%~dp0"

set "PYTHON="
set "PYTHON_ARGS="

if exist "%~dp0.venv\Scripts\python.exe" (
	set "PYTHON=%~dp0.venv\Scripts\python.exe"
) else (
	where py >nul 2>nul
	if not errorlevel 1 (
		set "PYTHON=py"
		set "PYTHON_ARGS=-3"
	) else (
		where python >nul 2>nul
		if not errorlevel 1 set "PYTHON=python"
	)
)

if not defined PYTHON (
	echo Python was not found. Install Python 3 or create a project .venv.
	pause
	exit /b 1
)

"%PYTHON%" %PYTHON_ARGS% -c "import streamlit" >nul 2>nul
if errorlevel 1 (
	echo Streamlit is not installed in the selected Python environment.
	echo Install the project dependencies with:
	echo   "%PYTHON%" %PYTHON_ARGS% -m pip install -r requirements.txt
	pause
	exit /b 1
)

"%PYTHON%" %PYTHON_ARGS% -m streamlit run clustering_app/app_clustering_gui.py
pause
