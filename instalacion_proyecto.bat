@echo off
REM ============================================================
REM Script de Instalación Automática
REM Sistema de Gestión de Taller Mecánico - MySQL
REM ============================================================

SETLOCAL EnableDelayedExpansion

REM Colores para mensajes
SET "GREEN=[92m"
SET "RED=[91m"
SET "YELLOW=[93m"
SET "BLUE=[94m"
SET "NC=[0m"

echo %BLUE%============================================================%NC%
echo %BLUE%   INSTALADOR AUTOMATICO - SISTEMA TALLER MECANICO%NC%
echo %BLUE%============================================================%NC%
echo.

REM Verificar permisos de administrador
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo %RED%ERROR: Este script requiere permisos de Administrador%NC%
    echo %YELLOW%Haz clic derecho en el script y selecciona "Ejecutar como administrador"%NC%
    pause
    exit /b 1
)

echo %GREEN%[OK] Permisos de administrador verificados%NC%
echo.

REM ============================================================
REM PASO 1: CONFIGURACION INICIAL
REM ============================================================

echo %BLUE%[PASO 1/10] Configurando rutas...%NC%

SET "BASE_DIR=C:\TallerMecanico"
SET "PROJECT_DIR=%BASE_DIR%\project"
SET "VENV_DIR=%PROJECT_DIR%\venv"
SET "LOGS_DIR=%BASE_DIR%\logs"
SET "BACKUPS_DIR=%BASE_DIR%\backups"
SET "MEDIA_DIR=%BASE_DIR%\media"
SET "STATIC_DIR=%BASE_DIR%\staticfiles"

echo Directorio base: %BASE_DIR%
echo.

REM ============================================================
REM PASO 2: CREAR ESTRUCTURA DE CARPETAS
REM ============================================================

echo %BLUE%[PASO 2/10] Creando estructura de carpetas...%NC%

if not exist "%BASE_DIR%" mkdir "%BASE_DIR%"
if not exist "%PROJECT_DIR%" mkdir "%PROJECT_DIR%"
if not exist "%LOGS_DIR%" mkdir "%LOGS_DIR%"
if not exist "%BACKUPS_DIR%" mkdir "%BACKUPS_DIR%"
if not exist "%MEDIA_DIR%" mkdir "%MEDIA_DIR%"
if not exist "%STATIC_DIR%" mkdir "%STATIC_DIR%"

echo %GREEN%[OK] Estructura de carpetas creada%NC%
echo.

REM ============================================================
REM PASO 3: VERIFICAR PYTHON
REM ============================================================

echo %BLUE%[PASO 3/10] Verificando instalación de Python...%NC%

python --version >nul 2>&1
if %errorLevel% neq 0 (
    echo %RED%[ERROR] Python no está instalado o no está en PATH%NC%
    echo %YELLOW%Por favor instala Python 3.10+ desde: https://www.python.org/downloads/%NC%
    echo %YELLOW%Asegúrate de marcar "Add Python to PATH" durante la instalación%NC%
    pause
    exit /b 1
)

for /f "tokens=2" %%i in ('python --version 2^>^&1') do set PYTHON_VERSION=%%i
echo %GREEN%[OK] Python %PYTHON_VERSION% detectado%NC%
echo.

REM ============================================================
REM PASO 4: VERIFICAR MYSQL
REM ============================================================

echo %BLUE%[PASO 4/10] Verificando instalación de MySQL...%NC%

mysql --version >nul 2>&1
if %errorLevel% neq 0 (
    echo %YELLOW%[ADVERTENCIA] MySQL no está en PATH%NC%
    echo Intentando agregar MySQL al PATH...
    
    if exist "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" (
        setx PATH "%PATH%;C:\Program Files\MySQL\MySQL Server 8.0\bin" /M >nul 2>&1
        set "PATH=%PATH%;C:\Program Files\MySQL\MySQL Server 8.0\bin"
        echo %GREEN%[OK] MySQL 8.0 agregado al PATH%NC%
    ) else if exist "C:\Program Files\MySQL\MySQL Server 8.1\bin\mysql.exe" (
        setx PATH "%PATH%;C:\Program Files\MySQL\MySQL Server 8.1\bin" /M >nul 2>&1
        set "PATH=%PATH%;C:\Program Files\MySQL\MySQL Server 8.1\bin"
        echo %GREEN%[OK] MySQL 8.1 agregado al PATH%NC%
    ) else if exist "C:\Program Files\MySQL\MySQL Server 5.7\bin\mysql.exe" (
        setx PATH "%PATH%;C:\Program Files\MySQL\MySQL Server 5.7\bin" /M >nul 2>&1
        set "PATH=%PATH%;C:\Program Files\MySQL\MySQL Server 5.7\bin"
        echo %GREEN%[OK] MySQL 5.7 agregado al PATH%NC%
    ) else (
        echo %RED%[ERROR] MySQL no está instalado%NC%
        echo %YELLOW%Por favor instala MySQL desde: https://dev.mysql.com/downloads/installer/%NC%
        pause
        exit /b 1
    )
)

