$repo = 'C:\Users\jaile\Downloads\KKOS_v5.2_Unified_Bundle'
$desktopPath = [Environment]::GetFolderPath('Desktop')
$launcher = Join-Path $repo 'desktop\KKOS_v5.2_Unified_Desktop.cmd'
$shortcutPath = Join-Path $repo 'desktop\KKOS v5.2 Unified Desktop.lnk'
$desktopShortcutPath = Join-Path $desktopPath 'KKOS v5.2 Unified Desktop.lnk'

$ws = New-Object -ComObject WScript.Shell
$shortcut = $ws.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $launcher
$shortcut.WorkingDirectory = Join-Path $repo 'desktop'
$shortcut.IconLocation = 'C:\Windows\System32\imageres.dll, 184'
$shortcut.WindowStyle = 7
$shortcut.Save()

$desktopShortcut = $ws.CreateShortcut($desktopShortcutPath)
$desktopShortcut.TargetPath = $launcher
$desktopShortcut.WorkingDirectory = Join-Path $repo 'desktop'
$desktopShortcut.IconLocation = 'C:\Windows\System32\imageres.dll, 184'
$desktopShortcut.WindowStyle = 7
$desktopShortcut.Save()

Write-Host "Created shortcut: $shortcutPath"
Write-Host "Created desktop shortcut: $desktopShortcutPath"
