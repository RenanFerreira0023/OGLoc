//+------------------------------------------------------------------+
//|                                             ESPANCADOR_SLAVE.mq5 |
//|                        Copyright 25/06/24,                     . |
//|                            Developer,      Renan Dutra Ferreira. |
//|                                                                  |
//|                   appsskilldeveloper@gmail.com                   |
//|                                OU                                |
//|                    NOS SIGA NO INSTAGRAM [  @_fdutra  ]          |
//                     https://www.mql5.com/en/users/renandutra/     |
//|                        ESPANCADOR_SLAVE                   |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+

#property copyright "Renan Dutra Ferreira"
#property link      "https://www.mql5.com/en/users/renandutra/"
#define VERSION "1.0"
#property version VERSION
#define NAME_BOT "Slave MT5"



bool static YES   = true;
bool static NO    = false;

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





#include <JAson.mqh>

#include <Trade/Trade.mqh>
CTrade trade;

enum SELECT_TYPE_OUT
  {
   type_bot_off      = 0,  // OFF
   type_bot_distance = 1,  // Distancia ( em Pnts baseado pelo grafico )
   type_bot_percent = 2  // Percentual

  };


enum SELECT_TYPE_ADJUST_HOURS
  {
   hours_more_12 = 12, // +12
   hours_more_11 = 11, // +11
   hours_more_10 = 10, // +10
   hours_more_9 = 9, // +9
   hours_more_8 = 8, // +8
   hours_more_7 = 7, // +7
   hours_more_6 = 6, // +6
   hours_more_5 = 5, // +5
   hours_more_4 = 4, // +4
   hours_more_3 = 3, // +3
   hours_more_2 = 2, // +2
   hours_more_1 = 1, // +1
   hours_zero =   0, // 0
   hours_less_1 = -1, // -1
   hours_less_2 = -2, // -2
   hours_less_3 = -3, // -3
   hours_less_4 = -4, // -4
   hours_less_5 = -5, // -5
   hours_less_6 = -6, // -6
   hours_less_7 = -7, // -7
   hours_less_8 = -8, // -8
   hours_less_9 = -9, // -9
   hours_less_10 = -10, // -10
   hours_less_11 = -11, // -11
   hours_less_12 = -12, // -12
  };

input int      MAGIC_NUM         = 8435434;                 // Número mágico
input string         URL_BASE                                  = "192.168.1.10";           // IP do PC
input double         INITIAL_LOT                               =5;                       // Lote envio

input SELECT_TYPE_ADJUST_HOURS TYPE_ADJUST_HOURS            = hours_zero;  //             Ajuste do horário em relação ao ADMIN

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input group       "  TakeProfit e StopLoss ( Individual por bot )         ";
input SELECT_TYPE_OUT TYPE_OUT              = type_bot_off;        // Tipo de saída por distancia
input double         VALUE_TAKEPROFIT        = 0;   //  Valor TakeProfit
input double         VALUE_STOPLOSS        = 0;   // Valor StopLoss




string URL_SERVER;
string GLOBAL_MSG_POWER = "";
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   trade.SetExpertMagicNumber(MAGIC_NUM);

   URL_SERVER = "http://"+URL_BASE+"/EspancadorMT5/api.php";

   TIME_WAIT_A_LOT = TimeCurrent() + 5;
//---
   GLOBAL_MSG_POWER = "";
   EventSetMillisecondTimer(700);
   wait_a_lot = TimeCurrent();

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
Comment("");
   EventKillTimer();
  }





