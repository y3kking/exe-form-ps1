# 获取第一个输入框的内容
$input1 = Read-Host "请输入第一个参数"
# 获取第二个输入框的内容
$input2 = Read-Host "请输入第二个参数"
# 执行cmd命令并传递参数
cmd.exe /c "mklink /j `"$input1`" `"$input2`""

