@echo off
set /p ui_file="drag .ui file here"
pyuic5 %ui_file% > %ui_file:.ui=.py%
pause
