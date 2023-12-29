:: This script is used for flashing i.MX android images whit fastboot.

@echo off

::---------------------------------------------------------------------------------
::Variables
::---------------------------------------------------------------------------------

:: For batch script, %0 is not script name in a so-called function, so save the script name here
set script_first_argument=%0
:: For users execute this script in powershell, clear the quation marks first.
set script_first_argument=%script_first_argument:"=%
:: reserve last 25 characters, which is the lenght of the name of this script file.
set script_name=%script_first_argument:~-25%

set soc_name=
set uboot_feature=
set dtb_feature=
set /A card_size=0
set slot=
set bootimage=boot.img
set systemimage_file=system.img
set system_extimage_file=system_ext.img
set vendor_file=vendor.img
set product_file=product.img
set partition_file=partition-table.img
set super_file=super.img
set vendorboot_file=vendor_boot.img
set initboot_file=init_boot.img
set /A support_dtbo=0
set /A support_recovery=0
set /A support_dualslot=0
set /A support_mcu_os=0
set /A support_dual_bootloader=0
set /A support_dynamic_partition=0
set /A support_vendor_boot=0
set /A support_init_boot=0
set dual_bootloader_partition=
set bootloader_flashed_to_board=
set uboot_proper_to_be_flashed=
set bootloader_partition=bootloader
set boot_partition=boot
set recovery_partition=recovery
set system_partition=system
set system_ext_partition=system_ext
set vendor_partition=vendor
set product_partition=product
set vbmeta_partition=vbmeta
set dtbo_partition=dtbo
set mcu_os_partition=mcu_os
set super_partition=super
set vendor_boot_partition=vendor_boot
set init_boot_partition=init_boot
set /A flash_mcu=0
set /A statisc=0
set /A lock=0
set /A erase=0
set /A has_system_ext_partition=0
set image_directory=
set ser_num=
set fastboot_tool=fastboot
set /A error_level=0
set /A flag=1


:: We want to detect illegal feature input to some extent. Here it's based on SoC names. Since an SoC may be on a
:: board running different set of images(android and automative for a example), so misuse the features of one set of
:: images when flash another set of images can not be detect early with this scenario.
set imx8mm_uboot_feature=dual trusty-dual 4g-evk-uuu 4g ddr4-evk-uuu ddr4 evk-uuu trusty-secure-unlock-dual
set imx8mn_uboot_feature=dual trusty-dual evk-uuu trusty-secure-unlock-dual ddr4-evk-uuu ddr4
set imx8mp_uboot_feature=dual trusty-dual evk-uuu trusty-secure-unlock-dual powersave trusty-powersave-dual
set imx8ulp_uboot_feature=dual trusty-dual trusty-dualboot-dual evk-uuu trusty-secure-unlock-dual 9x9-evk-uuu 9x9 9x9-dual trusty-9x9-dual trusty-lpa-dual
set imx8mq_uboot_feature=dual trusty-dual evk-uuu trusty-secure-unlock-dual wevk wevk-dual trusty-wevk-dual wevk-uuu trusty-secure-unlock-wevk-dual
set imx8qxp_uboot_feature=dual trusty-dual mek-uuu trusty-secure-unlock-dual secure-unlock c0 c0-dual trusty-c0-dual mek-c0-uuu
set imx8qm_uboot_feature=dual trusty-dual mek-uuu trusty-secure-unlock-dual secure-unlock md hdmi xen
set imx93_uboot_feature=dual trusty-dual evk-uuu
set imx7ulp_uboot_feature=evk-uuu

set imx8mm_dtb_feature=ddr4 m4 mipi-panel mipi-panel-rm67191 8mic
set imx8mn_dtb_feature=mipi-panel mipi-panel-rm67191 rpmsg ddr4 ddr4-mipi-panel ddr4-mipi-panel-rm67191 ddr4-rpmsg 8mic
set imx8mp_dtb_feature=rpmsg lvds-panel lvds mipi-panel mipi-panel-rm67191 basler powersave powersave-non-rpmsg basler-ov5640 ov5640 dual-basler os08a20-ov5640 os08a20 sof revb4 rpmsg-revb4 lvds-panel-revb4 lvds-revb4 mipi-panel-revb4 mipi-panel-rm67191-revb4 basler-revb4 powersave-revb4 powersave-non-rpmsg-revb4 basler-ov5640-revb4 ov5640-revb4 sof-revb4 dual-basler-revb4 os08a20-ov5640-revb4 os08a20-revb4
set imx8mq_dtb_feature=wevk dual mipi-panel mipi-panel-rm67191 mipi
set imx8qxp_dtb_feature=sof mipi-panel mipi-panel-rm67191 lvds0-panel
set imx8qm_dtb_feature=hdmi hdmi-rx mipi-panel mipi-panel-rm67191 md xen esai sof lvds1-panel
set imx8ulp_dtb_feature=hdmi epdc 9x9 9x9-hdmi sof lpa lpd
set imx93_dtb_feature=
set imx7ulp_dtb_feature=evk-mipi evk mipi

