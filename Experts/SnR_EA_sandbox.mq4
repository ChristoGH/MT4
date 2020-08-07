//+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
//|                                                                                                                                         Support_Resistance_EA.mq4 |
//|                                                                                                                             Copyright 20200716,Christo Strydom. |
//|                                                                                                                                      christo.w.strydom@gmail.com  |
//| This expert advisor no longer  calls the custom indicator "Support and Resistance (Barry)", but uses the same methodology |
//+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
#property copyright   "Christo Strydom"
#property link        "christo.w.strydom@gmail.com"
extern int EAMagic = 17384; //EA's magic number parameter
input double TakeProfit    =200; // 2000 for USDZAR
input double Lots          =0.1; // Trade size
input double StopLoss      =300; // Hard stop, 3000 for USDZAR, The stop loss is not MANAGED
input double Slippage      =3;
input double TrailingStop  =0; // 0 for NO trailing stop
input int Trade_StartHour        =8; // Start strategy AFTER this hour
input int Trade_StartMinute      =0;
input int Trade_EndHour          =14; // Start strategy AFTER this hour
input int Trade_EndMinute        =0;
input int PreviousDay_Strat_StartHour        =8; // Start strategy AFTER this hour
input int PreviousDay_Strat_StartMinute        =0; // Start strategy AFTER this hour
input int PreviousDay_Strat_EndHour        =20; // Start strategy AFTER this hour
input int PreviousDay_Strat_EndMinute        =0; // Start strategy AFTER this hour
input int MaxNumberDayTrades = 1;
input int SnRStartHour = 1;
input int SnREndHour = 24;

// int CountSymbolPositions=0;
double resistance; // =iCustom(NULL,0,"Support and Resistance (Barry)",0,0);
double support; // =iCustom(NULL,0,"Support and Resistance (Barry)",1,0);
double previous_resistance;
double previous_support;

