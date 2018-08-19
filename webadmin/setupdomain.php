<?php

// For clearnet setup this receives the preferred domain name
// and then begins the install by creating the setup.txt file
// which is detected by the webadmin daemon (freedombone-installer)

$output_filename = "index.html";

if (isset($_POST['setupdomain'])) {
    $install_domain = htmlspecialchars($_POST['default_domain_name']);

    if (preg_match('/^[a-z\d_\.\-]{4,128}$/i', $install_domain)) {
        $domain_file = fopen(".temp_domain.txt", "w") or die("Unable to write to domain file");
        fwrite($domain_file, $install_domain);
        fclose($domain_file);
    }

    if(file_exists(".temp_setup.txt")) {
        exec('mv .temp_setup.txt setup.txt');
        exec('cp setup_installing.html index.html');
    }

    $output_filename = "setup_installing.html";
}

$htmlfile = fopen("$output_filename", "r") or die("Unable to open $output_filename");
echo fread($htmlfile,filesize("$output_filename"));
fclose($htmlfile);

?>