for /f "tokens=1-3" %%i in ('mysql --version 2^>^&1') do set MYSQL_VERSION=%%k
echo %GREEN%[OK] MySQL %MYSQL_VERSION% detectado%NC%
echo.

REM ============================================================
REM PASO 5: SOLICITAR CONFIGURACION
REM ============================================================

echo %BLUE%[PASO 5/10] Configuración de la base de datos...%NC%
echo.

SET /P "DB_NAME=Nombre de la base de datos [taller_mecanico_db]: "
if "%DB_NAME%"=="" SET "DB_NAME=taller_mecanico_db"

SET /P "DB_USER=Usuario de la base de datos [taller_admin]: "
if "%DB_USER%"=="" SET "DB_USER=taller_admin"

SET /P "DB_PASSWORD=Contraseña de la base de datos [Password123!]: "
if "%DB_PASSWORD%"=="" SET "DB_PASSWORD=Password123!"

SET /P "MYSQL_ROOT_PASSWORD=Contraseña del usuario root de MySQL: "
if "%MYSQL_ROOT_PASSWORD%"=="" (
    echo %RED%[ERROR] Debes ingresar la contraseña de root%NC%
    pause
    exit /b 1
)

echo.
echo %GREEN%Configuración guardada:%NC%
echo   - Base de datos: %DB_NAME%
echo   - Usuario: %DB_USER%
echo   - Contraseña: %DB_PASSWORD%
echo.

REM ============================================================
REM PASO 6: CREAR BASE DE DATOS
REM ============================================================

echo %BLUE%[PASO 6/10] Creando base de datos...%NC%

REM Crear archivo SQL temporal
(
echo CREATE DATABASE IF NOT EXISTS %DB_NAME% CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
echo CREATE USER IF NOT EXISTS '%DB_USER%'@'localhost' IDENTIFIED BY '%DB_PASSWORD%';
echo GRANT ALL PRIVILEGES ON %DB_NAME%.* TO '%DB_USER%'@'localhost';
echo FLUSH PRIVILEGES;
) > "%TEMP%\create_db.sql"

REM Ejecutar SQL
mysql -u root -p%MYSQL_ROOT_PASSWORD% < "%TEMP%\create_db.sql" >nul 2>&1

if %errorLevel% equ 0 (
    echo %GREEN%[OK] Base de datos creada exitosamente%NC%
) else (
    echo %YELLOW%[ADVERTENCIA] La base de datos ya existe o hubo un error%NC%
    echo Continuando con la instalación...
)

del "%TEMP%\create_db.sql"
echo.

REM ============================================================
REM PASO 7: CLONAR O VERIFICAR PROYECTO
REM ============================================================

echo %BLUE%[PASO 7/10] Verificando archivos del proyecto...%NC%

if not exist "%PROJECT_DIR%\manage.py" (
    echo %YELLOW%[ADVERTENCIA] No se encuentra manage.py en %PROJECT_DIR%%NC%
    echo.
    echo Opciones:
    echo 1. Clonar desde repositorio Git
    echo 2. Ya copié los archivos manualmente
    echo 3. Salir
    echo.
    
    SET /P "OPTION=Selecciona una opción [1-3]: "
    
    if "!OPTION!"=="1" (
        SET /P "GIT_REPO=URL del repositorio Git: "
        if not "!GIT_REPO!"=="" (
            echo Clonando repositorio...
            git clone "!GIT_REPO!" "%PROJECT_DIR%" >nul 2>&1
            if !errorLevel! equ 0 (
                echo %GREEN%[OK] Repositorio clonado%NC%
            ) else (
                echo %RED%[ERROR] No se pudo clonar el repositorio%NC%
                pause
                exit /b 1
            )
        )
    ) else if "!OPTION!"=="2" (
        echo %YELLOW%Asegúrate de copiar todos los archivos a %PROJECT_DIR%%NC%
        pause
    ) else (
        echo Instalación cancelada
        exit /b 0
    )
)

if exist "%PROJECT_DIR%\manage.py" (
    echo %GREEN%[OK] Proyecto encontrado%NC%
) else (
    echo %RED%[ERROR] No se encuentra manage.py%NC%
    pause
    exit /b 1
)
echo.

REM ============================================================
REM PASO 8: CREAR ENTORNO VIRTUAL E INSTALAR DEPENDENCIAS
REM ============================================================

