@echo off
cd /d "%~dp0"
set PORT=8777
echo.
echo  Studio Tri  ·  Indoor Triathlon
echo  --------------------------------
echo  Dieser PC:     http://127.0.0.1:%PORT%/
for /f "tokens=2 delims=:" %%A in ('ipconfig ^| findstr /c:"IPv4"') do (
  for /f "tokens=1" %%B in ("%%A") do echo  Handy / WLAN:  http://%%B:%PORT%/
)
echo.
echo  Wichtig: Nicht die HTML-Datei doppelklicken.
echo  Nur http://127.0.0.1 oder die WLAN-Adresse aktiviert
echo  Display-an, Offline, Teilen und Installation.
echo.
echo  Handy: Adresse in Chrome oder Safari oeffnen.
echo  Android: Installieren / Zum Startbildschirm.
echo  iPhone:  Teilen - Zum Home-Bildschirm.
echo.
echo  Dieses Fenster offen lassen, solange trainiert wird.
echo.
start "" "http://127.0.0.1:%PORT%/"
if exist "%LocalAppData%\Programs\Python\Python313\python.exe" (
  "%LocalAppData%\Programs\Python\Python313\python.exe" -m http.server %PORT% --bind 0.0.0.0
) else (
  py -m http.server %PORT% --bind 0.0.0.0
)
