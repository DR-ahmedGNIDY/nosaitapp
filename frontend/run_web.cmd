@echo off
cd /d "%~dp0"
flutter run -d web-server --web-port 5959 --web-hostname 0.0.0.0
