REM clean up sources
rmdir /S /Q .\modules\cbflib\pycbf2
del /S /Q .\modules\cbflib\pycbf\pycbf_test1.py
del /S /Q .\modules\cbflib\pycbf\pycbf_test4.py
call futurize -f libfuturize.fixes.fix_print_with_import -wn .\modules\cbflib
call futurize -f lib2to3.fixes.fix_except -wn .\modules\cbflib

REM copy bootstrap.py
copy modules\cctbx_project\libtbx\auto_build\bootstrap.py .
if %errorlevel% neq 0 exit /b %errorlevel%

REM remove extra source code
rmdir /S /Q .\modules\boost
rmdir /S /Q .\modules\eigen
rmdir /S /Q .\modules\scons

REM remove some libtbx_refresh.py files
del /S /Q .\modules\dials\libtbx_refresh.py
del /S /Q .\modules\dxtbx\libtbx_refresh.py
del /S /Q .\modules\iota\libtbx_refresh.py
del /S /Q .\modules\xia2\libtbx_refresh.py

REM build
%PYTHON% bootstrap.py build ^
  --builder=xfel ^
  --use-conda %PREFIX% ^
  --nproc %CPU_COUNT% ^
  --config-flags="--no_bin_python" ^
  --config-flags="--skip_phenix_dispatchers"
if %errorlevel% neq 0 exit /b %errorlevel%
@REM cd build
@REM call .\bin\libtbx.configure cma_es crys3d fable rstbx spotinder
@REM if %errorlevel% neq 0 exit /b %errorlevel%
@REM call .\bin\libtbx.scons -j %CPU_COUNT%
@REM if %errorlevel% neq 0 exit /b %errorlevel%
@REM call .\bin\libtbx.scons -j %CPU_COUNT%
@REM if %errorlevel% neq 0 exit /b %errorlevel%
@REM cd ..

REM remove intermediate objects in build directory
cd build
del /S /Q *.obj
cd ..

REM copy files in build
SET EXTRA_CCTBX_DIR=%LIBRARY_PREFIX%\share\cctbx
mkdir  %EXTRA_CCTBX_DIR%
SET CCTBX_CONDA_BUILD=.\modules\cctbx_project\libtbx\auto_build\conda_build
call .\build\bin\libtbx.python %CCTBX_CONDA_BUILD%\install_build.py --prefix %LIBRARY_PREFIX% --sp-dir %SP_DIR% --ext-dir %PREFIX%\lib --preserve-egg-dir
if %errorlevel% neq 0 exit /b %errorlevel%

REM copy gui_resources
xcopy /E /I .\modules\gui_resources %SP_DIR%\gui_resources

REM copy dxtbx_flumpy separately since it does not end it *_ext.so
copy .\build\lib\dxtbx_flumpy.* %PREFIX%\Lib\
del /S /Q %LIBRARY_PREFIX%\dxtbx_flumpy.*

REM copy version and copyright files
%PYTHON% .\modules\cctbx_project\libtbx\version.py --version=%PKG_VERSION%
if %errorlevel% neq 0 exit /b %errorlevel%
copy .\modules\cctbx_project\COPYRIGHT.txt %EXTRA_CCTBX_DIR%
copy .\modules\cctbx_project\cctbx_version.txt %EXTRA_CCTBX_DIR%
copy .\modules\cctbx_project\cctbx_version.h %LIBRARY_INC%\cctbx
cd .\modules\cctbx_project
%PYTHON% setup.py install
if %errorlevel% neq 0 exit /b %errorlevel%
cd ..\..

REM copy libtbx_env and update dispatchers
echo Copying libtbx_env
call .\build\bin\libtbx.python %CCTBX_CONDA_BUILD%\update_libtbx_env.py
if %errorlevel% neq 0 exit /b %errorlevel%
%PYTHON% %CCTBX_CONDA_BUILD%\update_libtbx_env.py
if %errorlevel% neq 0 exit /b %errorlevel%

REM remove extra copies of dispatchers
attrib +H %LIBRARY_BIN%\libtbx.show_build_path.bat
attrib +H %LIBRARY_BIN%\libtbx.show_dist_paths.bat
del /Q %LIBRARY_BIN%\*show_build_path.bat
del /Q %LIBRARY_BIN%\*show_dist_paths.bat
attrib -H %LIBRARY_BIN%\libtbx.show_build_path.bat
attrib -H %LIBRARY_BIN%\libtbx.show_dist_paths.bat

REM install dxtbx, dials, iota, and xia2
rmdir /S /Q %SP_DIR%\dxtbx
del /S /Q %LIBRARY_PREFIX%\bin\cxi.*
del /S /Q %LIBRARY_PREFIX%\bin\dev.dxtbx.*
del /S /Q %LIBRARY_PREFIX%\bin\dxtbx.*
cd .\modules\dxtbx
%PYTHON% -m pip install . -vv --no-deps
if %errorlevel% neq 0 exit /b %errorlevel%

rmdir /S /Q %SP_DIR%\dials
del /S /Q %LIBRARY_PREFIX%\bin\cluster.dials.*
del /S /Q %LIBRARY_PREFIX%\bin\dev.dials.*
del /S /Q %LIBRARY_PREFIX%\bin\dials.*
cd ..\dials
%PYTHON% -m pip install . -vv --no-deps
if %errorlevel% neq 0 exit /b %errorlevel%

rmdir /S /Q %SP_DIR%\iota
del /S /Q %LIBRARY_PREFIX%\bin\iota.*
cd ..\iota
%PYTHON% -m pip install . -vv --no-deps
if %errorlevel% neq 0 exit /b %errorlevel%

rmdir /S /Q %SP_DIR%\xia2
del /S /Q %LIBRARY_PREFIX%\bin\dev.xia2.*
del /S /Q %LIBRARY_PREFIX%\bin\xia2.*
cd ..\xia2
%PYTHON% -m pip install . -vv --no-deps
if %errorlevel% neq 0 exit /b %errorlevel%
