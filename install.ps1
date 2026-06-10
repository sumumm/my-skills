# ========================================================
# Skills Manager for AI Extensions
# 管理 AI 扩展 (Claude Code / OpenCode / Roo) 的 Skills 安装、删除、列表
# ========================================================

# ========================================================
# 参数定义
# -h         : 显示帮助信息
# -l         : 列出所有已安装的 skills
# -add <tool>: 安装 skills 到指定工具 (claude/opencode/roo/all)
# -d <tool>  : 删除指定工具的所有 skills (claude/opencode/roo/all)
# -f         : 强制覆盖已存在的 skills (与 -add 配合使用)
# ========================================================
[CmdletBinding()]
param(
    [switch]$h,
    [switch]$l,
    [switch]$f,
    [ValidateSet("claude", "opencode", "roo", "all")]
    [string]$d,
    [ValidateSet("claude", "opencode", "roo", "all")]
    [string]$add
)

# ========================================================
# 全局配置
# ========================================================

# 设置控制台编码为 UTF-8，确保中文输出不乱码
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Skills 源目录 (脚本所在目录下的 skills/)
$script:srcPath = Join-Path $PSScriptRoot "skills"

# 工具配置表：键名为工具标识，Path 为目标安装路径，Name 为显示名称
# 所有函数通过此表统一获取路径和名称，避免重复定义
$script:tools = @{
    claude   = @{ Path = Join-Path $env:USERPROFILE ".claude\skills";                  Name = "Claude Code" }
    opencode = @{ Path = Join-Path $env:USERPROFILE ".config\opencode\skills";         Name = "OpenCode" }
    roo      = @{ Path = Join-Path $env:USERPROFILE ".roo\skills";                     Name = "Roo" }
}

# ========================================================
# 函数：Get-SkillsFromDir
# 从指定目录中读取所有 skill 子目录的信息
# 参数：
#   BasePath  - skill 目录的根路径 (如 ~/.claude/skills)
#   ToolName  - 工具显示名称 (如 "Claude Code")
# 返回：包含 Tool/Name/Description/Path 属性的对象数组
# ========================================================
function Get-SkillsFromDir {
    param(
        [string]$BasePath,
        [string]$ToolName
    )

    # 目录不存在则返回空数组
    if (-not (Test-Path -LiteralPath $BasePath)) {
        return @()
    }

    # 获取所有子目录 (每个子目录代表一个 skill)
    $skillDirs = Get-ChildItem -LiteralPath $BasePath -Directory -ErrorAction SilentlyContinue
    if (-not $skillDirs) {
        return @()
    }

    $results = @()
    foreach ($dir in $skillDirs) {
        $skillFile   = Join-Path $dir.FullName "SKILL.md"
        $name        = $dir.Name
        $description = ""

        # 从 SKILL.md 的 front matter 中提取 description 字段
        if (Test-Path -LiteralPath $skillFile) {
            $content = Get-Content -LiteralPath $skillFile -Encoding UTF8 -ErrorAction SilentlyContinue
            foreach ($line in $content) {
                if ($line -match '^\s*description:\s*(.+?)\s*(?:---\s*)?$') {
                    $description = $Matches[1].Trim()
                    break
                }
            }
        }

        $results += [PSCustomObject]@{
            Tool        = $ToolName
            Name        = $name
            Description = $description
            Path        = $dir.FullName
        }
    }

    return $results
}

# ========================================================
# 函数：Get-SkillList
# 列出所有工具中已安装的 skills，按工具分组显示
# ========================================================
function Get-SkillList {
    # 遍历所有工具，汇总 skill 列表
    $all = @()
    foreach ($key in $script:tools.Keys) {
        $tool = $script:tools[$key]
        $all += Get-SkillsFromDir -BasePath $tool.Path -ToolName $tool.Name
    }

    Write-Host ""
    if ($all.Count -eq 0) {
        Write-Host "  No skills found" -ForegroundColor Yellow
        Write-Host ""
        return
    }

    # 按工具分组显示
    $grouped = $all | Group-Object -Property Tool

    foreach ($group in $grouped) {
        Write-Host ("  {0} ({1})" -f $group.Name, $group.Count) -ForegroundColor Cyan

        foreach ($skill in $group.Group) {
            $desc = if ($skill.Description) { $skill.Description } else { "(no description)" }
            Write-Host ("    {0,-16} " -f $skill.Name) -ForegroundColor Yellow -NoNewline
            Write-Host $desc
        }

        Write-Host ""
    }

    Write-Host ("  Total: {0} skills" -f $all.Count) -ForegroundColor Green
    Write-Host ""
}

