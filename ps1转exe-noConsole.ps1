# ConvertToExe.ps1

# 导入 ps2exe 模块
Import-Module ps2exe

# 获取当前目录下的所有 .ps1 文件
$scripts = Get-ChildItem -Path . -Filter *.ps1

# 遍历每个 .ps1 文件并转换为 .exe
foreach ($script in $scripts) {
    $outputExe = [System.IO.Path]::ChangeExtension($script.FullName, ".exe")
    
    Write-Host "Converting $($script.FullName) to $outputExe ..."
    
    # 使用 ps2exe 转换脚本
    Invoke-ps2exe -InputFile $script.FullName -OutputFile $outputExe -noConsole
    
    Write-Host "Conversion completed: $outputExe"
}

Write-Host "All .ps1 scripts have been converted to .exe files."