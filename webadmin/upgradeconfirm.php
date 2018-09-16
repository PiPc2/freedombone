<?php

// Confirm manual upgrade

$output_filename = "settings.html";

if (isset($_POST['submitupgradesettings'])) {
    $output_filename = "settings_updates.html";
}

if (isset($_POST['upgradeconfirmsubmit'])) {
    if(isset($_POST['upgradeconfirm'])) {
        $confirm = htmlspecialchars($_POST['upgradeconfirm']);

        if($confirm == "1") {
            $upgrade_file = fopen(".upgrade.txt", "w") or die("Unable to write to upgrade file");
            fwrite($upgrade_file, "upgrade");
            fclose($upgrade_file);

            $output_filename = "upgrade.html";
        }
    }
}

$htmlfile = fopen("$output_filename", "r") or die("Unable to open $output_filename");
echo fread($htmlfile,filesize("$output_filename"));
fclose($htmlfile);

?>
