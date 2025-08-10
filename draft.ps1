$folderPath = "src\content\posts"

$mdFiles = Get-ChildItem -Path $folderPath -Filter "*.md" -Recurse -File

foreach ($file in $mdFiles) {
    $content = Get-Content -Path $file.FullName -Raw
    
    if ($content -imatch "draft\s*:\s*true") {
        # Print the full path of the matching file
        Write-Output $file.FullName
    }
}