void OnTick(void)
  {
  //  In this code section we need to find the high and low between two time points as defined by the previous day start of the strategy
   string      StratSymbol          = Symbol();
   int          StratPeriod           = Period();
   datetime PreviousDay =iTime(Symbol(),PERIOD_D1,1);  // The start time 00:00:00 of the PREVIOUS day   
   datetime SnRStartTime = PreviousDay + PreviousDay_Strat_StartHour * 60 *60+PreviousDay_Strat_StartMinute*60;
   datetime SnREndTime = PreviousDay + PreviousDay_Strat_EndHour * 60 *60+PreviousDay_Strat_EndMinute*60;
   int          SnRStartTime_shift   = iBarShift(StratSymbol,StratPeriod,SnRStartTime); //This is the index of the bar corresponding toSnRStartTime.
   int          SnREndTime_shift    = iBarShift(StratSymbol,StratPeriod,SnREndTime); //This is the index of the bar corresponding SnREndTime.
   int          bar_count   = SnRStartTime_shift-SnREndTime_shift; // The number of bars between SnREndTime_shift and SnRStartTime_shift
   int          high_shift  = iHighest(StratSymbol,StratPeriod,MODE_HIGH,bar_count,SnREndTime_shift); // This is the shift in bars to find the maximum value starting from SnREndTime_shift going back bar_count number of bars but no further than SnRStartTime.
   int          low_shift   = iLowest(StratSymbol,StratPeriod,MODE_LOW,bar_count,SnREndTime_shift); // This is the shift in bars to find the maximum value starting from SnREndTime_shift going back bar_count number of bars but no further than SnRStartTime..
   double    StratHigh        = High[high_shift];
   double    StratLow         = Low[low_shift];//iLow(StratSymbol,StratPeriod,low_shift);

   Print("Period ", Period());
   Print("For the previous day, from ",TimeToStr(SnRStartTime,TIME_DATE|TIME_SECONDS), " to ", TimeToStr(SnREndTime,TIME_DATE|TIME_SECONDS),", the HIGH is = ",StratHigh," and the LOW is = ",StratLow);  

   int    nDayTrades=0;
   int    trade;
   int    cnt,ticket;
   int    total=0;//,total;
   int    symbol_total=0;//,total;

   bool InTradeAllowance=true;  // InTradeAllowance is set to true.  It will only be set false once nDayTrades>=MaxNumberDayTrades
  //===================================================================================================
  //  Define in_trade_window, a boolean operator which is true only if we are inside the hours defined by StartHour and EndHour
  //  To do: convert all to seconds, so that comparison will include StartMinute
//Print("Current bar for Symbol() H1: ",iTime(Symbol(),PERIOD_M1,start_shift), "; TimeToStr(start_time,TIME_DATE|TIME_SECONDS): ",TimeToStr(start_time,TIME_DATE|TIME_SECONDS), "; start_shift: ", start_shift, "; ",  iOpen(Symbol(),PERIOD_M1,start_shift),", ",
//                                      iHigh(Symbol(),PERIOD_M1,start_shift),", ",  iLow(Symbol(),PERIOD_M1,start_shift),", ",
//                                      iClose(Symbol(),PERIOD_M1,start_shift),", ", iVolume(Symbol(),PERIOD_M1,start_shift),
//                                      "; period_high: ",iHigh(Symbol(),PERIOD_M1,iHi),
//                                       "; period_low: ",iLow(Symbol(),PERIOD_M1,iLo));

//int result =trade_window(start_time,end_time);
datetime current_day_time =iTime(Symbol(),PERIOD_D1,0);  // The start time 00:00:00 of the CURRENT day
datetime start_time=current_day_time+(60*60*Trade_StartHour)+(60*Trade_StartMinute);
datetime end_time=current_day_time+(60*60*Trade_EndHour)+(60*Trade_EndMinute);
int          start_shift=iBarShift(Symbol(),PERIOD_M1,start_time-60);  // 
int          day_shift=iBarShift(Symbol(),PERIOD_M1,current_day_time);  // Number of 'shifts' of the current bar type to the start of the day
int          in_trade_shift_hi=iHighest(Symbol(),PERIOD_M1,MODE_HIGH,start_shift,1); // Number of shifts  from current bar to HIGHEST bar in trade window
int          in_trade_shift_lo=iLowest(Symbol(),PERIOD_M1,MODE_LOW,start_shift,1); // Number of shifts  from current bar to LOWEST bar in trade window
int          premarket_shift_hi=iHighest(Symbol(),PERIOD_M1,MODE_HIGH,day_shift,start_shift); // Number of shifts from current bar to HIGHEST bar in pre market window
int          premarket_shift_lo=iLowest(Symbol(),PERIOD_M1,MODE_LOW,day_shift,start_shift); //  Number of shifts from current bar to LOWEST bar in pre market window 
bool        in_trade_window=false;
bool        after_trade_window=false;
double    period_high, period_low;  
double    previous_close= iClose(Symbol(),PERIOD_M1,1);
double    previous_high= iHigh(Symbol(),PERIOD_M1,1);
double    previous_low= iLow(Symbol(),PERIOD_M1,1);         

if(TimeLocal()>=start_time&&TimeLocal()<=end_time)
 in_trade_window=true;

//  Define AFTER trade window, CLOSE ALL positions:    
if(TimeLocal()>end_time)
 after_trade_window=true;
 
if((in_trade_shift_hi!=-1)&&(in_trade_window||after_trade_window)) 
{
period_high=iHigh(Symbol(),PERIOD_M1,in_trade_shift_hi);
} 

if((in_trade_shift_hi==-1)||(!in_trade_window)) 
{
period_high=iHigh(Symbol(),PERIOD_M1,premarket_shift_hi);
}

if((in_trade_shift_lo!=-1)||(in_trade_window||after_trade_window))
{
period_low=iLow(Symbol(),PERIOD_M1,in_trade_shift_lo);
} 

if((in_trade_shift_hi==-1)||(!in_trade_window)) 
{
period_low=iLow(Symbol(),PERIOD_M1,premarket_shift_lo);
}

   if(Bars<100)
     {
      Print("bars less than 100");
      return;
     }
   if(TakeProfit<10)
     {
      Print("TakeProfit less than 10");
      return;
     }
  
 // ======================================================================================
 // Calculate here the number of completed trades for the CURRENT day.  Starting at the most recent trade it goes back until OrderCloseTime()<CurrentDay
nDayTrades=0;
 datetime CurrentDay =iTime(Symbol(),PERIOD_D1,0);  // The start time 00:00:00 of the CURRENT day   
 for(trade=OrdersHistoryTotal()-1;trade>=0;trade--)
    {
     //Print("Trade number: ", trade);
     if(OrderSelect(trade,SELECT_BY_POS,MODE_HISTORY)==true)
       {
         //EA_OrderOpenTime=OrderOpenTime();
         //EA_OrderCloseTime=OrderCloseTime();
         if(OrderMagicNumber()==EAMagic)
         {
         if((OrderCloseTime()>=CurrentDay)&&(OrderSymbol()==Symbol()))
         {
          nDayTrades++;
         };
        //if(OOT>0) Print("OrdersTotal: ",hstTotal,"; Close time for the order:  ",trade," is: ",TimeToStr(OOT,TIME_DATE|TIME_SECONDS), );
       }
     else
       Print("OrderSelect failed error code is: ",GetLastError(), "; with trade: ", trade);
     if((OrderCloseTime()<CurrentDay)||(MaxNumberDayTrades<=nDayTrades))
     {
      InTradeAllowance=MaxNumberDayTrades<=nDayTrades;
      break;
     }
     }
//     if(MaxNumberDayTrades<=nDayTrades){
//     break;
//    }
    }
// Print("For loop - nDayTrades: ",nDayTrades);


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
//double time_diff=0;
//datetime current_time= iTime(Symbol(),PERIOD_M1,0);
//time_diff=(current_time-iTime(Symbol(),0,index))/(60*60);
//Print(" time_diff in seconds: ",time_diff, "; index: ", index,  "; Open[index]: ",Open[index],"; High[index]: ",High[index],"; Low[index]: ",Low[index], "; Close[index]: ",Close[index], "; time of index: ", TimeToStr(iTime(Symbol(),0,index),TIME_DATE|TIME_SECONDS));
}