# 获取当前的执行策略
$currentPolicy = Get-ExecutionPolicy

# 显示当前执行策略
Write-Host "当前的执行策略是: $currentPolicy"

# 判断当前策略并提示用户是否切换
if ($currentPolicy -eq "Restricted") {
    $newPolicy = "RemoteSigned"
    Write-Host "当前策略是 Restricted，是否切换到 RemoteSigned？ (y/n)"
} elseif ($currentPolicy -eq "RemoteSigned") {
    $newPolicy = "Restricted"
    Write-Host "当前策略是 RemoteSigned，是否切换到 Restricted？ (y/n)"
} else {
    Write-Host "当前策略既不是 Restricted 也不是 RemoteSigned，脚本结束。"
    exit
}

# 获取用户输入
$userInput = Read-Host

# 判断用户输入
if ($userInput -eq "y") {
    # 切换执行策略
    Set-ExecutionPolicy -ExecutionPolicy $newPolicy -Scope CurrentUser -Force
    Write-Host "执行策略已更改为: $newPolicy"
} else {
    Write-Host "未更改执行策略。"
}