:: an array to collect the supported soc_names
set supported_soc_names=imx8qm imx8qxp imx8mq imx8mm imx8mn imx7ulp imx8mp imx8ulp imx93



::---------------------------------------------------------------------------------
::Parse command line
::---------------------------------------------------------------------------------
:: If no option provied when executing this script, show help message and exit.
if [%1] == [] (
    echo please provide more information with command script options
    call :help
    set /A error_level=1 && goto :exit
)

:parse_loop
if [%1] == [] goto :parse_end
if %1 == -h call :help & goto :eof
if %1 == -f set soc_name=%2& shift & shift & goto :parse_loop
if %1 == -c set /A card_size=%2& shift & shift & goto :parse_loop
if %1 == -u set uboot_feature=-%2& shift & shift & goto :parse_loop
if %1 == -d set dtb_feature=%2& shift & shift & goto :parse_loop
if %1 == -a set slot=_a& shift & goto :parse_loop
if %1 == -b set slot=_b& shift & goto :parse_loop
if %1 == -m set /A flash_mcu=1 & shift & goto :parse_loop
if %1 == -l set /A lock=1 & shift & goto :parse_loop
if %1 == -e set /A erase=1 & shift & goto :parse_loop
if %1 == -D set image_directory=%2& shift & shift & goto :parse_loop
if %1 == -s set ser_num=%2&shift &shift & goto :parse_loop
echo %1 is an illegal option
call :help & goto :eof
:parse_end

:: check whether the soc_name is legal or not
if not [%soc_name%] == [] (
    setlocal enabledelayedexpansion
    call :whether_in_array soc_name supported_soc_names
    if !flag! neq 0 (
        echo illegal soc_name "%soc_name%"
        call :help
        set /A error_level=1 && goto :exit
    )
    endlocal
) else (
    echo use "-f" option to specify the soc name
    call :help
    set /A error_level=1 && goto :exit
)

:: avoid substring judgement error
set uboot_feature_test=A%uboot_feature%

:: Process of the uboot_feature parameter
if not [%uboot_feature_test:dual=%] == [%uboot_feature_test%] set /A support_dual_bootloader=1


:: If sdcard size is not correctly set, exit
if %card_size% neq 0 set /A statisc+=1
if %card_size% neq 7 set /A statisc+=1
if %card_size% neq 14 set /A statisc+=1
if %card_size% neq 28 set /A statisc+=1
if %statisc% == 4 echo card_size is not a legal value & goto :eof

:: Android Automative by default support dual bootloader, no "dual" in its partition table name
if [%support_dual_bootloader%] == [1] (
    if %card_size% gtr 0 (
        set partition_file=partition-table-%card_size%GB-dual.img
    ) else (
        set partition_file=partition-table-dual.img
    )
) else (
    if %card_size% gtr 0 (
        set partition_file=partition-table-%card_size%GB.img
    ) else (
        set partition_file=partition-table.img
    )
)


:: if directory is specified, and the last character is not backslash, add one backslash
if not [%image_directory%] == [] if not %image_directory:~-1% == \ (
    set image_directory=%image_directory%\
)

if not [%ser_num%] == [] set fastboot_tool=fastboot -s %ser_num%


:: check whether provided spl/bootloader/uboot feature is legal
set uboot_feature_no_pre_hyphen=%uboot_feature:~1%
if not [%uboot_feature%] == [] (
    setlocal enabledelayedexpansion
    call :whether_in_array uboot_feature_no_pre_hyphen %soc_name%_uboot_feature
    if !flag! neq 0 (
        echo illegal parameter "%uboot_feature_no_pre_hyphen%" for "-u" option
        call :help
        set /A error_level=1 && goto :exit
    )
    endlocal
)

