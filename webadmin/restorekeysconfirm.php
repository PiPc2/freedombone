<?php

// This receives the yes/no confirmation before
// restore of keys

$output_filename = "backup.html";

if (isset($_POST['submitrestorekeys'])) {
    if(isset($_POST['restorekeysconfirm'])) {
        $confirm = htmlspecialchars($_POST['restorekeysconfirm']);

        if($confirm == "1") {
            if(! file_exists(".start_restore_keys")) {
                exec('touch .start_restore_keys');
            }
            exec('cp restore_keys_progress_template.html restore_keys_progress.html');
            $output_filename = "restore_keys_progress.html";
        }
        else {
            if(file_exists(".start_restore_keys")) {
                exec('rm .start_restore_keys');
            }
        }
    }
}

$htmlfile = fopen("$output_filename", "r") or die("Unable to open $output_filename");
echo fread($htmlfile,filesize("$output_filename"));
fclose($htmlfile);

?>
