[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$flutter = Get-Command flutter -ErrorAction SilentlyContinue
if ($null -eq $flutter) {
  throw 'Flutter nije pronađen u PATH-u. Instalirajte Flutter 3.47+ sa Dart 3.13+, zatim ponovo pokrenite skriptu.'
}

$repositoryRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$mobileRoot = Join-Path $repositoryRoot 'apps\mobile'
$backofficeRoot = Join-Path $repositoryRoot 'apps\backoffice'

$platformTargets = @(
  (Join-Path $mobileRoot 'android'),
  (Join-Path $backofficeRoot 'windows'),
  (Join-Path $backofficeRoot 'web')
)
foreach ($target in $platformTargets) {
  if (Test-Path -LiteralPath $target) {
    throw "Platformski folder već postoji i skripta ga neće prepisati: $target"
  }
}

$tempParent = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
$tempRoot = [IO.Path]::GetFullPath((Join-Path $tempParent "device-guide-bootstrap-$([guid]::NewGuid())"))
if (-not $tempRoot.StartsWith($tempParent, [StringComparison]::OrdinalIgnoreCase)) {
  throw 'Privremeni folder nije unutar sistemskog temp foldera.'
}

try {
  $mobileTemplate = Join-Path $tempRoot 'mobile'
  $backofficeTemplate = Join-Path $tempRoot 'backoffice'

  & $flutter.Source create --empty --org rs.raf.rma --project-name device_guide_mobile --platforms android $mobileTemplate
  if ($LASTEXITCODE -ne 0) { throw 'Generisanje Android platforme nije uspelo.' }

  & $flutter.Source create --empty --org rs.raf.rma --project-name device_guide_backoffice --platforms windows,web $backofficeTemplate
  if ($LASTEXITCODE -ne 0) { throw 'Generisanje Windows i web platforme nije uspelo.' }

  Copy-Item -LiteralPath (Join-Path $mobileTemplate 'android') -Destination $mobileRoot -Recurse
  Copy-Item -LiteralPath (Join-Path $mobileTemplate '.metadata') -Destination $mobileRoot
  Copy-Item -LiteralPath (Join-Path $backofficeTemplate 'windows') -Destination $backofficeRoot -Recurse
  Copy-Item -LiteralPath (Join-Path $backofficeTemplate 'web') -Destination $backofficeRoot -Recurse
  Copy-Item -LiteralPath (Join-Path $backofficeTemplate '.metadata') -Destination $backofficeRoot

  Push-Location $repositoryRoot
  try {
    & $flutter.Source pub get
    if ($LASTEXITCODE -ne 0) { throw 'flutter pub get nije uspeo.' }
  } finally {
    Pop-Location
  }
} finally {
  if (Test-Path -LiteralPath $tempRoot) {
    $resolved = [IO.Path]::GetFullPath((Resolve-Path -LiteralPath $tempRoot))
    if (-not $resolved.StartsWith($tempParent, [StringComparison]::OrdinalIgnoreCase)) {
      throw 'Odbijeno brisanje foldera izvan sistemskog temp foldera.'
    }
    Remove-Item -LiteralPath $resolved -Recurse -Force
  }
}

Write-Host 'Platformski folderi su generisani. Pokrenite .\tool\verify.ps1.'
