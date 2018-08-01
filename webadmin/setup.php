<?php

$output_filename = "index.html";

if (isset($_POST['setup'])) {
    if(file_exists("setup_confirm.html")) {
        $my_username = htmlspecialchars($_POST['my_username']);

        if(!file_exists(".temp_setup.txt")) {
            $setup_file = fopen(".temp_setup.txt", "w") or die("Unable to create setup file");
            fwrite($setup_file, $my_username);
            fclose($setup_file);
        }

        $output_filename = "setup_confirm.html";
    }
}

$htmlfile = fopen("$output_filename", "r") or die("Unable to open $output_filename");
echo fread($htmlfile,filesize("$output_filename"));
fclose($htmlfile);

?>
