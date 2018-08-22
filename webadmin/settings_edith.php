<?php

// Edith settings menu

$output_filename = "app_edith.html";

if (isset($_POST['submitenablepassword'])) {
    $password = trim(htmlspecialchars($_POST['edith_password']));
    $password_enabled = '0';
    if (preg_match('/^[a-z\A-Z\d_]{8,512}$/', $password)) {
        $password_enabled = '1';
    }

    $settings_file = fopen(".appsettings.txt", "w") or die("Unable to write to appsettings file");
    fwrite($settings_file, "edith,enablepassword,".$password);
    fclose($settings_file);
}

$htmlfile = fopen("$output_filename", "r") or die("Unable to open $output_filename");
echo fread($htmlfile,filesize("$output_filename"));
fclose($htmlfile);

?>
