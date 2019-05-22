function Import-PSGalleryModule {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory, ValueFromPipeline)]
    [string]
    $Name
  )

  process {
    try {
      Import-Module -Name $Name -ErrorAction Stop
    }
    catch {
      $lookup = Find-Module -Name $Name
      if (-not $lookup) {
        Write-Error "Module `"$Name`" not found."
        continue
      }
      Install-Module -Name $Name -Scope CurrentUser -Force
      Import-Module -Name $Name
    }
  }
}

function Get-GitFile {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory, ValueFromPipeline)]
    [ValidatePattern('https://raw\.githubusercontent\.com.*')]
    [string]
    $URL
  )

  process {
    return (Invoke-WebRequest -Uri $URL).Content
  }
}

function Initialize-Profile {
  [CmdletBinding()]
  param ()

  process {
    if (-not (Test-Path $profile)) {
      New-Item $profile -Value "# Empty Profile"
    }
  }
}

function Test-IsAdministrator {
  $current_principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())

  if ($current_principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    $true
  }
  else {
    $false
  }
}
$psgallery_modules = [System.Collections.Generic.List[string]]::new()
# PowerShell Development Modules
('Pester', 'Plaster', 'psake', 'platyPS', 'PowerShellBuild', 'Stucco') | ForEach-Object { $psgallery_modules.Add($_) }
# PowerShell Commandline Quality of Life Modules
('posh-git', 'oh-my-posh', 'Get-ChildItemColor') | ForEach-Object { $psgallery_modules.Add($_) }
if (-not (Get-Module 'PSReadline')) { $psgallery_modules.Add('PSReadline') }

$git_ps_profile_url = 'https://raw.githubusercontent.com/bamsammich/PowerShell/master/Profile/Profile.ps1'
$git_ps_theme_url = 'https://raw.githubusercontent.com/bamsammich/PowerShell/master/Themes/Paradox_custom.psm1'

# Ensure Profile used by this session exists
Initialize-Profile

# Import defined PSGallery Modules
$psgallery_modules | Import-PSGalleryModule

$host_title = [ordered]@{
  'Elevation' = $(if (Test-IsAdministrator) { "Admin" } else { "Non-Admin" });
  'Version'   = $PSVersionTable.PSVersion.ToString();
  'Edition'   = $PSVersionTable.PSEdition;
  'Session'   = "$env:USERNAME@$env:COMPUTERNAME.$env:USERDOMAIN".ToLower();
}

# Set the Window Title
$host.ui.RawUI.WindowTitle = "PowerShell [ $($host_title.Values -join ' | ') ]"

# Ensure theme location exists
if (-not (Test-Path $ThemeSettings.MyThemesLocation)) {
  New-Item $ThemeSettings.MyThemesLocation -ItemType Directory -Force
}

# Set Theme
<# $theme_name = ($git_ps_theme_url -split '/' | Select-Object -Last 1).Trim()
$local_theme = Get-ChildItem $ThemeSettings.MyThemesLocation | Where-Object { $_.Name -eq $theme_name } | Get-Content -ErrorAction SilentlyContinue
$git_theme = Get-GitFile $git_ps_theme_url
if ($local_theme -ne $git_theme) {
  Write-Information "Updating local theme content from github."
  $git_theme | Out-File "$($ThemeSettings.MyThemesLocation)\$theme_name" -Force
}
Set-Theme (Get-Item "$($ThemeSettings.MyThemesLocation)\$theme_name").BaseName #>
Set-Theme Paradox

# Update local profile from github repo (if current does not match)
$git_ps_profile = Get-GitFile $git_ps_profile_url
$local_profile = Get-Content $profile -Raw
if ($local_profile -ne $git_ps_profile) {
  Write-Information "Updating local profile from github."
  $git_ps_profile | Out-File $profile -Force
}

