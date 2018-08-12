<?php

// Shuts down or resets the system

$output_filename = "settings.html";

if (isset($_POST['submitreset'])) {
    $reset_file = fopen(".reset.txt", "w") or die("Unable to write to domain file");
    fwrite($reset_file, "reset");
    fclose($reset_file);

    $output_filename = "restarting.html";
}

if (isset($_POST['submitshutdown'])) {
    $shutdown_file = fopen(".shutdown.txt", "w") or die("Unable to write to domain file");
    fwrite($shutdown_file, "shutdown");
    fclose($shutdown_file);

    $output_filename = "shutting_down.html";
}

$htmlfile = fopen("$output_filename", "r") or die("Unable to open $output_filename");
echo fread($htmlfile,filesize("$output_filename"));
fclose($htmlfile);

?>
