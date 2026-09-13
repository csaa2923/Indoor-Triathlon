@echo off
cd /d "%~dp0"
set PORT=8777
echo.
echo Studio Tri
echo ----------
echo Dieser PC:   http://127.0.0.1:%PORT%/
for /f "tokens=2 delims=:" %%A in ('ipconfig ^| findstr /c:"IPv4"') do (
  for /f "tokens=1" %%B in ("%%A") do echo Handy/WLAN: http://%%B:%PORT%/
)
echo.
echo Fenster offen lassen. Auf dem Handy die WLAN-Adresse oeffnen,
echo dann Teilen / Installieren / Zum Home-Bildschirm.
echo.
start "" "http://127.0.0.1:%PORT%/"
if exist "%LocalAppData%\Programs\Python\Python313\python.exe" (
  "%LocalAppData%\Programs\Python\Python313\python.exe" -m http.server %PORT% --bind 0.0.0.0
) else (
  py -m http.server %PORT% --bind 0.0.0.0
)
