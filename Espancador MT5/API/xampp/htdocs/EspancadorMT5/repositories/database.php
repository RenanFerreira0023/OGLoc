<?php

// Função para estabelecer a conexão com o banco de dados
function get_db_connection() {
    // Parâmetros de conexão com o banco de dados
    $servername = "localhost";
    $username = "root";
    $password = "";
    $dbname = "DB_ESPANCADOR_MT5"; // Nome do seu banco de dados

    // Cria a conexão
    $conn = new mysqli($servername, $username, $password, $dbname);

    // Verifica a conexão
    if ($conn->connect_error) {
        die("Falha na conexão com o banco de dados: " . $conn->connect_error);
    }

    return $conn;
}
?>