:: check whether provided dtb feature is legal
if not [%dtb_feature%] == [] (
    setlocal enabledelayedexpansion
    call :whether_in_array dtb_feature %soc_name%_dtb_feature
    if !flag! neq 0 (
        echo illegal parameter "%dtb_feature%" for "-d" option
        call :help
        set /A error_level=1 && goto :exit
    )
    endlocal
)

::---------------------------------------------------------------------------------
:: Invoke function to flash android images
::---------------------------------------------------------------------------------
call :flash_android || set /A error_level=1 && goto :exit

if %erase% == 1 (
    if %support_dualslot% == 0 (
        %fastboot_tool% erase cache
    )
    %fastboot_tool% erase misc
    %fastboot_tool% erase metadata
    %fastboot_tool% oem erase_uboot_env
    %fastboot_tool% erase userdata
)
if %lock% == 1 %fastboot_tool% oem lock

if not [%slot%] == []  if %support_dualslot% == 1 (
    %fastboot_tool% set_active %slot:~-1%
)

echo #######ALL IMAGE FILES FLASHED#######


::---------------------------------------------------------------------------------
:: The execution will end.
::---------------------------------------------------------------------------------
goto :eof


::----------------------------------------------------------------------------------
:: Function definition
::----------------------------------------------------------------------------------

