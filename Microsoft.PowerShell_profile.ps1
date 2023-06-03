# Beautiful powerline-style prompt written in pure PowerShell, simple and very fast.
#
# Author  : Yuri Plashenkov
# Github  : https://github.com/plashenkov/powerline.ps1
# License : MIT License

function prompt {
  # Options

  $hostText           = [Environment]::UserName + "@" + $(hostname)
  $hostBgColor        = 12      # all colors can be in R,G,B format as well as single color number
  $hostTextColor      = 231
  $hostBold           = $true
  $pathBgColor        = 240
  $pathTextColor      = 252
  $pathSeparatorColor = 245
  $pathBold           = $false
  $decoratePath       = $true   # use powerline  separators instead of traditional path separators + other customizations
  $driveBgColor       = 237
  $driveTextColor     = 231
  $driveBold          = $true
  $tildeHome          = $true   # show ~ when in home directory
  $tildeShowDrive     = $false  # only for Windows, only when tildeHome = true and decoratePath = true
  $maxFolders         = 4       # shorten too long path by showing only last N segments. 0 or $false means do not shorten

  if (isAdmin) {
    $hostBgColor      = 88      # customize values for admin here
  }

  # Algorithm

  $path = Convert-Path(Get-Location)
  $pathSeparator = [IO.Path]::DirectorySeparatorChar
  $isWindows = $pathSeparator -eq "\"

  if ($tildeHome -and $path.StartsWith($HOME)) {
    $path = "~" + $path.Substring($HOME.Length)
    if ($tildeShowDrive -and $decoratePath -and $isWindows) {
      $path = $HOME.Split("\")[0] + "\" + $path
    }
  }

  $isNetworkPath = $path.StartsWith("\\")
  $path = $path.Trim($pathSeparator).Split($pathSeparator)

  if ($maxFolders) {
    if ($isWindows) {
      if ($path.Length -gt $maxFolders + 1) {
        $path = $path[0],"..." + $path[-$maxFolders..-1]
      }
    } elseif ($path.Length -gt $maxFolders) {
      $path = ,"..." + $path[-$maxFolders..-1]
    }
  }

  Write-Host ""
  formatText " $hostText " $hostTextColor $hostBgColor $hostBold

  if ($decoratePath) {
    if ($isNetworkPath) {
      $path[0] = "\\" + $path[0]
    }
    $drive = $path[0]
    if ($isWindows -and -not $drive.StartsWith("~") -and ($driveBgColor -ne $pathBgColor)) {
      formatText " " $hostBgColor $driveBgColor
      formatText "$drive " $driveTextColor $driveBgColor $driveBold
      if ($path.Length -eq 1) {
        formatText " " $driveBgColor
        return " "
      }
      $path = $path[1..($path.Length - 1)]
      formatText " " $driveBgColor $pathBgColor
    } else {
      formatText " " $hostBgColor $pathBgColor
    }

    for ($i = 0; $i -lt $path.Length; $i++) {
      if ($i -ne 0) {
        formatText "  " $pathSeparatorColor $pathBgColor
      }
      formatText $path[$i] $pathTextColor $pathBgColor $pathBold
    }
  } else {
    formatText " " $hostBgColor $pathBgColor
    for ($i = 0; $i -lt $path.Length; $i++) {
      if ($i -ne 0) {
        formatText $pathSeparator $pathSeparatorColor $pathBgColor $pathBold
      } elseif ($isNetworkPath) {
        formatText "\\" $pathSeparatorColor $pathBgColor $pathBold
      }
      formatText $path[$i] $pathTextColor $pathBgColor $pathBold
    }
  }

  formatText " " $pathTextColor $pathBgColor
  formatText "" $pathBgColor
  return " "
}

function isAdmin {
  $principal = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent())
  return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function formatText($text, $textColor = $null, $bgColor = $null, $bold = $false) {
  $result = "$([char]27)["
  $result += if ($bold) {"1"} else {"0"}
  if ($bgColor) {
    $result += if ($bgColor -is [array]) {";48;2;$($bgColor -join ";")"} else {";48;5;$bgColor"}
  }
  if ($textColor) {
    $result += if ($textColor -is [array]) {";38;2;$($textColor -join ";")"} else {";38;5;$textColor"}
  }
  $result += "m$text"
  Write-Host $result -NoNewline
}