echo %BLUE%[PASO 8/10] Configurando entorno virtual...%NC%

cd /d "%PROJECT_DIR%"

if not exist "%VENV_DIR%" (
    echo Creando entorno virtual...
    python -m venv venv
    echo %GREEN%[OK] Entorno virtual creado%NC%
) else (
    echo %GREEN%[OK] Entorno virtual ya existe%NC%
)

echo Activando entorno virtual...
call "%VENV_DIR%\Scripts\activate.bat"

echo Actualizando pip...
python -m pip install --upgrade pip --quiet

echo Instalando dependencias...
if exist "requirements.txt" (
    pip install -r requirements.txt --quiet
) else (
    echo %YELLOW%No se encuentra requirements.txt, instalando paquetes básicos...%NC%
    pip install django==4.2.7 mysqlclient python-dotenv Pillow djangorestframework django-cors-headers openpyxl reportlab --quiet
)

echo %GREEN%[OK] Dependencias instaladas%NC%
echo.

REM ============================================================
REM PASO 9: CREAR ARCHIVO .ENV
REM ============================================================

echo %BLUE%[PASO 9/10] Creando archivo de configuración...%NC%

REM Generar SECRET_KEY
for /f %%i in ('python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"') do set SECRET_KEY=%%i

REM Crear archivo .env
(
echo # Configuración Django
echo SECRET_KEY=%SECRET_KEY%
echo DEBUG=True
echo ALLOWED_HOSTS=localhost,127.0.0.1
echo.
echo # Base de Datos MySQL
echo DB_ENGINE=django.db.backends.mysql
echo DB_NAME=%DB_NAME%
echo DB_USER=%DB_USER%
echo DB_PASSWORD=%DB_PASSWORD%
echo DB_HOST=localhost
echo DB_PORT=3306
echo.
echo # Archivos
echo MEDIA_ROOT=C:/TallerMecanico/media
echo STATIC_ROOT=C:/TallerMecanico/staticfiles
) > ".env"

echo %GREEN%[OK] Archivo .env creado%NC%
echo.

REM ============================================================
REM PASO 10: MIGRACIONES Y SUPERUSUARIO
REM ============================================================

echo %BLUE%[PASO 10/10] Configurando base de datos Django...%NC%

echo Aplicando migraciones...
python manage.py migrate

if %errorLevel% equ 0 (
    echo %GREEN%[OK] Migraciones aplicadas%NC%
) else (
    echo %RED%[ERROR] Error al aplicar migraciones%NC%
    echo Verifica la configuración en settings.py
    echo.
    echo %YELLOW%NOTA: Asegúrate de que settings.py use la configuración correcta:%NC%
    echo.
    echo DATABASES = {
    echo     'default': {
    echo         'ENGINE': 'django.db.backends.mysql',
    echo         'NAME': os.getenv('DB_NAME'^),
    echo         'USER': os.getenv('DB_USER'^),
    echo         'PASSWORD': os.getenv('DB_PASSWORD'^),
    echo         'HOST': os.getenv('DB_HOST'^),
    echo         'PORT': os.getenv('DB_PORT'^),
    echo         'OPTIONS': {
    echo             'charset': 'utf8mb4',
    echo             'init_command': "SET sql_mode='STRICT_TRANS_TABLES'"
    echo         }
    echo     }
    echo }
    echo.
    pause
    exit /b 1
)

echo.
echo Recolectando archivos estáticos...
python manage.py collectstatic --noinput >nul 2>&1
echo %GREEN%[OK] Archivos estáticos recolectados%NC%

echo.
echo %YELLOW%Ahora crearás el superusuario para acceder al sistema%NC%
echo.
python manage.py createsuperuser

echo.

REM ============================================================
REM CREAR SCRIPTS AUXILIARES
REM ============================================================

echo %BLUE%Creando scripts auxiliares...%NC%

REM Script para iniciar servidor de desarrollo
(
echo @echo off
echo cd /d "%PROJECT_DIR%"
echo call venv\Scripts\activate.bat
echo python manage.py runserver
echo pause
) > "%BASE_DIR%\iniciar_desarrollo.bat"

REM Script para backup
(
echo @echo off
echo SET BACKUP_DIR=%BACKUPS_DIR%
echo SET TIMESTAMP=%%DATE:~-4%%%%DATE:~3,2%%%%DATE:~0,2%%_%%TIME:~0,2%%%%TIME:~3,2%%
echo SET TIMESTAMP=%%TIMESTAMP: =0%%
echo.
echo mysqldump -u %DB_USER% -p%DB_PASSWORD% %DB_NAME% ^> "%%BACKUP_DIR%%\db_%%TIMESTAMP%%.sql"
echo echo Backup completado: %%TIMESTAMP%%
echo pause
) > "%BASE_DIR%\crear_backup.bat"

