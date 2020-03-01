@rem Initialization
@cd "%~dp0"
@cd ..\..\..\
@for %%a in ("%cd%") do @set devroot=%%~sa
@set projectname=swiftshader-dist-win
@IF /I %1==collectuids GOTO collectuids
@IF /I NOT %1==collectuids GOTO runci

:collectuids
@rem Collect build sources unique identifiers and push them to CI YAML configuration
@cd %devroot%\%projectname:~0,-9%
@FOR /F "tokens=*" %%a IN ('git rev-parse HEAD') do @set srcswiftshader=%%a
@cd %devroot%\%projectname%
@FOR /F "tokens=*" %%a IN ('git rev-parse HEAD') do @set distswiftshader=%%a
@call %devroot%\%projectname%\buildscript\ci\pushvar.cmd srcswiftshader
@call %devroot%\%projectname%\buildscript\ci\pushvar.cmd distswiftshader
@GOTO doneci

:runci
@rem Check if build is necessary first
@IF NOT EXIST %devroot%\%projectname%\buildscript\ci\assets md %devroot%\%projectname%\buildscript\ci\assets
@echo 1>%devroot%\%projectname%\buildscript\ci\assets\gotuids.ini
@IF EXIST %devroot%\%projectname%\buildscript\ci\assets\gotuids.ini IF EXIST %devroot%\%projectname%\buildscript\ci\assets-old\gotuids.ini GOTO skipci

@rem Generating version UID and artifact timestamp, push artifact timestamp to CI YAML configuration
@IF NOT EXIST %devroot%\%projectname%\dist md %devroot%\%projectname%\dist
@IF NOT EXIST %devroot%\%projectname%\dist\modules md %devroot%\%projectname%\dist\modules
@FOR /F "tokens=* USEBACKQ" %%a IN (`powershell -Command "Get-Date -Format FileDateTimeUniversal"`) do @set artifactuid=%%a
@set artifactver=%artifactuid%
@set artifactuid=%artifactuid:~0,4%-%artifactuid:~4,2%-%artifactuid:~6,2%_%artifactuid:~9,2%-%artifactuid:~11,2%
@set artifactver=%artifactver:~0,8%%artifactver:~9,4%
@echo @set artifactver=%artifactver%>%devroot%\%projectname%\dist\modules\config.cmd
@echo @set reactorbackend=%1>>%devroot%\%projectname%\dist\modules\config.cmd
@call %devroot%\%projectname%\buildscript\ci\pushvar.cmd artifactuid

@rem Write build unique identifiers to a HTML document with links to those commits
@IF NOT EXIST %devroot%\%projectname%\dist\buildinfo md %devroot%\%projectname%\dist\buildinfo
@echo ^<html^>>%devroot%\%projectname%\dist\buildinfo\sources-unique-identifiers.html
@echo ^<head^>>>%devroot%\%projectname%\dist\buildinfo\sources-unique-identifiers.html
@echo ^<title^>Sources unique identifiers^</title^>>>%devroot%\%projectname%\dist\buildinfo\sources-unique-identifiers.html
@echo ^</head^>>>%devroot%\%projectname%\dist\buildinfo\sources-unique-identifiers.html
@echo ^<body^>>>%devroot%\%projectname%\dist\buildinfo\sources-unique-identifiers.html
@echo Swiftshaader was built using the folowing code sources^<br^>>>%devroot%\%projectname%\dist\buildinfo\sources-unique-identifiers.html
@echo ^<table^>>>%devroot%\%projectname%\dist\buildinfo\sources-unique-identifiers.html
@echo ^<tr^>>>%devroot%\%projectname%\dist\buildinfo\sources-unique-identifiers.html
@echo ^<th^>Description^</th^>>>%devroot%\%projectname%\dist\buildinfo\sources-unique-identifiers.html
@echo ^<th^>Contents^</th^>>>%devroot%\%projectname%\dist\buildinfo\sources-unique-identifiers.html
@echo ^</tr^>>>%devroot%\%projectname%\dist\buildinfo\sources-unique-identifiers.html
@echo ^<tr^>>>%devroot%\%projectname%\dist\buildinfo\sources-unique-identifiers.html
@echo ^<td^>Google swiftshader source code^</td^>>>%devroot%\%projectname%\dist\buildinfo\sources-unique-identifiers.html
@echo ^<td^>^<a href='https://github.com/google/swiftshader/tree/%srcswiftshader%'^>%srcswiftshader%^</a^>^</td^>>>%devroot%\%projectname%\dist\buildinfo\sources-unique-identifiers.html
@echo ^</tr^>>>%devroot%\%projectname%\dist\buildinfo\sources-unique-identifiers.html
@echo ^<tr^>>>%devroot%\%projectname%\dist\buildinfo\sources-unique-identifiers.html
@echo ^<td^>Build, continous integration and usage utility source code^</td^>>>%devroot%\%projectname%\dist\buildinfo\sources-unique-identifiers.html
@echo ^<td^>^<a href='https://github.com/pal1000/swiftshader-dist-win/tree/%distswiftshader%'^>%distswiftshader%^</a^>^</td^>>>%devroot%\%projectname%\dist\buildinfo\sources-unique-identifiers.html
@echo ^</tr^>>>%devroot%\%projectname%\dist\buildinfo\sources-unique-identifiers.html
@echo ^</table^>>>%devroot%\%projectname%\dist\buildinfo\sources-unique-identifiers.html
@echo ^</body^>>>%devroot%\%projectname%\dist\buildinfo\sources-unique-identifiers.html
@echo ^</html^>>>%devroot%\%projectname%\dist\buildinfo\sources-unique-identifiers.html

@rem Run build
@call %devroot%\%projectname%\buildscript\build.cmd x64-%1
@cd %devroot%\%projectname%\dist
@IF EXIST x64\bin\vk_swiftshader_icd.json IF EXIST x64\bin\libEGL.dll IF EXIST x64\bin\vk_swiftshader.dll call %devroot%\%projectname%\buildscript\build.cmd x86-%1
@cd %devroot%\%projectname%\dist
@IF EXIST x64\bin\vk_swiftshader_icd.json IF EXIST x64\bin\libEGL.dll IF EXIST x64\bin\vk_swiftshader.dll IF EXIST x86\bin\vk_swiftshader_icd.json IF EXIST x86\bin\libEGL.dll IF EXIST x86\bin\vk_swiftshader.dll 7z a -t7z -mx=9 ..\swiftshader-%artifactuid%-%1.7z .\*
@IF NOT EXIST %devroot%\%projectname%\swiftshader-%artifactuid%-%1.7z GOTO doneci

@rem Prepare cache if we have build artifact
@IF EXIST %devroot%\%projectname%\buildscript\ci\assets-old RD /S /Q %devroot%\%projectname%\buildscript\ci\assets-old
@IF EXIST %devroot%\%projectname%\buildscript\ci\assets REN %devroot%\%projectname%\buildscript\ci\assets assets-old
@GOTO doneci

:skipci
@echo -------------------
@echo Build is up-to-date.

:doneci
@cd %devroot%