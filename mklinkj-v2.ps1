# 目录联接创建工具（增强版）
# 功能：创建目录联接，自动处理源目录存在的情况

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName PresentationFramework

# 检查管理员权限
function Test-Administrator {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# 复制目录并显示进度
function Copy-DirectoryWithProgress {
    param(
        [string]$SourcePath,
        [string]$DestinationPath,
        [System.Windows.Forms.ProgressBar]$ProgressBar,
        [System.Windows.Forms.Label]$StatusLabel,
        [System.Windows.Forms.Form]$Form
    )
    
    try {
        # 确保目标目录存在
        if (-not (Test-Path $DestinationPath)) {
            New-Item -ItemType Directory -Path $DestinationPath -Force | Out-Null
        }
        
        # 获取源目录中的所有文件
        $allFiles = Get-ChildItem -Path $SourcePath -File -Recurse
        
        # 计算总文件数
        $totalFiles = $allFiles.Count
        if ($totalFiles -eq 0) {
            $StatusLabel.Text = "源目录为空，无需复制"
            $Form.Refresh()
            return $true
        }
        
        $StatusLabel.Text = "正在复制文件 (0/$totalFiles)..."
        $Form.Refresh()
        
        # 初始化进度条
        $ProgressBar.Value = 0
        $ProgressBar.Maximum = $totalFiles
        $ProgressBar.Visible = $true
        $Form.Refresh()
        
        $copiedFiles = 0
        $errors = @()
        
        # 复制每个文件
        foreach ($file in $allFiles) {
            $relativePath = $file.FullName.Substring($SourcePath.Length)
            $destPath = Join-Path $DestinationPath $relativePath
            
            # 确保目标目录存在
            $destDir = Split-Path $destPath -Parent
            if (-not (Test-Path $destDir)) {
                New-Item -ItemType Directory -Path $destDir -Force | Out-Null
            }
            
            try {
                # 复制文件，保留所有属性
                Copy-Item -Path $file.FullName -Destination $destPath -Force
                $copiedFiles++
                
                # 更新进度
                $progressPercent = [math]::Round(($copiedFiles / $totalFiles) * 100)
                $ProgressBar.Value = $copiedFiles
                $StatusLabel.Text = "正在复制文件 ($copiedFiles/$totalFiles) - $progressPercent%"
                
                # 每复制10个文件更新一次界面
                if ($copiedFiles % 10 -eq 0) {
                    $Form.Refresh()
                }
            }
            catch {
                $errors += "无法复制文件 '$($file.Name)': $_"
            }
        }
        
        # 复制目录结构（空目录）
        $allDirectories = Get-ChildItem -Path $SourcePath -Directory -Recurse
        foreach ($dir in $allDirectories) {
            $relativePath = $dir.FullName.Substring($SourcePath.Length)
            $destDirPath = Join-Path $DestinationPath $relativePath
            
            if (-not (Test-Path $destDirPath)) {
                New-Item -ItemType Directory -Path $destDirPath -Force | Out-Null | Out-Null
            }
        }
        
        # 隐藏进度条
        $ProgressBar.Visible = $false
        
        if ($errors.Count -gt 0) {
            $StatusLabel.Text = "复制完成，但有 $($errors.Count) 个错误"
            $Form.Refresh()
            
            # 显示错误摘要
            $errorMsg = "复制过程中发生以下错误：`n`n"
            $errorMsg += ($errors -join "`n")
            [System.Windows.MessageBox]::Show($errorMsg, "复制错误", "OK", "Warning")
            
            return $false
        }
        else {
            $StatusLabel.Text = "复制完成，已成功复制 $copiedFiles/$totalFiles 个文件"
            $Form.Refresh()
            return $true
        }
    }
    catch {
        $StatusLabel.Text = "复制过程中发生错误: $_"
        $Form.Refresh()
        return $false
    }
}

# 创建主窗体
$form = New-Object System.Windows.Forms.Form
$form.Text = "目录联接创建工具 (增强版)"
$form.Size = New-Object System.Drawing.Size(650, 520)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 250)

