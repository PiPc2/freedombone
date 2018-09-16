<?php

// Enable or disable ssh

$output_filename = "index.html";

if (isset($_POST['submitssh'])) {
    $confirm = htmlspecialchars($_POST['sshconfirm']);

    $ssh_file = fopen(".ssh.txt", "w") or die("Unable to create ssh file");
    fwrite($ssh_file, '0,');
    fclose($ssh_file);
    $output_filename = "ssh_disabled.html";

    if($confirm == "1") {
        $publickey = htmlspecialchars($_POST['publickey']);
        if (substr($publickey, 0, 4) === "ssh-") {
            $ssh_file = fopen(".ssh.txt", "w") or die("Unable to create ssh file");
            fwrite($ssh_file, '1,'.$publickey);
            fclose($ssh_file);

            $host=gethostname();
            exec('sed -i "s|HOSTNAME|'.$host.'|g" ssh_enabled.html');

            $output_filename = "ssh_enabled.html";
        }
        else {
            $output_filename = "ssh_no_public_key.html";
        }
    }
}

$htmlfile = fopen("$output_filename", "r") or die("Unable to open $output_filename");
echo fread($htmlfile,filesize("$output_filename"));
fclose($htmlfile);

?>
