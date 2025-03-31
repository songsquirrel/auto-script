# 注意：需以管理员身份运行
# 读取当前系统 PATH 变量
$oldPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")

# 设置 JAVA_HOME 和 MAVEN_HOME 变量
$javaHome = "H:\develop\jdk-21"
$mavenHome = "H:\develop\apache-maven-3.9.9"

[System.Environment]::SetEnvironmentVariable("JAVA_HOME", $javaHome, "Machine")
[System.Environment]::SetEnvironmentVariable("MAVEN_HOME", $mavenHome, "Machine")

# 追加 Java 和 Maven 的 bin 目录到 PATH
$newPath = "$oldPath;$javaHome\bin;$mavenHome\bin"
[System.Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")

# 重新启动 PowerShell 或运行 `refreshenv` 使修改生效
