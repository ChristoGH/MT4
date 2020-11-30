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
int EAMagicNumber                   = 19015; //EA's magic number parameter
input double TakeProfit              = 2000; //  Hard TAKE PROFIT
input double Lots                      = 0.1; // Trade size
input double StopLoss               = 3000; // Hard STOP
input int Confirmation_Delta       = 1000; // 
//input double IB_factor               = 100; //IB multiplier

input int Slippage                        = 3; // Slippage
input double TrailingStop            = 0; // 0 for NO trailing stop
input int Trade_StartHour           = 9; // Trade Start AFTER this hour
input int Trade_StartMinute        = 0;  // Trade Start AFTER this Trade_StartMinute and Trade_StartHour
input int Trade_EndHour            = 14; // Trade ends BEFORE this hour
input int Trade_EndMinute         = 0; // Trade ends BEFORE Trade_EndHour and Trade_EndMinute
input int IB_StartHour                = 8; // Measure IB AFTER this hour
input int IB_StartMinute             = 0; // Measure IB AFTER this IB_StartMinute
input int IB_EndHour                 = 9; // Measure IB BEFORE this hour
input int IB_EndMinute              = 0; // Measure IB BEFORE this IB_EndMinute
input int MaxNumberDayTrades = 1; // Maximum number of day trades

double    current_buy_stoploss;//=Ask-StopLoss*Point;
double    current_buy_takeprofit;// =Ask+TakeProfit*Point;
double    current_buy_entry;
double    current_sell_stoploss;//=IB_Resistance+StopLoss*Point;
double    current_sell_takeprofit;// =IB_Resistance-TakeProfit*Point;
double   current_sell_entry;
string      sell_comment="Reverse_InitialBalanceEA_Resistance SELL STOP";
string      buy_comment="Reverse_InitialBalanceEA_Support BUY STOP";      

datetime             EveryLastActiontime;
datetime             SecondEveryDayActionTime;
datetime             TradeWindowLastActiontime;
datetime             EveryDayActionTime;
datetime             current_day;// =iTime(Symbol(),PERIOD_D1,0);  // The start time 00:00:00 of the CURRENT day
datetime             previous_day;// =iTime(Symbol(),PERIOD_D1,0);  // The start time 00:00:00 of the CURRENT day

string      IB_High_Name;
string      IB_Low_Name;
string      StratSymbol          = Symbol();
int           StratPeriod           = 0; //Period();
//datetime current_day_time     = iTime(Symbol(),PERIOD_D1,0);  // The start time 00:00:00 of the CURRENT day

bool InTradeAllowance=true;  // InTradeAllowance is set to true.  It will only be set false once nDayTrades>=MaxNumberDayTrades
int    nDayTrades=0;
int    trade;
int    cnt;
int      sell_ticket;
int      buy_ticket;
int    total=0;//,total;
int    symbol_total=0;//,total;

//input color           SnRColor=clrYellow; //

double    period_high, period_low;  
datetime IB_StartTime;// = current_day + IB_StartHour * 60 *60+IB_EndMinute*60;
datetime IB_EndTime;// = current_day + IB_EndHour * 60 *60+IB_EndMinute*60;   
datetime start_time;//               = current_day+(60*60*Trade_StartHour)+(60*Trade_StartMinute); // Start time of the current TRADING day;
datetime end_time ;//               = current_day+(60*60*Trade_EndHour)+(60*Trade_EndMinute); // End time of the current TRADING day;
int          start_shift;//=iBarShift(Symbol(),PERIOD_M1,start_time-60);  // Shift in 1 Minute bars to the start start of the TRADING day
int          day_shift;//=iBarShift(Symbol(),PERIOD_M1,current_day);  // Number of 1 minute 'shifts' of the current bar type to the start of the CURRENT day
int          in_trade_shift_hi;//=iHighest(Symbol(),PERIOD_M1,MODE_HIGH,start_shift,1); // Number of shifts  from current bar to HIGHEST bar in trade window
int          in_trade_shift_lo;//=iLowest(Symbol(),PERIOD_M1,MODE_LOW,start_shift,1); // Number of shifts  from current bar to LOWEST bar in trade window
int          premarket_shift_hi;//=iHighest(Symbol(),PERIOD_M1,MODE_HIGH,day_shift,start_shift); // Number of shifts from current bar to HIGHEST bar in pre market window
int          premarket_shift_lo;//=iLowest(Symbol(),PERIOD_M1,MODE_LOW,day_shift,start_shift); //  Number of shifts from current bar to LOWEST bar in pre market window 
//bool        in_trade_window=false;
//bool        after_trade_window=false;
int          IB_StartTime_shift;//   = iBarShift(StratSymbol,StratPeriod,IB_StartTime); //This is the index of the bar corresponding toSnRStartTime.
int          IB_EndTime_shift;//    = iBarShift(StratSymbol,StratPeriod,IB_EndTime); //This is the index of the bar corresponding SnREndTime.
int          bar_count;//   = IB_StartTime_shift-IB_EndTime_shift; // The number of bars between SnREndTime_shift and SnRStartTime_shift
int          high_shift;//  = iHighest(StratSymbol,StratPeriod,MODE_HIGH,bar_count,IB_StartTime_shift); // This is the shift in bars to find the maximum value starting from SnREndTime_shift going back bar_count number of bars but no further than SnRStartTime.
int          low_shift;//   = iLowest(StratSymbol,StratPeriod,MODE_LOW,bar_count,IB_EndTime_shift); // This is the shift in bars to find the maximum value starting from SnREndTime_shift going back bar_count number of bars but no further than SnRStartTime..
double   IB=0;
double    IB_High=0;//        = High[high_shift];
double    IB_Low=0;//         = Low[low_shift];//iLow(StratSymbol,StratPeriod,low_shift); 
datetime TimeOffset;

