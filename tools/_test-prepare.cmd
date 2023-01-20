@echo off
REM SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com)
REM SPDX-FileContributor: Sebastian Thomschke, Vegard IT GmbH
REM SPDX-License-Identifier: Apache-2.0

pushd .

REM cd into project root
cd %~dp0..

if not defined TEST_SSH_HOST        ( set TEST_SSH_HOST=127.0.0.1 )
if not defined TEST_SSH_PORT        ( set TEST_SSH_PORT=2222 )
if not defined TEST_SSH_USER        ( set TEST_SSH_USER=testuser )
if not defined TEST_SSH_PW          ( set TEST_SSH_PW=MySuperPW123 )
if not defined TEST_SSH_PEMKEY_FILE ( set TEST_SSH_PEMKEY_FILE=test/id_key.txt )
if not defined TEST_SSH_PPKKEY_FILE ( set TEST_SSH_PPKKEY_FILE=test/id_key.ppk )
if not defined TEST_SSH_PUBKEY_FILE ( set TEST_SSH_PUBKEY_FILE=test/id_pub.txt )

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
