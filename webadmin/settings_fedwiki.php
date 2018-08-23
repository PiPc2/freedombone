<?php

// Fedwiki settings menu

$output_filename = "settings_fedwiki.html";

if (isset($_POST['submitfedwikipassword'])) {
    $pass = trim(htmlspecialchars($_POST['fedwiki_password']));
    if (strpos($pass, ' ') === false) {
        if (preg_match('/^[a-z\A-Z\d_]{8,512}$/', $pass)) {
            $settings_file = fopen(".appsettings.txt", "w") or die("Unable to write to appsettings file");
            fwrite($settings_file, "fedwiki,password,".$pass);
            fclose($settings_file);
        }
        else {
            $output_filename = "invalid_password.html";
        }
    }
    else {
        $output_filename = "invalid_password.html";
    }
}

if (isset($_POST['submitfavicon'])) {
    $url = trim(htmlspecialchars($_POST['favicon_url']));
    if (strpos($url, ' ') === false) {
        $settings_file = fopen(".appsettings.txt", "w") or die("Unable to write to appsettings file");
        fwrite($settings_file, "fedwiki,favicon,".$url);
        fclose($settings_file);
    }
}

$htmlfile = fopen("$output_filename", "r") or die("Unable to open $output_filename");
echo fread($htmlfile,filesize("$output_filename"));
fclose($htmlfile);

?>
