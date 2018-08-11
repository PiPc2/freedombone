<?php

$output_filename = "users.html";

if (isset($_POST['submitremoveuser'])) {
    if(isset($_POST['removeuserconfirm'])) {
        $confirm = htmlspecialchars($_POST['removeuserconfirm']);

        if($confirm == "1") {
            if(file_exists(".temp_remove_user.txt")) {
                exec('mv .temp_remove_user.txt .remove_user.txt');
                $output_filename = "removing_user.html";
            }
        }
    }
}

$htmlfile = fopen("$output_filename", "r") or die("Unable to open $output_filename");
echo fread($htmlfile,filesize("$output_filename"));
fclose($htmlfile);

if(file_exists('remove_user_confirm.html')) {
    exec('rm remove_user_confirm.html');
}

?>
