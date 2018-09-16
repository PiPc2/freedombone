<?php

function endsWith($haystack, $needle)
{
    $length = strlen($needle);
    if ($length == 0) {
        return true;
    }

    return (substr($haystack, -$length) === $needle);
}

// Updates values for the system monitor screen

$output_filename = "settings.html";

if (isset($_POST['submitsystemmonitor'])) {
    $system_monitor_file = fopen(".system_monitor.txt", "w") or die("Unable to create system monitor file");
    fwrite($system_monitor_file, "update");
    fclose($system_monitor_file);

    # remain on this screen after clicking update
    $host  = $_SERVER['HTTP_HOST'];
    $uri   = rtrim(dirname($_SERVER['PHP_SELF']), '/\\');
    if (endsWith($uri, 'admin')) {
        header("Location: http://$host$uri/system_monitor.html");
    }
    else {
        header("Location: http://$host$uri/admin/system_monitor.html");
    }

    sleep(3);

    $output_filename = "system_monitor.html";
}

$htmlfile = fopen("$output_filename", "r") or die("Unable to open $output_filename");
echo fread($htmlfile,filesize("$output_filename"));
fclose($htmlfile);

?>
