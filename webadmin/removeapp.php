<?php

// This is used to begin removing an app.
//
// It creates the confirm screen, populates the variables
// in it and then opens it.

$output_filename = "apps.html";

if (isset($_POST['uninstall'])) {
    $app_name = htmlspecialchars($_POST['app_name']);

    // create the confirm screen populated with details for the app
    exec('cp remove_app_confirm_template.html remove_app_confirm.html');
    if(file_exists("remove_app_confirm.html")) {
        exec('sed -i "s|APPNAME|'.$app_name.'|g" remove_app_confirm.html');
        $output_filename = "remove_app_confirm.html";
    }
}

if (isset($_POST['submitappsettings'])) {
    $app_name = htmlspecialchars($_POST['app_name']);
    $output_filename = "settings_".$app_name.".html";
}

$htmlfile = fopen("$output_filename", "r") or die("Unable to open $output_filename");
echo fread($htmlfile,filesize("$output_filename"));
fclose($htmlfile);

?>
