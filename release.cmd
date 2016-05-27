@echo off
rmdir /s /q release
mkdir release\temp\addon_d.ipf\enhancedcollection
copy enhancedcollection.lua release\temp\addon_d.ipf\enhancedcollection\enhancedcollection.lua
copy enhancedcollection.xml release\temp\addon_d.ipf\enhancedcollection\enhancedcollection.xml
python buildtools\ipf.py -c -f release\enhancedcollection.ipf release\temp
buildtools\ipf_unpack.exe release\enhancedcollection.ipf encrypt
