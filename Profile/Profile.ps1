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

$psgallery_modules = @('posh-git', 'oh-my-posh', 'Get-ChildItemColor')

$psgallery_modules | Import-PSGalleryModule