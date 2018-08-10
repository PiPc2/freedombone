<?php

// This receives the yes/no confirmation before a restore

$output_filename = "backup.html";

if (isset($_POST['restoreconfirmsubmit'])) {
    if(isset($_POST['restoreconfirm'])) {
        $confirm = htmlspecialchars($_POST['restoreconfirm']);

        if($confirm == "1") {
            if(! file_exists(".start_restore")) {
                exec('touch .start_restore');
            }
            exec('cp restore_progress_template.html restore_progress.html');
            $output_filename = "restore_progress.html";
        }
        else {
            if(file_exists(".start_restore")) {
                exec('rm .start_restore');
            }
        }
    }
}

$htmlfile = fopen("$output_filename", "r") or die("Unable to open $output_filename");
echo fread($htmlfile,filesize("$output_filename"));
fclose($htmlfile);

?>