datetime  IB_previousDay_StartTime;
datetime  IB_previousDay_EndTime;       
int           IB_previousDay_StartTime_shift; //This is the index of the bar corresponding toSnRStartTime.
int            IB_previousDay_EndTime_shift; //This is the index of the bar corresponding SnREndTime.
int            previousDaybar_count; // The number of bars between SnREndTime_shift and SnRStartTime_shift     
int            previousDay_high_shift; // This is the shift in bars to find the maximum value starting from SnREndTime_shift going back bar_count number of bars but no further than SnRStartTime.
int            previousDay_low_shift; // This is the shift in bars to find the maximum value starting from SnREndTime_shift going back bar_count number of bars but no further than SnRStartTime..
//int            nDayTrades;//---

double      previousDay_IB_High;
double      previousDay_IB_Low;//iLow(StratSymbol,StratPeriod,low_shift);
double      IB_Resistance=0;
double      IB_Support=0;

string         IB_Resistance_Name; // = "IB_Resistance_"+ (string)IB_Resistance;
string         IB_Support_Name;// = "IB_Support_"+(string)IB_Support;


// int CountSymbolPositions=0;
//double resistance; // =iCustom(NULL,0,"Support and Resistance (Barry)",0,0);
//double support; // =iCustom(NULL,0,"Support and Resistance (Barry)",1,0);
//double previous_resistance;
//double previous_support;

// string var1;
// double val;
//---Here is a to do list:------------------------------------------------------
//---https://docs.mql4.com/series/ibarshift
//---datetime some_time=D'2004.03.21 12:00';
//---int shift=iBarShift(Symbol(),PERIOD_M1,some_time);
//---Print("index of the bar for the time ",TimeToStr(some_time)," is ",shift);

//---https://www.mql5.com/en/forum/143602
// datetime Last;
// int TotalNumberOfOrders = OrdersHistoryTotal();   //  
// for(int i = 0; i >=TotalNumberOfOrders - 1 ; i++)  //  
//    {
//    if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==false) continue; // falls Zeile leer
//       {
//       if(OrderType()==OP_BUY && OrderType()==OP_SELL ) {Last=OrderCloseTime(); Alert(OrderCloseTime());}
//       }
//    } 
// Alert(TimeToStr(TimeCurrent(),TIME_DATE|TIME_SECONDS),"  Letzter Trade: ",Last);
// }

//void OnStart()
//{

//}

