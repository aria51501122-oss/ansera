@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
title Ansera セットアップ
cd /d "%~dp0"

set FORCE=0
if /i "%~1"=="--force" set FORCE=1

set LOG=%~dp0setup.log
echo === Ansera Setup %date% %time% === > "%LOG%"

echo.
echo ========================================
echo   Ansera セットアップを開始します
echo ========================================
echo.

REM ---------- 前提確認 ----------
echo [前提確認 1/4] 管理者権限を確認中...
net session >nul 2>&1
if errorlevel 1 (
    echo.
    echo [エラー] 管理者権限がありません。
    echo 対処法: setup.bat を右クリックし「管理者として実行」を選んでください。
    echo ログ: %LOG%
    echo.
    pause
    exit /b 1
)

echo [前提確認 2/4] Docker Desktop を確認中...
docker info >nul 2>>"%LOG%"
if errorlevel 1 (
    echo.
    echo [エラー] Docker Desktop が起動していません。
    echo 対処法: Docker Desktop をインストールし、起動してから再実行してください。
    echo ダウンロード: https://www.docker.com/products/docker-desktop/
    echo ログ: %LOG%
    echo.
    pause
    exit /b 1
)

echo [前提確認 3/4] NVIDIA GPU を確認中...
nvidia-smi >nul 2>&1
if errorlevel 1 (
    echo.
    echo [警告] NVIDIA GPU が見つかりませんでした。
    echo CPU 動作になり、応答に数分かかる場合があります。
    echo.
    set /p YN=続行しますか？ (Y/N):
    if /i not "!YN!"=="Y" (
        echo セットアップを中止しました。
        pause
        exit /b 1
    )
)

echo [前提確認 4/4] 空きディスク容量を確認中...
for /f "delims=" %%A in ('powershell -NoProfile -Command "[int64]((Get-PSDrive C).Free)"') do set FREE=%%A
set /a FREE_GB=!FREE! / 1073741824
echo 空き容量: !FREE_GB! GB
if !FREE_GB! LSS 20 (
    echo.
    echo [警告] 空きディスク容量が 20GB 未満です（!FREE_GB! GB）。
    echo セットアップには 20GB 以上を推奨します。
    echo.
    set /p YN=続行しますか？ (Y/N):
    if /i not "!YN!"=="Y" (
        echo セットアップを中止しました。
        pause
        exit /b 1
    )
)

echo.
echo ========================================
echo   サービスを起動します
echo ========================================
echo.

REM ---------- [1/7] compose up ----------
echo [1/7] Docker サービスを起動中...
docker compose up -d >>"%LOG%" 2>&1
if errorlevel 1 (
    echo.
    echo [エラー] Docker サービスの起動に失敗しました。
    echo 対処法: Docker Desktop を再起動して setup.bat を再実行してください。
    echo ログ: %LOG%
    echo.
    pause
    exit /b 1
)

REM ---------- [2/7] PostgreSQL ----------
echo [2/7] PostgreSQL の起動を待機中...
set RETRY=0
:wait_pg
docker exec ansera-db pg_isready -U ansera >nul 2>&1
if not errorlevel 1 goto pg_ok
set /a RETRY+=1
if !RETRY! GEQ 60 (
    echo.
    echo [エラー] PostgreSQL が起動しませんでした（120秒タイムアウト）。
    echo 対処法: docker logs ansera-db で詳細を確認してください。
    echo ログ: %LOG%
    echo.
    pause
    exit /b 1
)
timeout /t 2 >nul
goto wait_pg
:pg_ok
echo PostgreSQL 起動完了

REM ---------- [3/7] n8n ----------
echo [3/7] n8n の起動を待機中...
set RETRY=0
:wait_n8n
curl -fsS http://localhost:5678/healthz >nul 2>&1
if not errorlevel 1 goto n8n_ok
set /a RETRY+=1
if !RETRY! GEQ 90 (
    echo.
    echo [エラー] n8n が起動しませんでした（180秒タイムアウト）。
    echo 対処法: docker logs ansera-n8n で詳細を確認してください。
    echo ログ: %LOG%
    echo.
    pause
    exit /b 1
)
timeout /t 2 >nul
goto wait_n8n
:n8n_ok
echo n8n 起動完了

