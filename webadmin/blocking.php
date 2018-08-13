<?php

// Receives the list of blocked domains/users

$output_filename = "settings.html";

if (isset($_POST['submitblocking'])) {
    $blockinglist = htmlspecialchars($_POST['blockinglist']);

    $blocking_file = fopen(".blocklist.txt", "w") or die("Unable to create setup file");
    fwrite($blocking_file, $blockinglist);
    fclose($blocking_file);
}

$htmlfile = fopen("$output_filename", "r") or die("Unable to open $output_filename");
echo fread($htmlfile,filesize("$output_filename"));
fclose($htmlfile);

?>
