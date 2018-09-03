<?php

// DAT server

$output_filename = "app_datserver.html";

if (isset($_POST['submitdatlinks'])) {
    $datlinks = htmlspecialchars($_POST['datlinks']);

    $datlinks_file = fopen(".datlinks.txt", "w") or die("Unable to create datlinks file");
    fwrite($datlinks_file, $datlinks);
    fclose($datlinks_file);
}

$htmlfile = fopen("$output_filename", "r") or die("Unable to open $output_filename");
echo fread($htmlfile,filesize("$output_filename"));
fclose($htmlfile);

?>
