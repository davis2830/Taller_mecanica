# 1. Borrar la base de datos SQLite (si existe)
if (Test-Path "db.sqlite3") {
    Remove-Item "db.sqlite3"
    Write-Host "✅ Base de datos db.sqlite3 eliminada." -ForegroundColor Cyan
}

# 2. Borrar todos los archivos de migración excepto los __init__.py
# Busca en todas las subcarpetas del proyecto
Get-ChildItem -Path . -Include *.pyc -Recurse | Remove-Item
Get-ChildItem -Path . -Filter "migrations" -Recurse | ForEach-Object {
    $path = $_.FullName
    Get-ChildItem -Path $path -Exclude "__init__.py" -Filter "*.py" | Remove-Item
    Write-Host "✅ Migraciones limpiadas en: $path" -ForegroundColor Cyan
}

# 3. Ejecutar nuevos comandos de Django
Write-Host "🚀 Generando nuevas migraciones..." -ForegroundColor Yellow
python manage.py makemigrations

Write-Host "💾 Aplicando migraciones..." -ForegroundColor Yellow
python manage.py migrate

Write-Host "✨ ¡Proceso terminado! Tu base de datos está limpia." -ForegroundColor Green