:help
echo Version: 1.6
echo Last change: update the parameters which can be followed with "-d" option
echo.
echo eg: fastboot_imx_flashall.bat -f imx8mm -a -D C:\Users\user_01\evk_8mm
echo.
echo Usage: %script_name% ^<option^>
echo.
echo options:
echo  -h                displays this help message
echo  -f soc_name       flash android image file with soc_name
echo  -a                only flash image to slot_a
echo  -b                only flash image to slot_b
echo  -c card_size      optional setting: 14 / 28
echo                        If not set, use partition-table.img/partition-table-dual.img (default)
echo                        If set to 14, use partition-table-14GB.img for 16GB SD card
echo                        If set to 28, use partition-table-28GB.img/partition-table-28GB-dual.img for 32GB SD card
echo                    Make sure the corresponding file exist for your platform
echo  -m                flash mcu image
echo  -u uboot_feature  flash uboot or spl&bootloader image with "uboot_feature" in their names
echo                        For Standard Android:
echo                            If the parameter after "-u" option contains the string of "dual", then spl&bootloader image will be flashed,
echo                            otherwise uboot image will be flashed
echo                        For Android Automative:
echo                            only dual bootloader feature is supported, by default spl&bootloader image will be flashed
echo                        Below table lists the legal value supported now based on the soc_name provided:
echo                           �����������������������������������Щ�������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������
echo                           ��   soc_name     ��  legal parameter after "-u"                                                                          ��
echo                           �����������������������������������੤������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������
echo                           ��   imx8mm       ��  dual trusty-dual 4g-evk-uuu 4g ddr4-evk-uuu ddr4 evk-uuu trusty-secure-unlock-dual                  ��
echo                           �����������������������������������੤������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������
echo                           ��   imx8mn       ��  dual trusty-dual evk-uuu trusty-secure-unlock-dual ddr4-evk-uuu ddr4                                ��
echo                           �����������������������������������੤������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������
echo                           ��   imx8mp       ��  dual trusty-dual evk-uuu trusty-secure-unlock-dual powersave trusty-powersave-dual                  ��
echo                           �����������������������������������੤������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������
echo                           ��   imx8ulp      ��  dual trusty-dual trusty-dualboot-dual evk-uuu trusty-secure-unlock-dual 9x9-evk-uuu 9x9 9x9-dual trusty-9x9-dual trusty-lpa-dual  ��
echo                           �����������������������������������੤������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������
echo                           ��   imx8mq       ��  dual trusty-dual evk-uuu trusty-secure-unlock-dual wevk wevk-dual                                   ��
echo                           ��                ��  trusty-wevk-dual wevk-uuu trusty-secure-unlock-wevk-dual                                            ��
echo                           �����������������������������������੤������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������
echo                           ��   imx8qxp      ��  dual trusty-dual mek-uuu trusty-secure-unlock-dual secure-unlock c0 c0-dual                         ��
echo                           ��                ��  trusty-c0-dual mek-c0-uuu                                                                           ��
echo                           �����������������������������������੤������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������
echo                           ��   imx8qm       ��  dual trusty-dual mek-uuu trusty-secure-unlock-dual secure-unlock md hdmi xen                        ��
echo                           �����������������������������������੤������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������
echo                           ��   imx93        ��  dual trusty-dual evk-uuu                                                                            ��
echo                           �����������������������������������੤������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������
echo                           ��   imx7ulp      ��  evk-uuu                                                                                             ��
echo                           �����������������������������������ة�������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������
echo
echo  -d dtb_feature    flash dtbo, vbmeta and recovery image file with "dtb_feature" in their names
echo                        If not set, default dtbo, vbmeta and recovery image will be flashed
echo                        Below table lists the legal value supported now based on the soc_name provided:
echo                           �����������������������������������Щ�������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������
echo                           ��   soc_name     ��  legal parameter after "-d"                                                                          ��
echo                           �����������������������������������੤������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������
echo                           ��   imx8mm       ��  ddr4 m4 mipi-panel mipi-panel-rm67191 8mic                                                          ��
echo                           �����������������������������������੤������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������
echo                           ��   imx8mn       ��  mipi-panel mipi-panel-rm67191 rpmsg ddr4 ddr4-mipi-panel ddr4-mipi-panel-rm67191 ddr4-rpmsg 8mic    ��
echo                           �����������������������������������੤������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������
echo                           ��   imx8mp       ��  rpmsg lvds-panel lvds mipi-panel mipi-panel-rm67191 basler powersave powersave-non-rpmsg            ��
echo                           ��                ��  basler-ov5640 ov5640 dual-basler os08a20-ov5640 os08a20 sof revb4 rpmsg-revb4 lvds-panel-revb4 lvds-revb4 ��
echo                           ��                ��  mipi-panel-revb4 mipi-panel-rm67191-revb4 basler-revb4 powersave-revb4 powersave-non-rpmsg-revb4    ��
echo                           ��                ��  basler-ov5640-revb4 ov5640.img-revb4 sof-revb4 dual-basler-revb4 os08a20-ov5640-revb4 os08a20-revb4 ��
echo                           �����������������������������������੤������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������
echo                           ��   imx8mq       ��  wevk dual mipi-panel mipi-panel-rm67191 mipi                                                        ��
echo                           �����������������������������������੤������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������
echo                           ��   imx8qxp      ��  sof mipi-panel mipi-panel-rm67191 lvds0-panel                                                       ��
echo                           �����������������������������������੤������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������
echo                           ��   imx8qm       ��  hdmi mipi-panel mipi-panel-rm67191 md xen esai sof lvds1-panel                                      ��
echo                           �����������������������������������੤������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������
echo                           ��   imx8ulp      ��  hdmi epdc 9x9 9x9-hdmi sof lpa lpd                                                                  ��
echo                           �����������������������������������੤������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������
echo                           ��   imx93        ��                                                                                                      ��
echo                           �����������������������������������੤������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������
echo                           ��   imx7ulp      ��  evk-mipi evk mipi                                                                                   ��
echo                           �����������������������������������ة�������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������
echo
echo  -e                erase user data after all image files being flashed
echo  -l                lock the device after all image files being flashed
echo  -D directory      the directory of of images
echo                        No need to use this option if images are in current working directory
echo  -s ser_num        the serial number of board
echo                        If only one board connected to computer, no need to use this option
goto :eof

:: this function checks whether the value of first parameter is in the array value of second parameter.
:: pass the name of the (array)variable to this function. the first is potential element, the second one is array,
:: a global flag is used to store the result. make sure the first parameter is not empty
:whether_in_array
for /F "tokens=*" %%F in ('echo %%%1%%') do (
set potential_element=%%F
)

for /F "tokens=*" %%F in ('echo %%%2%%') do (
set array_passed_in=%%F
)

(for %%a in (%array_passed_in%) do (
   if %%a == %potential_element% (
        set /A flag=0
        goto :eof
   )
))
set /A flag=1
goto :eof

:flash_partition
set partition_to_be_flashed=%1
:: if there is slot information, delete it.
set local_str=%1
set local_str=%local_str:_a=%
set local_str=%local_str:_b=%

set img_name=%local_str%-%soc_name%.img

