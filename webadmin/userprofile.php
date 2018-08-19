<?php

// Functions available from the user's profile
// Remove, change password

$output_filename = "users.html";

if (isset($_POST['submitremoveuser'])) {
    $username = htmlspecialchars($_POST['myuser']);

    $remove_user_file = fopen(".temp_remove_user.txt", "w") or die("Unable to write to domain file");
    fwrite($remove_user_file, $username);
    fclose($remove_user_file);

    if(file_exists("remove_user_confirm_template.html")) {
        exec('cp remove_user_confirm_template.html remove_user_confirm.html');
        exec('sed -i "s|USERNAME|'.$username.'|g" remove_user_confirm.html');
    }

    $output_filename = "remove_user_confirm.html";
}

if (isset($_POST['submitchangepassword'])) {
    $username = htmlspecialchars($_POST['myuser']);

    // Don't rely on php PRNG
    $newpassword = exec("openssl rand -base64 32 | tr -dc A-Za-z0-9 | head -c 10 ; echo -n ''");
    exec('cp password_confirm_template.html password_confirm.html');
    exec('sed -i "s|USERNAME|'.$username.'|g" password_confirm.html');
    exec('sed -i "s|NEWPASSWORD|'.$newpassword.'|g" password_confirm.html');

    $output_filename = "password_confirm.html";
}

$htmlfile = fopen("$output_filename", "r") or die("Unable to open $output_filename");
echo fread($htmlfile,filesize("$output_filename"));
fclose($htmlfile);

?>