# 图标（使用系统图标）
$form.Icon = [System.Drawing.SystemIcons]::Information

# 标题标签
$labelTitle = New-Object System.Windows.Forms.Label
$labelTitle.Text = "目录联接创建工具 (增强版)"
$labelTitle.Location = New-Object System.Drawing.Point(20, 20)
$labelTitle.Size = New-Object System.Drawing.Size(600, 35)
$labelTitle.Font = New-Object System.Drawing.Font("微软雅黑", 16, [System.Drawing.FontStyle]::Bold)
$labelTitle.ForeColor = [System.Drawing.Color]::DarkSlateBlue
$form.Controls.Add($labelTitle)

# 说明标签
$labelDescription = New-Object System.Windows.Forms.Label
$labelDescription.Text = "此工具用于创建目录联接（Junction Point）。当源目录存在时，会自动复制内容到目标目录。"
$labelDescription.Location = New-Object System.Drawing.Point(20, 65)
$labelDescription.Size = New-Object System.Drawing.Size(600, 40)
$labelDescription.Font = New-Object System.Drawing.Font("微软雅黑", 9)
$form.Controls.Add($labelDescription)

# 源目录（链接点）部分
$labelSource = New-Object System.Windows.Forms.Label
$labelSource.Text = "链接点目录（新创建的联接点）:"
$labelSource.Location = New-Object System.Drawing.Point(20, 120)
$labelSource.Size = New-Object System.Drawing.Size(400, 20)
$labelSource.Font = New-Object System.Drawing.Font("微软雅黑", 9, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($labelSource)

$textBoxSource = New-Object System.Windows.Forms.TextBox
$textBoxSource.Location = New-Object System.Drawing.Point(20, 145)
$textBoxSource.Size = New-Object System.Drawing.Size(510, 20)
$textBoxSource.Font = New-Object System.Drawing.Font("微软雅黑", 9)
$form.Controls.Add($textBoxSource)

$buttonBrowseSource = New-Object System.Windows.Forms.Button
$buttonBrowseSource.Text = "浏览..."
$buttonBrowseSource.Location = New-Object System.Drawing.Point(540, 143)
$buttonBrowseSource.Size = New-Object System.Drawing.Size(80, 25)
$buttonBrowseSource.Font = New-Object System.Drawing.Font("微软雅黑", 9)
$buttonBrowseSource.BackColor = [System.Drawing.Color]::LightGray
$form.Controls.Add($buttonBrowseSource)

# 目标目录部分
$labelTarget = New-Object System.Windows.Forms.Label
$labelTarget.Text = "目标目录（实际内容所在位置）:"
$labelTarget.Location = New-Object System.Drawing.Point(20, 185)
$labelTarget.Size = New-Object System.Drawing.Size(400, 20)
$labelTarget.Font = New-Object System.Drawing.Font("微软雅黑", 9, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($labelTarget)

$textBoxTarget = New-Object System.Windows.Forms.TextBox
$textBoxTarget.Location = New-Object System.Drawing.Point(20, 210)
$textBoxTarget.Size = New-Object System.Drawing.Size(510, 20)
$textBoxTarget.Font = New-Object System.Drawing.Font("微软雅黑", 9)
$form.Controls.Add($textBoxTarget)

$buttonBrowseTarget = New-Object System.Windows.Forms.Button
$buttonBrowseTarget.Text = "浏览..."
$buttonBrowseTarget.Location = New-Object System.Drawing.Point(540, 208)
$buttonBrowseTarget.Size = New-Object System.Drawing.Size(80, 25)
$buttonBrowseTarget.Font = New-Object System.Drawing.Font("微软雅黑", 9)
$buttonBrowseTarget.BackColor = [System.Drawing.Color]::LightGray
$form.Controls.Add($buttonBrowseTarget)

# 选项部分
$groupBoxOptions = New-Object System.Windows.Forms.GroupBox
$groupBoxOptions.Text = "选项设置"
$groupBoxOptions.Location = New-Object System.Drawing.Point(20, 250)
$groupBoxOptions.Size = New-Object System.Drawing.Size(600, 120)
$groupBoxOptions.Font = New-Object System.Drawing.Font("微软雅黑", 9, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($groupBoxOptions)

$checkBoxOpenAfter = New-Object System.Windows.Forms.CheckBox
$checkBoxOpenAfter.Text = "创建后打开链接点目录"
$checkBoxOpenAfter.Location = New-Object System.Drawing.Point(15, 25)
$checkBoxOpenAfter.Size = New-Object System.Drawing.Size(200, 20)
$checkBoxOpenAfter.Checked = $true
$checkBoxOpenAfter.Font = New-Object System.Drawing.Font("微软雅黑", 9)
$groupBoxOptions.Controls.Add($checkBoxOpenAfter)

$checkBoxCopyContent = New-Object System.Windows.Forms.CheckBox
$checkBoxCopyContent.Text = "自动复制源目录内容到目标目录"
$checkBoxCopyContent.Location = New-Object System.Drawing.Point(15, 50)
$checkBoxCopyContent.Size = New-Object System.Drawing.Size(280, 20)
$checkBoxCopyContent.Checked = $true
$checkBoxCopyContent.Font = New-Object System.Drawing.Font("微软雅黑", 9)
$groupBoxOptions.Controls.Add($checkBoxCopyContent)

$checkBoxVerifyCopy = New-Object System.Windows.Forms.CheckBox
$checkBoxVerifyCopy.Text = "复制完成后验证文件完整性"
$checkBoxVerifyCopy.Location = New-Object System.Drawing.Point(15, 75)
$checkBoxVerifyCopy.Size = New-Object System.Drawing.Size(250, 20)
$checkBoxVerifyCopy.Checked = $true
$checkBoxVerifyCopy.Font = New-Object System.Drawing.Font("微软雅黑", 9)
$groupBoxOptions.Controls.Add($checkBoxVerifyCopy)

$checkBoxBackup = New-Object System.Windows.Forms.CheckBox
$checkBoxBackup.Text = "创建前备份目标目录（如存在）"
$checkBoxBackup.Location = New-Object System.Drawing.Point(300, 25)
$checkBoxBackup.Size = New-Object System.Drawing.Size(280, 20)
$checkBoxBackup.Checked = $false
$checkBoxBackup.Font = New-Object System.Drawing.Font("微软雅黑", 9)
$groupBoxOptions.Controls.Add($checkBoxBackup)

# 进度条
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(20, 380)
$progressBar.Size = New-Object System.Drawing.Size(600, 25)
$progressBar.Style = "Continuous"
$progressBar.Visible = $false
$form.Controls.Add($progressBar)

# 状态栏
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "就绪"
$statusLabel.Location = New-Object System.Drawing.Point(20, 410)
$statusLabel.Size = New-Object System.Drawing.Size(600, 20)
$statusLabel.Font = New-Object System.Drawing.Font("微软雅黑", 9)
$statusLabel.ForeColor = [System.Drawing.Color]::DarkGreen
$form.Controls.Add($statusLabel)

# 按钮区域
$buttonCreate = New-Object System.Windows.Forms.Button
$buttonCreate.Text = "创建目录联接"
$buttonCreate.Location = New-Object System.Drawing.Point(150, 440)
$buttonCreate.Size = New-Object System.Drawing.Size(140, 40)
$buttonCreate.Font = New-Object System.Drawing.Font("微软雅黑", 10, [System.Drawing.FontStyle]::Bold)
$buttonCreate.BackColor = [System.Drawing.Color]::FromArgb(70, 130, 180)
$buttonCreate.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($buttonCreate)

$buttonTest = New-Object System.Windows.Forms.Button
$buttonTest.Text = "分析目录"
$buttonTest.Location = New-Object System.Drawing.Point(300, 440)
$buttonTest.Size = New-Object System.Drawing.Size(100, 40)
$buttonTest.Font = New-Object System.Drawing.Font("微软雅黑", 9)
$buttonTest.BackColor = [System.Drawing.Color]::LightGray
$form.Controls.Add($buttonTest)

$buttonExit = New-Object System.Windows.Forms.Button
$buttonExit.Text = "退出"
$buttonExit.Location = New-Object System.Drawing.Point(410, 440)
$buttonExit.Size = New-Object System.Drawing.Size(90, 40)
$buttonExit.Font = New-Object System.Drawing.Font("微软雅黑", 9)
$buttonExit.BackColor = [System.Drawing.Color]::LightGray
$form.Controls.Add($buttonExit)

# 浏览源目录按钮事件
$buttonBrowseSource.Add_Click({
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = "选择链接点目录（新创建的联接点）"
    $folderBrowser.RootFolder = 'MyComputer'
    
    if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $textBoxSource.Text = $folderBrowser.SelectedPath
        $statusLabel.Text = "已选择链接点目录"
    }
})

# 浏览目标目录按钮事件
$buttonBrowseTarget.Add_Click({
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = "选择目标目录（实际内容所在位置）"
    $folderBrowser.RootFolder = 'MyComputer'
    
    if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $textBoxTarget.Text = $folderBrowser.SelectedPath
        $statusLabel.Text = "已选择目标目录"
    }
})

# 分析目录按钮事件
$buttonTest.Add_Click({
    $source = $textBoxSource.Text.Trim()
    $target = $textBoxTarget.Text.Trim()
    
    if ([string]::IsNullOrEmpty($source) -or [string]::IsNullOrEmpty($target)) {
        [System.Windows.MessageBox]::Show("请输入源目录和目标目录", "错误", 
            [System.Windows.MessageBoxButton]::OK, 
            [System.Windows.MessageBoxImage]::Warning)
        return
    }
    
    $analysis = "目录分析结果:`n`n"
    $totalSize = 0
    $fileCount = 0
    $dirCount = 0
    
    # 分析源目录
    if (Test-Path $source) {
        try {
            $sourceItem = Get-Item $source -Force -ErrorAction Stop
            $attr = $sourceItem.Attributes
            
            if ($attr -match "ReparsePoint") {
                $analysis += "链接点目录: 已存在（是一个重解析点/联接）`n"
            } else {
                $analysis += "链接点目录: 已存在（是一个普通目录）`n"
                
                # 计算目录大小和文件数量
                $files = Get-ChildItem -Path $source -File -Recurse -ErrorAction SilentlyContinue
                $dirs = Get-ChildItem -Path $source -Directory -Recurse -ErrorAction SilentlyContinue
                $fileCount = $files.Count
                $dirCount = $dirs.Count + 1  # 包括根目录
                
                foreach ($file in $files) {
                    $totalSize += $file.Length
                }
                
                $sizeMB = [math]::Round($totalSize / 1MB, 2)
                $analysis += "  包含: $fileCount 个文件, $dirCount 个目录`n"
                $analysis += "  大小: $sizeMB MB`n"
            }
        } catch {
            $analysis += "链接点目录: 无法访问（权限不足）`n"
        }
    } else {
        $analysis += "链接点目录: 不存在（将创建新联接点）`n"
    }
    
    # 分析目标目录
    if (Test-Path $target) {
        $targetItem = Get-Item $target -Force -ErrorAction SilentlyContinue
        if ($targetItem) {
            $attr = $targetItem.Attributes
            if ($attr -match "ReparsePoint") {
                $analysis += "目标目录: 存在（是一个重解析点/联接）`n"
            } else {
                $analysis += "目标目录: 存在（是一个普通目录）`n"
                
                # 检查目标目录是否为空
                $targetFiles = Get-ChildItem -Path $target -ErrorAction SilentlyContinue
                if ($targetFiles.Count -eq 0) {
                    $analysis += "  目录为空`n"
                } else {
                    $analysis += "  目录非空（包含 $($targetFiles.Count) 个条目）`n"
                }
            }
        }
    } else {
        $analysis += "目标目录: 不存在（将创建）`n"
    }
    
    # 显示建议
    $analysis += "`n建议操作: "
    if (Test-Path $source -and $fileCount -gt 0) {
        $analysis += "源目录存在且包含数据。启用'自动复制'选项可将内容迁移到目标目录。"
    } elseif (Test-Path $source) {
        $analysis += "源目录存在但为空，可以直接删除并创建联接。"
    } else {
        $analysis += "源目录不存在，可以直接创建联接。"
    }
    
    $statusLabel.Text = "目录分析完成"
    [System.Windows.MessageBox]::Show($analysis, "目录分析", 
        [System.Windows.MessageBoxButton]::OK, 
        [System.Windows.MessageBoxImage]::Information)
})

# 验证文件完整性
function Verify-CopyIntegrity {
    param(
        [string]$SourcePath,
        [string]$DestinationPath
    )
    
    try {
        $sourceFiles = Get-ChildItem -Path $SourcePath -File -Recurse | Select-Object FullName, Length, LastWriteTime
        $destFiles = Get-ChildItem -Path $DestinationPath -File -Recurse | Select-Object FullName, Length, LastWriteTime
        
        $sourceCount = $sourceFiles.Count
        $destCount = $destFiles.Count
        
        if ($sourceCount -ne $destCount) {
            return "文件数量不匹配: 源目录 $sourceCount 个文件, 目标目录 $destCount 个文件"
        }
        
        # 检查每个文件
        $errors = @()
        foreach ($sourceFile in $sourceFiles) {
            $relativePath = $sourceFile.FullName.Substring($SourcePath.Length)
            $destFilePath = Join-Path $DestinationPath $relativePath
            
            if (Test-Path $destFilePath) {
                $destFile = Get-Item $destFilePath -ErrorAction SilentlyContinue
                if ($destFile) {
                    if ($sourceFile.Length -ne $destFile.Length) {
                        $errors += "文件大小不匹配: $relativePath"
                    }
                } else {
                    $errors += "文件不存在: $relativePath"
                }
            } else {
                $errors += "文件不存在: $relativePath"
            }
        }
        
        if ($errors.Count -eq 0) {
            return "验证成功: 所有 $sourceCount 个文件已正确复制"
        } else {
            return "验证失败: `n" + ($errors -join "`n")
        }
    }
    catch {
        return "验证过程中发生错误: $_"
    }
}

# 创建目录联接按钮事件
$buttonCreate.Add_Click({
    $source = $textBoxSource.Text.Trim()
    $target = $textBoxTarget.Text.Trim()
    
    # 验证输入
    if ([string]::IsNullOrEmpty($source)) {
        [System.Windows.MessageBox]::Show("请输入链接点目录", "错误", 
            [System.Windows.MessageBoxButton]::OK, 
            [System.Windows.MessageBoxImage]::Warning)
        $statusLabel.Text = "错误：链接点目录不能为空"
        return
    }
    
    if ([string]::IsNullOrEmpty($target)) {
        [System.Windows.MessageBox]::Show("请输入目标目录", "错误", 
            [System.Windows.MessageBoxButton]::OK, 
            [System.Windows.MessageBoxImage]::Warning)
        $statusLabel.Text = "错误：目标目录不能为空"
        return
    }
    
    # 检查目标目录是否存在
    if (-not (Test-Path $target)) {
        $result = [System.Windows.MessageBox]::Show("目标目录不存在，是否创建？", "确认", 
            [System.Windows.MessageBoxButton]::YesNo, 
            [System.Windows.MessageBoxImage]::Question)
        
        if ($result -eq [System.Windows.MessageBoxResult]::Yes) {
            try {
                New-Item -ItemType Directory -Path $target -Force | Out-Null
                $statusLabel.Text = "已创建目标目录"
            } catch {
                [System.Windows.MessageBox]::Show("无法创建目标目录：$_", "错误", 
                    [System.Windows.MessageBoxButton]::OK, 
                    [System.Windows.MessageBoxImage]::Error)
                $statusLabel.Text = "错误：无法创建目标目录"
                return
            }
        } else {
            $statusLabel.Text = "操作已取消"
            return
        }
    }
    
    # 备份目标目录（如果选项启用且目标目录已存在且非空）
    if ($checkBoxBackup.Checked -and (Test-Path $target)) {
        $targetItems = Get-ChildItem -Path $target -ErrorAction SilentlyContinue
        if ($targetItems.Count -gt 0) {
            $backupPath = $target + "_备份_" + (Get-Date -Format "yyyyMMdd_HHmmss")
            try {
                Copy-Item -Path $target -Destination $backupPath -Recurse -Force -ErrorAction Stop
                $statusLabel.Text = "已创建备份: $backupPath"
                $form.Refresh()
            } catch {
                $result = [System.Windows.MessageBox]::Show("无法创建备份：$_`n是否继续？", "备份失败", 
                    [System.Windows.MessageBoxButton]::YesNo, 
                    [System.Windows.MessageBoxImage]::Warning)
                if ($result -ne [System.Windows.MessageBoxResult]::Yes) {
                    $statusLabel.Text = "操作已取消（备份失败）"
                    return
                }
            }
        }
    }
    
    # 检查源目录是否存在
    $copyPerformed = $false
    if (Test-Path $source) {
        # 检查是否是重解析点
        $attr = Get-Item $source -Force | Select-Object -ExpandProperty Attributes -ErrorAction SilentlyContinue
        
        if ($attr -match "ReparsePoint") {
            # 如果是重解析点，询问是否删除
            $result = [System.Windows.MessageBox]::Show("源目录是一个现有的联接点。是否删除并创建新的联接？", "确认", 
                [System.Windows.MessageBoxButton]::YesNo, 
                [System.Windows.MessageBoxImage]::Question)
            
            if ($result -eq [System.Windows.MessageBoxResult]::Yes) {
                try {
                    cmd.exe /c rmdir "`"$source`"" 2>$null
                    $statusLabel.Text = "已删除现有重解析点"
                } catch {
                    [System.Windows.MessageBox]::Show("无法删除现有重解析点：$_", "错误", 
                        [System.Windows.MessageBoxButton]::OK, 
                        [System.Windows.MessageBoxImage]::Error)
                    $statusLabel.Text = "错误：无法删除现有重解析点"
                    return
                }
            } else {
                $statusLabel.Text = "操作已取消"
                return
            }
        } else {
            # 如果是普通目录且包含内容
            $fileCount = (Get-ChildItem -Path $source -File -Recurse -ErrorAction SilentlyContinue).Count
            
            if ($fileCount -gt 0) {
                if ($checkBoxCopyContent.Checked) {
                    # 询问用户是否复制内容
                    $sizeMB = [math]::Round((Get-ChildItem -Path $source -Recurse -File | Measure-Object -Property Length -Sum).Sum / 1MB, 2)
                    $result = [System.Windows.MessageBox]::Show("源目录包含 $fileCount 个文件（约 $sizeMB MB）。`n是否复制这些文件到目标目录，然后删除源目录并创建联接？", "确认复制", 
                        [System.Windows.MessageBoxButton]::YesNo, 
                        [System.Windows.MessageBoxImage]::Question)
                    
                    if ($result -eq [System.Windows.MessageBoxResult]::Yes) {
                        # 禁用按钮，防止重复点击
                        $buttonCreate.Enabled = $false
                        $buttonTest.Enabled = $false
                        $buttonExit.Enabled = $false
                        
                        # 复制目录内容
                        $statusLabel.Text = "开始复制源目录内容..."
                        $form.Refresh()
                        
                        $copyResult = Copy-DirectoryWithProgress -SourcePath $source -DestinationPath $target -ProgressBar $progressBar -StatusLabel $statusLabel -Form $form
                        
                        if ($copyResult) {
                            $copyPerformed = $true
                            
                            # 验证复制完整性（如果选项启用）
                            if ($checkBoxVerifyCopy.Checked) {
                                $statusLabel.Text = "正在验证文件完整性..."
                                $form.Refresh()
                                $verifyResult = Verify-CopyIntegrity -SourcePath $source -DestinationPath $target
                                $statusLabel.Text = $verifyResult
                                $form.Refresh()
                                
                                if ($verifyResult -notlike "验证成功*") {
                                    $result = [System.Windows.MessageBox]::Show("$verifyResult`n`n是否继续删除源目录并创建联接？", "验证警告", 
                                        [System.Windows.MessageBoxButton]::YesNo, 
                                        [System.Windows.MessageBoxImage]::Warning)
                                    
                                    if ($result -ne [System.Windows.MessageBoxResult]::Yes) {
                                        # 重新启用按钮
                                        $buttonCreate.Enabled = $true
                                        $buttonTest.Enabled = $true
                                        $buttonExit.Enabled = $true
                                        $statusLabel.Text = "操作已取消（验证失败）"
                                        return
                                    }
                                }
                            }
                            
                            # 删除源目录
                            $statusLabel.Text = "正在删除源目录..."
                            $form.Refresh()
                            
                            try {
                                Remove-Item -Path $source -Recurse -Force -ErrorAction Stop
                                $statusLabel.Text = "已删除源目录"
                                $form.Refresh()
                            } catch {
                                [System.Windows.MessageBox]::Show("无法删除源目录：$_`n但文件已复制到目标目录。", "警告", 
                                    [System.Windows.MessageBoxButton]::OK, 
                                    [System.Windows.MessageBoxImage]::Warning)
                                $statusLabel.Text = "警告：无法删除源目录"
                            }
                        } else {
                            # 重新启用按钮
                            $buttonCreate.Enabled = $true
                            $buttonTest.Enabled = $true
                            $buttonExit.Enabled = $true
                            $statusLabel.Text = "复制失败，操作已取消"
                            return
                        }
                        
                        # 重新启用按钮
                        $buttonCreate.Enabled = $true
                        $buttonTest.Enabled = $true
                        $buttonExit.Enabled = $true
                    } else {
                        # 用户选择不复制
                        $result = [System.Windows.MessageBox]::Show("是否删除源目录并创建联接（不复制内容）？", "确认", 
                            [System.Windows.MessageBoxButton]::YesNo, 
                            [System.Windows.MessageBoxImage]::Question)
                        
                        if ($result -eq [System.Windows.MessageBoxResult]::Yes) {
                            try {
                                Remove-Item -Path $source -Recurse -Force -ErrorAction Stop
                                $statusLabel.Text = "已删除源目录（未复制内容）"
                            } catch {
                                [System.Windows.MessageBox]::Show("无法删除源目录：$_`n目录可能正在被使用。", "错误", 
                                    [System.Windows.MessageBoxButton]::OK, 
                                    [System.Windows.MessageBoxImage]::Error)
                                $statusLabel.Text = "错误：无法删除源目录"
                                return
                            }
                        } else {
                            $statusLabel.Text = "操作已取消"
                            return
                        }
                    }
                } else {
                    # 自动复制选项未启用
                    $result = [System.Windows.MessageBox]::Show("源目录存在且包含文件，但'自动复制'选项未启用。`n是否启用此选项并继续？", "选项建议", 
                        [System.Windows.MessageBoxButton]::YesNo, 
                        [System.Windows.MessageBoxImage]::Question)
                    
                    if ($result -eq [System.Windows.MessageBoxResult]::Yes) {
                        $checkBoxCopyContent.Checked = $true
                        # 重新触发点击事件
                        $buttonCreate.PerformClick()
                        return
                    } else {
                        $statusLabel.Text = "操作已取消"
                        return
                    }
                }
            } else {
                # 源目录存在但为空
                $result = [System.Windows.MessageBox]::Show("源目录存在但为空。是否删除并创建联接？", "确认", 
                    [System.Windows.MessageBoxButton]::YesNo, 
                    [System.Windows.MessageBoxImage]::Question)
                
                if ($result -eq [System.Windows.MessageBoxResult]::Yes) {
                    try {
                        Remove-Item -Path $source -Recurse -Force -ErrorAction Stop
                        $statusLabel.Text = "已删除空源目录"
                    } catch {
                        [System.Windows.MessageBox]::Show("无法删除源目录：$_", "错误", 
                            [System.Windows.MessageBoxButton]::OK, 
                            [System.Windows.MessageBoxImage]::Error)
                        $statusLabel.Text = "错误：无法删除源目录"
                        return
                    }
                } else {
                    $statusLabel.Text = "操作已取消"
                    return
                }
            }
        }
    }
    
    # 创建目录联接
    $statusLabel.Text = "正在创建目录联接..."
    $form.Refresh()
    
    try {
        # 使用cmd的mklink命令创建目录联接
        $output = cmd.exe /c "mklink /j `"$source`" `"$target`"" 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            $statusLabel.Text = "目录联接创建成功！"
            $statusLabel.ForeColor = [System.Drawing.Color]::DarkGreen
            
            # 显示成功消息
            $message = "目录联接创建成功！`n`n"
            $message += "链接点: $source`n"
            $message += "目标目录: $target`n"
            
            if ($copyPerformed) {
                $message += "`n已完成内容复制和迁移。"
            }
            
            [System.Windows.MessageBox]::Show($message, "成功", 
                [System.Windows.MessageBoxButton]::OK, 
                [System.Windows.MessageBoxImage]::Information)
            
            # 如果选项被选中，打开链接点目录
            if ($checkBoxOpenAfter.Checked) {
                if (Test-Path $source) {
                    Start-Process "explorer.exe" -ArgumentList $source
                }
            }
        } else {
            $statusLabel.Text = "创建目录联接失败"
            $statusLabel.ForeColor = [System.Drawing.Color]::DarkRed
            
            $errorMsg = "创建目录联接失败。错误信息：`n$output"
            [System.Windows.MessageBox]::Show($errorMsg, "错误", 
                [System.Windows.MessageBoxButton]::OK, 
                [System.Windows.MessageBoxImage]::Error)
        }
    } catch {
        $statusLabel.Text = "创建目录联接时发生异常"
        $statusLabel.ForeColor = [System.Drawing.Color]::DarkRed
        
        [System.Windows.MessageBox]::Show("创建目录联接时发生异常：$_", "错误", 
            [System.Windows.MessageBoxButton]::OK, 
            [System.Windows.MessageBoxImage]::Error)
    }
})

