<?php

// Update playlist settings for icecast

$output_filename = "app_icecast.html";

if (isset($_POST['submiticecast'])) {
    $icecast_name = trim(htmlspecialchars($_POST['icecast_name']));
    $icecast_description = trim(htmlspecialchars($_POST['icecast_description']));
    $icecast_genre = trim(htmlspecialchars($_POST['icecast_genre']));

    if(($icecast_name === '') || ($icecast_description === '') || ($icecast_genre === '')) {
        $output_filename = "icecast_missing_fields.html";
    }
    else {
        $icecast_file = fopen(".icecast.txt", "w") or die("Unable to write to icecast file");
        fwrite($icecast_file, $icecast_name.','.$icecast_description.','.$icecast_genre);
        fclose($icecast_file);

        $output_filename = "icecast_updating.html";
    }
}

$htmlfile = fopen("$output_filename", "r") or die("Unable to open $output_filename");
echo fread($htmlfile,filesize("$output_filename"));
fclose($htmlfile);

?>
