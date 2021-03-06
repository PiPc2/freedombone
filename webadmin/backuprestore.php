<?php

function endsWith($haystack, $needle)
{
    $length = strlen($needle);
    if ($length == 0) {
        return true;
    }

    return (substr($haystack, -$length) === $needle);
}

// Backup password screen for getting the password
// prior to backup or restore

$output_filename = "backup.html";

if (isset($_POST['submitbackuppassword'])) {
    $pass = trim(htmlspecialchars($_POST['backup_password']));
    $pass_confirm = trim(htmlspecialchars($_POST['backup_password_confirm']));
    if ($pass === $pass_confirm) {
        if (strpos($pass, ' ') === false) {
            if (preg_match('/^[a-z\A-Z\d_]{8,512}$/', $pass)) {
                $settings_file = fopen("/tmp/backup_password.txt", "w") or die("Unable to write to backup_password file");
                fwrite($settings_file, $pass);
                fclose($settings_file);

                if(! file_exists(".start_backup")) {
                    exec('touch .start_backup');
                }
                exec('cp backup_progress_template.html backup_progress.html');
                $host  = $_SERVER['HTTP_HOST'];
                $uri   = rtrim(dirname($_SERVER['PHP_SELF']), '/\\');
                if (endsWith($uri, 'admin')) {
                    header("Location: http://$host$uri/backup_progress.html");
                }
                else {
                    header("Location: http://$host$uri/admin/backup_progress.html");
                }
                $output_filename = "backup_progress.html";
            }
            else {
                $output_filename = "invalid_backup_password.html";
            }
        }
        else {
            $output_filename = "invalid_backup_password.html";
        }
    }
    else {
        $output_filename = "invalid_password_match.html";
    }
}

if (isset($_POST['submitrestorepassword'])) {
    $pass = trim(htmlspecialchars($_POST['backup_password']));
    if (strpos($pass, ' ') === false) {
        if (preg_match('/^[a-z\A-Z\d_]{8,512}$/', $pass)) {
            $settings_file = fopen("/tmp/backup_password.txt", "w") or die("Unable to write to backup_password file");
            fwrite($settings_file, $pass);
            fclose($settings_file);

            if(! file_exists(".start_restore")) {
                exec('touch .start_restore');
            }
            exec('cp restore_progress_template.html restore_progress.html');
            $host  = $_SERVER['HTTP_HOST'];
            $uri   = rtrim(dirname($_SERVER['PHP_SELF']), '/\\');
            if (endsWith($uri, 'admin')) {
                header("Location: http://$host$uri/restore_progress.html");
            }
            else {
                header("Location: http://$host$uri/admin/restore_progress.html");
            }
            $output_filename = "restore_progress.html";
        }
        else {
            $output_filename = "invalid_backup_password.html";
        }
    }
    else {
        $output_filename = "invalid_backup_password.html";
    }
}

$htmlfile = fopen("$output_filename", "r") or die("Unable to open $output_filename");
echo fread($htmlfile,filesize("$output_filename"));
fclose($htmlfile);

?>
