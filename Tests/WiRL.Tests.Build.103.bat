@ECHO OFF

:: Delphi 10.3 Rio
@SET BDS=C:\Program Files (x86)\Embarcadero\Studio\20.0
@SET BDSINCLUDE=%BDS%\include
@SET BDSCOMMONDIR=C:\Users\Public\Documents\Embarcadero\Studio\20.0
@SET FrameworkDir=C:\Windows\Microsoft.NET\Framework\v4.0.30319
@SET FrameworkVersion=v4.5
@SET FrameworkSDKDir=
@SET PATH=%FrameworkDir%;%FrameworkSDKDir%;%BDS%\bin;%BDS%\bin64;%PATH%
@SET LANGDIR=EN
@SET PLATFORM=
@SET PlatformSDK=
::::::::::::::::::::::::::::::::

call WiRL.Tests.Build.Common.bat
