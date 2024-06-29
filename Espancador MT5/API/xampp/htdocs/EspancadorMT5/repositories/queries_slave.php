<?php

require_once 'database.php';




function update_direction_order_slave($direction_order)
{
    $conn = get_db_connection();

    // Prepara a instrução SQL parametrizada para atualização do direction_order
    $stmt = $conn->prepare("UPDATE mt5_slave SET direction_order = ? WHERE id = 1");

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
       // die("Erro ao atualizar direction_order na tabela mt5_slave: " . $conn->error);
return true;
    }
}



function get_datas_slave()
{
    $conn = get_db_connection();

    $stmt = $conn->prepare("SELECT id, price_ask, price_bid, price_close, volume_opened, profit_opened, datetime_opened, datetime_current, direction_order, price_entry ,position_type FROM mt5_slave");

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



function update_mt5_slave($data)
{
    $conn = get_db_connection();

    // Utilizando id=1 como exemplo; ajuste conforme necessário
    $stmt = $conn->prepare("UPDATE mt5_slave SET volume_opened=?, price_close=?, price_ask=?, price_bid=?, datetime_opened=?,  datetime_current=?,profit_opened=? , price_entry=? , position_type=? WHERE id=1");

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

        // Verifica se a atualização foi bem-sucedida
        if ($stmt->affected_rows > 0) {
            // Recupera o direction_order do registro atualizado
            $direction_order = get_direction_order_slave(1); // Substitua 1 pelo valor correto de id

            $stmt->close();
            $conn->close();

            return $direction_order;
        } else {
            $direction_order = get_direction_order_slave(1); // Substitua 1 pelo valor correto de id
            return $direction_order;
            
        }
    } else {
        die("Parâmetros incompletos para atualização na tabela mt5_slave.");
    }
}



// Função para obter o direction_order pelo id
function get_direction_order_slave($id)
{

    $conn = get_db_connection();

    $stmt = $conn->prepare("SELECT direction_order FROM mt5_slave WHERE id = ?");

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
        die("Erro ao recuperar direction_order da tabela mt5_slave: " . $conn->error);
    }
}
