<?php

$output_filename = "index.html";

if (isset($_POST['setupconfirmsubmit'])) {
    if(isset($_POST['setupconfirm'])) {
        $confirm = htmlspecialchars($_POST['setupconfirm']);

        if($confirm == "1") {
            if(file_exists(".temp_setup.txt")) {
                exec('mv .temp_setup.txt setup.txt');
            }
            if(file_exists("setup.txt")) {
                $output_filename = "setup_installing.html";
            }
        }
    }
}

$htmlfile = fopen("$output_filename", "r") or die("Unable to open $output_filename");
echo fread($htmlfile,filesize("$output_filename"));
fclose($htmlfile);

?>
