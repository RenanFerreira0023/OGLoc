//+------------------------------------------------------------------+
//|                                             ESPANCADOR_ADMIN.mq5 |
//|                        Copyright 25/06/24,                     . |
//|                            Developer,      Renan Dutra Ferreira. |
//|                                                                  |
//|                   appsskilldeveloper@gmail.com                   |
//|                                OU                                |
//|                    NOS SIGA NO INSTAGRAM [  @_fdutra  ]          |
//                     https://www.mql5.com/en/users/renandutra/     |
//|                        ESPANCADOR_ADMIN                   |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+

#property copyright "Renan Dutra Ferreira"
#property link      "https://www.mql5.com/en/users/renandutra/"
#define VERSION "1.0"
#property version VERSION
#define NAME_BOT "Admin MT5"

#include <JAson.mqh>

#include <Trade/Trade.mqh>
CTrade trade;



int static UNLOCK = 0;
int static LOCK   = 1;

//+------------------------------------------------------------------+
//|                                                                  |
//|                                                                  |
//|  CONFIGURAÇÃO CONTA DEMO                                         |
//|                                                                  |
//|                                                                  |
int lockedDemo = UNLOCK;
bool ENTRY_LOCK = false;
int LOCKED_REAL_MODE = 0;                    // ~~~~  CONFIGURAÇÃO DO CONTROLE DE CONTA ( 0 = demo e real | 1 = somente demo | 2 = somente real )
datetime dtStart = D'2017.01.01 01:00';      // ~~~~ CONFIGURAÇÃO DE DATA INICIO DA CONTA DEMO
datetime dtEnd = D'2099.08.12 12:30';        // ~~~~ CONFIGURAÇÃO DE DATA FIM DA CONTA DEMO
ulong static accountFree[] =
  {
   334628,                                   //~~~~~~ renan genial
// .. 33333333,
// .. 44444444,
// .. 555555555,
   5008776285,                                  //~~~~~~ renan icmarket
   944894
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string demo_module()
  {

   if(LOCKED_REAL_MODE == 1) // 1 = somente demo
      if((MQLInfoInteger(MQL_TESTER)
          || MQLInfoInteger(MQL_DEBUG)
          || MQLInfoInteger(MQL_PROFILER)
          || MQLInfoInteger(MQL_FORWARD)
          || MQLInfoInteger(MQL_OPTIMIZATION)
          || MQLInfoInteger(MQL_VISUAL_MODE))
        )
         return NAME_BOT+" v"+VERSION+"\n CÓPIA LIBERADA APENAS PARA AMBIENTE DE TESTE.";

   if(LOCKED_REAL_MODE == 2) // 2 = somente real
      if(!(MQLInfoInteger(MQL_TESTER)
           || MQLInfoInteger(MQL_DEBUG)
           || MQLInfoInteger(MQL_PROFILER)
           || MQLInfoInteger(MQL_FORWARD)
           || MQLInfoInteger(MQL_OPTIMIZATION)
           || MQLInfoInteger(MQL_VISUAL_MODE))
        )
         return NAME_BOT+" v"+VERSION+"\n CÓPIA LIBERADA APENAS PARA AMBIENTE DE PRODUÇÃO.";

   datetime dtNow = TimeCurrent();


//   if(valid_number_account() == LOCK)
//      return NAME_BOT+" v"+VERSION+"\n CONTA NÃO AUTORIZADA PARA ESTA CÓPIA.";

   if(dtNow > dtEnd)
      return NAME_BOT+" v"+VERSION+"\nDemo Finalizada, obrigado :) ";
   else
     {
      if(MQLInfoInteger(MQL_TESTER))
        {
         datetime dtNow = TimeCurrent();


         if(dtNow < dtEnd &&
            dtNow > dtStart)
            return "";
         else
            return NAME_BOT+" v"+VERSION+"\nDemo Finalizada, obrigado :) ";
        }
      return "";
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int valid_number_account()
  {
   long loginAccount = AccountInfoInteger(ACCOUNT_LOGIN);
   for(int i = 0; i < ArraySize(accountFree) ; i++)
      if(accountFree[i] == loginAccount)
         return UNLOCK;
   return LOCK;
  }

//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+




enum SELECT_POWER_BOT
  {
   bot_on = 1, // Ligado
   bot_off = 0 // Desligado

  };

enum SELECT_TYPE_OUT
  {
   type_bot_off      = 0,  // OFF
   type_bot_distance = 1,  // Distancia ( em Pnts baseado pelo grafico )
   type_bot_percent = 2  // Percentual
  };

enum SELECT_PRICE_BASE
  {
   price_base_closed = 1, // Fechamento
   price_base_ask_bid = 2 // Ask e Bid
  };


input int      MAGIC_NUM                                       = 8435434;                 // Número mágico
input string         URL_BASE                                  = "192.168.1.10";           // IP do PC
input double         INITIAL_LOT                               =25;                       // Lote envio
input group       "  Configuração compartilhada entre os 2 metatraders";
input SELECT_POWER_BOT           POWER_AUTOMATIZATION          = bot_off;                 // Liga/Desliga
input string         HOURS_X                                   =  "09:00";             // Horário início
input string         HOURS_Y                                   =  "17:00";             // Horário fim
input int            MINUTES_TO_EXIT_ORDER                     = 2;                       // Minutos para encerrar ordem
input double         SPREAD_LIMIT                              = 0.20;                      // Tamanho minimo do spread
input double         GOAL_TAKEPROFIT                           = 15;                         // ($) Meta Gain
input double         GOAL_STOPLOSS                             = -15;                     // ($) Meta Loss
input SELECT_PRICE_BASE TYPE_PRICE_BASE                         = price_base_closed;       // Preço Base
input group       "  TakeProfit e StopLoss ( Individual por bot )         ";
input SELECT_TYPE_OUT TYPE_OUT                                  = type_bot_off;        // Tipo de saída por distancia
input double         VALUE_TAKEPROFIT                             = 0;                    //  Valor TakeProfit
input double         VALUE_STOPLOSS                               = 0;                  // Valor StopLoss

bool static YES   = true;
bool static NO    = false;





struct STC_DATAS_MT5
  {
   double            price_ask;
   double            price_bid;
   double            price_close;
   double            volume_opened;
   double            profit_opened;
   datetime          datetime_opened;
   int               direction_order;
   double            price_entry;
   string            position_type;

  };

struct STC_DATAS_CONFIG
  {
   int               send_order;
   int               type_price_base;
   double               limit_spread;
   double               profit_takeprofit;
   double              profit_stoploss;
   string               horario_x;
   string               horario_y;
  };




int GLOBAL_SEND_ORDER = 0;


string URL_SERVER;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   trade.SetExpertMagicNumber(MAGIC_NUM);

   URL_SERVER = "http://"+URL_BASE+"/EspancadorMT5/api.php";

   GLOBAL_SEND_ORDER = 0;

   TIME_WAIT_A_LOT = TimeCurrent() + 5;

   EventSetMillisecondTimer(700);

   post_configuration();
   post_pause_flow(POWER_AUTOMATIZATION);

   create_button(ChartID(),"BTN_PAUSAR",0,5,350,
                 150,30,CORNER_LEFT_UPPER,"LIGA/DESLIGA","Arial",10,clrWhite,C'0,128,255',clrWhite,false,false,false,0);

   create_button(ChartID(),"BTN_DELL_ALL",0,5,400,
                 150,30,CORNER_LEFT_UPPER,"ZERAR TUDO","Arial",10,clrWhite,C'255,21,21',clrWhite,false,false,false,0);

   wait_a_lot = TimeCurrent();

   return(INIT_SUCCEEDED);
  }


datetime wait_a_lot;
datetime TIME_WAIT_A_LOT;
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTimer()
  {

   if(demo_module() != "")
     {
      if(lockedDemo == UNLOCK)
        {
         Alert(demo_module());
         Comment(demo_module());
         Print(demo_module());
         lockedDemo  = LOCK;
        }
      return;
     }


   project_takeprofit_and_stoploss();

   string msgRequest = "";
   STC_DATAS_MT5 dataAdmin;
   STC_DATAS_MT5 dataSlave;
   STC_DATAS_CONFIG dataConfig;
   engine_macchine(dataAdmin,dataSlave,dataConfig,msgRequest);


   print_panel(dataAdmin,dataSlave,dataConfig);



   int requestDirectOrder = 0;
   int sendOrder = 0;           // botao liga/desliga
   double limitSpread = 0;
   double profitTakeProfit = 0;
   double profitStopLoss = 0;
   string requestHoursX = "";
   string requestHoursY = "";
   post_send_datas(requestDirectOrder,
                   sendOrder,           // botao liga/desliga
                   limitSpread,
                   profitTakeProfit,
                   profitStopLoss,
                   requestHoursX,
                   requestHoursY);

// deleta


   if(requestDirectOrder == 99)
     {
      TIME_WAIT_A_LOT = TimeCurrent() + 5;
      if(TimeCurrent() > wait_a_lot)
        {
         delete_all_orders_opened();
         wait_a_lot = TimeCurrent() + 5;
        }
      confirm_action_admin();
      Print("Deletado pelo sistema    "+ msgRequest);
     }



   if(sendOrder == 0) // Botao liga/desliga  esta DESLIGADO
      return;

   if(TimeCurrent() < TIME_WAIT_A_LOT)
      return;



   bool isOnHours = hours_zone_today(requestHoursX,requestHoursY);
   if(isOnHours == NO)
     {
      Print("Fora do horário permitido [ das "+requestHoursX+" as "+requestHoursY+" ]");
      return;
     }



   if(is_position() == YES)
      return;

// Mnadar compra
   if(requestDirectOrder == 1)
     {
      TIME_WAIT_A_LOT = TimeCurrent() + 5;
      buy_market(0,0,INITIAL_LOT,"");
      confirm_action_admin();
     }

// Mnadar venda
   if(requestDirectOrder == -1)
     {
      TIME_WAIT_A_LOT = TimeCurrent() + 5;
      sell_market(0,0,INITIAL_LOT,"");
      confirm_action_admin();
     }


  }
//+------------------------------------------------------------------+



//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ObjectsDeleteAll(ChartID(),0);
   EventKillTimer();
   Comment("");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//| Expert chart event function                                      |
//|                                                                  |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,         // event ID
                  const long& lparam,   // event parameter of the long type
                  const double& dparam, // event parameter of the double type
                  const string& sparam)   // event parameter of the string type
  {


   if(id == CHARTEVENT_OBJECT_CLICK)
     {
      if(StringFind(sparam,"BTN_PAUSAR",0) > -1)
        {

         if(GLOBAL_SEND_ORDER == 1)
            GLOBAL_SEND_ORDER = 0;
         else
            if(GLOBAL_SEND_ORDER == 0)
               GLOBAL_SEND_ORDER = 1;


         post_pause_flow(GLOBAL_SEND_ORDER);
        }

      if(StringFind(sparam,"BTN_DELL_ALL",0) > -1)
        {
         post_delete_all_orders();

         GLOBAL_SEND_ORDER = 0;
         post_pause_flow(GLOBAL_SEND_ORDER);
        }
     }
  }




//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string create_json_configuration()
  {

   string itemJson = "";

   itemJson += "{";
   itemJson += "\"send_order\":\""+POWER_AUTOMATIZATION+"\",";
   itemJson += "\"limit_spread\":\""+SPREAD_LIMIT+"\",";
   itemJson += "\"minutes_to_exit\":\""+MINUTES_TO_EXIT_ORDER+"\",";
   itemJson += "\"profit_takeprofit\":\""+GOAL_TAKEPROFIT+"\",";
   itemJson += "\"profit_stoploss\":\""+GOAL_STOPLOSS+"\",";
   itemJson += "\"type_price_base\":\""+TYPE_PRICE_BASE+"\",";
   itemJson += "\"horario_x\":\""+HOURS_X+"\",";
   itemJson += "\"horario_y\":\""+HOURS_Y+"\"";
   itemJson += "}";


   return itemJson;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void post_pause_flow(int status)
  {

   string msgError = "";



   int loopAuth = 0;
   do
     {
      int retCode = 0;


      string jsonToken = "";


      jsonToken += "{";
      jsonToken += "\"send_order\":\""+status+"\"";
      jsonToken += "}";



      string urlToken = URL_SERVER+"/pause_flow/";
      post_webrequest(urlToken,jsonToken,retCode,jsonToken);
      string msgError = "";

      if(retCode == 200 || retCode == 201)
        {
         msgError = "";


         loopAuth = GLOBAL_LIMIT_LOOP + 2;
         break;
        }
      else
        {
         if(retCode == 1001)
            msgError += ("Servidor fora do ar .");
         else
           {
            CJAVal json;
            json.Deserialize(jsonToken);
            msgError += json["error"].ToStr();
            Print("  -     "+retCode);
            Print("erro na solicitação    "+msgError);
           }
         loopAuth++;
         Print("\n"+urlToken+"\nTentativa de conecção :   "+loopAuth+" / "+GLOBAL_LIMIT_LOOP);
         Sleep(700);
        }
     }
   while(loopAuth <= GLOBAL_LIMIT_LOOP);
  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void post_delete_all_orders()
  {

   string msgError = "";

   int loopAuth = 0;
   do
     {
      int retCode = 0;
      string jsonToken = "";
      string urlToken = URL_SERVER+"/delete_all_orders/";
      post_webrequest(urlToken,"",retCode,jsonToken);
      string msgError = "";

      if(retCode == 200 || retCode == 201)
        {
         msgError = "";


         loopAuth = GLOBAL_LIMIT_LOOP + 2;
         break;
        }
      else
        {
         if(retCode == 1001)
            msgError += ("Servidor fora do ar .");
         else
           {
            CJAVal json;
            json.Deserialize(jsonToken);
            msgError += json["error"].ToStr();
            Print("  -     "+retCode);
            Print("erro na solicitação    "+msgError);
           }
         loopAuth++;
         Print("\n"+urlToken+"\nTentativa de conecção :   "+loopAuth+" / "+GLOBAL_LIMIT_LOOP);
         Sleep(700);
        }
     }
   while(loopAuth <= GLOBAL_LIMIT_LOOP);

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void post_configuration()
  {
   string json = create_json_configuration();
   string msgError = "";

   int loopAuth = 0;
   do
     {
      int retCode = 0;
      string jsonToken = "";
      string urlToken = URL_SERVER+"/configuration/";
      post_webrequest(urlToken,json,retCode,jsonToken);
      string msgError = "";

      if(retCode == 200 || retCode == 201)
        {
         msgError = "";


         loopAuth = GLOBAL_LIMIT_LOOP + 2;
         break;
        }
      else
        {
         if(retCode == 1001)
            msgError += ("Servidor fora do ar .");
         else
           {
            CJAVal json;
            json.Deserialize(jsonToken);
            msgError += json["error"].ToStr();
            Print("  -     "+retCode);
            Print("erro na solicitação    "+msgError);
           }
         loopAuth++;
         Print("\n"+urlToken+"\nTentativa de conecção :   "+loopAuth+" / "+GLOBAL_LIMIT_LOOP);
         Sleep(700);
        }
     }
   while(loopAuth <= GLOBAL_LIMIT_LOOP);
  }

//+------------------------------------------------------------------+
//| Criar o botão                                                    |
//+------------------------------------------------------------------+
bool create_button(const long              chart_ID=0,               // ID do gráfico
                   const string            name="Button",            // nome do botão
                   const int               sub_window=0,             // índice da sub-janela
                   const int               x=0,                      // coordenada X
                   const int               y=0,                      // coordenada Y
                   const int               width=50,                 // largura do botão
                   const int               height=18,                // altura do botão
                   const ENUM_BASE_CORNER  corner=CORNER_LEFT_UPPER, // canto do gráfico para ancoragem
                   const string            text="Button",            // texto
                   const string            font="Arial",             // fonte
                   const int               font_size=10,             // tamanho da fonte
                   const color             clr=clrBlack,             // cor do texto
                   const color             back_clr=C'236,233,216',  // cor do fundo
                   const color             border_clr=clrNONE,       // cor da borda
                   const bool              state=false,              // pressionada/liberada
                   const bool              back=false,               // no fundo
                   const bool              selection=false,          // destaque para mover
                   const bool              hidden=true,              // ocultar na lista de objeto
                   const long              z_order=0)                // prioridade para clicar no mouse
  {
//--- redefine o valor de erro
   ResetLastError();
//--- criar o botão
   if(!ObjectCreate(chart_ID,name,OBJ_BUTTON,sub_window,0,0))
     {
      Print(__FUNCTION__,
            ": falha ao criar o botão! Código de erro = ",GetLastError());
      return(false);
     }
//--- definir coordenadas do botão
   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y);
//--- definir tamanho do botão
   ObjectSetInteger(chart_ID,name,OBJPROP_XSIZE,width);
   ObjectSetInteger(chart_ID,name,OBJPROP_YSIZE,height);
//--- determinar o canto do gráfico onde as coordenadas do ponto são definidas
   ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,corner);
//--- definir o texto
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
//--- definir o texto fonte
   ObjectSetString(chart_ID,name,OBJPROP_FONT,font);
//--- definir tamanho da fonte
   ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size);
//--- definir a cor do texto
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- definir a cor de fundo
   ObjectSetInteger(chart_ID,name,OBJPROP_BGCOLOR,back_clr);
//--- definir a cor da borda
   ObjectSetInteger(chart_ID,name,OBJPROP_BORDER_COLOR,border_clr);
//--- exibir em primeiro plano (false) ou fundo (true)
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- set button state
   ObjectSetInteger(chart_ID,name,OBJPROP_STATE,state);
//--- habilitar (true) ou desabilitar (false) o modo do movimento do botão com o mouse
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
//--- ocultar (true) ou exibir (false) o nome do objeto gráfico na lista de objeto
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- definir a prioridade para receber o evento com um clique do mouse no gráfico
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- sucesso na execução

   return(true);
  }




//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void  engine_macchine(STC_DATAS_MT5 &dataAdmin,
                      STC_DATAS_MT5 &dataSlave,
                      STC_DATAS_CONFIG &dataConfig,
                      string &msgRequest)
  {

   string msgError = "";

   int loopAuth = 0;
   do
     {
      int retCode = 0;
      string jsonToken = "";
      string urlToken = URL_SERVER+"/machinne/";
      get_webrequest(urlToken,NO,retCode,jsonToken);
      string msgError = "";

      if(retCode == 200 || retCode == 201)
        {
         msgError = "";
         //         Print("Motor ligado ");

         CJAVal json;
         json.Deserialize(jsonToken);
         double price_ask  = json["response"]["mt5_admin"][0]["price_ask"].ToDbl();
         double price_bid  = json["response"]["mt5_admin"][0]["price_bid"].ToDbl();
         double price_close  = json["response"]["mt5_admin"][0]["price_close"].ToDbl();
         double volume_opened  = json["response"]["mt5_admin"][0]["volume_opened"].ToDbl();
         double profit_opened  = json["response"]["mt5_admin"][0]["profit_opened"].ToDbl();
         string datetime_opened  = json["response"]["mt5_admin"][0]["datetime_opened"].ToStr();
         int direction_order  = json["response"]["mt5_admin"][0]["direction_order"].ToInt();
         double price_entry  = json["response"]["mt5_admin"][0]["price_entry"].ToDbl();
         string position_type  = json["response"]["mt5_admin"][0]["position_type"].ToStr();
         dataAdmin.price_ask = price_ask;
         dataAdmin.price_bid = price_bid;
         dataAdmin.price_close = price_close;
         dataAdmin.volume_opened = volume_opened;
         dataAdmin.profit_opened = profit_opened;
         dataAdmin.datetime_opened = datetime_opened;
         dataAdmin.direction_order = direction_order;
         dataAdmin.price_entry = price_entry;
         dataAdmin.position_type = position_type;

         /////////////////////////////////
         /////////////////////////////////
         /////////////////////////////////


         price_ask  = json["response"]["mt5_slave"][0]["price_ask"].ToDbl();
         price_bid  = json["response"]["mt5_slave"][0]["price_bid"].ToDbl();
         price_close  = json["response"]["mt5_slave"][0]["price_close"].ToDbl();
         volume_opened  = json["response"]["mt5_slave"][0]["volume_opened"].ToDbl();
         profit_opened  = json["response"]["mt5_slave"][0]["profit_opened"].ToDbl();
         datetime_opened  = json["response"]["mt5_slave"][0]["datetime_opened"].ToStr();
         direction_order  = json["response"]["mt5_slave"][0]["direction_order"].ToInt();
         price_entry  = json["response"]["mt5_slave"][0]["price_entry"].ToDbl();
         position_type  = json["response"]["mt5_slave"][0]["position_type"].ToStr();
         dataSlave.price_ask = price_ask;
         dataSlave.price_bid = price_bid;
         dataSlave.price_close = price_close;
         dataSlave.volume_opened = volume_opened;
         dataSlave.profit_opened = profit_opened;
         dataSlave.datetime_opened = datetime_opened;
         dataSlave.direction_order = direction_order;
         dataSlave.price_entry = price_entry;
         dataSlave.position_type = position_type;


         /////////////////////////////////
         /////////////////////////////////
         /////////////////////////////////


         int send_order  = json["response"]["config_espancador"][0]["send_order"].ToInt();
         int type_price_base  = json["response"]["config_espancador"][0]["type_price_base"].ToInt();
         double limit_spread  = json["response"]["config_espancador"][0]["limit_spread"].ToDbl();
         double profit_takeprofit  = json["response"]["config_espancador"][0]["profit_takeprofit"].ToDbl();
         double profit_stoploss  = json["response"]["config_espancador"][0]["profit_stoploss"].ToDbl();
         string horario_x  = json["response"]["config_espancador"][0]["horario_x"].ToStr();
         string horario_y  = json["response"]["config_espancador"][0]["horario_y"].ToStr();
         dataConfig.send_order = send_order;
         dataConfig.type_price_base = type_price_base;
         dataConfig.limit_spread = limit_spread;
         dataConfig.profit_takeprofit = profit_takeprofit;
         dataConfig.profit_stoploss = profit_stoploss;
         dataConfig.horario_x = horario_x;
         dataConfig.horario_y = horario_y;


         ////////////////////////

         msgRequest = json["message"].ToStr();


         loopAuth = GLOBAL_LIMIT_LOOP + 2;
         break;
        }
      else
        {
         if(retCode == 1001)
            msgError += ("Servidor fora do ar .");
         else
           {
            CJAVal json;
            json.Deserialize(jsonToken);
            msgError += json["error"].ToStr();
            Print("  -     "+retCode);
            Print("erro na solicitação    "+msgError);
           }
         loopAuth++;
         Print("\n"+urlToken+"\nTentativa de conecção :   "+loopAuth+" / "+GLOBAL_LIMIT_LOOP);
         Sleep(700);
        }
     }
   while(loopAuth <= GLOBAL_LIMIT_LOOP);

  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void  print_panel(STC_DATAS_MT5 &dataAdmin,
                  STC_DATAS_MT5 &dataSlave,
                  STC_DATAS_CONFIG &dataConfig)
  {

   string msgPanel = "";

   msgPanel += "\n#####################################";
   msgPanel += "\n##########  "+NAME_BOT+" "+VERSION+" ##############";
   msgPanel += "\n#####################################\n";
   msgPanel += "  "+TimeCurrent()+"\n\n";

   if(dataConfig.send_order == 0)
      msgPanel += "\n       ~~~~~~~>>   Sistema Pausado   <<~~~~~~~";
   else
      msgPanel += "\n       ~~~~~~~>>   R O D A N D O   <<~~~~~~~";




   bool isOnHours = hours_zone_today(dataConfig.horario_x,dataConfig.horario_y);
   if(isOnHours == NO)
      msgPanel += "\n     ~~~~~~~>>   Sistema Pausado   <<~~~~~~~ \n              Fora do horário permitido [ das "+dataConfig.horario_x +" as "+dataConfig.horario_y+" ]";

   msgPanel += "\n\n                  Discrepancias  ";

   msgPanel += "\n    MT5 Adm      ||     "+NormalizeDouble(dataAdmin.price_close,_Digits);
   msgPanel += "    ||  Ask  "+dataAdmin.price_ask+"       ";
   msgPanel += "    ||  Bid  "+dataAdmin.price_bid+"       ";


   msgPanel += "\n    MT5 Slave    ||     "+NormalizeDouble(dataSlave.price_close,_Digits);
   msgPanel += "    ||  Bid  "+dataAdmin.price_bid+"       ";
   msgPanel += "    ||  Ask  "+dataAdmin.price_ask+"       ";


   msgPanel += "\n                           ||     "+(MathAbs(NormalizeDouble((dataAdmin.price_close - dataSlave.price_close),_Digits)));
   msgPanel += "    ||    "+(MathAbs(NormalizeDouble((dataAdmin.price_bid - dataSlave.price_ask),_Digits)));
   msgPanel += "                     ||    "+(MathAbs(NormalizeDouble((dataAdmin.price_bid - dataSlave.price_ask),_Digits)));
   msgPanel += "\n\n#####################################\n";


   if(is_position() == YES)
     {
      msgPanel += "\n                  Em operação  \n";


      msgPanel +=  "\n        MT5 Admin  ->   "+dataAdmin.position_type+"  R$  "+dataAdmin.profit_opened;
      msgPanel +=  "         |   Lote "+dataAdmin.volume_opened;

      msgPanel +=  "\n        MT5 Slave  ->   "+dataSlave.position_type+"  R$  "+dataSlave.profit_opened;
      msgPanel +=  "         |   Lote "+dataSlave.volume_opened;
      msgPanel +=  "\n                       ________________________________";
      msgPanel +=  "\n                                 R$  "+((dataAdmin.profit_opened + dataSlave.profit_opened));
      msgPanel +=  "                     Lotes  "+((dataAdmin.volume_opened + dataSlave.volume_opened));

     }


   Comment(msgPanel);

  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void project_takeprofit_and_stoploss()
  {
   if(TYPE_OUT == type_bot_off)
      return;

   int total=PositionsTotal();

   if(total == 0)
      return;

   for(int cnt=0; cnt<total; cnt++)
     {
      string symbol = PositionGetSymbol(cnt);
      ulong magic = PositionGetInteger(POSITION_MAGIC);
      if(_Symbol == symbol  && magic == MAGIC_NUM)
        {
         ulong ticket = PositionGetInteger(POSITION_TICKET);

         double slCurrent = PositionGetDouble(POSITION_SL);
         double tpCurrent = PositionGetDouble(POSITION_TP);

         if(slCurrent == 0 || tpCurrent == 0)
           {

            ENUM_POSITION_TYPE position_type  = PositionGetInteger(POSITION_TYPE);
            double priceEntry = PositionGetDouble(POSITION_PRICE_OPEN);
            double priceCurrent = PositionGetDouble(POSITION_PRICE_CURRENT);
            double newTakeProfit = 0;
            double newStopLoss = 0;
            if(position_type == POSITION_TYPE_BUY)
              {

               if(TYPE_OUT == type_bot_distance)
                 {
                  newTakeProfit = priceEntry + return_value_inputs(VALUE_TAKEPROFIT);
                  newStopLoss = priceEntry - return_value_inputs(VALUE_STOPLOSS);
                 }
               if(TYPE_OUT == type_bot_percent)
                 {
                  newTakeProfit = get_price_to_percent(priceEntry,VALUE_TAKEPROFIT);
                  newStopLoss = get_price_to_percent(priceEntry,-VALUE_STOPLOSS);
                 }
              }

            if(position_type == POSITION_TYPE_SELL)
              {
               if(TYPE_OUT == type_bot_distance)
                 {
                  newTakeProfit = priceEntry - return_value_inputs(VALUE_TAKEPROFIT);
                  newStopLoss = priceEntry + return_value_inputs(VALUE_STOPLOSS);
                 }
               if(TYPE_OUT == type_bot_percent)
                 {
                  newTakeProfit = get_price_to_percent(priceEntry,-VALUE_TAKEPROFIT);
                  newStopLoss = get_price_to_percent(priceEntry,VALUE_STOPLOSS);
                 }
              }

            trade.PositionModify(ticket,newStopLoss,newTakeProfit);

           }
        }
     }


  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double get_percentual(double preco_inicial, double preco_final)
  {
   return ((preco_final - preco_inicial) / preco_inicial) * 100;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double get_price_to_percent(double preco_inicial, double porcentagem)
  {
   return preco_inicial * (1 + porcentagem / 100);
  }




//+------------------------------------------------------------------+
//|                                                                  |
//| Methot that converting number to PIPs, TICKs and PONTOS          |
//|                                                                  |
//+------------------------------------------------------------------+
double return_value_inputs(double valueInput)
  {
   return (valueInput*_Point);
  }




//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool hours_out_operation(bool usinghorus, string HOURS)
  {
   if(usinghorus == NO)
      return NO;

   datetime entryHours = TimeCurrent();

   string onlyDate =  TimeToString(entryHours,TIME_DATE);
   datetime timeFake = StringToTime(onlyDate+" "+HOURS);

   if(entryHours > timeFake)
      return YES;
   return NO;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool hours_zone_today(string HOURS_X, string HOURS_Y)
  {

   if(HOURS_X == "00:00" &&
      HOURS_Y == "00:00")
      return YES;
   datetime entryHours = TimeCurrent();

   string onlyDate =  TimeToString(entryHours,TIME_DATE);
   datetime timeFakeX = StringToTime(onlyDate+" "+HOURS_X);
   datetime timeFakeY = StringToTime(onlyDate+" "+HOURS_Y);
   datetime timeFakeZ = StringToTime(onlyDate+" "+entryHours);

   if(timeFakeX <= entryHours && timeFakeY >= entryHours)
      return YES;
   return NO;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void confirm_action_admin()
  {

   string msgError = "";

   int loopAuth = 0;
   do
     {
      int retCode = 0;
      string jsonToken = "";
      string urlToken = URL_SERVER+"/confirm_action_admin/";
      post_webrequest(urlToken,"",retCode,jsonToken);
      string msgError = "";

      if(retCode == 200 || retCode == 201)
        {
         msgError = "";


         loopAuth = GLOBAL_LIMIT_LOOP + 2;
         break;
        }
      else
        {
         if(retCode == 1001)
            msgError += ("Servidor fora do ar .");
         else
           {
            CJAVal json;
            json.Deserialize(jsonToken);
            msgError += json["error"].ToStr();
            Print("  -     "+retCode);
            Print("erro na solicitação    "+msgError);
           }
         loopAuth++;
         Print("\n"+urlToken+"\nTentativa de conecção :   "+loopAuth+" / "+GLOBAL_LIMIT_LOOP);
         Sleep(700);
        }
     }
   while(loopAuth <= GLOBAL_LIMIT_LOOP);

  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void delete_all_orders_opened()
  {

   int total = PositionsTotal();

   if(total == 0)
      return;

   double arrayTktForDell[];
   ArrayFree(arrayTktForDell);
   ArrayResize(arrayTktForDell,true);
   ArrayResize(arrayTktForDell,0);
   ArrayPrint(arrayTktForDell);
   for(int i = 0; i < total; i++)
     {
      ulong ticket = PositionGetTicket(i);
      string symbol = PositionGetSymbol(i);
      ulong magic = PositionGetInteger(POSITION_MAGIC);
      if((_Symbol == symbol && magic == MAGIC_NUM))
        {
         ArrayResize(arrayTktForDell,ArraySize(arrayTktForDell)+1);
         arrayTktForDell[ArraySize(arrayTktForDell)-1] = ticket;
        }
     }

   if(ArraySize(arrayTktForDell) == 0)
      return; // tem ordens abertas mais nenhuma deste bot

   int numOperationOpened = ArraySize(arrayTktForDell);

   int loopCount = 0;
   int loopCountError  = 0;
   while(loopCount < ArraySize(arrayTktForDell) || loopCountError > 5)
     {


      ulong tkt = arrayTktForDell[loopCount];

      CPositionInfo myPosition;
      if(myPosition.SelectByTicket(tkt) == YES)
         if(trade.PositionClose(tkt) == true)
            loopCount++;
         else
            loopCountError++;


      if(loopCountError > 5)
         break;
     };
  }





static int GLOBAL_LIMIT_LOOP = 10;



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string create_json_send_order(double &volume_opened,
                              double &price_ask,
                              double &price_close,
                              double &price_bid,
                              double &price_entry,
                              datetime &datetime_opened,
                              double &profit_opened,
                              string &position_type)
  {


   if(is_position() == true)
     {
      int total=PositionsTotal();

      for(int cnt=0; cnt<total; cnt++)
        {
         string symbol = PositionGetSymbol(cnt);
         ulong magic = PositionGetInteger(POSITION_MAGIC);
         if(_Symbol == symbol  && magic == MAGIC_NUM)
           {
            volume_opened += PositionGetDouble(POSITION_VOLUME);
            price_entry = PositionGetDouble(POSITION_PRICE_OPEN);
            datetime_opened = (datetime)PositionGetInteger(POSITION_TIME);
            profit_opened += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);

            ENUM_POSITION_TYPE positionType = PositionGetInteger(POSITION_TYPE);
            if(positionType == POSITION_TYPE_BUY)
               position_type = "BUY";
            if(positionType == POSITION_TYPE_SELL)
               position_type = "SELL";

           }
        }

     }
   price_ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   price_close = iClose(_Symbol,PERIOD_CURRENT,0);
   price_bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);


   string itemJson = "";

   itemJson += "{";
   itemJson += "\"volume_opened\":\""+volume_opened+"\",";
   itemJson += "\"price_ask\":\""+price_ask+"\",";
   itemJson += "\"price_close\":\""+price_close+"\",";
   itemJson += "\"price_bid\":\""+price_bid+"\",";
   itemJson += "\"price_entry\":\""+price_entry+"\",";
   itemJson += "\"datetime_opened\":\""+datetime_opened+"\",";
   itemJson += "\"datetime_current\":\""+TimeCurrent()+"\",";
   itemJson += "\"profit_opened\":\""+profit_opened+"\",";
   itemJson += "\"position_type\":\""+position_type+"\"";

   itemJson += "}";

   return itemJson;
  }





//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool is_position()
  {
   int total=PositionsTotal();

   if(total == 0)
      return false;

   for(int cnt=0; cnt<total; cnt++)
     {
      string symbol = PositionGetSymbol(cnt);
      ulong magic = PositionGetInteger(POSITION_MAGIC);
      if(_Symbol == symbol  && magic == MAGIC_NUM)
        {
         return true;
        }
     }
   return false;
  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void post_send_datas(int &direcaoOrdem,
                     int &sendOrder,           // botao liga/desliga
                     double &limitSpread,
                     double &profitTakeProfit,
                     double &profitStopLoss,
                     string &requestHoursX,
                     string &requestHoursY)

  {

   double volume_opened = 0;
   double price_ask = 0;
   double price_close = 0;
   double price_bid = 0;
   double price_entry = 0;
   datetime datetime_opened = TimeCurrent();
   double profit_opened = 0;
   string position_type = "";
   string jsonData = create_json_send_order(volume_opened,
                     price_ask,
                     price_close,
                     price_bid,
                     price_entry,
                     datetime_opened,
                     profit_opened,
                     position_type);


   string msgError = "";

   int loopAuth = 0;
   do
     {
      int retCode = 0;
      string jsonToken = "";
      string urlToken = URL_SERVER+"/send_data_mt5_admin/";
      post_webrequest(urlToken,jsonData,retCode,jsonToken);
      string msgError = "";

      if(retCode == 200 || retCode == 201)
        {
         msgError = "";


         CJAVal json;
         json.Deserialize(jsonToken);
         direcaoOrdem = json["direction_order"].ToInt();
         sendOrder = json["send_order"].ToInt();
         limitSpread = json["limit_spread"].ToDbl();
         profitTakeProfit = json["profit_takeprofit"].ToDbl();
         profitStopLoss = json["profit_stoploss"].ToDbl();
         requestHoursX = json["horario_x"].ToStr();
         requestHoursY = json["horario_y"].ToStr();

         loopAuth = GLOBAL_LIMIT_LOOP + 2;
         break;
        }
      else
        {

         if(retCode == 1001)
            msgError += ("Servidor fora do ar .");
         else
           {
            CJAVal json;
            json.Deserialize(jsonToken);
            msgError += json["error"].ToStr();
            Print("  -     "+retCode);
            Print("1111  erro na solicitação    "+msgError);
           }
         loopAuth++;
         Print("\n"+urlToken+"\n Tentativa de conecção :   "+loopAuth+" / "+GLOBAL_LIMIT_LOOP);
         Sleep(700);
        }
     }
   while(loopAuth <= GLOBAL_LIMIT_LOOP);

   if(msgError != "")
     {
      Print(msgError);
      Alert(msgError);
     }

  }





//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void get_webrequest(string url, bool headersUsing,int &retCode, string &requestJson)
  {
   string jsonData = "";
   int jsonDataSize = 0;
   uchar jsonDataChar[];
   StringToCharArray(jsonData, jsonDataChar, 0,jsonDataSize,CP_UTF8);

   uchar serverResult[];
   string serverHeaders;
   retCode = WebRequest("GET", url,"",500,jsonDataChar,  serverResult, serverHeaders);
   if(retCode == 200 || retCode == 201)
      requestJson = CharArrayToString(serverResult,0,ArraySize(serverResult), CP_UTF8);
   else
      if(retCode == 1001)
        {
         requestJson = ("Servidor não encontrado");
        }
      else
         requestJson = CharArrayToString(serverResult,0,ArraySize(serverResult), CP_UTF8);
  }






//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void post_webrequest(string url, string jsonData, int &retCode, string &requestJson)
  {
   int jsonDataSize = StringLen(jsonData);
   uchar jsonDataChar[];
   StringToCharArray(jsonData, jsonDataChar, 0,jsonDataSize,CP_UTF8);

   uchar serverResult[];
   string serverHeaders;
   retCode = WebRequest("POST", url,"",500,jsonDataChar,  serverResult, serverHeaders);
   if(retCode == 200 || retCode == 201)
      requestJson = CharArrayToString(serverResult,0,ArraySize(serverResult), CP_UTF8);
   else
      if(retCode == 1001)
        {
         requestJson = ("Servidor não encontrado");
        }
      else
         requestJson = CharArrayToString(serverResult,0,ArraySize(serverResult), CP_UTF8);
  }
//+------------------------------------------------------------------+





//+------------------------------------------------------------------+
//|                                                                  |
//|  send BUY to market                                              |
//|                                                                  |
//+------------------------------------------------------------------+
ulong buy_market(double takeprofit,double stoploss, double lots, string comment)
  {
   double ask = SymbolInfoDouble(_Symbol,   SYMBOL_ASK);
   if(lots < 0)
      lots = +lots;

   bool ok = trade.Buy(lots, _Symbol,ask, stoploss, takeprofit,comment);
   if(!ok)
     {
      int errorCode = GetLastError();
      Print("lots    "+lots+"   BuyMarket : "+errorCode+"         |        ResultRetcode :  "+trade.ResultRetcode());
      ResetLastError();
      return -1;
     }

   Print("\n===== A MERDADO COMPRA | RESULT RET CODE :  "+trade.ResultRetcode());
   Print("LOTE ENVIADO  :  "+lots);
   ulong order = trade.ResultOrder();

   Print("TKT OFERTA : "+order);
   return order;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//|  send SELL to market                                             |
//|                                                                  |
//+------------------------------------------------------------------+
ulong sell_market(double takeprofit,double stoploss, double lots, string comment)
  {
   double bid = SymbolInfoDouble(_Symbol,   SYMBOL_BID);
   if(lots < 0)
      lots = +lots;

   bool ok = trade.Sell(lots, _Symbol,bid, stoploss, takeprofit,comment);
   if(!ok)
     {
      int errorCode = GetLastError();
      Print("lots    "+lots+"    SellMarket : "+errorCode+"         |        ResultRetcode :  "+trade.ResultRetcode());
      ResetLastError();
      return -1;
     }

   Print("\n===== A MERDADO VENDA | RESULT RET CODE :  "+trade.ResultRetcode());
   Print("LOTE ENVIADO  :  "+lots);
   ulong order = trade.ResultOrder();

   Print("TKT OFERTA : "+order);

   return order;
  }
struct TRADE_INFO
  {
   double            stoploss;
   double            takeprofit;
   double            lot;
   int               typeConvert;
  };
//+------------------------------------------------------------------+
