<?php

// This receives the yes/no confirmation before a restore

$output_filename = "backup.html";

if (isset($_POST['formatconfirmsubmit'])) {
    if(isset($_POST['formatconfirm'])) {
        $confirm = htmlspecialchars($_POST['formatconfirm']);

        if($confirm == "1") {
            if(! file_exists(".start_format")) {
                exec('touch .start_format');
            }
            exec('cp format_progress_template.html format_progress.html');
            $output_filename = "format_progress.html";
        }
        else {
            if(file_exists(".start_format")) {
                exec('rm .start_format');
            }
        }
    }
}

$htmlfile = fopen("$output_filename", "r") or die("Unable to open $output_filename");
echo fread($htmlfile,filesize("$output_filename"));
fclose($htmlfile);

?>
