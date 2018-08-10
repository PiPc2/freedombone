<?php

// This receives the yes/no confirmation before a backup

$output_filename = "backup.html";

if (isset($_POST['backupconfirmsubmit'])) {
    if(isset($_POST['backupconfirm'])) {
        $confirm = htmlspecialchars($_POST['backupconfirm']);

        if($confirm == "1") {
            if(! file_exists(".start_backup")) {
                exec('touch .start_backup');
            }
            exec('cp backup_progress_template.html backup_progress.html');
            $output_filename = "backup_progress.html";
        }
        else {
            if(file_exists(".start_backup")) {
                exec('rm .start_backup');
            }
        }
    }
}

$htmlfile = fopen("$output_filename", "r") or die("Unable to open $output_filename");
echo fread($htmlfile,filesize("$output_filename"));
fclose($htmlfile);

?>
