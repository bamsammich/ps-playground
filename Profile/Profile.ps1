#requires -RunAsAdministrator
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
$psgallery_modules = @('posh-git', 'oh-my-posh', 'Get-ChildItemColor')
$git_ps_profile_url = 'https://raw.githubusercontent.com/bamsammich/PowerShell/master/Profile/Profile.ps1'

# Ensure Profile used by this session exists
Initialize-Profile

# Import defined PSGallery Modules
$psgallery_modules | Import-PSGalleryModule

# Update local profile from github repo (if current does not match)
$git_ps_profile = Get-GitFile $git_ps_profile_url
$local_profile = Get-Content $profile -Raw
if ($local_profile -ne $git_ps_profile) {
  Write-Information "Updating local profile from github location."
  $git_ps_profile | Out-File $profile
}
else {
  Write-Information "Matched"
}
