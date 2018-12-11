@echo off
set xv_path=C:\\Xilinx\\Vivado\\2017.2\\bin
call %xv_path%/xelab  -wto 2fe8c54348764623925075d1a84493c8 -m64 --debug typical --relax --mt 2 -L xil_defaultlib -L secureip --snapshot bouncing_box_behav xil_defaultlib.bouncing_box -log elaborate.log
if "%errorlevel%"=="0" goto SUCCESS
if "%errorlevel%"=="1" goto END
:END
exit 1
:SUCCESS
exit 0
