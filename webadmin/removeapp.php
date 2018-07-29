<?php

$output_filename = "apps.html";

if (isset($_POST['uninstall'])) {
    $app_name = htmlspecialchars($_POST['app_name']);

    $continue_remove=true;
    if(file_exists("pending_installs.txt")) {
        // Is this app in the pending_installs list?
        if(exec('grep '.escapeshellarg("install_".$app_name).' ./pending_installs.txt')) {
            if(! exec('grep '.escapeshellarg("install_".$app_name).'_running ./pending_installs.txt')) {
                // Not installing yet so remove from schedule
                exec('sed -i "/'.escapeshellarg("install_".$app_name).'/d');
            }
            else {
                // Installing so don't continue
                $continue_remove=false;
            }
        }
    }

    if($continue_remove) {
        if(! file_exists("pending_removes.txt")) {
            $pending_removes = fopen("pending_removes.txt", "w") or die("Unable to create removes file");
            fclose($pending_removes);
        }

        if(! exec('grep '.escapeshellarg("remove_".$app_name).' ./pending_removes.txt')) {
            $pending_removes = fopen("pending_removes.txt", "a") or die("Unable to append to removes file");
            fwrite($pending_removes, "remove_".$app_name."\n");
            fclose($pending_removes);
            $output_filename = "app_remove.html";
        }
        else {
            // The app is already scheduled for removal
            $output_filename = "app_remove_scheduled.html";
        }
    }
}

$htmlfile = fopen("$output_filename", "r") or die("Unable to open $output_filename");
echo fread($htmlfile,filesize("$output_filename"));
fclose($htmlfile);

?>
