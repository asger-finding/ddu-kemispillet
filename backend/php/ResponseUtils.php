<?php
function response($datasize, $dictionary = [], $error = "") {
    ob_end_clean();
    header('Content-Type: application/json');
    $string = "{\"error\" : \"$error\",
                \"command\" : \"{$_REQUEST['command']}\",
                \"datasize\" : $datasize, 
                \"response\" :" . json_encode($dictionary) . "}";    
    echo $string;
}
?>