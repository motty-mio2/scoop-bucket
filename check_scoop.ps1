param(
    [String] $repo = $(Split-Path -Parent $MyInvocation.MyCommand.Definition).ToString(),
    [String] $SCOOP_HOME = "~/scoop/apps/scoop/current"
)

$pattern = "(?<name>.*?): (?<new_ver>[0-9a-zA-Z.-]*) \(scoop version is (?<old_ver>[0-9a-zA-Z.-]*)\) autoupdate available"

function create_pr {
    param (
        [string]$app_name, [string]$old_version, [string]$new_version, [switch]$draft = $false
    )
    $pr_title = "${app_name}: update to ${new_version}"
    $pr_body = "${app_name}: update to ${new_version}"
    $branch = "update/$app_name/v$new_version"


    $branch_list = git branch | Out-String
    if ( ! $branch_list.Contains( $branch) ) {

        git checkout -b $branch
        powershell -noprofile -file "$(Convert-Path $SCOOP_HOME/bin/checkver.ps1)" -Dir $repo -App $app_name -u

        if ($app_name -eq "verible") {
            $target_file = Convert-Path "$PSScriptRoot/scoop/verible.json"
            $old_pat = '"extract_dir": "verible-v(.*)-win64",'
            $new_pat = '\"version\": \"(.*)\",'

            $new_version = Select-String -Path "$target_file" -Pattern $new_pat | ForEach-Object { $_.Matches.Groups[1].Value }
            $old_version = Select-String -Path "$target_file" -Pattern $old_pat | ForEach-Object { $_.Matches.Groups[1].Value }

            $new_content = (Get-Content $target_file) -replace "$old_version", "$new_version"
            $new_content | Set-Content $target_file
        }

        git commit -a -m "$pr_title"
        git push --set-upstream origin $branch

        if ($draft) {
            gh pr create -d -t $pr_title -b $pr_body
        }
        else {
            gh pr create  -t $pr_title -b $pr_body
        }

        git clean -f
    }
}


$output = powershell -noprofile -file "$(Convert-Path $SCOOP_HOME/bin/checkver.ps1)" -Dir $repo
Write-Output $output

Set-Location $repo

foreach ($line in $output) {
    $tmp = Select-String -InputObject $line -Pattern $pattern -AllMatches


    if ($tmp.Matches.Length -gt 0) {
        $match = $tmp.Matches[0]

        create_pr -app_name $match.Groups["name"].Value -old_version $match.Groups["old_ver"].Value -new_version $match.Groups["new_ver"].Value
    }
    git checkout main
}
