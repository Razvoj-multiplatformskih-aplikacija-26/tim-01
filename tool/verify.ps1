[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$flutter = Get-Command flutter -ErrorAction SilentlyContinue
if ($null -eq $flutter) {
  throw 'Flutter nije pronađen u PATH-u.'
}

$repositoryRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))

Push-Location $repositoryRoot
try {
  & $flutter.Source pub get
  if ($LASTEXITCODE -ne 0) { throw 'flutter pub get nije uspeo.' }

  & dart format --output=none --set-exit-if-changed .
  if ($LASTEXITCODE -ne 0) { throw 'dart format je pronašao neformatirane fajlove.' }

  & $flutter.Source analyze
  if ($LASTEXITCODE -ne 0) { throw 'flutter analyze nije uspeo.' }

  & dart test packages/domain
  if ($LASTEXITCODE -ne 0) { throw 'Testovi paketa domain nisu uspeli.' }

  & dart test packages/blocs
  if ($LASTEXITCODE -ne 0) { throw 'Testovi paketa blocs nisu uspeli.' }

  Push-Location 'apps\mobile'
  try {
    & $flutter.Source test
    if ($LASTEXITCODE -ne 0) { throw 'Testovi mobilne aplikacije nisu uspeli.' }
  } finally {
    Pop-Location
  }

  Push-Location 'apps\backoffice'
  try {
    & $flutter.Source test
    if ($LASTEXITCODE -ne 0) { throw 'Testovi backoffice aplikacije nisu uspeli.' }
  } finally {
    Pop-Location
  }
} finally {
  Pop-Location
}

Write-Host 'Sve provere su uspešno završene.'
