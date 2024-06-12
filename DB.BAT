@echo off
setbus 8 >nul
td -p- %1 %2 %3 %4 %5 %6 %7 %8 %9
setbus 16 >nul
rstclk
