
 <body>

 <?php

ini_set('error_reporting', E_ALL);
ini_set('display_errors', true);
// display errors

$servername = "dbase.cs.jhu.edu";
$username = "20fa_rzhai2";
$password = "AgadM8or";
$dbname = "20fa_rzhai2_db";
$connection = new mysqli($servername, $username, $password, $dbname);
// ********* Remember to use your MySQL username and password here ********* //

/* check connection */
if (mysqli_connect_errno()) {
  printf("Connect failed: %s<br>", mysqli_connect_error());
  exit();
}
else {
    $Input_Title = $_POST['Input_Title'];
    $query = "CALL proc_4('$Input_Title')";
    if(mysqli_multi_query($connection, $query)) {
        if($result = mysqli_store_result($connection)) {
            echo "<table border=1>\n";
            echo "<tr><td>Hero</td><td>Role</td><td>TotalTime</td></tr>\n";
            while($row = mysqli_fetch_row($result)) {
                printf("<tr><td>%s</td><td>%s</td><td>%s</td></tr>\n", 
                    $row[0], $row[1], $row[2]);
            }
            mysqli_free_result($result);
        }
    }
    else {
        printf("<br>Error: %s\n", $connection->error);
    }
}
mysqli_close($connection);

 ?>

 </body>