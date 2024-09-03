@echo off
setlocal
title RVC AI Cover Maker


if not exist env(
    set "principal=%cd%"
    set "CONDA_ROOT_PREFIX=%UserProfile%\Miniconda3"
    set "INSTALL_ENV_DIR=%principal%\env"
    set "MINICONDA_DOWNLOAD_URL=https://repo.anaconda.com/miniconda/Miniconda3-py39_23.9.0-0-Windows-x86_64.exe"
    set "CONDA_EXECUTABLE=%CONDA_ROOT_PREFIX%\Scripts\conda.exe"
    if not exist "%CONDA_EXECUTABLE%" (
        echo Miniconda not found. Starting download and installation...
        echo Downloading Miniconda...
        powershell -Command "& {Invoke-WebRequest -Uri '%MINICONDA_DOWNLOAD_URL%' -OutFile 'miniconda.exe'}"
        if not exist "miniconda.exe" (
            echo Download failed. Please check your internet connection and try again.
            goto :error
        )

        echo Installing Miniconda...
        start /wait "" miniconda.exe /InstallationType=JustMe /RegisterPython=0 /S /D=%CONDA_ROOT_PREFIX%
        if errorlevel 1 (
            echo Miniconda installation failed.
            goto :error
        )
        del miniconda.exe
        echo Miniconda installation complete.
    ) else (
        echo Miniconda already installed. Skipping installation.
    )
    echo.

    echo Creating Conda environment...
    call "%CONDA_ROOT_PREFIX%\_conda.exe" create --no-shortcuts -y -k --prefix "%INSTALL_ENV_DIR%" python=3.9
    if errorlevel 1 goto :error
    echo Conda environment created successfully.
    echo.

    if exist "%INSTALL_ENV_DIR%\python.exe" (
        echo Installing specific pip version...
        "%INSTALL_ENV_DIR%\python.exe" -m pip install "pip<24.1"
        if errorlevel 1 goto :error
        echo Pip installation complete.
        echo.
    )

    echo Installing dependencies...
    call "%CONDA_ROOT_PREFIX%\condabin\conda.bat" activate "%INSTALL_ENV_DIR%" || goto :error
    pip install --upgrade setuptools || goto :error
    pip install --no-deps -r "%principal%\requirements.txt" || goto :error
    pip uninstall torch torchvision torchaudio -y
    pip install torch==2.1.1 torchvision==0.16.1 torchaudio==2.1.1 --index-url https://download.pytorch.org/whl/cu121 || goto :error
    call "%CONDA_ROOT_PREFIX%\condabin\conda.bat" deactivate
    echo Dependencies installation complete.
    echo.
)

if not exist "programs/Music-Source-Separation-Training"(
    echo Cloning Music-Source-Separation-Training...
    git clone https://github.com/ZFTurbo/Music-Source-Separation-Training.git programs/Music-Source-Separation-Training
    del "programs/Music-Source-Separation-Training/inference.py"
    curl -o "programs/Music-Source-Separation-Training/inference.py" "https://raw.githubusercontent.com/ShiromiyaG/RVC-AI-Cover-Maker/v2/Utils/inference.py"
    echo.
)

if not exist "programs/Applio"(
    echo Cloning Applio...
    git clone https://github.com/IAHispano/Applio.git programs/Applio
    cd programs/Applio
    python core.py prerequisites --pretraineds_v1 "False" --pretraineds_v2 "False" --models "True" --exe "True"
    cd %principal%
    echo.
)

env\python.exe main.py --open
echo.
pause
exit /b 0

:error
echo An error occurred during installation. Please check the output above for details.
pause
exit /b 1