<?php

// Change language

$output_filename = "settings.html";

if (isset($_POST['submitlanguage'])) {
    $language = htmlspecialchars($_POST['language']);

    $language_file = fopen(".language.txt", "w") or die("Unable to create language file");
    fwrite($language_file, $language);
    fclose($language_file);
}

$htmlfile = fopen("$output_filename", "r") or die("Unable to open $output_filename");
echo fread($htmlfile,filesize("$output_filename"));
fclose($htmlfile);

?>