void OnTick(void)
  {
  //  This code section runs once a day or at midnight

  //---------------------------------------------------------------------------------------------------------------
  //---  For safety sake, let's delete all pending orders for this magic number at the start of the new day:  
  deleteallpendingorders(EAMagicNumber);
  //---------------------------------------------------------------------------------------------------------------  
  if(EveryDayActionTime!=iTime(Symbol(),PERIOD_D1,0))
  {
      TimeOffset                = TimeCurrent()-TimeLocal(); // The difference between Local time and server time
      current_day               =iTime(Symbol(),PERIOD_D1,0)+TimeOffset;  // The start time 00:00:00 of the CURRENT day
      previous_day            =iTime(Symbol(),PERIOD_D1,1)+TimeOffset;
      start_time               = current_day+(60*60*Trade_StartHour)+(60*Trade_StartMinute); // Start time of the current TRADING day;
      end_time                = current_day+(60*60*Trade_EndHour)+(60*Trade_EndMinute); // End time of the current TRADING day;
      IB_StartTime            = current_day + IB_StartHour * 60 *60+IB_StartMinute*60;
      IB_EndTime              = current_day + IB_EndHour * 60 *60+IB_EndMinute*60; 
      // Previous day IB values ========================================================================
            
      VLineDelete(0,IinitialBalance_Start);
      VLineDelete(0,IinitialBalance_End);
      if(!VLineCreate(0,IinitialBalance_Start,0,IB_StartTime,IBColor,InpStyle,InpWidth,InpBack,InpSelection,InpHidden,InpZOrder))
         {
         return;
         }
      if(!VLineCreate(0,IinitialBalance_End,0,IB_EndTime,IBColor,InpStyle,InpWidth,InpBack,InpSelection,InpHidden,InpZOrder))
         {
         return;
         }
      
      VLineDelete(0,IBMidNightName);
      VLineDelete(0,IBTradingDayStart);
      VLineDelete(0,IBTradingDayEnd);
      if(!VLineCreate(0,IBMidNightName,0,current_day,IBMidNightColor,InpStyle,InpWidth,InpBack,InpSelection,InpHidden,InpZOrder))
         {
         return;
         }
      if(!VLineCreate(0,IBTradingDayStart,0,start_time,IBTradingDayStartColor,InpStyle,InpWidth,InpBack,InpSelection,InpHidden,InpZOrder))
         {
         return;
         }
      if(!VLineCreate(0,IBTradingDayEnd,0,end_time,IBTradingDayEndColor,InpStyle,InpWidth,InpBack,InpSelection,InpHidden,InpZOrder))
         {
         return;
         }
      
      EveryDayActionTime = iTime(Symbol(),PERIOD_D1,0);      
  }
  
  //  This code section runs at the start of every bar:
   if(EveryLastActiontime!=Time[0]){
            
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
      EveryLastActiontime=Time[0];
      //ChartRedraw();
     // VLineDelete(0,MidNightName);
     // ChartRedraw();      
      Print("This code is executed only once in the bar started ",Time[0], "; ", TimeToStr(EveryLastActiontime,TIME_DATE|TIME_SECONDS), "; TimeLocal: ", TimeLocal());      
   }   
      
      //Print("This code is executed only once in the bar started ",Time[0], "; ", TimeToStr(EveryLastActiontime,TIME_DATE|TIME_SECONDS), "; TimeLocal: ", TimeLocal());    
      // Print("IB_StartTime: ", TimeToStr(IB_StartTime,TIME_DATE|TIME_SECONDS), ";  High[IB_StartTime_shift]: ", High[IB_StartTime_shift],"; IB_EndTime: ", TimeToStr(IB_EndTime,TIME_DATE|TIME_SECONDS), ";  High[IB_EndTime_shift]: ", High[IB_EndTime_shift]);    
      // Print("IB_StartTime_shift: ",IB_StartTime_shift, "; IB_EndTime_shift: ", IB_EndTime_shift);

      
      //Print("start_time: ", TimeToStr(start_time,TIME_DATE|TIME_SECONDS),"; end_time: ", TimeToStr(end_time,TIME_DATE|TIME_SECONDS), "; IB_StartTime: ", TimeToStr(IB_StartTime,TIME_DATE|TIME_SECONDS),"; IB_EndTime: ", TimeToStr(IB_EndTime,TIME_DATE|TIME_SECONDS));    
      
      //Print("previousDay_IB_High: ",previousDay_IB_High, "; previousDay_IB_Low: ", previousDay_IB_Low, "; TimeToStr(iTime(Symbol(),0,previousDay_high_shift),TIME_DATE|TIME_SECONDS): ", TimeToStr(iTime(Symbol(),0,previousDay_high_shift),TIME_DATE|TIME_SECONDS));    
  //===================================================================================================
  //  Define in_trade_window, a boolean operator which is true only if we are inside the hours defined by StartHour and EndHour
  //  To do: convert all to seconds, so that comparison will include StartMinute
   //Print("Current bar for Symbol() H1: ",iTime(Symbol(),PERIOD_M1,start_shift), "; TimeToStr(iTime(Symbol(),PERIOD_M1,start_shift),TIME_DATE|TIME_SECONDS): ",TimeToStr(start_time,TIME_DATE|TIME_SECONDS), "; start_shift: ", start_shift, "; ",  iOpen(Symbol(),PERIOD_M1,start_shift),", ",
   //                                      iHigh(Symbol(),PERIOD_M1,start_shift),", ",  iLow(Symbol(),PERIOD_M1,start_shift),", ",
   //                                      iClose(Symbol(),PERIOD_M1,start_shift),", ", iVolume(Symbol(),PERIOD_M1,start_shift),
   //                                      "; period_high: ",iHigh(Symbol(),PERIOD_M1,iHi),
   //                                       "; period_low: ",iLow(Symbol(),PERIOD_M1,iLo));
   
   //int result =trade_window(start_time,end_time);

// ====================================================================================================================
// Here we determine if we are in the tradinbg window:   
//for(trade=OrdersHistoryTotal()-1;trade>=0;trade--)
// {
//  if(OrderSelect(trade,SELECT_BY_POS,MODE_HISTORY)==true)
//    {
//     // Print("In REVERSE_IB_EA.mq4 we have OrderSymbol: ",OrderSymbol(),"; OrderComment: ",OrderComment(), "; Symbol: ", Symbol(), "; OrderMagicNumber: ",OrderMagicNumber(), "; OrdersHistoryTotal(): ", OrdersHistoryTotal());    
//      if(OrderMagicNumber()==EAMagicNumber)
//      {
//      if((OrderCloseTime()>=current_day)&&(OrderSymbol()==Symbol()))
//      {
//      Print("Trade allowance reached for ",sell_comment, ". DELETE pending SELL orders.");
//      deleteallpendingorders(EAMagicNumber)
//      };
//    }
//    }
//  else
//    Print("OrderSelect failed error code is: ",GetLastError(), "; with trade: ", trade);
// }



if(trade_window_fn(start_time, end_time))
{

      double    previous_close= iClose(Symbol(),PERIOD_M1,1);
      double    previous_high= iHigh(Symbol(),PERIOD_M1,1);
      double    previous_low= iLow(Symbol(),PERIOD_M1,1);    

          // ======================================================================================
          // Calculate here the number of completed trades for the CURRENT day and CURRENT sumbol.  Starting at the most recent trade it goes back until OrderCloseTime()<CurrentDay.

         nDayTrades=0;
          for(trade=OrdersHistoryTotal()-1;trade>=0;trade--)
             {
              if(OrderSelect(trade,SELECT_BY_POS,MODE_HISTORY)==true)
                {
                  if(OrderMagicNumber()==EAMagicNumber)
                  {
                  if((OrderCloseTime()>=current_day)&&(OrderSymbol()==Symbol()))
                     {
                     Print("We have executed a trade - delete all pending orders on REVERSE_IB_EA.mq4.");
                     //RemoveAllOrders(sell_comment);
                     deleteallpendingorders(EAMagicNumber);
                     }
                  };
                }
              else
                Print("OrderSelect failed error code is: ",GetLastError(), "; with trade: ", trade);
              if((OrderCloseTime()<current_day)||(!InTradeAllowance))
              {
               break;
              }
             }

      if(TradeWindowLastActiontime!=Time[0]) // && YOUR_CONDITION)
      {
         //Code to execute once in the bar
         //Print("This code is executed only once when a new bar starts ",Time[0]);
         previous_close= iClose(Symbol(),PERIOD_M1,1);
         previous_high= iHigh(Symbol(),PERIOD_M1,1);
         previous_low= iLow(Symbol(),PERIOD_M1,1);
         if(SecondEveryDayActionTime !=iTime(Symbol(),PERIOD_D1,0))  // This will happen once per day only!
         {
         
               IB_StartTime_shift   = iBarShift(StratSymbol,StratPeriod,IB_StartTime); //This is the index of the bar corresponding IB_StartTime.
               IB_EndTime_shift    = iBarShift(StratSymbol,StratPeriod,IB_EndTime); //This is the index of the bar corresponding IB_EndTime.
               bar_count   = IB_StartTime_shift-IB_EndTime_shift; // The number of bars between SnREndTime_shift and SnRStartTime_shift
               high_shift  = iHighest(StratSymbol,StratPeriod,MODE_HIGH,bar_count,IB_EndTime_shift+1); // This is the shift in bars to find the maximum value starting from SnREndTime_shift going back bar_count number of bars but no further than SnRStartTime.
               low_shift   = iLowest(StratSymbol,StratPeriod,MODE_LOW,bar_count,IB_EndTime_shift+1); // This is the shift in bars to find the maximum value starting from SnREndTime_shift going back bar_count number of bars but no further than SnRStartTime..
               IB_High        = High[high_shift];
               IB_Low         = Low[low_shift];//iLow(StratSymbol,StratPeriod,low_shift); 
               IB_High_Name = "IB_High_"+ (string)IB_High;
               IB_Low_Name = "IB_Low_"+(string)IB_Low;
               IB=IB_High-IB_Low;
               IB_Resistance          = IB_High;
               IB_Support               = IB_Low;
               IB_Resistance_Name = "Reverse_IB_Resistance_"+ (string)IB_Resistance;
               IB_Support_Name = "Reverse_IB_Support_"+(string)IB_Support;
               current_buy_stoploss=IB_Resistance-(StopLoss)*Point +(Confirmation_Delta)*Point;
               current_buy_takeprofit =IB_Resistance+(TakeProfit*Point)+(Confirmation_Delta)*Point;
               current_buy_entry =IB_Resistance+Confirmation_Delta*Point;
               current_sell_stoploss=IB_Support+StopLoss*Point - (Confirmation_Delta)*Point;
               current_sell_takeprofit =IB_Support-TakeProfit*Point - (Confirmation_Delta)*Point;
               current_sell_entry =IB_Support-Confirmation_Delta*Point;               
               TrendDelete(0,IB_High_Name); 
               TrendDelete(0,IB_Low_Name);
               TrendDelete(0,IB_Resistance_Name);
               TrendDelete(0,IB_Support_Name);             
               Print("ReverseIB: Are there pending SELL orders for this currency? ",CheckOpenOrders(sell_comment));
               Print("ReverseIB: Are there pending BUY orders for this currency? ",CheckOpenOrders(buy_comment));
               deleteallpendingorders(EAMagicNumber); //Clear all orders for this new day
               SecondEveryDayActionTime = iTime(Symbol(),PERIOD_D1,0);
               if(!CheckOpenOrders(sell_comment))
               {
                  sell_ticket=OrderSend(Symbol(),OP_SELLSTOP,Lots,current_sell_entry,Slippage,current_sell_stoploss,current_sell_takeprofit,sell_comment,EAMagicNumber,end_time,Red);
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
                  buy_ticket=OrderSend(Symbol(),OP_BUYSTOP,Lots,current_buy_entry,Slippage,current_buy_stoploss,current_buy_takeprofit,buy_comment,EAMagicNumber,end_time,Red);
                  if(buy_ticket>0)
                    {
                     if(OrderSelect(buy_ticket,SELECT_BY_TICKET,MODE_TRADES))
                        Print("BUY order opened : ",OrderOpenPrice());
                    }
                  else
                     Print("Error opening BUY order : ",GetLastError());
                  //return;
               }

               if(!TrendCreate(0,        // chart's ID 
                          IB_High_Name,  // line name 
                          0,      // subwindow index 
                          IB_StartTime,           // first point time 
                          IB_High,          // first point price 
                          end_time,           // second point time 
                          IB_High,          // second point price 
                          IBHighColor,        // line color 
                          SnRStyle, // line style 
                          SnRwidth,           // line width 
                          SnRback,        // in the background 
                          SnRselection,    // highlight to move 
                          SnRray_left,    // line's continuation to the left 
                          SnRray_right,   // line's continuation to the right 
                          SnRhidden,       // hidden in the object list 
                          SnRz_order))
                          {
                          return;
                          }         
               if(!TrendCreate(0,        // chart's ID 
                          IB_Low_Name,  // line name 
                          0,      // subwindow index 
                          IB_StartTime,           // first point time 
                          IB_Low,          // first point price 
                          end_time,           // second point time 
                          IB_Low,          // second point price 
                          IBLowColor,        // line color 
                          SnRStyle, // line style 
                          SnRwidth,           // line width 
                          SnRback,        // in the background 
                          SnRselection,    // highlight to move 
                          SnRray_left,    // line's continuation to the left 
                          SnRray_right,   // line's continuation to the right 
                          SnRhidden,       // hidden in the object list 
                          SnRz_order))
                          {
                          return;
                          }
      
              if(!TrendCreate(0,        // chart's ID 
                         IB_Resistance_Name,  // line name 
                         0,      // subwindow index 
                         IB_StartTime,           // first point time 
                         IB_Resistance,          // first point price 
                         end_time,           // second point time 
                         IB_Resistance,          // second point price 
                         IBHighColor,        // line color 
                         IBSnRStule, // line style 
                         SnRwidth,           // line width 
                         SnRback,        // in the background 
                         SnRselection,    // highlight to move 
                         SnRray_left,    // line's continuation to the left 
                         SnRray_right,   // line's continuation to the right 
                         SnRhidden,       // hidden in the object list 
                         SnRz_order))
                          {
                          return;
                          }         
      
      
              if(!TrendCreate(0,        // chart's ID 
                         IB_Support_Name,  // line name 
                         0,      // subwindow index 
                         IB_StartTime,           // first point time 
                         IB_Support,          // first point price 
                         end_time,           // second point time 
                         IB_Support,          // second point price 
                         IBHighColor,        // line color 
                         IBSnRStule, // line style 
                         SnRwidth,           // line width 
                         SnRback,        // in the background 
                         SnRselection,    // highlight to move 
                         SnRray_left,    // line's continuation to the left 
                         SnRray_right,   // line's continuation to the right 
                         SnRhidden,       // hidden in the object list 
                         SnRz_order))
                          {
                          return;
                          }

               Print("This code is executed only once in the bar started ",Time[0], "; ", TimeToStr(SecondEveryDayActionTime,TIME_DATE|TIME_SECONDS), "; TimeLocal: ", TimeLocal());                    
      }





         TradeWindowLastActiontime=Time[0];
      }

      if(TradeWindowLastActiontime==start_time)
      {

      
      }

      //Print("For the IB from ",TimeToStr(IB_StartTime,TIME_DATE|TIME_SECONDS), " to ", TimeToStr(IB_EndTime,TIME_DATE|TIME_SECONDS),", the HIGH is = ",IB_High," and the LOW is = ",IB_Low);  
      //Print("For the IB, IB_StartTime_shift ",IB_StartTime_shift, " IB_EndTime_shift ", IB_EndTime_shift,", the bar_count is = ",bar_count," and the high_shift is = ",high_shift, " and the low_shift is = ",low_shift);  

       // ======================================================================================
       // Calculate here the number of completed trades for the CURRENT day.  Starting at the most recent trade it goes back until OrderCloseTime()<CurrentDay
      nDayTrades=0;
       //datetime CurrentDay =iTime(Symbol(),PERIOD_D1,0);  // The start time 00:00:00 of the CURRENT day   
       for(trade=OrdersHistoryTotal()-1;trade>=0;trade--)
          {
              //Print("Trade number: ", trade);
              if(OrderSelect(trade,SELECT_BY_POS,MODE_HISTORY)==true)
                  {
                  //EA_OrderOpenTime=OrderOpenTime();
                  //EA_OrderCloseTime=OrderCloseTime();
                  //         if(OrderMagicNumber()==EAMagic)
                  //         {
                  if((OrderCloseTime()>=current_day)&&(OrderSymbol()==Symbol()))
                     {
                      nDayTrades++;
                     };
                  //if(OOT>0) Print("OrdersTotal: ",hstTotal,"; Close time for the order:  ",trade," is: ",TimeToStr(OOT,TIME_DATE|TIME_SECONDS), );
                  }
              else
                Print("OrderSelect failed error code is: ",GetLastError(), "; with trade: ", trade);
              if((OrderCloseTime()<current_day)||(MaxNumberDayTrades<=nDayTrades))
                 {
                  InTradeAllowance=MaxNumberDayTrades<=nDayTrades;
                  break;
                 }
         //     }
         //     if(MaxNumberDayTrades<=nDayTrades){
         //     break;
         //    }
          }
      // Print("For loop - nDayTrades: ",nDayTrades);
      //=========================================================================================
      // Calculate the number of open trades for the current Symbol, this produces symbol_total which is not allowed to be > 1
      for(trade=OrdersTotal()-1;trade>=0;trade--)
      {
      //  if(OrderMagicNumber()==EAMagic)
      //  {
        if(!OrderSelect(trade,SELECT_BY_POS,MODE_TRADES))
         continue;
         if(OrderSymbol()==Symbol())
         {
           if((OrderType()==OP_SELL||OrderType()==OP_BUY) && OrderMagicNumber()==EAMagicNumber)
           //ctm=OrderOpenTime();
           //Print(" Trade: ",trade,"OrderOpenTime: ", TimeToStr(ctm,TIME_DATE|TIME_SECONDS));
           symbol_total++;
      //     }
        }
      }

  }
}
