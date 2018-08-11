<?php

// This receives the yes/no confirmation before
// backup of keys

$output_filename = "backup.html";

if (isset($_POST['submitbackupkeys'])) {
    if(isset($_POST['backupkeysconfirm'])) {
        $confirm = htmlspecialchars($_POST['backupkeysconfirm']);

        if($confirm == "1") {
            if(! file_exists(".start_backup_keys")) {
                exec('touch .start_backup_keys');
            }
            exec('cp backup_keys_progress_template.html backup_keys_progress.html');
            $output_filename = "backup_keys_progress.html";
        }
        else {
            if(file_exists(".start_backup_keys")) {
                exec('rm .start_backup_keys');
            }
        }
    }
}

$htmlfile = fopen("$output_filename", "r") or die("Unable to open $output_filename");
echo fread($htmlfile,filesize("$output_filename"));
fclose($htmlfile);

?>