REM Script de inicio para producción
(
echo @echo off
echo cd /d "%PROJECT_DIR%"
echo call venv\Scripts\activate.bat
echo pip install waitress
echo python -c "from waitress import serve; from config.wsgi import application; serve(application, host='0.0.0.0', port=80, threads=4)"
) > "%BASE_DIR%\iniciar_produccion.bat"

REM Script para restaurar backup
(
echo @echo off
echo SET BACKUP_DIR=%BACKUPS_DIR%
echo echo.
echo echo Archivos de backup disponibles:
echo dir /b "%%BACKUP_DIR%%\*.sql"
echo echo.
echo SET /P BACKUP_FILE=Ingresa el nombre del archivo a restaurar: 
echo.
echo mysql -u %DB_USER% -p%DB_PASSWORD% %DB_NAME% ^< "%%BACKUP_DIR%%\%%BACKUP_FILE%%"
echo echo Restauración completada
echo pause
) > "%BASE_DIR%\restaurar_backup.bat"

echo %GREEN%[OK] Scripts auxiliares creados%NC%
echo.

REM ============================================================
REM CONFIGURAR FIREWALL
REM ============================================================

echo %BLUE%Configurando Firewall de Windows...%NC%

powershell -Command "New-NetFirewallRule -DisplayName 'Django-Dev-8000' -Direction Inbound -LocalPort 8000 -Protocol TCP -Action Allow" >nul 2>&1
powershell -Command "New-NetFirewallRule -DisplayName 'HTTP-80' -Direction Inbound -LocalPort 80 -Protocol TCP -Action Allow" >nul 2>&1
powershell -Command "New-NetFirewallRule -DisplayName 'MySQL-3306' -Direction Inbound -LocalPort 3306 -Protocol TCP -Action Allow" >nul 2>&1

echo %GREEN%[OK] Reglas de firewall configuradas%NC%
echo.

REM ============================================================
REM RESUMEN FINAL
REM ============================================================

echo.
echo %GREEN%============================================================%NC%
echo %GREEN%   INSTALACION COMPLETADA EXITOSAMENTE%NC%
echo %GREEN%============================================================%NC%
echo.
echo %BLUE%Ubicación del proyecto:%NC% %PROJECT_DIR%
echo %BLUE%Logs:%NC% %LOGS_DIR%
echo %BLUE%Backups:%NC% %BACKUPS_DIR%
echo.
echo %YELLOW%Scripts disponibles:%NC%
echo   - %BASE_DIR%\iniciar_desarrollo.bat  (Modo desarrollo)
echo   - %BASE_DIR%\iniciar_produccion.bat  (Modo producción)
echo   - %BASE_DIR%\crear_backup.bat        (Backup manual)
echo   - %BASE_DIR%\restaurar_backup.bat    (Restaurar backup)
echo.
echo %YELLOW%Para iniciar el servidor:%NC%
echo   1. Ejecuta: %BASE_DIR%\iniciar_desarrollo.bat
echo   2. Abre tu navegador en: http://localhost:8000
echo   3. Panel admin: http://localhost:8000/admin
echo.
echo %YELLOW%Próximos pasos:%NC%
echo   - Verifica la configuración en %PROJECT_DIR%\.env
echo   - Revisa settings.py para ajustes adicionales
echo   - Configura el backup automático en Programador de tareas
echo.
echo %YELLOW%IMPORTANTE - Configuración de settings.py para MySQL:%NC%
echo.
echo Asegúrate de que tu settings.py tenga esta configuración:
echo.
echo import os
echo from dotenv import load_dotenv
echo load_dotenv(^)
echo.
echo DATABASES = {
echo     'default': {
echo         'ENGINE': 'django.db.backends.mysql',
echo         'NAME': os.getenv('DB_NAME'^),
echo         'USER': os.getenv('DB_USER'^),
echo         'PASSWORD': os.getenv('DB_PASSWORD'^),
echo         'HOST': os.getenv('DB_HOST', 'localhost'^),
echo         'PORT': os.getenv('DB_PORT', '3306'^),
echo         'OPTIONS': {
echo             'charset': 'utf8mb4',
echo             'init_command': "SET sql_mode='STRICT_TRANS_TABLES'",
echo         }
echo     }
echo }
echo.
echo %GREEN%¡Listo para usar!%NC%
echo.

pause

REM Preguntar si desea iniciar el servidor
SET /P "START_SERVER=¿Deseas iniciar el servidor de desarrollo ahora? (S/N): "
if /i "%START_SERVER%"=="S" (
    start cmd /k "%BASE_DIR%\iniciar_desarrollo.bat"
)

ENDLOCAL
exit /b 0