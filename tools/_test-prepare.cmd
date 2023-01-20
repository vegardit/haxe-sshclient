@echo off
REM SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com)
REM SPDX-FileContributor: Sebastian Thomschke, Vegard IT GmbH
REM SPDX-License-Identifier: Apache-2.0

pushd .

REM cd into project root
cd %~dp0..

set TEST_SSH_HOST=%DOCKER_HOSTNAME%
set TEST_SSH_USER=testuser
set TEST_SSH_PORT=2222
set TEST_SSH_PW=MySuperPW123
set TEST_SSH_KEY_FILE=test/id_key.txt
set TEST_SSH_KEY_PPK=test/id_key.ppk

if exist dump\%1 (
   echo Cleaning [dump\%1]...
   rd /s /q dump\%1
)
if exist target\%1 (
   echo Cleaning [target\%1]...
   rd /s /q target\%1
)
shift

REM install common libs
echo Checking required haxelibs...
for %%i in (haxe-doctest) do (
   haxelib list | findstr %%i >NUL
   if errorlevel 1 (
      echo Installing [%%i]...
      haxelib install %%i
   )
)

goto :eof

REM install additional libs
:iterate

   if "%~1"=="" goto :eof

   haxelib list | findstr %1 >NUL
   if errorlevel 1 (
      echo Installing [%1]...
      haxelib install %1
   )

   shift
   goto iterate