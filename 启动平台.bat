@echo off
title Club Platform
echo Starting backend and frontend...
start "backend-8000" cmd /k "cd /d %~dp0backend && D:\Anaconda\python.exe -m uvicorn app.main:app --port 8000"
start "frontend-5173" cmd /k "cd /d %~dp0frontend && D:\ÐÂÃ½¾ºÈü\npm.cmd run dev"
timeout /t 8 >nul
start http://localhost:5173
exit
