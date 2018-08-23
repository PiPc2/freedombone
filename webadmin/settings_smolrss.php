<?php

// SmolRSS feeds

$output_filename = "app_smolrss.html";

if (isset($_POST['submitfeeds'])) {
    $feeds = htmlspecialchars($_POST['feeds']);

    $feeds_file = fopen(".rssfeeds.txt", "w") or die("Unable to create feeds file");
    fwrite($feeds_file, $feeds);
    fclose($feeds_file);
}

$htmlfile = fopen("$output_filename", "r") or die("Unable to open $output_filename");
echo fread($htmlfile,filesize("$output_filename"));
fclose($htmlfile);

?>