datetime wait_a_lot;
datetime TIME_WAIT_A_LOT;
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTimer()
  {


   string msgPanel = "";

   msgPanel += "\n#####################################";
   msgPanel += "\n##########  "+NAME_BOT+" "+VERSION+" ##############";
   msgPanel += "\n#####################################\n";
   msgPanel += "  "+TimeCurrent()+"\n\n";

   if(GLOBAL_MSG_POWER == "Pausado")
      msgPanel += "\n       ~~~~~~~>>   Sistema Pausado   <<~~~~~~~";
   else
      msgPanel += "\n       ~~~~~~~>>   R O D A N D O   <<~~~~~~~";

   Comment(msgPanel);


   project_takeprofit_and_stoploss();

//+------------------------------------------------------------------+
//|   Motor                                                          |
//+------------------------------------------------------------------+
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

      confirm_action_slave();
     }


   if(sendOrder == 0) // Botao liga/desliga  esta DESLIGADO
     {
      GLOBAL_MSG_POWER = "Pausado";
      return;
     }
   GLOBAL_MSG_POWER = "Rodando";


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
      confirm_action_slave();
     }

// Mnadar venda
   if(requestDirectOrder == -1)
     {
      TIME_WAIT_A_LOT = TimeCurrent() + 5;
      sell_market(0,0,INITIAL_LOT,"");
      confirm_action_slave();
     }

//+-------
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
bool hours_zone_today(string HOURS_X, string HOURS_Y)
  {

   if(HOURS_X == "00:00" &&
      HOURS_Y == "00:00")
      return YES;
   datetime entryHours = TimeCurrent() + (PeriodSeconds(PERIOD_H1) * TYPE_ADJUST_HOURS);

   string onlyDate =  TimeToString(entryHours,TIME_DATE);
   datetime timeFakeX = StringToTime(onlyDate+" "+HOURS_X);
   datetime timeFakeY = StringToTime(onlyDate+" "+HOURS_Y);
   datetime timeFakeZ = StringToTime(onlyDate+" "+entryHours) ;
/*
   Print("\n\ntimeFakeX     "+timeFakeX);
   Print("timeFakeY     "+timeFakeY);
   Print("timeFakeZ     "+timeFakeZ);
   Print("entryHours     "+entryHours);
   Print("TYPE_ADJUST_HOURS     "+TYPE_ADJUST_HOURS);
   Print("TimeCurrent()     "+TimeCurrent());
*/

   if(timeFakeX <= entryHours && timeFakeY >= entryHours)
      return YES;
   return NO;
  }



static int GLOBAL_LIMIT_LOOP = 10;




//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void confirm_action_slave()
  {

   string msgError = "";

   int loopAuth = 0;
   do
     {
      int retCode = 0;
      string jsonToken = "";
      string urlToken = URL_SERVER+"/confirm_action_slave/";
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
            msgError += json["message_error"].ToStr();
            Print("  -     "+retCode);
            Print("erro na solicitação    "+msgError);
           }
         loopAuth++;
         Print("\nTentativa de conecção :   "+loopAuth+" / "+GLOBAL_LIMIT_LOOP);
         Sleep(700);
        }
     }
   while(loopAuth <= GLOBAL_LIMIT_LOOP);

  }





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
   /*
      Print("Se preparando para enviar uma copy... [ AGUARDE ] ");
      string jsonData = ;
   */

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

//   Print("jsonData   \n"+jsonData);
   string msgError = "";

   int loopAuth = 0;
   do
     {
      int retCode = 0;
      string jsonToken = "";
      string urlToken = URL_SERVER+"/send_data_mt5_slave/";
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
         //   Print("AAAA");
         if(retCode == 1001)
            msgError += ("Servidor fora do ar .");
         else
           {
            CJAVal json;
            json.Deserialize(jsonToken);
            msgError += json["message_error"].ToStr();
            Print("  -     "+retCode);
            Print("erro na solicitação    "+msgError);
           }
         loopAuth++;
         Print("\nTentativa de conecção :   "+loopAuth+" / "+GLOBAL_LIMIT_LOOP);
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
   while(loopCount < ArraySize(arrayTktForDell))
     {


      ulong tkt = arrayTktForDell[loopCount];

      CPositionInfo myPosition;
      if(myPosition.SelectByTicket(tkt) == YES)
         if(trade.PositionClose(tkt) == true)
            loopCount++;
         else
            loopCountError++;
      

      if(loopCountError > 15)
         break;
     };
  }


//+------------------------------------------------------------------+

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
