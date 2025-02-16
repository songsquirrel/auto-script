[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$Pp 
)
 
$patterns = $Pp -split " "
$script:ConfigFile = "pack-config.json" 
$currentPath = Get-Location
$currentDate = Get-Date -Format "yyyy-MM-dd"
$script:LogFile = Join-Path -Path $currentPath -ChildPath "build.log"
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
 
function Invoke-Command($command, $projectName) {
    Write-Log "Executing command for $projectName : $command"
    try {
        $output = Invoke-Expression $command 2>&1 
        # 执行powershell表达式时，$LASTEXITCODE不会被设置，因此使用$?来判断是否执行成功
        # if ($LASTEXITCODE -ne 0) { 
        if (!$?) {
            throw "Command failed with exit code $LASTEXITCODE. Output: $output"
        }
        return $output 
    } catch {
        Write-Log "Error executing command: $_"
        throw "Error executing command: $_"
    }
}

function Remove-Directory($directoryPath) {
    # 检查目录是否存在，存在则删除
    try {
        if (Test-Path $directoryPath) {
            Remove-Item -Path $directoryPath -Recurse -Force
            Write-Log "Removed directory: $directoryPath"
        } else {
            Write-Log "Directory does not exist: $directoryPath"
        }
    } catch {
        Write-Log "Error removing directory: $_"
        throw "Error removing directory: $_"
    }
}
 
function Move-BuildOutput($sourcePattern, $projectName) {
    try {
        if (-not (Test-Path $packagePath)) {
            New-Item -ItemType Directory -Path $packagePath -Force | Out-Null 
        }
        Copy-Item -Path $sourcePattern -Destination $packagePath -Recurse -Force 
        Write-Log "Build output for $projectName moved to $packagePath"
    } catch {
        throw "Error moving build output: $_"
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
    Write-Output "Found projects: $($patterns -join ", ")"
    Write-Log "Found $($matchingProjects.Count) projects matching pattern: $($patterns -join ", ") \n $($matchingProjects -join ", ")"
 
    # 清空打包目录
    Remove-Directory $packagePath

    foreach ($project in $matchingProjects) {
        try {
            Write-Output "Building project: $($project.Name)"
            Write-Log "Starting build for project: $($project.Name)"
            
            # 执行打包命令 
            foreach ($command in $project.BuildCommands) {
                Invoke-Command $command $($project.Name)
            }

            # 根据配置文件中的type字段移动打包输出
            if ($project.Type -eq "java") {
                Move-BuildOutput .\target\*.jar $($project.Name)
            } elseif ($project.Type -eq "vue") {
                Move-BuildOutput .\$($project.OutputDir) $($project.Name)
            } else {
                Write-Error "Unknown project type: $($project.Type)"
                exit 1
            }
 
            Write-Log "Successfully built and moved output for project: $($project.Name)"
        } catch {
            Write-Log "Error building project $($project.Name): $_"
            throw 
        }
    }

    # 将$packagePath目录压缩为zip文件
    $zipFilePath = Join-Path -Path $currentPath -ChildPath "$currentDate.zip"
    Compress-Archive -Path $packagePath -DestinationPath $zipFilePath -Force
    Write-Log "Compressed $packagePath to $zipFilePath"

    cd $currentPath
 
} catch {
    Write-Error $_ 
    exit 1 
}