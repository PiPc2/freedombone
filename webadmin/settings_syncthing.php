<?php

// Receives the list of Syncthing IDs

$output_filename = "app_syncthing.html";

if (isset($_POST['submitsyncthing'])) {
    $ids = htmlspecialchars($_POST['syncthing_ids']);

    $ids_file = fopen(".syncthing.txt", "w") or die("Unable to create syncthing ids file");
    fwrite($ids_file, $ids);
    fclose($ids_file);
}

$htmlfile = fopen("$output_filename", "r") or die("Unable to open $output_filename");
echo fread($htmlfile,filesize("$output_filename"));
fclose($htmlfile);

?>