REM ---------- [4/7] Ollama ----------
echo [4/7] Ollama の起動を待機中...
set RETRY=0
:wait_ollama
curl -fsS http://localhost:11434/api/tags >nul 2>&1
if not errorlevel 1 goto ollama_ok
set /a RETRY+=1
if !RETRY! GEQ 60 (
    echo.
    echo [エラー] Ollama が起動しませんでした（120秒タイムアウト）。
    echo 対処法: docker logs ansera-ollama で詳細を確認してください。
    echo ログ: %LOG%
    echo.
    pause
    exit /b 1
)
timeout /t 2 >nul
goto wait_ollama
:ollama_ok
echo Ollama 起動完了

REM ---------- [5/7] qwen3:8b ----------
echo.
echo [5/7] AI モデル qwen3:8b をダウンロード中（約 5GB、数分かかります）...
docker exec ansera-ollama ollama pull qwen3:8b
if errorlevel 1 (
    echo.
    echo [エラー] qwen3:8b のダウンロードに失敗しました。
    echo 対処法: ネットワーク接続を確認し、setup.bat を再実行してください。
    echo.
    pause
    exit /b 1
)

REM ---------- [6/7] bge-m3 ----------
echo.
echo [6/7] 埋め込みモデル bge-m3 をダウンロード中（約 1.2GB）...
docker exec ansera-ollama ollama pull bge-m3
if errorlevel 1 (
    echo.
    echo [エラー] bge-m3 のダウンロードに失敗しました。
    echo 対処法: ネットワーク接続を確認し、setup.bat を再実行してください。
    echo.
    pause
    exit /b 1
)

echo.
echo ============================================
echo   n8n の初期設定をしてください
echo ============================================
echo.
echo   1. ブラウザで http://localhost:5678 を開く
echo   2. アカウントを作成（名前/メール/パスワード）
echo   3. 左メニュー Settings → Credentials → Add Credential
echo   4. 「PostgreSQL」を検索して選択
echo   5. 以下を入力：
echo      Name: Postgres account
echo      Host: postgres
echo      Port: 5432
echo      Database: ansera
echo      User: ansera
echo      Password: ansera
echo   6. Save をクリック
echo.
echo   完了したら、このウィンドウに戻って
set /p READY=  Enterキーを押してください:

REM ---------- [7/7] WF import ----------
set SKIP_WF=0
if exist "%~dp0.setup_done" if !FORCE! EQU 0 set SKIP_WF=1

if !SKIP_WF! EQU 1 (
    echo [7/7] n8n ワークフローはインポート済みのためスキップします。
    echo       再インポートする場合: setup.bat --force
    goto done
)

echo [7/7] n8n ワークフローをインポート中...
docker exec --user root ansera-n8n rm -rf /tmp/n8n-workflows >>"%LOG%" 2>&1
docker cp "%~dp0n8n-workflows" ansera-n8n:/tmp/n8n-workflows >>"%LOG%" 2>&1
if errorlevel 1 (
    echo.
    echo [エラー] ワークフローファイルのコピーに失敗しました。
    echo ログ: %LOG%
    echo.
    pause
    exit /b 1
)
docker exec ansera-n8n n8n import:workflow --separate --input=/tmp/n8n-workflows >>"%LOG%" 2>&1
if errorlevel 1 (
    echo.
    echo [エラー] ワークフローのインポートに失敗しました。
    echo ログ: %LOG%
    echo.
    pause
    exit /b 1
)
echo %date% %time% > "%~dp0.setup_done"
echo ワークフローのインポート完了

echo 全ワークフローを有効化中...
docker exec -u node ansera-n8n n8n update:workflow --all --active=true >>"%LOG%" 2>&1
if errorlevel 1 (
    echo [警告] 自動有効化に失敗しました。n8n 画面から手動で有効化してください。
)

:done
echo.
echo ========================================
echo   セットアップが完了しました！
echo ========================================
echo.
echo 次の手順:
echo.
echo  ui\index.html をダブルクリックして Ansera を起動してください
echo.
echo ブラウザを起動します...
start "" http://localhost:5678
echo.
pause
endlocal
exit /b 0
