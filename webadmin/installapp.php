<?php

$output_filename = "apps_add.html";

if (isset($_POST['install'])) {
    $app_name = htmlspecialchars($_POST['app_name']);
    $install_domain = $_POST['install_domain'];

    if(! file_exists("pending_installs.txt")) {
        $pending_installs = fopen("pending_installs.txt", "w") or die("Unable to create installs file");
        fclose($pending_installs);
    }

    if(! exec('grep '.escapeshellarg("install_".$app_name).' ./pending_installs.txt')) {
        $pending_installs = fopen("pending_installs.txt", "a") or die("Unable to append to installs file");
        fwrite($pending_installs, "install_".$app_name."\n");
        fclose($pending_installs);
        $output_filename = "app_installing.html";
    }
    else {
        // The app is already scheduled for installation
        $output_filename = "app_scheduled.html";
    }
}

$htmlfile = fopen("$output_filename", "r") or die("Unable to open $output_filename");
echo fread($htmlfile,filesize("$output_filename"));
fclose($htmlfile);

?>