# ========================================================
# 函数：Remove-SkillsByTool
# 删除指定工具下的所有 skill 目录
# 参数：
#   ToolName - 工具标识 (claude/opencode/roo)
# ========================================================
function Remove-SkillsByTool {
    param(
        [string]$ToolName
    )

    # 根据工具标识获取路径和显示名称
    $key  = $ToolName.ToLower()
    $tool = $script:tools[$key]
    $path = $tool.Path

    # 目录不存在则提示
    if (-not (Test-Path -LiteralPath $path)) {
        Write-Host ""
        Write-Host "  Skills directory not found: $path" -ForegroundColor Yellow
        Write-Host ""
        return
    }

    # 获取所有 skill 子目录
    $dirs = Get-ChildItem -LiteralPath $path -Directory -ErrorAction SilentlyContinue
    if (-not $dirs) {
        Write-Host ""
        Write-Host "  No skills to remove in: $path" -ForegroundColor Yellow
        Write-Host ""
        return
    }

    # 逐个删除 skill 目录
    $count = $dirs.Count
    foreach ($dir in $dirs) {
        Remove-Item -LiteralPath $dir.FullName -Recurse -Force
        Write-Host ("  Removed: {0}" -f $dir.Name) -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host ("  Removed {0} skill(s) from {1}" -f $count, $tool.Name) -ForegroundColor Green
    Write-Host ""
}

# ========================================================
# 函数：Install-Skills
# 将 skills 源目录中的所有 skill 安装到指定工具的目标路径
# 参数：
#   ToolName - 工具标识 (claude/opencode/roo)
#   Force    - 是否强制覆盖已存在的 skill (开关参数)
# ========================================================
function Install-Skills {
    param(
        [string]$ToolName,
        [switch]$Force
    )

    # 检查 skills 源目录是否存在
    if (-not (Test-Path -LiteralPath $script:srcPath)) {
        Write-Host ""
        Write-Host "  Skills source directory not found: $script:srcPath" -ForegroundColor Red
        Write-Host ""
        return
    }

    # 根据工具标识获取目标路径和显示名称
    $key  = $ToolName.ToLower()
    $tool = $script:tools[$key]
    $path = $tool.Path

    # 获取源目录中的所有 skill 子目录
    $skillDirs = Get-ChildItem -LiteralPath $script:srcPath -Directory -ErrorAction SilentlyContinue
    if (-not $skillDirs) {
        Write-Host ""
        Write-Host "  No skills found in source directory" -ForegroundColor Yellow
        Write-Host ""
        return
    }

    # 如果目标路径不存在则自动创建
    if (-not (Test-Path -LiteralPath $path)) {
        New-Item -Path $path -ItemType Directory -Force | Out-Null
    }

    Write-Host ""
    Write-Host ("  Installing skills to {0} ({1}):" -f $tool.Name, $path) -ForegroundColor Cyan

    $count = 0
    $skipped = 0

    foreach ($dir in $skillDirs) {
        $dst = Join-Path $path $dir.Name

        if (Test-Path -LiteralPath $dst) {
            # 目标 skill 已存在
            if ($Force) {
                # -f 模式：直接覆盖
                Remove-Item -LiteralPath $dst -Recurse -Force
                Copy-Item -LiteralPath $dir.FullName -Destination $path -Recurse -Force
                Write-Host ("    {0,-16} overwritten" -f $dir.Name) -ForegroundColor Yellow
                $count++
            }
            else {
                # 交互模式：询问用户是否覆盖
                $answer = Read-Host ("    {0,-16} already exists, overwrite? [y/N]" -f $dir.Name)
                if ($answer -eq 'y' -or $answer -eq 'Y') {
                    Remove-Item -LiteralPath $dst -Recurse -Force
                    Copy-Item -LiteralPath $dir.FullName -Destination $path -Recurse -Force
                    Write-Host ("    {0,-16} overwritten" -f $dir.Name) -ForegroundColor Yellow
                    $count++
                }
                else {
                    Write-Host ("    {0,-16} skipped" -f $dir.Name) -ForegroundColor DarkGray
                    $skipped++
                }
            }
        }
        else {
            # 目标不存在，直接安装
            Copy-Item -LiteralPath $dir.FullName -Destination $path -Recurse -Force
            Write-Host ("    {0,-16} installed" -f $dir.Name) -ForegroundColor Green
            $count++
        }
    }

    Write-Host ""
    Write-Host ("  {0}: {1} skill(s) installed{2}" -f $tool.Name, $count, $(if ($skipped -gt 0) { ", $skipped skipped" } else { "" })) -ForegroundColor Green
    Write-Host ""
}

# ========================================================
# 函数：Show-Help
# 显示帮助信息
# ========================================================
function Show-Help {
    Write-Host ""
    Write-Host "  Skills Manager for AI Extensions" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Usage: ./install.ps1 [option] [argument]" -ForegroundColor White
    Write-Host ""
    Write-Host "  Options:" -ForegroundColor White
    Write-Host "    -h                Show this help message"
    Write-Host "    -l                List all installed skills"
    Write-Host "    -add <tool>       Install skills to specified tool"
    Write-Host "                      Available tools: claude, opencode, roo, all"
    Write-Host "    -f                Force overwrite (use with -add)"
    Write-Host "    -d <tool>         Delete all skills from specified tool"
    Write-Host "                      Available tools: claude, opencode, roo, all"
    Write-Host ""
}

# ========================================================
# 主入口：根据参数执行对应操作
# ========================================================
if ($h) {
    Show-Help
}
elseif ($l) {
    Get-SkillList
}
elseif ($add) {
    # -add all 时遍历所有工具依次安装
    if ($add -eq "all") {
        foreach ($key in $script:tools.Keys) {
            Install-Skills -ToolName $key -Force:$f
        }
    }
    else {
        Install-Skills -ToolName $add -Force:$f
    }
}
elseif ($d) {
    # -d all 时遍历所有工具依次删除
    if ($d -eq "all") {
        foreach ($key in $script:tools.Keys) {
            Remove-SkillsByTool -ToolName $key
        }
    }
    else {
        Remove-SkillsByTool -ToolName $d
    }
}
else {
    # 无参数时显示帮助
    Show-Help
}