<?php

// Backup password screen for getting the password
// prior to backup or restore

$output_filename = "backup.html";

if (isset($_POST['submitbackuppassword'])) {
    $pass = trim(htmlspecialchars($_POST['backup_password']));
    $pass_confirm = trim(htmlspecialchars($_POST['backup_password_confirm']));
    if ($pass === $pass_confirm) {
        if (strpos($pass, ' ') === false) {
            if (preg_match('/^[a-z\A-Z\d_]{8,512}$/', $pass)) {
                $settings_file = fopen("/tmp/backup_password.txt", "w") or die("Unable to write to appsettings file");
                fwrite($settings_file, $pass);
                fclose($settings_file);
            }
            else {
                $output_filename = "invalid_backup_password.html";
            }
        }
        else {
            $output_filename = "invalid_backup_password.html";
        }
    }
}

$htmlfile = fopen("$output_filename", "r") or die("Unable to open $output_filename");
echo fread($htmlfile,filesize("$output_filename"));
fclose($htmlfile);

?>
