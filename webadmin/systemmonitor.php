<?php

// Updates values for the system monitor screen

$output_filename = "settings.html";

if (isset($_POST['submitsystemmonitor'])) {
    $system_monitor_file = fopen(".system_monitor.txt", "w") or die("Unable to create system monitor file");
    fwrite($system_monitor_file, " ");
    fclose($system_monitor_file);
    $output_filename = "system_monitor.html";
}

$htmlfile = fopen("$output_filename", "r") or die("Unable to open $output_filename");
echo fread($htmlfile,filesize("$output_filename"));
fclose($htmlfile);

?>
