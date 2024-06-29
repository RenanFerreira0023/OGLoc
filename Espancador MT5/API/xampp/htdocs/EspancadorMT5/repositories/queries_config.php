<?php

require_once 'database.php';

function get_configdatas()
{
    $conn = get_db_connection();

    // Consulta SQL que especifica todos os campos
    $sql = "SELECT id, send_order, limit_spread, profit_takeprofit, profit_stoploss, horario_x, horario_y ,type_price_base , minutes_to_exit FROM config_espancador";
    $result = $conn->query($sql);

    $data = [];

    if ($result->num_rows > 0) {
        while ($row = $result->fetch_assoc()) {
            // Converte os campos numéricos para float ou int
            $row['id'] = (int) $row['id'];
            $row['send_order'] = (int) $row['send_order'];
            $row['limit_spread'] = (float) $row['limit_spread'];
            $row['profit_takeprofit'] = (float) $row['profit_takeprofit'];
            $row['profit_stoploss'] = (float) $row['profit_stoploss'];
            $row['type_price_base'] = (int) $row['type_price_base'];
            $row['minutes_to_exit'] = (int) $row['minutes_to_exit'];

            $data[] = $row;
        }
    }

    $conn->close();

    return $data;
}

function update_configuration($datas)
{
    $conn = get_db_connection();

    if ($conn->connect_error) {
        die("Falha na conexão: " . $conn->connect_error);
    }

    // Prepara a instrução SQL parametrizada para atualização
    $stmt = $conn->prepare("
        UPDATE config_espancador 
        SET send_order = ?, 
            minutes_to_exit = ?,
            type_price_base = ? ,
            limit_spread = ?, 
            profit_takeprofit = ?, 
            profit_stoploss = ?, 
            horario_x = ?, 
            horario_y = ?
        WHERE id = 1
    ");

    if ($stmt === false) {
        die("Erro ao preparar a consulta SQL: " . $conn->error);
    }

    // Binda os parâmetros à consulta SQL
    $stmt->bind_param(
        "iiiddsss",
        $datas['send_order'],
        $datas['minutes_to_exit'],
        $datas['type_price_base'],
        $datas['limit_spread'],
        $datas['profit_takeprofit'],
        $datas['profit_stoploss'],
        $datas['horario_x'],
        $datas['horario_y']
    );

    $stmt->execute();

 //   if ($stmt->affected_rows > 0) {
//        echo "Configuração atualizada com sucesso. Linhas afetadas: " . $stmt->affected_rows . "\n";
  //  } else {
  //      echo "Nenhuma linha foi afetada pela atualização.\n";
  //  }

    $stmt->close();
    $conn->close();
}



function set_flow_bot($datas)
{

    $conn = get_db_connection();

    if ($conn->connect_error) {
        die("Falha na conexão: " . $conn->connect_error);
    }

    // Prepara a instrução SQL parametrizada para atualização
    $stmt = $conn->prepare("
        UPDATE config_espancador 
        SET send_order = ?
        WHERE id = 1");

    if ($stmt === false) {
        die("Erro ao preparar a consulta SQL: " . $conn->error);
    }

    // Binda os parâmetros à consulta SQL
    $stmt->bind_param(
        "i",
        $datas['send_order']

    );

    $stmt->execute();

    if ($stmt->affected_rows > 0) {
        echo "Configuração atualizada com sucesso. Linhas afetadas: " . $stmt->affected_rows . "\n";
    } else {
        echo "Nenhuma linha foi afetada pela atualização.\n";
    }

    $stmt->close();
    $conn->close();
}
