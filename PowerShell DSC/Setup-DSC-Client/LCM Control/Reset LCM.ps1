#Remove all mof files (pending,current,backup,MetaConfig.mof,caches,etc)
rm C:\windows\system32\Configuration\*.mof*
#Kill the LCM/DSC processes
gps wmi* | ? {$_.modules.ModuleName -like "*DSC*"} | stop-process -force
