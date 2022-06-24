:: USER VARIABLES ::
set old_password=not-real-password
set new_password=not-real-password
set rca_password=not-real-password
set jgl_password=not-real-password

:: SET WORKING DIRECTORY ::
c:
cd\scripts

:: KSP Sask Drive - Admin Cluster ::
call backupesxi 10.0.100.133 %old_password%
call backupesxi 10.0.100.147 %old_password%
call backupesxi 10.0.100.167 %old_password%

:: KSP Sask Drive - Production Cluster ::
call backupesxi 10.252.4.21 %new_password%
call backupesxi 10.252.4.22 %new_password%
call backupesxi 10.252.4.23 %new_password%
call backupesxi 10.252.4.24 %new_password%
call backupesxi 10.252.4.25 %new_password%
call backupesxi 10.252.4.26 %old_password%
call backupesxi 10.252.4.27 %old_password%
call backupesxi 10.252.4.28 %old_password%
call backupesxi 10.252.4.29 %old_password%
call backupesxi 10.252.4.30 %old_password%
call backupesxi 10.252.4.31 %old_password%
call backupesxi 10.252.4.32 %old_password%
call backupesxi 10.252.4.33 %old_password%
call backupesxi 10.252.4.34 %old_password%
call backupesxi 10.252.4.35 %old_password%
call backupesxi 10.252.4.36 %old_password%
call backupesxi 10.252.4.37 %old_password%
call backupesxi 10.252.4.38 %old_password%
call backupesxi 10.252.4.39 %old_password%
call backupesxi 10.252.4.40 %old_password%
call backupesxi 10.252.4.41 %new_password%
call backupesxi 10.252.4.42 %new_password%
call backupesxi 10.252.4.43 %new_password%

:: KSP MWC - DR Site ::
call backupesxi 10.10.168.7 %old_password%

:: KSP Toronto - Priority Colo ::
call backupesxi 204.11.51.78 %old_password%
call backupesxi 204.11.51.80 %old_password%
call backupesxi 204.11.51.82 %old_password%

:: Cornerstone PA ::
call backupesxi 10.10.146.7 %old_password%

:: S3 Enterprises Swift Current ::
call backupesxi_new_pw 10.10.100.41
call backupesxi_new_pw 10.10.100.43
call backupesxi_new_pw 10.10.100.45
call backupesxi_new_pw 10.10.100.47

:: Motor Safety ::
call backupesxi 10.10.6.7 %old_password%

:: Industrial Scale ::
call backupesxi 10.10.14.7 %old_password%

:: Carmichael Outreach ::
call backupesxi 10.10.16.7 %old_password%

:: Gilroy Homes ::
call backupesxi 10.10.39.7 %old_password%

:: Pharos ::
call backupesxi 10.10.63.7 %old_password%
call backupesxi 10.10.63.250 %old_password%

:: Lakeside Vision ::
call backupesxi 10.10.80.7 %old_password%

:: Estevan Medical Center ::
call backupesxi 10.10.98.7 %old_password%

:: Garratt Industries ::
call backupesxi 10.10.165.7 %old_password%

:: MWC ::
call backupesxi 10.10.118.7 %old_password%

:: RCA ::
call backupesxi 192.168.200.7 %rca_password%

:: JGL Boharm ::
:: 10.20.4.11-13 but needs a different password
call backupesxi 10.20.4.11 %jgl_password%
call backupesxi 10.20.4.12 %jgl_password%
call backupesxi 10.20.4.13 %jgl_password%

:: BPCC ::
call backupesxi 10.30.4.11 %jgl_password%
call backupesxi 10.30.4.12 %jgl_password%
call backupesxi 10.30.4.13 %jgl_password%
