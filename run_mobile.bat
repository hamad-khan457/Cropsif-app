@echo off
:: run_mobile.bat — auto-detect IP and run Flutter
:: Usage: run_mobile.bat              (debug)
::        run_mobile.bat --release    (release)

powershell -ExecutionPolicy Bypass -File "%~dp0run_mobile.ps1" %*
