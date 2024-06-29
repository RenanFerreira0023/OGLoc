<?php
$log_file = 'log.txt';
require_once 'repositories/queries_slave.php';
require_once 'repositories/queries_admin.php';
require_once 'repositories/queries_config.php';


function log_message($message, $file)
{
    file_put_contents($file, $message, FILE_APPEND);
}

$request_uri = $_SERVER['REQUEST_URI'];
$script_name = $_SERVER['SCRIPT_NAME'];
$uri = substr($request_uri, strlen($script_name));


// Função para enviar a resposta HTTP com o código de status apropriado
function send_response($status_code, $response_data)
{
    header("Content-Type: application/json");
    http_response_code($status_code);
    echo json_encode($response_data);
    exit();
}




if ($_SERVER['REQUEST_METHOD'] === 'GET' && strpos($uri, '/criar_ambiente/') === 0) {
    $servername = "localhost";
    $username = "root";
    $password = "";
    $dbname = "DB_ESPANCADOR_MT5"; // Nome do seu banco de dados

    // Conectar ao servidor MySQL
    $conn = new mysqli($servername, $username, $password);

    // Verificar conexão
    if ($conn->connect_error) {
        die("Erro de conexão: " . $conn->connect_error);
    }

    // Verificar se o banco de dados já existe
    $sql = "SHOW DATABASES LIKE '$dbname'";
    $result = $conn->query($sql);

    if ($result->num_rows > 0) {
        echo "\nO banco de dados '$dbname' já existe. Nenhuma ação necessária.";
        return;
    } else {
        // Comando SQL para criar um banco de dados
        $sql = "CREATE DATABASE $dbname";

        if ($conn->query($sql) === TRUE) {
            echo "\nBanco de dados criado com sucesso!";
        } else {
            echo "\nErro ao criar o banco de dados: " . $conn->error;
            return;
        }
    }

    // Conectar ao banco de dados específico
    $conn->select_db($dbname);

    // SQL para criar as tabelas
    $sql = "
    CREATE TABLE IF NOT EXISTS mt5_admin (
        id INT AUTO_INCREMENT PRIMARY KEY,
        price_ask DOUBLE(15, 2) DEFAULT 0,
        price_bid DOUBLE(15, 2) DEFAULT 0,
        price_close DOUBLE(15, 2) DEFAULT 0,
        volume_opened DOUBLE(5, 2) DEFAULT 0,
        profit_opened DOUBLE(15, 2) DEFAULT 0,
        price_entry DOUBLE(15, 2) DEFAULT 0,
        datetime_opened VARCHAR(20) DEFAULT '2001.01.01 00:00:00',
        datetime_current VARCHAR(20) DEFAULT '2001.01.01 00:00:00',
        direction_order INTEGER(1) DEFAULT 0,
        position_type VARCHAR(4) DEFAULT ''
    );

    CREATE TABLE IF NOT EXISTS mt5_slave (
        id INT AUTO_INCREMENT PRIMARY KEY,
        price_ask DOUBLE(15, 2) DEFAULT 0,
        price_bid DOUBLE(15, 2) DEFAULT 0,
        price_close DOUBLE(15, 2) DEFAULT 0,
        volume_opened DOUBLE(5, 2) DEFAULT 0,
        profit_opened DOUBLE(15, 2) DEFAULT 0,
        price_entry DOUBLE(15, 2) DEFAULT 0,
        datetime_opened VARCHAR(20) DEFAULT '2001.01.01 00:00:00',
        datetime_current VARCHAR(20) DEFAULT '2001.01.01 00:00:00',
        direction_order INTEGER(1) DEFAULT 0,
        position_type VARCHAR(4) DEFAULT ''
    );

    CREATE TABLE IF NOT EXISTS config_espancador (
        id INT AUTO_INCREMENT PRIMARY KEY,
        send_order INTEGER(1) DEFAULT 0,
        minutes_to_exit INTEGER(1) DEFAULT 0,
        limit_spread DOUBLE(15, 2) DEFAULT 30,
        profit_takeprofit DOUBLE(15, 2) DEFAULT 150,
        profit_stoploss DOUBLE(15, 2) DEFAULT -200,
        horario_x VARCHAR(5) DEFAULT '08:00',
        horario_y VARCHAR(5) DEFAULT '18:00',
        type_price_base INTEGER(1) DEFAULT 0
    );
    ";

    if ($conn->multi_query($sql) === TRUE) {
        do {
            // Store the result set to free the buffer
            if ($result = $conn->store_result()) {
                $result->free();
            }
        } while ($conn->more_results() && $conn->next_result());
        echo "\nTabelas criadas com sucesso!";
    } else {
        echo "\nErro ao criar tabelas: " . $conn->error;
    }

    // Inserir dados nas tabelas individualmente
    $sqls = [
        "INSERT INTO mt5_admin (price_ask, price_bid, price_close, volume_opened, profit_opened, price_entry, datetime_opened, datetime_current, direction_order, position_type)
        VALUES (0, 0, 0, 0, 0, 0, '2024-06-22 13:30:00', '2024-06-24 13:30:00', 0, '')",

        "INSERT INTO mt5_slave (price_ask, price_bid, price_close, volume_opened, profit_opened, price_entry, datetime_opened, datetime_current, direction_order, position_type)
        VALUES (0, 0, 0, 0, 0, 0, '2024-06-22 13:30:00', '2024-06-24 13:30:00', 0, '')",

        "INSERT INTO config_espancador (send_order, limit_spread, profit_takeprofit, profit_stoploss, horario_x, horario_y, type_price_base, minutes_to_exit)
        VALUES (0, 30, 150, -200, '08:00', '18:00', 1, 2)"
    ];

    foreach ($sqls as $sql) {
        if ($conn->query($sql) === TRUE) {
            echo "\nDados inseridos com sucesso!";
        } else {
            echo "\nErro ao inserir dados: " . $conn->error;
        }
    }

    // Fechar a conexão
    $conn->close();
}

