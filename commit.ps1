#Requires -Version 5.1
<#
.SYNOPSIS
    一个全自动的Git提交脚本，无需任何手动交互，并能自动解决冲突。

.DESCRIPTION
    此脚本将彻底自动化Git提交流程，包括自动生成提交信息和强制解决冲突。
    执行流程：
    1. 自动生成一个带时间戳的提交信息，无需用户输入。
    2. 暂存所有本地更改（包括新文件）。
    3. 强制将本地分支与远程分支同步（git reset --hard），这是“远程覆盖本地”的基础。
    4. 恢复之前暂存的更改。
    5. **核心功能：如果恢复时发生冲突，脚本将自动放弃您在冲突文件中的本地更改（保留远程版本），然后继续执行，不会中断。**
    6. 自动添加、提交和推送所有最终的更改。

.WARNING
    此脚本包含数据破坏性操作。当发生冲突时，它会**自动且无提示地丢弃**您在这些文件中的本地（暂存）更改，以保证流程不中断。这是一个为特定自动化场景设计的强大功能，但可能会导致预期外的工作丢失。请在完全理解其行为后使用。

.EXAMPLE
    .\commit-auto.ps1
#>

# 设置当命令出错时立即停止脚本
$ErrorActionPreference = "Stop"

# 开始主流程
try {
    # 检查工作目录是否有更改
    if (-not (git status --porcelain)) {
        Write-Host "工作目录是干净的，没有需要提交的更改。" -ForegroundColor Green
        exit 0
    }

    # 1. 自动生成提交信息
    $commitMessage = "Auto-commit: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    
    Write-Host "== 开始Git全自动提交流程 ==" -ForegroundColor Cyan
    Write-Host "将使用的提交信息: $commitMessage" -ForegroundColor Yellow
    
    # 2. 获取当前分支名称
    $currentBranch = git rev-parse --abbrev-ref HEAD
    if ([string]::IsNullOrWhiteSpace($currentBranch)) {
        throw "无法确定当前的Git分支。"
    }
    Write-Host "当前分支: $currentBranch"

    # 3. 暂存所有本地更改
    Write-Host "[1/5] 正在暂存本地更改..."
    git stash push -u -m "auto-commit-stash-$(Get-Date -Format 'yyyyMMddHHmmss')" | Out-Null

    # 4. 强制与远程分支同步
    Write-Host "[2/5] 正在从远程拉取并强制同步..."
    git fetch origin $currentBranch
    git reset --hard origin/$currentBranch

    # 5. 恢复暂存的更改，并自动处理冲突
    Write-Host "[3/5] 正在恢复您的本地更改..."
    $stashResult = git stash pop 2>&1 | Out-String
    
    if ($LASTEXITCODE -ne 0) {
        if ($stashResult -match "CONFLICT") {
            Write-Host "[警告] 检测到冲突。将自动以远程版本为准解决。" -ForegroundColor Yellow
            
            # 获取所有冲突文件的列表
            $conflictingFiles = git diff --name-only --diff-filter=U
            
            if ($conflictingFiles) {
                foreach ($file in $conflictingFiles) {
                    $trimmedFile = $file.Trim()
                    Write-Host "  - 正在解决: '$trimmedFile' (强制保留远程版本，丢弃您的更改)" -ForegroundColor Magenta
                    # 对每个冲突文件，检出当前HEAD的版本（即远程版本），从而丢弃暂存中的更改
                    git checkout HEAD -- $trimmedFile
                }
                # 解决冲突后，冲突的暂存条目默认不会被丢弃，需要手动清理
                Write-Host "  - 清理已处理的暂存..."
                git stash drop | Out-Null
            }
            Write-Host "[信息] 所有冲突已按预设策略自动解决。" -ForegroundColor Green

        } elseif ($stashResult -match "No stash entries found") {
            Write-Host "没有发现需要恢复的暂存。"
        } else {
            # 其他未知错误
            throw "恢复暂存时发生未知错误: $stashResult"
        }
    }

    # 再次检查，如果合并后代码没有变化，则无需提交
    if (-not (git status --porcelain)) {
        Write-Host "与远程代码合并并解决冲突后，没有净更改需要提交。" -ForegroundColor Green
        exit 0
    }

    # 6. 添加、提交并推送
    Write-Host "[4/5] 正在添加并提交更改..."
    git add .
    git commit -m $commitMessage

    Write-Host "[5/5] 正在推送到远程仓库..."
    git push origin $currentBranch

    Write-Host "======================================"
    Write-Host "✅ 全自动提交流程成功完成！" -ForegroundColor Green

}
catch {
    Write-Host "[严重错误] 脚本执行失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}