# Windows PowerShell setup (no Administrator permission required).
# Neovim on Windows reads %LOCALAPPDATA%/nvim by default.
param(
    [switch]$ConfigOnly
)
$ErrorActionPreference = 'Stop'

$source = Join-Path $PSScriptRoot 'nvim'
if (-not (Test-Path -LiteralPath (Join-Path $source 'init.lua') -PathType Leaf)) {
    throw 'Run install.ps1 from the 1337-session repository checkout.'
}
$configHome = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { $env:LOCALAPPDATA }
if (-not $configHome) { throw 'Cannot determine the Neovim config directory.' }
New-Item -ItemType Directory -Path $configHome -Force | Out-Null
$destination = Join-Path $configHome 'nvim'
$stage = Join-Path $configHome ('nvim.stage.' + [guid]::NewGuid().ToString('N'))
$backup = $null

try {
    Copy-Item -LiteralPath $source -Destination $stage -Recurse -Force
    if (Test-Path -LiteralPath $destination) {
        $backup = $destination + '.bak.' + (Get-Date -Format 'yyyyMMddHHmmss') + '.' + [guid]::NewGuid().ToString('N')
        Move-Item -LiteralPath $destination -Destination $backup
        Write-Host "Previous configuration backed up at $backup"
    }
    Move-Item -LiteralPath $stage -Destination $destination
} catch {
    if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
    if ($backup -and -not (Test-Path -LiteralPath $destination) -and (Test-Path -LiteralPath $backup)) {
        Move-Item -LiteralPath $backup -Destination $destination
    }
    throw
}

Write-Host "1337-session Neovim configuration installed at $destination"
if (-not (Get-Command nvim -ErrorAction SilentlyContinue)) {
    Write-Warning 'Neovim 0.11+ is not on PATH. Install Neovim, Git, a C compiler and LSP tools for the full setup.'
} elseif (-not $ConfigOnly) {
    Write-Host 'Run nvim to initialize plugins. Git and compiler tools are needed for plugin downloads and Tree-sitter.'
}
Write-Host 'Optional: use $env:NVIM_ASCII_ICONS="1" for terminals without a Nerd Font.'
