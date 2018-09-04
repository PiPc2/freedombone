<?php

// This is used to begin installing an app.
//
// It creates the confirm screen, populates the variables
// in it and then opens it.

$output_filename = "apps_add.html";

if (isset($_POST['submitappinstall'])) {
    $app_name = htmlspecialchars($_POST['app_name']);
    $install_domain = '';
    $freedns_code = '';

    // Note that this value can be changed by install_web_admin
    $onion_only=false;

    $continue_install=true;

    if(! $onion_only) {
        $no_domain = htmlspecialchars($_POST['no_domain']);
        if ($no_domain === '0') {
            $install_domain = htmlspecialchars($_POST['install_domain']);
            if (strpos($install_domain, '.') === false) {
                // No domain was provided
                $continue_install=false;
            }
            $freedns_code = htmlspecialchars($_POST['freedns_code']);
        }
    }

    if($continue_install) {
        // create the confirm screen populated with details for the app
        exec('cp add_app_confirm_template.html add_app_confirm.html');
        if(file_exists("add_app_confirm.html")) {
            exec('sed -i "s|APPNAME|'.$app_name.'|g" add_app_confirm.html');
            exec('sed -i "s|APPDOMAIN|'.$install_domain.'|g" add_app_confirm.html');
            exec('sed -i "s|APPCODE|'.$freedns_code.'|g" add_app_confirm.html');
            $output_filename = "add_app_confirm.html";
        }
    }
}

$htmlfile = fopen("$output_filename", "r") or die("Unable to open $output_filename");
echo fread($htmlfile,filesize("$output_filename"));
fclose($htmlfile);

?>
