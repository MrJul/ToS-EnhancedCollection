@echo off
rmdir /s /q release
mkdir release
cd release
mkdir enhancedcollection
copy ..\enhancedcollection.lua enhancedcollection\enhancedcollection.lua
copy ..\README.md enhancedcollection\README.md
"%programfiles%\7-Zip\7z.exe" a -tzip EnhancedCollection-v1.0.zip enhancedcollection