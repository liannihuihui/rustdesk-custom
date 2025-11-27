# RustDesk 自定义客户端批量部署脚本 (Windows)
# 使用方法：
#   1. 管理员权限运行 PowerShell
#   2. 执行: .\deploy_windows.ps1
#   3. 或者远程部署: .\deploy_windows.ps1 -ComputerName "PC1","PC2","PC3"

param(
    [Parameter(Mandatory=$false)]
    [string[]]$ComputerName = @("localhost"),

    [Parameter(Mandatory=$false)]
    [string]$InstallerPath = ".\rustdesk-setup.exe",

    [Parameter(Mandatory=$false)]
    [switch]$Silent = $true
)

# 检查管理员权限
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Error "此脚本需要管理员权限运行！"
    exit 1
}

# 检查安装包是否存在
if (-not (Test-Path $InstallerPath)) {
    Write-Error "找不到安装包: $InstallerPath"
    exit 1
}

Write-Host "=" * 60
Write-Host "RustDesk 自定义客户端批量部署工具"
Write-Host "=" * 60
Write-Host ""
Write-Host "配置信息:"
Write-Host "  - ID Server: rdapi.qzz.io"
Write-Host "  - Relay Server: rustdesk.qzz.io"
Write-Host "  - 管理员密码: ljhcch791115"
Write-Host "  - 启动模式: 后台静默"
Write-Host ""
Write-Host "=" * 60
Write-Host ""

# 部署函数
function Deploy-RustDesk {
    param([string]$Computer)

    Write-Host "[$Computer] 开始部署..."

    try {
        if ($Computer -eq "localhost") {
            # 本地部署
            Write-Host "[$Computer] 安装 RustDesk..."

            # 静默安装
            $installArgs = "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-"
            Start-Process -FilePath $InstallerPath -ArgumentList $installArgs -Wait -NoNewWindow

            # 等待服务启动
            Start-Sleep -Seconds 5

            # 检查服务状态
            $service = Get-Service -Name "RustDesk" -ErrorAction SilentlyContinue
            if ($service -and $service.Status -eq "Running") {
                Write-Host "[$Computer] ✓ 部署成功！服务已启动"
            } else {
                Write-Host "[$Computer] ⚠ 服务未运行，尝试启动..."
                Start-Service -Name "RustDesk" -ErrorAction SilentlyContinue
            }

        } else {
            # 远程部署
            Write-Host "[$Computer] 复制安装包到远程主机..."
            $remotePath = "\\$Computer\C$\Temp\rustdesk-setup.exe"
            Copy-Item -Path $InstallerPath -Destination $remotePath -Force

            Write-Host "[$Computer] 远程执行安装..."
            Invoke-Command -ComputerName $Computer -ScriptBlock {
                param($installer)
                Start-Process -FilePath $installer -ArgumentList "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-" -Wait -NoNewWindow
                Start-Sleep -Seconds 5
                Remove-Item $installer -Force -ErrorAction SilentlyContinue
            } -ArgumentList "C:\Temp\rustdesk-setup.exe"

            Write-Host "[$Computer] ✓ 远程部署完成"
        }

    } catch {
        Write-Host "[$Computer] ✗ 部署失败: $_" -ForegroundColor Red
    }

    Write-Host ""
}

# 执行部署
foreach ($computer in $ComputerName) {
    Deploy-RustDesk -Computer $computer
}

Write-Host "=" * 60
Write-Host "部署完成！"
Write-Host ""
Write-Host "提示："
Write-Host "  - 客户端已在后台静默运行（无托盘图标）"
Write-Host "  - 使用 'rustdesk.exe --gui' 可以打开主界面"
Write-Host "  - 服务器设置已锁定，用户无法修改"
Write-Host "=" * 60
