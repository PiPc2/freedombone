<?php

// This receives the yes/no confirmation on initial setup
// of the system and creates the setup.txt file which is
// then detected by the webadmin daemon (freedombone-installer)

$output_filename = "index.html";

if (isset($_POST['setupconfirmsubmit'])) {
    if(isset($_POST['setupconfirm'])) {
        $confirm = htmlspecialchars($_POST['setupconfirm']);

        if($confirm == "1") {
            if(file_exists(".temp_setup.txt")) {
                // This gets changed by web_admin_onion_only
                $output_filename = "setup_domain.html";
            }
            if($output_filename == "setup_installing.html") {
                if(file_exists(".temp_setup.txt")) {
                    exec('mv .temp_setup.txt setup.txt');
                    exec('cp setup_installing.html index.html');
                }
            }
        }
    }
}

$htmlfile = fopen("$output_filename", "r") or die("Unable to open $output_filename");
echo fread($htmlfile,filesize("$output_filename"));
fclose($htmlfile);

?>
