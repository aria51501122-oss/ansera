#Requires -Version 5.1
<#
.SYNOPSIS
    Ansera バックアップスクリプト — PostgreSQL ダンプ + n8n データアーカイブ

.DESCRIPTION
    PostgreSQL データと n8n ボリューム（ワークフロー定義・認証情報・実行履歴）を
    タイムスタンプ付きでバックアップします。

    出力先のデフォルトは <project root>\backups\ です。
    -Destination で任意のパスに出力できます。

.EXAMPLE
    .\backup.ps1
    .\backup.ps1 -Destination D:\Ansera\Backups
#>
[CmdletBinding()]
param(
    [string]$Destination = (Join-Path $PSScriptRoot '..\backups')
)

$ErrorActionPreference = 'Stop'

# Docker コマンド存在確認
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Error 'docker コマンドが見つかりません。Docker Desktop をインストールしてください。'
    exit 1
}

# ansera-db / ansera-n8n コンテナ起動確認
$dbStatus  = docker ps --filter 'name=ansera-db'  --format '{{.Status}}'
$n8nStatus = docker ps --filter 'name=ansera-n8n' --format '{{.Status}}'
if (-not $dbStatus) {
    Write-Error 'ansera-db コンテナが起動していません。docker compose up -d を実行してください。'
    exit 1
}
if (-not $n8nStatus) {
    Write-Error 'ansera-n8n コンテナが起動していません。docker compose up -d を実行してください。'
    exit 1
}

# n8n ボリューム名を実コンテナから動的解決（プロジェクト名が異なる環境にも対応）
$n8nVolume = docker inspect ansera-n8n --format '{{range .Mounts}}{{if eq .Destination "/home/node/.n8n"}}{{.Name}}{{end}}{{end}}'
if (-not $n8nVolume) {
    Write-Error 'n8n ボリューム名を特定できませんでした。docker inspect ansera-n8n を確認してください。'
    exit 1
}

# 出力先準備
if (-not (Test-Path $Destination)) {
    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
}
$Destination = (Resolve-Path $Destination).Path

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$dumpFile  = Join-Path $Destination "ansera-db-$timestamp.sql"
$n8nFile   = Join-Path $Destination "ansera-n8n-$timestamp.tar"

# [1/2] PostgreSQL pg_dump
Write-Host "[1/2] PostgreSQL ダンプ中..."
# cmd.exe の > リダイレクトで raw bytes (UTF-8) を保持
& cmd /c "docker exec ansera-db pg_dump -U ansera -d ansera > `"$dumpFile`""
if ($LASTEXITCODE -ne 0) {
    Write-Error 'pg_dump に失敗しました。'
    exit 1
}
Write-Host "[OK] $dumpFile"

# [2/2] n8n ボリュームを tar でアーカイブ
Write-Host "[2/2] n8n ボリューム (WF 定義 / 認証情報) をアーカイブ中..."
docker run --rm `
    -v "${n8nVolume}:/data:ro" `
    -v "${Destination}:/backup" `
    alpine `
    tar -cf "/backup/ansera-n8n-$timestamp.tar" -C /data .
if ($LASTEXITCODE -ne 0) {
    Write-Error 'n8n ボリュームの tar 作成に失敗しました。'
    exit 1
}
Write-Host "[OK] $n8nFile"

Write-Host ''
Write-Host '======================================'
Write-Host '  バックアップ完了'
Write-Host '======================================'
Write-Host "出力先: $Destination"
Write-Host ''
Write-Host '推奨: 別ドライブまたはクラウドストレージへ転送してください。'
Write-Host '      同一ディスクに置くと災害時に同時消失します。'
