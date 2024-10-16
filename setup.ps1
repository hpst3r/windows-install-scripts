#Requires -RunAsAdministrator
<#
    .SYNOPSIS
    Installs applications and configures a base Windows system for use.

    .DESCRIPTION
    
    .NOTES
#>
param(

    # TODO: point Winget installer at this directory
    [System.IO.DirectoryInfo]$WorkingDirectory = 'C:\tmp\installer',

    # TODO: implement
    [Boolean]$EncryptDisks = 1,

    # install .NET 3.5 (3.0, 2.0)
    [Boolean]$InstallDotNet3 = 1,

    # enable the Hyper-V hypervisor environment
    [Boolean]$EnableHyperV = 1,
        
        # installs the Windows Subsystem for Linux and specified distro, or Debian
        [Boolean]$InstallWsl = 1,

            # my default is Debian
            [String]$WslDistro = 'Debian',

        # enables the Disposable Client VM feature
        [Boolean]$InstallWindowsSandbox = 1,

        # install the Docker Container Engine TODO: Fix
        [Boolean]$InstallDockerCe = 0,

    # make registry tweaks to adjust the performance and functionality of Windows
    [Boolean]$UseRegistryTweaks = 1,

        # 1 - display the taskbar on main screen only
        # 0 - display taskbar on all screens (W11 default)
        [Boolean]$TaskbarSingleMonitor = 1,

        # 1 - hide the Search box on the taskbar
        # 0 - show the Search box on the taskbar (W11 default)
        [Boolean]$TaskbarHideSearch = 1,

        # 1 - hide the Task View taskbar button
        # 0 - show the Task View taskbar button (W11 default)
        [Boolean]$TaskbarHideTaskview = 1,

        # Disable the new W11 context menu
        # 1 - force the W10 style 'more options' context menu on right click
        # 0 - use the default W11 context menu, make no changes
        [Boolean]$SimpleContextMenu = 1,

        # older method of link-local name resolution, should be removed in newer W11 builds (I think)
        # 1 - disable LLMNR
        # 0 - keep LLMNR enabled
        [Boolean]$DisableLlmnr = 1,

        # Leaves hibernate enabled, just disables Hiberboot
        # 1 - enables Fast Startup
        # 0 - disables Fast Startup
        [Boolean]$FastStartupEnabled = 0,

        # This is the 'shake to minimize everything' "feature"
        # 1 - enables Aero Shake
        # 0 - disables Aero Shake
        [Boolean]$ShakeWindowsToMinimize = 0,

        # The DNS Client service provides a DNS cache and registers the computer with DNS servers
        # 1 - DNS cache DWORD 2 (Automatic) - default 'trigger start,' run the service
        # 0 - DNS cache DWORD 4 (Disabled) - disable DNS Client service autostart
        [Boolean]$DnsCacheEnabled = 1,
        
        # Disable adding Microsoft accounts.
        # Default in 10 21H2 IOT LTSC - doesn't exist
        # 1 - NoConnectedUser DWORD 3, can't add or sign in with a Microsoft account
        # 0 - NoConnectedUser DWORD 0, allow Microsoft accounts
        [Boolean]$DisableMicrosoftAccountSignIn = 1,

    # This is silly. Do this stuff with registry edits!
    [Boolean]$SetGroupPolicy = 1,

        [Boolean]$ForceWindowsHelloMfa = 1,
        [Boolean]$ConfigureChrome = 1,
        [Boolean]$DisableTransparency = 1,
        [Boolean]$DisableAnimations = 1,
        [Boolean]$DrawWindowsInMotion = 1,

    # This is also scaffolding. TODO: Future features
    [Boolean]$SyncPsProfile = 1,
    [Boolean]$RestoreDataDriveFromBackup = 0,
    [Boolean]$InstallBackupJobs = 1,

    # rename the computer by hashing the serial number and using LUT below
    [Boolean]$RenameComputer = 1,
        
        # where hash of hwid = friendly name:
        [hashtable]$Machines = @{

            'E059D9801FDE40FE35781C7C45D3C427D4C5CCADCFFF92854B9FCC998D2BC2AA' = 'liam-t14sg1a'
            '4C25652AF622E1A1AA13053F25187960621D08EBD554C319AFB4EDB0B44E7588' = 'liam-p1g4'
            '5EF84F905BCAEA90F3E2984D02085AE0CC76CF46BDC8BECCDAE3DFA621402D76' = 'liam-12900ks'

        },
    
    # global on/off toggle to install apps with any package manager.
    # the following True/False bindings apply to all InstallX boolean config switches.
    # 1 - install applications
    # 0 - do not install applications
    [Boolean]$InstallPrograms = 1,

        [Boolean]$InstallScoop = 1,

            # thing needed to download Scoop buckets, and Git for some reason
            # removing Git will probably break something
            [Array]$ScoopEarlyDeps = @(
                'git',
                'aria2'),

            # scoop repositories
            [Array]$ScoopBuckets = @(
                'java',
                'extras',
                'sysinternals'),

            # programming languages to install with Scoop.
            # I prefer to manage them this way vs Winget
            [Array]$ScoopLangs = @(
                'python',
                'ruby',
                'go',
                'perl',
                'nodejs',
                'java/openjdk'),

            # utilities to install with Scoop
            # sudo is a prerequisite for something, I think. TODO: figure this out
            [Array]$ScoopUtilities = @(
                'sudo',
                'curl',
                'grep',
                'sed',
                'less',
                'touch'), # sudo MUST come first

        [Boolean]$UseWinget = 1,

            # general dependencies wanted on any machine
            [Array]$WingetDependencies = @(
                'Microsoft.VCRedist.2015+.x64',
                'Microsoft.VCRedist.2015+.x86'),

            # Productivity and productivity adjacent applications
            [Boolean]$InstallWingetProductivity = 1,
            [Array]$WingetProductivity = @(
                'Spotify.Spotify',
                'Mozilla.Firefox.DeveloperEdition',
                'Microsoft.Office',
                'Notion.Notion'
                'Obsidian.Obsidian',
                'Microsoft.WindowsTerminal',
                'JGraph.Draw'),

            # System utilities and a password manager
            [Boolean]$InstallWingetUtilities = 1,
            [Array]$WingetUtilities = @(
                '7zip.7zip',
                'REALiX.HWiNFO',
                'AgileBits.1Password'),

            # Extra tools that I sometimes use and sometimes do not
            # TODO: it would be neat if I could configure Powertoys in this script, too
            [Boolean]$InstallWingetExtras = 1,
            [Array]$WingetExtras = @(
                'Nlitesoft.Nlite',
                'SyncTrayzor.SyncTrayzor',
                'Microsoft.PowerToys',
                'Armin2208.WindowsAutoNightMode'),

            # Basic development tools
            # ...and Windows debugger because I crash my computers a lot
            [Boolean]$InstallWingetDevtools = 1,
            [Array]$WingetDevtools = @(
                'Git.Git',
                'GitHub.cli',
                'Microsoft.VisualStudioCode',
                'Microsoft.VisualStudioCode.CLI',
                'Microsoft.PowerShell',
                'Microsoft.WinDbg'),
            
            # utilities for troubleshooting networks
            [Boolean]$InstallWingetNetworking = 1,
            [Array]$WingetNetworking = @(
                'Insecure.Npcap',
                'WiresharkFoundation.Wireshark',
                'PuTTY.PuTTY'), # easier than adding 5 args to openssh to connect to a 3560

            # utilities related to virtualization
            [Boolean]$InstallWingetVirtualization = 1,
            [Array]$WingetVirtualization = @('Hashicorp.Vagrant'),

            # command-line tools (text editor, ported GNU utilities maybe)
            [Boolean]$InstallWingetCliTools = 1,
            [Array]$WingetCliTools = @('Neovim.Neovim'),

            # anything 3D design/3D printer related
            # unfortunately, installing AutoCAD sucks
            [Boolean]$InstallWingetCad = 1,
            [Array]$WingetCad = @('UltiMaker.Cura'),

            # the Windows Assessment and Deployment toolkit.
            # I don't find myself needing this often.
            [Boolean]$InstallWingetAdk = 0,
            [Array]$WingetAdk = @('Microsoft.WindowsAdk'),

            # TODO: implement
            # Get-WmiObject win32_bios | Select Manufacturer
            [Boolean]$InstallOemDriverTool = 1,
                
                # Lenovo Commercial Vantage
                [Array]$Lenovo = @('9NR5B8GVVM13'),

                # Dell Command | Update
                [Array]$Dell = @('Dell.CommandUpdate')

)
BEGIN{
    # https://learn.microsoft.com/en-us/windows/package-manager/winget/
    function Install-Winget {

        $StartingDirectory = Get-Location
        Set-Location $WorkingDirectory

        $progressPreference = 'silentlyContinue'

        # TODO: clean this up a bit, cut line count down
        
        Invoke-WebRequest `
            -Uri 'https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx' `
            -OutFile 'Microsoft.VCLibs.x64.14.00.Desktop.appx'

        Add-AppxPackage `
            -Path 'Microsoft.VCLibs.x64.14.00.Desktop.appx'

        Invoke-WebRequest `
            -Uri 'https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.x64.appx' `
            -OutFile 'Microsoft.UI.Xaml.2.8.x64.appx'

        Add-AppxPackage `
            -Path 'Microsoft.UI.Xaml.2.8.x64.appx'

        Invoke-WebRequest `
            -Uri 'https://aka.ms/getwinget' `
            -OutFile 'Microsoft.DesktopAppInstaller.msixbundle'

        Add-AppxPackage `
            -Path 'Microsoft.DesktopAppInstaller.msixbundle'

        Set-Location $StartingDirectory

    }

    <#   
    function Install-Range {
        [CmdletBinding()]
        param (
            [command]$InputFunction,
            [Array]$InputArray        
        )

        foreach ($InputObject in $InputArray) {
            $InputFunction install $InputObject
        }
    }
    #>

    function Install-WingetRange {

        [CmdletBinding()]
        param (
            [Array]$WingetPackages
        )

        foreach ($WingetPackage in $WingetPackages) {
            winget install $WingetPackage
        }

    }

    function Install-ScoopRange {

        [CmdletBinding()]
        param (
            [Array]$ScoopPackages
        )

        foreach ($ScoopPackage in $ScoopPackages) {
            scoop install $ScoopPackage
        }

    }

    function Add-ScoopBucketRange {

        [CmdletBinding()]
        param (
            [Array]$ScoopBuckets
        )

        foreach ($ScoopBucket in $ScoopBuckets) {
            scoop bucket add $ScoopBucket
        }

    }

    Function New-RegistryKey {

        param (
            [String]$KeyPath
        )

        if (-not (Test-Path -Path $KeyPath)) {

            New-Item `
                -Path $KeyPath `
                -Force

        }

    }

    function Set-RegistryValue {

        [CmdletBinding()]
        param (
            [String]$KeyPath,
            [String]$ValueName,
            [String]$ValueType,
            [int]$Value
        )

        # splat these so they're reused
        $PathAndValueName = @{
            Path = $KeyPath
            Name = $ValueName
        }
        # if exists set value
        if (Get-ItemProperty @PathAndValueName) {
            Set-ItemProperty @PathAndValueName -Value $Value -Force
        } else { # if not exists create value
            New-ItemProperty @PathAndValueName -Type $ValueType -Value $Value
        }

    }

    Function Get-Hash {
        
        param (
            [String]$Text,
            [String]$Algorithm = 'md5'
        )

        Return Get-FileHash `
            -InputStream ([IO.MemoryStream]::new([byte[]][char[]]$Text)) `
            -Algorithm $Algorithm

    }
    }PROCESS{
    # basics
    Set-TimeZone -Name 'Eastern Standard Time'

    if ($UseRegistryTweaks) {

        # show taskbar on all (1, default) or main (0) monitor(s)
        # set CLRF=0 in HKCU\Software\Microsoft\Telnet

        $MultiMonitorTaskbarMode = @{
            KeyPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
            ValueName = 'MMTaskbarEnabled'
            ValueType = 'DWord'
            Value = if ($TaskbarSingleMonitor) { 0 } else { 1 }
        }

        # show (1, default) or hide (0) the search box on the taskbar

        $SearchBoxTaskbarMode = @{
            KeyPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search'
            ValueName = 'SearchBoxTaskbarMode'
            ValueType = 'DWord'
            Value = if ($TaskbarHideSearch) { 0 } else { 1 }
        }

        # show (1, default) or hide (0) the task view button on the taskbar

        $ShowTaskViewButton = @{
            KeyPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
            ValueName = 'ShowTaskViewButton'
            ValueType = 'DWord'
            Value = if ($TaskbarHideTaskview) { 0 } else { 1 }
        }

        # enable (1, default) or disable (0) Fast Startup

        $FastStartup = @{
            KeyPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power'
            ValueName = 'HiberbootEnabled'
            ValueType = 'DWord'
            Value = if ($FastStartupEnabled) { 1 } else { 0 }
        }

        # enable (0, default) or disable (1) Shake to Minimize

        $DisallowShaking = @{
            KeyPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
            ValueName = 'DisallowShaking'
            ValueType = 'DWord'
            Value = if ($ShakeWindowsToMinimize) { 0 } else { 1 }
        }

        # enable (2, default) or disable (4) the Windows DNS Client DNS cache

        $DnsCache = @{
            KeyPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache'
            ValueName = 'Start'
            ValueType = 'DWord'
            Value = if ($DnsCacheEnabled) { 2 } else { 4 }
        }

        # allow (0, default) or disallow (3) Microsoft accounts on this PC
        
        $NoConnectedUser = @{
            KeyPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
            ValueName = 'NoConnectedUser'
            ValueType = 'DWord'
            Value = if ($DisableMicrosoftAccountSignIn) { 3 } else { 0 }
        }

        # create a registry key to disable the new Windows 11 context menu

        $InprocServerOldContextMenu = @{
            KeyPath = 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32'
            ValueName = '(Default)'
            ValueType = 'String'
            Value = ''
        }

        # disable link-local multicast name resolution (LLMNR), which forces the use of a DNS server
        $DNSClientMulticastResolution = @{
            KeyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient'
            ValueName = 'EnableMultiCast'
            ValueType = 'DWORD'
            Value = 0
        }


        # list of splatted parameters to be passed to Set-RegistryValue one at a time
        [Array]$RegistryValues = @(

            $MultiMonitorTaskbarMode # show or hide the taskbar on secondary displays
            $SearchBoxTaskbarMode # show or hide the Search box on the taskbar
            $ShowTaskViewButton # show or hide the Task View taskbar button
            $FastStartup # set HiberbootEnabled
            $DisallowShaking # enable or disable the Shake to Minimize feature
            $DnsCache # set the autostart status of the DNS Client service
            $NoConnectedUser # set if Microsoft accounts are allowed or not
            if ($SimpleContextMenu) {$InprocServerOldContextMenu}
            if ($DisableLlmnr) {$DNSClientMulticastResolution}
            
        )

        Foreach ($RegistryValue in $RegistryValues) { Set-RegistryValue @RegistryValue }

        # kill Explorer (it will restart) to apply changes immediately
        Stop-Process -Name Explorer -Force

    }

    # Windows tweaks: disable Netbios - this will only disable Netbios on adapters that are currently up
    # TODO: spawn a script on network adapter change to kill netbios?
    # (Get-WmiObject Win32_NetworkAdapterConfiguration -Filter IpEnabled='true').SetTcpipNetbios(2)

    if ($EnableHyperV) {
        
        Enable-WindowsOptionalFeature `
            -Online `
            -FeatureName Microsoft-Hyper-V `
            -All ` # -IncludeManagementTools
            -NoRestart

        <#
        # ConfigureHyperV params are declared at the beginning of the script
        if ($ConfigureHyperV) {

            Set-VMHost -VirtualHardDiskPath $HyperVVhdxPath
            Set-VMHost -VirtualMachinePath $HyperVVmcfgPath
        }
        #>

        if ($InstallDockerCe) {

            # this reboots the computer unprompted in the middle of the script
            # thanks Microsoft
            # TODO: fix before implementing

            <#
                Invoke-WebRequest -UseBasicParsing 'https://raw.githubusercontent.com/microsoft/Windows-Containers/Main/helpful_tools/Install-DockerCE/install-docker-ce.ps1' -o install-docker-ce.ps1
                .\install-docker-ce.ps1
                
            #>
            
        }

        if ($InstallWsl) {

            # without explicitly adding VMP, VMP is not enabled
            # and first WSL boot fails. Not sure why that is.
            Enable-WindowsOptionalFeature `
                -Online `
                -FeatureName 'VirtualMachinePlatform' `
                -NoRestart

            wsl.exe `
                --install `
                -d $WslDistro

        }
        

        if ($InstallWindowsSandbox) {

            Write-Host('+++ Enabling Windows Sandbox +++')

            Enable-WindowsOptionalFeature `
                -FeatureName 'Containers-DisposableClientVM' `
                -Online `
                -NoRestart `
                -ErrorAction Stop

        }

    }

    if ($InstallPrograms) {

        Write-Host('+++ Installing applications +++')

        if ($InstallScoop) {
            
            Write-Host('+++ pre-install for Scoop - check if it already exists +++')
        
            if ( -not [bool](Get-Command scoop)) {
        
                Write-Host('+++ Scoop not found. Installing the Scoop package manager +++')
                Invoke-Expression '& {$(Invoke-RestMethod get.scoop.sh)} -RunAsAdmin' -ErrorVariable ScoopErrVar -ErrorAction Inquire
        
            } else { Write-Host('+++ Scoop was found. Skipping installation +++') }
        
            # install the Scoop packages necessary to add buckets
            Install-ScoopRange($ScoopEarlyDeps)
            # add Scoop repos (buckets)
            Add-ScoopBucketRange($ScoopBuckets)
            # install the Scoop packages we want
            Install-ScoopRange($ScoopUtilities)
            Install-ScoopRange($ScoopLangs)
        
        } else { Write-Host('--- Skipping development group ---') }
        
        # Install apps with the winget package manager
        if ($UseWinget) {
        
            if (-not (Get-Command winget.exe)) { Install-Winget }
        
            Write-Host('+++ Beginning installation of Winget and Windows Store apps. +++')

            Install-WingetRange $WingetDependencies
        
            if ($InstallWingetProductivity) { Install-WingetRange $WingetProductivity }
        
            if ($InstallWingetUtilities) { Install-WingetRange $WingetUtilities }
        
            if ($InstallWingetDevtools) { Install-WingetRange $WingetDevtools }
        
            if ($InstallWingetExtras) { Install-WingetRange $WingetExtras } 
        
            if ($InstallWingetNetworking) { Install-WingetRange $WingetNetworking }

            if ($InstallWingetCliTools) { Install-WingetRange $WingetCliTools }

            if ($InstallWingetVirtualization) { Install-WingetRange $WingetVirtualization }

            if ($InstallWingetAdk) { Install-WingetRange $WingetAdk }
        
        }

    } else { Write-Host('--- Package installation bypassed ---') }

    # TODO: clean this up
    dism /online /Enable-Feature /FeatureName:TelnetClient

    # match sn hash in LUT for defined hostname
    # so I don't have to post serial numbers in public repo (not that it matters)
    # TODO: this should work, but is untested - 7/25/2024
    if ($RenameComputer) {

        $SerialNumber = Get-Hash `
            -text (Get-WmiObject win32_bios | Select-Object SerialNumber) `
            -algorithm SHA256

        Rename-Computer $Machines[$SerialNumber]

    }
}
END{
    Exit 0
}
