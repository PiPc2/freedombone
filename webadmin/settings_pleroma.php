<?php

// Pleroma settings menu

$output_filename = "settings_pleroma.html";

if (isset($_POST['submitallowregistrations'])) {
    $confirm = htmlspecialchars($_POST['allowregistrations']);
    $settings_file = fopen(".appsettings.txt", "w") or die("Unable to write to appsettings file");
    fwrite($settings_file, "pleroma,registration,".$confirm);
    fclose($settings_file);
}

if (isset($_POST['submitemoji'])) {
    $shortcode = htmlspecialchars($_POST['emoji_shortcode']);
    if (strpos($shortcode, ' ') === false) {
        $url = htmlspecialchars($_POST['emoji_url']);
        if (strpos($url, ' ') === false) {
            $settings_file = fopen(".appsettings.txt", "w") or die("Unable to write to appsettings file");
            fwrite($settings_file, "pleroma,emoji,".$shortcode.' '.$url);
            fclose($settings_file);
        }
    }
}

$htmlfile = fopen("$output_filename", "r") or die("Unable to open $output_filename");
echo fread($htmlfile,filesize("$output_filename"));
fclose($htmlfile);

?>