if not [%partition_to_be_flashed:bootloader_=%] == [%partition_to_be_flashed%] (
    set img_name=%uboot_proper_to_be_flashed%
    goto :start_to_flash
)

if not [%partition_to_be_flashed:vendor_boot=%] == [%partition_to_be_flashed%] (
    set img_name=%vendorboot_file%
    goto :start_to_flash
)

if not [%partition_to_be_flashed:init_boot=%] == [%partition_to_be_flashed%] (
    set img_name=%initboot_file%
    goto :start_to_flash
)

if not [%partition_to_be_flashed:system_ext=%] == [%partition_to_be_flashed%] (
    set img_name=%system_extimage_file%
    goto :start_to_flash
)
if not [%partition_to_be_flashed:system=%] == [%partition_to_be_flashed%] (
    set img_name=%systemimage_file%
    goto :start_to_flash
)
if not [%partition_to_be_flashed:vendor=%] == [%partition_to_be_flashed%] (
    set img_name=%vendor_file%
    goto :start_to_flash
)
if not [%partition_to_be_flashed:product=%] == [%partition_to_be_flashed%] (
    set img_name=%product_file%
    goto :start_to_flash
)
if not [%partition_to_be_flashed:mcu_os=%] == [%partition_to_be_flashed%] (
    if [%soc_name%] == [imx7ulp] (
        set img_name=%soc_name%_m4_demo.img
    ) else (
        set img_name=%soc_name%_mcu_demo.img
    )
    goto :start_to_flash
)
if not [%partition_to_be_flashed:vbmeta=%] == [%partition_to_be_flashed%] if not [%dtb_feature%] == [] (
    set img_name=%local_str%-%soc_name%-%dtb_feature%.img
    goto :start_to_flash
)
if not [%partition_to_be_flashed:dtbo=%] == [%partition_to_be_flashed%] if not [%dtb_feature%] == [] (
    set img_name=%local_str%-%soc_name%-%dtb_feature%.img
    goto :start_to_flash
)
if not [%partition_to_be_flashed:recovery=%] == [%partition_to_be_flashed%] if not [%dtb_feature%] == [] (
    set img_name=%local_str%-%soc_name%-%dtb_feature%.img
    goto :start_to_flash
)
if not [%partition_to_be_flashed:bootloader=%] == [%partition_to_be_flashed%] (
    set img_name=%bootloader_flashed_to_board%
    goto :start_to_flash
)


if %support_dtbo% == 1 (
    if not [%partition_to_be_flashed:boot=%] == [%partition_to_be_flashed%] (
        set img_name=%bootimage%
        goto :start_to_flash
    )
)

if not [%partition_to_be_flashed:gpt=%] == [%partition_to_be_flashed%] (
    set img_name=%partition_file%
    goto :start_to_flash
)

if not [%partition_to_be_flashed:super=%] == [%partition_to_be_flashed%] (
    set img_name=%super_file%
    goto :start_to_flash
)

:start_to_flash
echo flash the file of %img_name% to the partition of %partition_to_be_flashed%
%fastboot_tool% flash %1 %image_directory%%img_name% || set /A error_level=1 && goto :exit
goto :eof


:flash_userpartitions
if %support_dtbo% == 1 call :flash_partition %dtbo_partition% || set /A error_level=1 && goto :exit
if %support_recovery% == 1 call :flash_partition %recovery_partition% || set /A error_level=1 && goto :exit
if %support_vendor_boot% == 1 call :flash_partition %vendor_boot_partition% || set /A error_level=1 && goto :exit
if %support_init_boot% == 1 call :flash_partition %init_boot_partition% || set /A error_level=1 && goto :exit
call :flash_partition %boot_partition% || set /A error_level=1 && goto :exit
if %support_dynamic_partition% == 0 (
    call :flash_partition %system_partition% || set /A error_level=1 && goto :exit
    if %has_system_ext_partition% == 1 (
        call :flash_partition %system_ext_partition% || set /A error_level=1 && goto :exit
    )
    call :flash_partition %vendor_partition% || set /A error_level=1 && goto :exit
    call :flash_partition %product_partition% || set /A error_level=1 && goto :exit
)
call :flash_partition %vbmeta_partition% || set /A error_level=1 && goto :exit
goto :eof


