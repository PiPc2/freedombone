<?php

// Receives the list of Tor bridges

$output_filename = "settings.html";

if (isset($_POST['submitbridges'])) {
    $bridgeslist = htmlspecialchars($_POST['bridgeslist']);

    $bridges_file = fopen(".bridgeslist.txt", "w") or die("Unable to create bridges file");
    fwrite($bridges_file, $bridgeslist);
    fclose($bridges_file);
}

$htmlfile = fopen("$output_filename", "r") or die("Unable to open $output_filename");
echo fread($htmlfile,filesize("$output_filename"));
fclose($htmlfile);

?>
