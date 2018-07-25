<?php

if (isset($_POST['install'])) {
    $app_name = htmlspecialchars($_POST['app_name']);
    $install_domain = $app_name.".".gethostname();
    echo "domain: ".$install_domain;
}

?>
