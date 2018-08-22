<?php

// Koel settings menu

$output_filename = "app_koel.html";

if (isset($_POST['submitmusic'])) {
    $musicfile = htmlspecialchars($_POST['musicfile']);
    if(file_exists($musicfile)) {
        $settings_file = fopen(".appsettings.txt", "w") or die("Unable to write to appsettings file");
        fwrite($settings_file, "koel,upload,".$musicfile);
        fclose($settings_file);
    }
}

$htmlfile = fopen("$output_filename", "r") or die("Unable to open $output_filename");
echo fread($htmlfile,filesize("$output_filename"));
fclose($htmlfile);

?>
