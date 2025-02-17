[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$Pp 
)
 
$patterns = $Pp -split " "
$script:ConfigFile = "pack-config.json" 
$currentPath = Get-Location
$currentDate = Get-Date -Format "yyyy-MM-dd"
$packagePath = Join-Path -Path $currentPath -ChildPath $currentDate

 
function Get-Projects {
    try {
        $config = Get-Content $script:ConfigFile | ConvertFrom-Json 
        return $config.Projects 
    } catch {
        Write-Error "Failed to load configuration file: $_"
        exit 1 
    }
}
 
function Get-MatchingProjects($projects, $patterns) {
    $matchingProjects = @()
    foreach ($pattern in $patterns) {
        $matchingProjects += $projects | Where-Object { $_.Name -like "*$pattern*" }
    }
    return $matchingProjects
}
 
function Remove-Directory($directoryPath) {
    # 检查目录是否存在，存在则删除
    try {
        if (Test-Path $directoryPath) {
            Remove-Item -Path $directoryPath -Recurse -Force
            Write-Output "Removed directory: $directoryPath"
        } else {
            Write-Output "Directory does not exist: $directoryPath"
        }
    } catch {
        throw "Error removing directory: $_"
    }
}

 
function Write-Log($message) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $message" | Add-Content -Path $script:LogFile 
}
 
try {
    # 加载项目配置 
    $projects = Get-Projects 
 
    # 获取匹配的项目 
    $matchingProjects = Get-MatchingProjects $projects $patterns 
 
    if ($matchingProjects.Count -eq 0) {
        Write-Error "No projects found matching pattern: $($patterns -join ", ")"
        exit 1 
    }
    Write-Output "Found $($matchingProjects.Count) projects: $($patterns -join ", ") in config $script:ConfigFile"
 
    # 清空打包目录
    Remove-Directory $packagePath

    $jobs = @()
    $throttleLimit = 6 # 设置最大并行数
    foreach ($project in $matchingProjects) {
        $jobs += Start-Job -Name $project.Name -InitializationScript {
            function Invoke-Command($command, $projectName) {
                try {
                    $output = Invoke-Expression $command 2>&1 
                    # 执行powershell表达式时，$LASTEXITCODE不会被设置，因此使用$?来判断是否执行成功
                    # if ($LASTEXITCODE -ne 0) { 
                    if (!$?) {
                        throw "Command failed with exit code $LASTEXITCODE. Output: $output"
                    }
                    return $output 
                } catch {
                    throw "Error executing command: $_"
                }
            }
            function Move-BuildOutput($sourcePattern, $projectName) {
                try {
                    if (-not (Test-Path $packagePath)) {
                        New-Item -ItemType Directory -Path $packagePath -Force | Out-Null 
                    }
                    Copy-Item -Path $sourcePattern -Destination $packagePath -Recurse -Force 
                } catch {
                    throw "Error moving build output: $_"
                }
            }

        } -ScriptBlock {
            param($project, $packagePath)
            try {
                # 执行打包命令 
                foreach ($command in $project.BuildCommands) {
                    Invoke-Command $command $($project.Name)
                }
    
                # 根据配置文件中的type字段移动打包输出
                if ($project.Type -eq "java") {
                    Move-BuildOutput .\target\*.jar $($project.Name)
                } elseif ($project.Type -eq "vue") {
                    Move-BuildOutput .\$($project.DistName) $($project.Name)
                } else {
                    throw "Unknown project type: $($project.Type)"
                }
    
            } catch {
                throw "Error building project $($project.Name): $_"
            }
        } -ArgumentList $project, $packagePath -ThrottleLimit $throttleLimit
    }

    # 等待所有任务完成
    $jobs | ForEach-Object { 
        $job = $_
        $job | Wait-Job
        $job | Receive-Job

        if ($job.State -ne "Completed") {
            Write-Error "Job $($job.Name) failed with state $($job.State)"
        }
    }

    # 将$packagePath目录压缩为zip文件
    if (Test-Path $packagePath) {
        $zipFilePath = Join-Path -Path $currentPath -ChildPath "$currentDate.zip"
        Compress-Archive -Path $packagePath -DestinationPath $zipFilePath -Force
        Write-Log "Compressed $packagePath to $zipFilePath"
    } else {
        throw "All package failed!"
    }

    Set-Location $currentPath
 
} catch {
    Write-Error $_ 
    exit 1 
}