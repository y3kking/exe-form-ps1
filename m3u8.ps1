# 弹出第一个输入框
$input1 = Read-Host "请输入第一个参数"

# 弹出第二个输入框
$input2 = Read-Host "请输入第二个参数"

# 创建并启动进程
Start-Process -FilePath "N_m3u8DL-RE.exe" -ArgumentList "`"$input1`"", "-mt", "-M", "mp4", "--save-name", "`"$input2`""
