<?php

// Change settings for updates

$output_filename = "reset.html";

if (isset($_POST['submitsettingsupdates'])) {
    $enable = htmlspecialchars($_POST['enable_updates']);
    $repo = htmlspecialchars($_POST['updates_repo']);
    $branch = htmlspecialchars($_POST['updates_branch']);

    $updates_file = fopen(".settingsupdates.txt", "w") or die("Unable to create settingsupdates file");
    fwrite($updates_file, $enable.','.$repo.','.$branch);
    fclose($updates_file);

    $output_filename = "settings_updates_confirm.html";
}

$htmlfile = fopen("$output_filename", "r") or die("Unable to open $output_filename");
echo fread($htmlfile,filesize("$output_filename"));
fclose($htmlfile);

?>