if ($_SERVER['REQUEST_METHOD'] === 'GET' && strpos($uri, '/machinne/') === 0) {
    header('Content-Type: application/json');


    $dataAdmin = get_datas_admin();
    $dataSlave = get_datas_slave();
    $configDatas = get_configdatas();

    // Cria um array com todos os dados
    $response = [
        'mt5_admin' => $dataAdmin,
        'mt5_slave' => $dataSlave,
        'config_espancador' => $configDatas
    ];


    if (
        $dataAdmin[0]['volume_opened'] == 0 &&
        $dataSlave[0]['volume_opened'] == 0
    ) {
        $LIMIT_SPREAD = $configDatas[0]['limit_spread'];
        $sizeDiscrepance = 0;
        $type_price_base = $configDatas[0]['type_price_base'];

        if ($configDatas[0]['send_order'] == 1) {
            if ($type_price_base == 1) {
                if ($dataAdmin[0]['price_close'] > $dataSlave[0]['price_close']) {
                    $sizeDiscrepance = $dataAdmin[0]['price_close'] - $dataSlave[0]['price_close'];

                    if ($sizeDiscrepance >= $LIMIT_SPREAD) {
                        update_direction_order_admin(-1);
                        update_direction_order_slave(1);
                        send_response(201, [
                            "message" => "Uma venda em ADMIN | uma compra em SLAVE",
                            "response" => $response
                        ]);
                        return;
                    }
                }
                if ($dataAdmin[0]['price_close'] < $dataSlave[0]['price_close']) {
                    $sizeDiscrepance = $dataSlave[0]['price_close'] - $dataAdmin[0]['price_close'];

                    if ($sizeDiscrepance >= $LIMIT_SPREAD) {
                        update_direction_order_admin(1);
                        update_direction_order_slave(-1);
                        send_response(201, [
                            "message" => "Uma compra em ADMIN | uma venda em SLAVE",
                            "response" => $response
                        ]);
                        return;
                    }
                }
            }



            if ($type_price_base == 2) {
                if ($dataAdmin[0]['price_ask'] > $dataSlave[0]['price_bid']) {
                    $sizeDiscrepance = $dataAdmin[0]['price_ask'] - $dataSlave[0]['price_bid'];

                    if ($sizeDiscrepance >= $LIMIT_SPREAD) {
                        update_direction_order_admin(-1);
                        update_direction_order_slave(1);
                        send_response(201, [
                            "message" => "Uma venda em ADMIN | uma compra em SLAVE",
                            "response" => $response
                        ]);
                        return;
                    }
                }

                if ($dataSlave[0]['price_ask'] > $dataAdmin[0]['price_bid']) {
                    $sizeDiscrepance = $dataSlave[0]['price_ask'] - $dataAdmin[0]['price_bid'];

                    if ($sizeDiscrepance >= $LIMIT_SPREAD) {
                        update_direction_order_admin(1);
                        update_direction_order_slave(-1);
                        send_response(201, [
                            "message" => "Uma compra em ADMIN | uma venda em SLAVE",
                            "response" => $response
                        ]);
                        return;
                    }
                }
            }
        }

        send_response(200, [
            "message" => "Discrepancia insuficiencete [ " . $sizeDiscrepance . " / " . $LIMIT_SPREAD . "",
            "response" => $response
        ]);
    } else {
        /////////////////////////////////////////
        ////// SAÍDA POR TEMPO
        /////////////////////////////////////////
        $datatimeentradaAdmin = $dataAdmin[0]['datetime_opened'];
        $datatimeentradaAdminCurrent = $dataAdmin[0]['datetime_current'];
        $dataOpen = DateTime::createFromFormat('Y.m.d H:i:s', $datatimeentradaAdmin);
        $dataCurrent = DateTime::createFromFormat('Y.m.d H:i:s', $datatimeentradaAdminCurrent);
        $interval = $dataOpen->diff($dataCurrent);
        $minutesOpened = ($interval->days * 24 * 60) + ($interval->h * 60) + $interval->i;
        if ($minutesOpened >= $configDatas[0]['minutes_to_exit']) {
            update_direction_order_admin(99);
            update_direction_order_slave(99);
            send_response(200, [
                "message" => "Tempo mínimo de ordens aberta atingida [ " . $minutesOpened . " / " . $configDatas[0]['minutes_to_exit'] . " ]"
                ,
                "response" => $response   ]);
            return;
        }


        /////////////////////////////////////////
        ////// SAÍDA POR DINHEIRO
        /////////////////////////////////////////
        $LIMIT_PROFIT_GAIN = $configDatas[0]['profit_takeprofit'];
        $LIMIT_PROFIT_LOSS  = $configDatas[0]['profit_stoploss'];
        $saldoContaAdmin = $dataAdmin[0]['profit_opened'];
        $saldoContaSlave = $dataSlave[0]['profit_opened'];
        $volumeAdmin = $dataAdmin[0]['volume_opened'];
        $somaProfits  = ($saldoContaAdmin + $saldoContaSlave);

        if ($somaProfits >= $LIMIT_PROFIT_GAIN) {
            // mandar um 99 nos 2 e informar que deu gain
            update_direction_order_admin(99);
            update_direction_order_slave(99);
            send_response(200, [
                "message" => "Meta de Gain atingida [ " . $somaProfits . " / " . $LIMIT_PROFIT_LOSS . "",
                "response" => $response
            ]);
            return;
        }
        if ($somaProfits <= $LIMIT_PROFIT_LOSS) {
            // mandar um 99 nos 2 e informar que deu loss
            update_direction_order_admin(99);
            update_direction_order_slave(99);
            send_response(200, [
                "message" => "Meta de Loss atingida [ " . $somaProfits . " / " . $LIMIT_PROFIT_LOSS . "",
                "response" => $response
            ]);
            return;
        }
    }


    send_response(200, [
        "response" => $response
    ]);

    return;
}