:flash_partition_name
set boot_partition=boot%1
set recovery_partition=recovery%1
set system_partition=system%1
set system_ext_partition=system_ext%1
set vendor_partition=vendor%1
set product_partition=product%1
set vbmeta_partition=vbmeta%1
set dtbo_partition=dtbo%1
set vendor_boot_partition=vendor_boot%1
set init_boot_partition=init_boot%1
goto :eof

:flash_android
call :flash_partition gpt || set /A error_level=1 && goto :exit

%fastboot_tool% getvar all 2> fastboot_var.log
find "bootloader_a" fastboot_var.log > nul && set /A support_dual_bootloader=1
find "dtbo" fastboot_var.log > nul && set /A support_dtbo=1

find "recovery" fastboot_var.log > nul && set /A support_recovery=1

::use boot_b to check whether current gpt support a/b slot
find "boot_b" fastboot_var.log > nul && set /A support_dualslot=1
find "super" fastboot_var.log > nul && set /A support_dynamic_partition=1
find "vendor_boot" fastboot_var.log > nul && set /A support_vendor_boot=1
find "init_boot" fastboot_var.log > nul && set /A support_init_boot=1
find "system_ext" fastboot_var.log > nul && set /A has_system_ext_partition=1
del fastboot_var.log

:: some partitions are hard-coded in uboot, flash the uboot first and then reboot to check these partitions

:: uboot or spl&bootloader
if %support_dual_bootloader% == 1 (
    set bootloader_flashed_to_board=spl-%soc_name%%uboot_feature%.bin
    set uboot_proper_to_be_flashed=bootloader-%soc_name%%uboot_feature%.img
) else (
    set bootloader_flashed_to_board=u-boot-%soc_name%%uboot_feature%.imx
)


:: in the source code, if AB slot feature is supported, uboot partition name is bootloader0
if %support_dualslot% == 1 set bootloader_partition=bootloader0
if not [%dtb_feature%] == [xen] (
    call :flash_partition %bootloader_partition% || set /A error_level=1 && goto :exit
)

if %support_dualslot% == 0 set slot=


:: if dual-bootloader feature is supported, we need to flash the u-boot proper then reboot to get hard-coded partition info
if %support_dual_bootloader% == 1 (
    if not [%slot%] == [] (
        call :flash_partition bootloader%slot% || set /A error_level=1 && goto :exit
        %fastboot_tool% set_active %slot:~-1%
    ) else (
        call :flash_partition bootloader_a || set /A error_level=1 && goto :exit
        call :flash_partition bootloader_b || set /A error_level=1 && goto :exit
        %fastboot_tool% set_active a
    )
)
:: full uboot is flashed to the board and active slot is set, reboot to u-boot fastboot boot command
:: XEN images on mek_8qm, it can't reboot
if not [%dtb_feature%] == [xen] (
    %fastboot_tool% reboot bootloader
    :: pause for about 5 second
    ping localhost -n 6 >nul
)

%fastboot_tool% getvar all 2> fastboot_var.log
find "mcu_os" fastboot_var.log > nul && set /A support_mcu_os=1

:: mcu_os is not supported will cause ERRORLEVEL to be a non-zero value, clear it here to avoid unexpected quit
cd .

if %flash_mcu% == 1 if %support_mcu_os% == 1 call :flash_partition %mcu_os_partition% || set /A error_level=1 && goto :exit
if [%slot%] == [] if %support_dualslot% == 1 (
:: flash image to both a and b slot
    call :flash_partition_name _a || set /A error_level=1 && goto :exit
    call :flash_userpartitions || set /A error_level=1 && goto :exit

    call :flash_partition_name _b || set /A error_level=1 && goto :exit
    call :flash_userpartitions || set /A error_level=1 && goto :exit
)
if not [%slot%] == []  if %support_dualslot% == 1 (
    call :flash_partition_name %slot% || set /A error_level=1 && goto :exit
    call :flash_userpartitions || set /A error_level=1 && goto :exit
)
if %support_dualslot% == 0 (
    call :flash_partition_name %slot% || set /A error_level=1 && goto :exit
    call :flash_userpartitions || set /A error_level=1 && goto :exit
)
::super partition does not have a/b slot, handle it individually
if %support_dynamic_partition% == 1 (
    call :flash_partition %super_partition% || set /A error_level=1 && goto :exit
)

del fastboot_var.log

goto :eof


:exit
exit /B %error_level%
