//+------------------------------------------------------------------------------------------------------------------+
//|                                                                                                  IB_EA.mq4 |
//|                                                        This is the Initial Balance Expert Advisor |
//|                                                             Copyright 20200725,Christo Strydom. |
//|                                                                      christo.w.strydom@gmail.com  |
//+------------------------------------------------------------------------------------------------------------------+
#property                  copyright                     "Christo Strydom"
#property link                             "christo.w.strydom@gmail.com"
#include "SnR_EA.mqh"
//=================================================================================================================================
extern int EAMagic                   = 19012; //EA's magic number parameter
input double TakeProfit              = 2000; // 2000 for USDZAR
input double Lots                      = 0.1; // Trade size
input double StopLoss               = 3000; // Hard stop, 3000 for USDZAR, The stop loss is not MANAGED
input double IB_factor               = 200; //IB multiplier

input int Slippage                        = 3; // Slippage
input double TrailingStop            = 0; // 0 for NO trailing stop
input int MaxNumberDayTrades = 1; // Maximum number of day trades

int            sell_ticket;
int            buy_ticket;
double    current_buy_stoploss;//=Ask-StopLoss*Point;
double    current_buy_takeprofit;// =Ask+TakeProfit*Point;
double    current_sell_stoploss;//=IB_Resistance+StopLoss*Point;
double    current_sell_takeprofit;// =IB_Resistance-TakeProfit*Point;
string      sell_comment="EveryBarEA_Resistance";
string      buy_comment="EveryBarEA_Support";      

datetime             EveryLastActiontime;
datetime             SecondEveryDayActionTime;
datetime             TradeWindowLastActiontime;
datetime             EveryDayActionTime;
datetime             current_day;// =iTime(Symbol(),PERIOD_D1,0);  // The start time 00:00:00 of the CURRENT day

datetime IB_StartTime;// = current_day + IB_StartHour * 60 *60+IB_EndMinute*60;
datetime IB_EndTime;// = current_day + IB_EndHour * 60 *60+IB_EndMinute*60;   
datetime start_time;//               = current_day+(60*60*Trade_StartHour)+(60*Trade_StartMinute); // Start time of the current TRADING day;
datetime end_time ;//               = current_day+(60*60*Trade_EndHour)+(60*Trade_EndMinute); // End time of the current TRADING day;
double    IB_High=0;//        = High[high_shift];
double    IB_Low=0;//         = Low[low_shift];//iLow(StratSymbol,StratPeriod,low_shift); 
double      IB_Resistance=0;
double      IB_Support=0;
string         IB_Resistance_Name; // = "IB_Resistance_"+ (string)IB_Resistance;
string         IB_Support_Name;// = "IB_Support_"+(string)IB_Support;


void OnTick(void)
  {
  //  This code section runs once a day or at midnight
  //  This code section runs at the start of every bar:
   if(EveryLastActiontime!=Time[0])
   {
               ObjectsDeleteAll();   
               EveryLastActiontime=Time[0];               
               IB_High        = High[1];
               IB_Low         = Low[1];//iLow(StratSymbol,StratPeriod,low_shift); 

               IB_Resistance          = (IB_High-IB_Low)*IB_factor/100+IB_High;
               IB_Support               = IB_Low-(IB_High-IB_Low)*IB_factor/100;
               IB_Resistance_Name = "IB_Resistance_"+ (string)IB_Resistance;
               IB_Support_Name = "IB_Support_"+(string)IB_Support;
               current_buy_stoploss=IB_Support-StopLoss*Point;
               current_buy_takeprofit =IB_Support+TakeProfit*Point;
               current_sell_stoploss=IB_Resistance+StopLoss*Point;
               current_sell_takeprofit =IB_Resistance-TakeProfit*Point;
               Print("Are there pending SELL orders for this currency? ",CheckOpenOrders(sell_comment));
               Print("Are there pending BUY orders for this currency? ",CheckOpenOrders(buy_comment));
               //deleteallpendingorders(EAMagic);
               if(!CheckOpenOrders(sell_comment))
               {
                  sell_ticket=OrderSend(Symbol(),OP_SELLLIMIT,Lots,IB_Resistance,Slippage,current_sell_stoploss,current_sell_takeprofit,sell_comment,EAMagic,Time[0]-Time[1]+Time[0],Red);
                  if(sell_ticket>0)
                    {
                     if(OrderSelect(sell_ticket,SELECT_BY_TICKET,MODE_TRADES))
                     {Print("SELL order opened : ",OrderOpenPrice());}
                    }
                  else
                     Print("Error opening SELL order : ",GetLastError());
                  //return;      
               }      
               if(!CheckOpenOrders(buy_comment))
               {
                  buy_ticket=OrderSend(Symbol(),OP_BUYLIMIT,Lots,IB_Support,Slippage,current_buy_stoploss,current_buy_takeprofit,buy_comment,EAMagic,Time[0]-Time[1]+Time[0],Green);
                  if(buy_ticket>0)
                    {
                     if(OrderSelect(buy_ticket,SELECT_BY_TICKET,MODE_TRADES))
                        Print("BUY order opened : ",OrderOpenPrice());
                    }
                  else
                     Print("Error opening BUY order : ",GetLastError());
                  //return;
               }

      
      //start_shift=iBarShift(Symbol(),PERIOD_M1,start_time-60);  // Shift in 1 Minute bars to the start start of the TRADING day
      //day_shift=iBarShift(Symbol(),PERIOD_M1,current_day);  // Number of 1 minute 'shifts' of the current bar type to the start of the CURRENT day
      //in_trade_shift_hi=iHighest(Symbol(),PERIOD_M1,MODE_HIGH,start_shift,1); // Number of shifts  from current bar to HIGHEST bar in trade window
      //in_trade_shift_lo=iLowest(Symbol(),PERIOD_M1,MODE_LOW,start_shift,1); // Number of shifts  from current bar to LOWEST bar in trade window
      //premarket_shift_hi=iHighest(Symbol(),PERIOD_M1,MODE_HIGH,day_shift,start_shift); // Number of shifts from current bar to HIGHEST bar in pre market window
      //premarket_shift_lo=iLowest(Symbol(),PERIOD_M1,MODE_LOW,day_shift,start_shift); //  Number of shifts from current bar to LOWEST bar in pre market window
      //IB_StartTime = current_day + IB_StartHour * 60 *60+IB_EndMinute*60;
      //IB_EndTime = current_day + IB_EndHour * 60 *60+IB_EndMinute*60;   
      //Code to execute once in the bar
      // Print("This code is executed only once in the bar started ",Time[0], TimeToStr(LastActiontime,TIME_DATE|TIME_SECONDS));

      //ChartRedraw();
     // VLineDelete(0,MidNightName);
     // ChartRedraw();      
      Print("This code is executed only once in the bar started ",Time[0], "; ", TimeToStr(EveryLastActiontime,TIME_DATE|TIME_SECONDS), "; TimeLocal: ", TimeLocal());      
   }   
}