# 退出按钮事件
$buttonExit.Add_Click({
    $form.Close()
})

# 窗体加载事件
$form.Add_Load({
    # 检查管理员权限
    if (-not (Test-Administrator)) {
        $result = [System.Windows.MessageBox]::Show("创建目录联接需要管理员权限。是否以管理员身份重新运行？", "需要管理员权限", 
            [System.Windows.MessageBoxButton]::YesNo, 
            [System.Windows.MessageBoxImage]::Warning)
        
        if ($result -eq [System.Windows.MessageBoxResult]::Yes) {
            # 重新以管理员身份启动
            $scriptPath = $MyInvocation.MyCommand.Path
            $psi = New-Object System.Diagnostics.ProcessStartInfo
            $psi.FileName = "PowerShell"
            $psi.Arguments = "-ExecutionPolicy Bypass -File `"$scriptPath`""
            $psi.Verb = "runas"
            [System.Diagnostics.Process]::Start($psi) | Out-Null
            $form.Close()
        } else {
            $statusLabel.Text = "警告：无管理员权限，某些操作可能失败"
            $statusLabel.ForeColor = [System.Drawing.Color]::Orange
        }
    } else {
        $statusLabel.Text = "已以管理员身份运行"
    }
})

# 显示窗体
[void]$form.ShowDialog()