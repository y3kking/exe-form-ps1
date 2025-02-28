# 嵌入 C# 代码以隐藏控制台窗口
Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    public class WindowHelper {
        [DllImport("kernel32.dll")]
        public static extern IntPtr GetConsoleWindow();
        [DllImport("user32.dll")]
        public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    }
"@

# 隐藏控制台窗口
$consolePtr = [WindowHelper]::GetConsoleWindow()
[WindowHelper]::ShowWindow($consolePtr, 0)  # 0 表示隐藏窗口

# 加载 Windows Forms 程序集
Add-Type -AssemblyName System.Windows.Forms

# 创建主窗体
$form = New-Object System.Windows.Forms.Form
$form.Text = "M3U8 下载器"
$form.Size = New-Object System.Drawing.Size(700, 400)
$form.MinimumSize = New-Object System.Drawing.Size(700, 400)  # 设置最小窗口大小
$form.StartPosition = "CenterScreen"  # 窗口居中显示

# 创建第一个输入框
$label1 = New-Object System.Windows.Forms.Label
$label1.Text = "URL:"
$label1.Location = New-Object System.Drawing.Point(10, 20)
$label1.AutoSize = $true
$form.Controls.Add($label1)

$input1 = New-Object System.Windows.Forms.TextBox
$input1.Location = New-Object System.Drawing.Point(60, 20)
$input1.Size = New-Object System.Drawing.Size(500, 20)
$form.Controls.Add($input1)

# 创建第一个粘贴按钮
$buttonPaste1 = New-Object System.Windows.Forms.Button
$buttonPaste1.Text = "粘贴"
$buttonPaste1.Location = New-Object System.Drawing.Point(570, 20)
$buttonPaste1.Size = New-Object System.Drawing.Size(80, 23)
$form.Controls.Add($buttonPaste1)

# 创建第二个输入框
$label2 = New-Object System.Windows.Forms.Label
$label2.Text = "文件名:"
$label2.Location = New-Object System.Drawing.Point(10, 60)
$label2.AutoSize = $true
$form.Controls.Add($label2)

$input2 = New-Object System.Windows.Forms.TextBox
$input2.Location = New-Object System.Drawing.Point(60, 60)
$input2.Size = New-Object System.Drawing.Size(400, 20)
$form.Controls.Add($input2)

# 创建第二个粘贴按钮
$buttonPaste2 = New-Object System.Windows.Forms.Button
$buttonPaste2.Text = "粘贴"
$buttonPaste2.Location = New-Object System.Drawing.Point(470, 60)
$buttonPaste2.Size = New-Object System.Drawing.Size(80, 23)
$form.Controls.Add($buttonPaste2)

# 创建文件名递增按钮
$buttonIncrement = New-Object System.Windows.Forms.Button
$buttonIncrement.Text = "+1"
$buttonIncrement.Location = New-Object System.Drawing.Point(570, 60)
$buttonIncrement.Size = New-Object System.Drawing.Size(80, 23)
$form.Controls.Add($buttonIncrement)

# 创建下载按钮
$buttonDownload = New-Object System.Windows.Forms.Button
$buttonDownload.Text = "开始下载"
$buttonDownload.Location = New-Object System.Drawing.Point(60, 100)
$buttonDownload.Size = New-Object System.Drawing.Size(100, 30)
$form.Controls.Add($buttonDownload)

# 创建列表控件
$listView = New-Object System.Windows.Forms.ListView
$listView.Location = New-Object System.Drawing.Point(10, 150)
$listView.Size = New-Object System.Drawing.Size(660, 180)
$listView.View = [System.Windows.Forms.View]::Details
$listView.FullRowSelect = $true
$listView.Columns.Add("文件名", 200)
$listView.Columns.Add("URL", 440)
$form.Controls.Add($listView)

# 第一个粘贴按钮点击事件
$buttonPaste1.Add_Click({
    # 获取剪贴板内容
    $clipboardText = [System.Windows.Forms.Clipboard]::GetText()
    # 替换输入框内容
    $input1.Text = $clipboardText
})

# 第二个粘贴按钮点击事件
$buttonPaste2.Add_Click({
    # 获取剪贴板内容
    $clipboardText = [System.Windows.Forms.Clipboard]::GetText()
    # 替换输入框内容
    $input2.Text = $clipboardText
})

# 文件名递增按钮点击事件
$buttonIncrement.Add_Click({
    $currentName = $input2.Text
    if ($currentName -match '(\d+)$') {
        # 如果文件名以数字结尾，则递增数字
        $number = [int]$matches[1] + 1
        $newName = $currentName -replace '\d+$', $number
    } else {
        # 如果文件名不以数字结尾，则添加 _1
        $newName = "$currentName`_1"
    }
    $input2.Text = $newName
})

# 下载按钮点击事件
$buttonDownload.Add_Click({
    $param1 = $input1.Text
    $param2 = $input2.Text

    # 构建命令
    $command = "Start-Process -FilePath `"N_m3u8DL-RE.exe`" -ArgumentList `"`"$param1`"`", `"-mt`", `"-M`", `"mp4`", `"--save-name`", `"`"$param2`"`""

    # 记录日志
    $logEntry = "————————————————————`n$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n$command`n"
    Add-Content -Path ".\log.txt" -Value $logEntry

    # 执行命令
    Start-Process -FilePath "N_m3u8DL-RE.exe" -ArgumentList "`"$param1`"", "-mt", "-M", "mp4", "--save-name", "`"$param2`""

    # 将下载记录添加到列表
    $item = New-Object System.Windows.Forms.ListViewItem($param2)
    $item.SubItems.Add($param1)
    $listView.Items.Add($item)
})

# 列表点击事件
$listView.Add_Click({
    if ($listView.SelectedItems.Count -gt 0) {
        $selectedItem = $listView.SelectedItems[0]
        $input1.Text = $selectedItem.SubItems[1].Text  # URL
        $input2.Text = $selectedItem.Text  # 文件名
    }
})

# 窗口大小变化事件
$form.Add_Resize({
    # 调整输入框和按钮的宽度
    $input1.Width = $form.ClientSize.Width - 140
    $input2.Width = $form.ClientSize.Width - 240
    $buttonPaste1.Left = $form.ClientSize.Width - 90
    $buttonPaste2.Left = $form.ClientSize.Width - 190
    $buttonIncrement.Left = $form.ClientSize.Width - 90

    # 调整列表控件的大小
    $listView.Width = $form.ClientSize.Width - 20
    $listView.Height = $form.ClientSize.Height - 170
    $listView.Columns[1].Width = $listView.Width - 220  # 动态调整 URL 列宽度
})

# 显示窗体
$form.ShowDialog()