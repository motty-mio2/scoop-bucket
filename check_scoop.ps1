# svls: 0.2.7 (scoop version is 0.2.6) autoupdate available
param(
    [String] $repo = "~/Projects/mio2_bucket",
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
    git checkout main
    $tmp = Select-String -InputObject $line -Pattern $pattern -AllMatches
    if ($tmp.Matches.Length) {
        $match = $tmp.Matches[0]

        create_pr -app_name $match.Groups["name"].Value -old_version $match.Groups["old_ver"].Value -new_version $match.Groups["new_ver"].Value -draft $true
    }
}