if ($_SERVER['REQUEST_METHOD'] === 'POST' && strpos($uri, '/send_data_mt5_admin/') === 0) {
    $input = file_get_contents('php://input');

    $data = json_decode($input, true);

    if (json_last_error() === JSON_ERROR_NONE) {
        if (isset(
            $data['volume_opened'],
            $data['price_close'],
            $data['price_ask'],
            $data['price_bid'],
            $data['datetime_opened'],
            $data['profit_opened'],
            $data['position_type']
        )) {

            $last_insert_id = update_mt5_admin($data);
            $datas_config = get_configdatas();
            $response = [
                "send_order" => $datas_config[0]['send_order'],
                "limit_spread" => $datas_config[0]['limit_spread'],
                "profit_takeprofit" => $datas_config[0]['profit_takeprofit'],
                "profit_stoploss" => $datas_config[0]['profit_stoploss'],
                "horario_x" => $datas_config[0]['horario_x'],
                "horario_y" => $datas_config[0]['horario_y'],
                "direction_order" => $last_insert_id
            ];
            send_response(200,  $response);
            return;
        } else {
            send_response(400, ["error" => "Parâmetros incompletos."]);
            return;
        }
    } else {
        send_response(400, ["error" => "JSON malformado."]);
        return;
    }
}



