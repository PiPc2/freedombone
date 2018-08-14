<?php

// Change dynamic DNS settings

$output_filename = "settings.html";

if (isset($_POST['submitddns'])) {
    $ddns = htmlspecialchars($_POST['dynamicdns']);
    $ddns_username = htmlspecialchars($_POST['ddns_username']);
    $ddns_password = htmlspecialchars($_POST['ddns_password']);

    $ddns_file = fopen(".dynamicdns.txt", "w") or die("Unable to create dynamicdns file");
    fwrite($ddns_file, $ddns.','.$ddns_username.','.$ddns_password);
    fclose($ddns_file);
}

$htmlfile = fopen("$output_filename", "r") or die("Unable to open $output_filename");
echo fread($htmlfile,filesize("$output_filename"));
fclose($htmlfile);

?>
