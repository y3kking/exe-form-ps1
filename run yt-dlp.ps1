Add-Type @"
using System; 
using System.Runtime.InteropServices; 
public class Window { 
    [DllImport("kernel32.dll")] 
    static extern IntPtr GetConsoleWindow(); 
    [DllImport("user32.dll")] 
    static extern bool ShowWindow(IntPtr hWnd, int nCmdShow); 
    public static void Hide() { 
        ShowWindow(GetConsoleWindow(), 0); 
    }
} 
"@
[Window]::Hide()

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# 主窗口
$mainForm = New-Object System.Windows.Forms.Form
$mainForm.Text = "视频下载器"
$mainForm.Size = New-Object System.Drawing.Size(600, 300)

# 视频链接输入框
$urlLabel = New-Object System.Windows.Forms.Label
$urlLabel.Text = "视频链接:"
$urlLabel.Location = New-Object System.Drawing.Point(10, 20)
$urlLabel.Size = New-Object System.Drawing.Size(80, 20)
$mainForm.Controls.Add($urlLabel)

$urlTextBox = New-Object System.Windows.Forms.TextBox
$urlTextBox.Location = New-Object System.Drawing.Point(100, 20)
$urlTextBox.Size = New-Object System.Drawing.Size(350, 20)
$mainForm.Controls.Add($urlTextBox)

# 解析按钮
$parseButton = New-Object System.Windows.Forms.Button
$parseButton.Text = "解析"
$parseButton.Location = New-Object System.Drawing.Point(460, 20)
$parseButton.Size = New-Object System.Drawing.Size(100, 20)
$parseButton.Add_Click({
    $url = $urlTextBox.Text.Trim()
    if ($url -ne "") {
        Start-Process cmd -ArgumentList "/k yt-dlp --cookies-from-browser firefox --list-formats `"$url`" && echo 请在此窗口查看格式后关闭"
    } else {
        [System.Windows.Forms.MessageBox]::Show("请输入视频链接", "错误", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})
$mainForm.Controls.Add($parseButton)

# 文件名输入框
$filenameLabel = New-Object System.Windows.Forms.Label
$filenameLabel.Text = "文件名:"
$filenameLabel.Location = New-Object System.Drawing.Point(10, 60)
$filenameLabel.Size = New-Object System.Drawing.Size(80, 20)
$mainForm.Controls.Add($filenameLabel)

$filenameTextBox = New-Object System.Windows.Forms.TextBox
$filenameTextBox.Location = New-Object System.Drawing.Point(100, 60)
$filenameTextBox.Size = New-Object System.Drawing.Size(460, 20)
$mainForm.Controls.Add($filenameTextBox)

# 格式选择
$formatLabel = New-Object System.Windows.Forms.Label
$formatLabel.Text = "格式选择:"
$formatLabel.Location = New-Object System.Drawing.Point(10, 100)
$formatLabel.Size = New-Object System.Drawing.Size(80, 20)
$mainForm.Controls.Add($formatLabel)

$formatRadio1 = New-Object System.Windows.Forms.RadioButton
$formatRadio1.Text = "137+140"
$formatRadio1.Location = New-Object System.Drawing.Point(100, 100)
$formatRadio1.Size = New-Object System.Drawing.Size(100, 20)
$mainForm.Controls.Add($formatRadio1)

$formatRadio2 = New-Object System.Windows.Forms.RadioButton
$formatRadio2.Text = "399+140"
$formatRadio2.Location = New-Object System.Drawing.Point(210, 100)
$formatRadio2.Size = New-Object System.Drawing.Size(100, 20)
$mainForm.Controls.Add($formatRadio2)

$formatTextBox = New-Object System.Windows.Forms.TextBox
$formatTextBox.Location = New-Object System.Drawing.Point(320, 100)
$formatTextBox.Size = New-Object System.Drawing.Size(240, 20)
$formatTextBox.PlaceholderText = "自定义格式"
$mainForm.Controls.Add($formatTextBox)

# 生成按钮
$generateButton = New-Object System.Windows.Forms.Button
$generateButton.Text = "生成 BAT 文件"
$generateButton.Location = New-Object System.Drawing.Point(100, 140)
$generateButton.Size = New-Object System.Drawing.Size(150, 30)
$generateButton.Add_Click({
    $url = $urlTextBox.Text.Trim()
    $filename = $filenameTextBox.Text.Trim()
    $format = if ($formatRadio1.Checked) { "137+140" } elseif ($formatRadio2.Checked) { "399+140" } else { $formatTextBox.Text.Trim() }

    if ($url -eq "" -or $filename -eq "" -or $format -eq "") {
        [System.Windows.Forms.MessageBox]::Show("请填写所有字段", "错误", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }

    $batContent = @"
yt-dlp --cookies-from-browser firefox -f $format -o "$filename.%%(ext)s" --merge-output-format mp4 "$url"
"@

    $batFilePath = "$PWD\$filename.bat"
    # 使用 ANSI 编码保存 BAT 文件
    $batContent | Out-File -FilePath $batFilePath -Encoding Default

    $logFilePath = "$PWD\log.txt"
    $logEntry = @"
$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
$batContent
————————————————————————————————————————————
"@
    # 使用 UTF-8 编码保存日志文件
    $logEntry | Out-File -FilePath $logFilePath -Encoding UTF8 -Append

    [System.Windows.Forms.MessageBox]::Show("BAT 文件已生成: $batFilePath", "成功", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
})
$mainForm.Controls.Add($generateButton)

# 下载按钮
$downloadButton = New-Object System.Windows.Forms.Button
$downloadButton.Text = "下载"
$downloadButton.Location = New-Object System.Drawing.Point(260, 140)
$downloadButton.Size = New-Object System.Drawing.Size(150, 30)
$downloadButton.Add_Click({
    $url = $urlTextBox.Text.Trim()
    $filename = $filenameTextBox.Text.Trim()
    $format = if ($formatRadio1.Checked) { "137+140" } elseif ($formatRadio2.Checked) { "399+140" } else { $formatTextBox.Text.Trim() }

    if ($url -eq "" -or $filename -eq "" -or $format -eq "") {
        [System.Windows.Forms.MessageBox]::Show("请填写所有字段", "错误", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }

    $command = "yt-dlp --cookies-from-browser firefox -f $format -o `"$filename.%(ext)s`" --merge-output-format mp4 `"$url`""
    
    # 记录日志
    $logFilePath = "$PWD\log.txt"
    $logEntry = @"
$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
$command
————————————————————————————————————————————
"@
    $logEntry | Out-File -FilePath $logFilePath -Encoding UTF8 -Append

    # 调用 yt-dlp 进行下载
    Start-Process cmd -ArgumentList "/k $command && echo 下载完成，窗口将在3秒后自动关闭 && timeout /t 3"
})
$mainForm.Controls.Add($downloadButton)

# 显示主窗口
$mainForm.ShowDialog()