@echo off
PowerShell -ExecutionPolicy Unrestricted -Command "irm https://raw.githubusercontent.com/Laezor/biorand-seed/refs/heads/main/biorand-seed.ps1 | iex" %*