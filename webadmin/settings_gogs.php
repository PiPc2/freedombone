<?php

// Gogs settings menu

$output_filename = "app_gogs.html";

if (isset($_POST['submitallowregistrations'])) {
    $confirm = htmlspecialchars($_POST['allowregistrations']);
    $settings_file = fopen(".appsettings.txt", "w") or die("Unable to write to appsettings file");
    fwrite($settings_file, "gogs,registration,".$confirm);
    fclose($settings_file);
}

$htmlfile = fopen("$output_filename", "r") or die("Unable to open $output_filename");
echo fread($htmlfile,filesize("$output_filename"));
fclose($htmlfile);

?>
