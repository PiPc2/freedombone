<?php

if (isset($_POST['setup'])) {
    $my_username = htmlspecialchars($_POST['my_username']);
    $default_domain_name = htmlspecialchars($_POST['default_domain_name']);

    if(!file_exists(".temp_setup.txt")) {
        $setup_file = fopen(".temp_setup.txt", "w") or die("Unable to create setup file");
        fwrite($setup_file, $my_username.",".$default_domain_name."\n");
        fclose($);
    }

    $output_filename = "setup_installing.html";
    $htmlfile = fopen("$output_filename", "r") or die("Unable to open $output_filename");
    echo fread($htmlfile,filesize("$output_filename"));
    fclose($htmlfile);
}

?>
