<?php

require_once 'database.php';


function update_direction_order_admin($direction_order)
{
    $conn = get_db_connection();

    // Prepara a instrução SQL parametrizada para atualização do direction_order
    $stmt = $conn->prepare("UPDATE mt5_admin SET direction_order = ? WHERE id = 1");

    if ($stmt === false) {
        die("Erro ao preparar a consulta SQL: " . $conn->error);
    }

    // Binda parâmetro à consulta SQL e executa a atualização
    $stmt->bind_param("i", $direction_order);
    $stmt->execute();

    if ($stmt->affected_rows > 0) {
        // Atualização bem-sucedida
        $stmt->close();
        $conn->close();
        return true;
    } else {
        // Caso a atualização não tenha afetado nenhuma linha
        return true;
        //      die("Erro ao atualizar direction_order na tabela mt5_admin: " . $conn->error);
    }
}


function get_datas_admin()
{
    $conn = get_db_connection();

    $stmt = $conn->prepare("SELECT id, price_ask, price_bid, price_close, volume_opened, profit_opened, datetime_opened, datetime_current, direction_order , price_entry, position_type  FROM mt5_admin");

    if ($stmt === false) {
        die("Erro ao preparar a consulta SQL: " . $conn->error);
    }

    $stmt->execute();

    $result = $stmt->get_result();

    if ($result->num_rows > 0) {
        $data = [];

        while ($row = $result->fetch_assoc()) {
            $data[] = $row;
        }

        $stmt->close();

        $conn->close();

        return $data;
    } else {
        $stmt->close();

        $conn->close();

        return [];
    }
}


function update_mt5_admin($data)
{
    $conn = get_db_connection();

    // Utilizando id=1 como exemplo; você deve ajustar isso conforme necessário
    $stmt = $conn->prepare("UPDATE mt5_admin SET volume_opened=?, price_close=?, price_ask=?, price_bid=?, datetime_opened=?, datetime_current=?, profit_opened=? , price_entry=? , position_type=?  WHERE id=1");


    if ($stmt === false) {
        die("Erro ao preparar a consulta SQL: " . $conn->error);
    }

    if (
        isset(
            $data['volume_opened'],
            $data['price_close'],
            $data['price_ask'],
            $data['price_bid'],
            $data['datetime_opened'],
            $data['datetime_current'],
            $data['profit_opened'],
            $data['price_entry'],
            $data['position_type']

        )
    ) {
        // Binda parâmetros à consulta SQL
        $stmt->bind_param(
            "ddddssdds",
            $data['volume_opened'],
            $data['price_close'],
            $data['price_ask'],
            $data['price_bid'],
            $data['datetime_opened'],
            $data['datetime_current'],
            $data['profit_opened'],
            $data['price_entry'],
            $data['position_type']

        );

        // Executa a instrução SQL
        $stmt->execute();


        if ($stmt->affected_rows > 0) {
            $direction_order = get_direction_order_admin(1);
            $stmt->close();
            $conn->close();

            return $direction_order;
        } else {
            $direction_order = get_direction_order_admin(1);
            return $direction_order;
        }
    } else {
        die("Parâmetros incompletos para atualização na tabela mt5_admin.");
    }
}


// Função para obter o direction_order pelo id
function get_direction_order_admin($id)
{

    $conn = get_db_connection();

    $stmt = $conn->prepare("SELECT direction_order FROM mt5_admin WHERE id = ?");

    if ($stmt === false) {
        die("Erro ao preparar a consulta SQL: " . $conn->error);
    }

    $stmt->bind_param("i", $id);
    $stmt->execute();
    $stmt->bind_result($direction_order);

    if ($stmt->fetch()) {
        $stmt->close();
        $conn->close();
        return $direction_order;
    } else {
        die("Erro ao recuperar direction_order da tabela mt5_admin: " . $conn->error);
    }
}
