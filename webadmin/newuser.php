<?php

// Adds a new user to the system

$output_filename = "users.html";

if (isset($_POST['submitnewuser'])) {
    $username = htmlspecialchars($_POST['username']);

    if ((!preg_match('/[^a-z0-9]/', $username)) || (strlen($username)<4)) {
        $output_filename = "new_user_invalid.html";
    }
    else {
        $domain_file = fopen(".new_user.txt", "w") or die("Unable to write to new_user file");
        fwrite($domain_file, $username);
        fclose($domain_file);

        $output_filename = "new_user_confirm.html";
    }
}

$htmlfile = fopen("$output_filename", "r") or die("Unable to open $output_filename");
echo fread($htmlfile,filesize("$output_filename"));
fclose($htmlfile);

?>
