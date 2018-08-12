<?php

// Changes the password for a user

$output_filename = "users.html";

if (isset($_POST['submitacceptpassword'])) {
    $username = htmlspecialchars($_POST['myuser']);
    $newpassword = htmlspecialchars($_POST['mypassword']);

    $temp_file = tmpfile();
    $password_file_path = stream_get_meta_data($temp_file)['uri'];

    $password_file = fopen("changepassword.dat", "w") or die("Unable to create changepassword file");
    fwrite($password_file, $password_file_path);
    fclose($password_file);

    fwrite($temp_file, $my_username.",".$newpassword);
    fclose($temp_file);

    $output_filename = "password_changed.html";
}

$htmlfile = fopen("$output_filename", "r") or die("Unable to open $output_filename");
echo fread($htmlfile,filesize("$output_filename"));
fclose($htmlfile);

exec('rm password_confirm.html');

?>