if ($_SERVER['REQUEST_METHOD'] === 'POST' && strpos($uri, '/send_data_mt5_slave/') === 0) {
    $input = file_get_contents('php://input');

    $data = json_decode($input, true);

    if (json_last_error() === JSON_ERROR_NONE) {
        if (isset(
            $data['volume_opened'],
            $data['price_close'],
            $data['price_ask'],
            $data['price_bid'],
            $data['datetime_opened'],
            $data['profit_opened'],
            $data['position_type']
        )) {

            $last_insert_id = update_mt5_slave($data);
            $datas_config = get_configdatas();

            $response = [
                "send_order" => $datas_config[0]['send_order'],
                "limit_spread" => $datas_config[0]['limit_spread'],
                "profit_takeprofit" => $datas_config[0]['profit_takeprofit'],
                "profit_stoploss" => $datas_config[0]['profit_stoploss'],
                "horario_x" => $datas_config[0]['horario_x'],
                "horario_y" => $datas_config[0]['horario_y'],
                "direction_order" => $last_insert_id
            ];

            send_response(200,  $response);
            return;
        } else {
            send_response(400, ["error" => "Parâmetros incompletos."]);
            return;
        }
    } else {
        send_response(400, ["error" => "JSON malformado."]);
        return;
    }
}


if ($_SERVER['REQUEST_METHOD'] === 'POST' && strpos($uri, '/confirm_action_admin/') === 0) {

    update_direction_order_admin(0);
    send_response(200, ["message" => "Dados resetados com sucesso"]);
    return;
}


if ($_SERVER['REQUEST_METHOD'] === 'POST' && strpos($uri, '/confirm_action_slave/') === 0) {

    update_direction_order_slave(0);
    send_response(200, ["message" => "Dados resetados com sucesso"]);
    return;
}





if ($_SERVER['REQUEST_METHOD'] === 'POST' && strpos($uri, '/configuration/') === 0) {
    $input = file_get_contents('php://input');

    $data = json_decode($input, true);

    if (json_last_error() === JSON_ERROR_NONE) {
        if (isset(
            $data['send_order'],
            $data['minutes_to_exit'],
            $data['type_price_base'],
            $data['limit_spread'],
            $data['profit_takeprofit'],
            $data['profit_stoploss'],
            $data['horario_x'],
            $data['horario_y']
        )) {
            update_configuration($data);
            send_response(200, ["message" => "Salvo com sucesso"]);
            return;
        } else {
            send_response(400, ["error" => "Parâmetros incompletos."]);
            return;
        }
    } else {
        send_response(400, ["error" => "JSON malformado."]);
        return;
    }
}


if ($_SERVER['REQUEST_METHOD'] === 'POST' && strpos($uri, '/delete_all_orders/') === 0) {
    update_direction_order_admin(99);
    update_direction_order_slave(99);
    send_response(200, ["message" => "Todas as ordens deletadas"]);
    return;
}



if ($_SERVER['REQUEST_METHOD'] === 'POST' && strpos($uri, '/pause_flow/') === 0) {
    $input = file_get_contents('php://input');

    $data = json_decode($input, true);

    if (json_last_error() === JSON_ERROR_NONE) {
        if (isset(
            $data['send_order']
        )) {

            set_flow_bot($data);

            send_response(200,  "ok -  fazer um post no db com a resposta " . $data['send_order']);
            return;
        } else {
            send_response(400, ["error" => "Parâmetros incompletos."]);
            return;
        }
    } else {
        send_response(400, ["error" => "JSON malformado."]);
        return;
    }
}





http_response_code(405);
echo "Método de requisição não suportado ou URI incorreta.";
