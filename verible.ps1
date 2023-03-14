$target_file = Convert-Path "$PSScriptRoot/scoop/verible.json"

$old_pat = '"extract_dir": "verible-v(.*)-win64",'
$new_pat = '\"version\": \"(.*)\",'

$new_version = Select-String -Path "$target_file" -Pattern $new_pat | ForEach-Object { $_.Matches.Groups[1].Value }
$old_version = Select-String -Path "$target_file" -Pattern $old_pat | ForEach-Object { $_.Matches.Groups[1].Value }


$new_content = (Get-Content $target_file) -replace "$old_version", "$new_version"
$new_content | Set-Content $target_file
