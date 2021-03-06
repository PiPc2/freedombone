<?php

// Adds a new user to the system

$output_filename = "users.html";

if (isset($_POST['submitnewuser'])) {
    $username = htmlspecialchars($_POST['username']);

    if (!preg_match('/^[a-z\d_]{4,32}$/', $username)) {
        $output_filename = "new_user_invalid.html";
    }
    else {
        // Don't rely on php PRNG
        $newpassword = exec('diceware');
        $new_user_file = fopen(".new_user.txt", "w") or die("Unable to write to new_user file");
        fwrite($new_user_file, $username.",".$newpassword);
        fclose($new_user_file);

        exec('cp new_user_confirm_template.html new_user_confirm.html');
        exec('sed -i "s|NEWPASSWORD|'.$newpassword.'|g" new_user_confirm.html');
        $output_filename = "new_user_confirm.html";
    }
}

$htmlfile = fopen("$output_filename", "r") or die("Unable to open $output_filename");
echo fread($htmlfile,filesize("$output_filename"));
fclose($htmlfile);

?>
