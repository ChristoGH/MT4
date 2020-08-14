//+------------------------------------------------------------------------------------------------------------------+
//|                                                                        Support_Resistance_EA.mq4 |
//|                                                             Copyright 20200725,Christo Strydom. |
//|                                                                      christo.w.strydom@gmail.com  |
//+------------------------------------------------------------------------------------------------------------------+
#property copyright   "Christo Strydom"
#property link        "christo.w.strydom@gmail.com"
extern int EAMagic = 17384; //EA's magic number parameter
input double TakeProfit    =2000; // 2000 for USDZAR
input double Lots          =0.1; // Trade size
input double StopLoss      =300; // Hard stop, 3000 for USDZAR, The stop loss is not MANAGED
input double Slippage      =3;
input double TrailingStop  =0; // 0 for NO trailing stop
input int Trade_StartHour        =8; // Start strategy AFTER this hour
input int Trade_StartMinute      =0;
input int Trade_EndHour          =14; // Start strategy AFTER this hour
input int Trade_EndMinute        =0;
input int PreviousDay_Strat_StartHour        =8; // Measure previous day trading AFTER this hour
input int PreviousDay_Strat_StartMinute        =0; // Measure previous day trading AFTER this minute
input int PreviousDay_Strat_EndHour        =20; // Measure previous day trading BEFORE this hour
input int PreviousDay_Strat_EndMinute        =0; // Measure previous day trading BEFORE this minute
input int MaxNumberDayTrades = 1;
input int SnRStartHour = 1;
input int SnREndHour = 24;

// int CountSymbolPositions=0;
double resistance; // =iCustom(NULL,0,"Support and Resistance (Barry)",0,0);
double support; // =iCustom(NULL,0,"Support and Resistance (Barry)",1,0);
double previous_resistance;
double previous_support;

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
  //  In this code section we need to find the high and low between two time points as defined by the previous day start of the strategy
   string      StratSymbol          = Symbol();
   int          StratPeriod           = 0; //Period();
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
   
   datetime some_time=D'2020.08.13 12:00';
   int      shift=iBarShift("EURUSD",0,some_time);
   Print("index of the bar for the time ",TimeToStr(some_time)," is ",shift, "; some_time: ",some_time);

   Print("SnRStartTime ",TimeToStr(SnRStartTime));
   Print("For the previous day, from ",TimeToStr(SnRStartTime,TIME_DATE|TIME_SECONDS), " to ", TimeToStr(SnREndTime,TIME_DATE|TIME_SECONDS),", the HIGH is = ",StratHigh," and the LOW is = ",StratLow);  
   Print("For the previous day, SnRStartTime_shift ",SnRStartTime_shift, " SnREndTime_shift ", SnREndTime_shift,", the bar_count is = ",bar_count," and the high_shift is = ",high_shift, " and the low_shift is = ",low_shift);  
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
   datetime start_time=current_day_time+(60*60*Trade_StartHour)+(60*Trade_StartMinute); // Start time of the current TRADING day;
   datetime end_time=current_day_time+(60*60*Trade_EndHour)+(60*Trade_EndMinute); // End time of the current TRADING day;
   int          start_shift=iBarShift(Symbol(),PERIOD_M1,start_time-60);  // Shift in 1 Minute bars to the start start of the TRADING day
   int          day_shift=iBarShift(Symbol(),PERIOD_M1,current_day_time);  // Number of 1 minute 'shifts' of the current bar type to the start of the CURRENT day
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


// ====================================================================================================================
// Here we determine if we are in the tradinbg window:   
if(TimeLocal()>=start_time&&TimeLocal()<=end_time)
 in_trade_window=true;

//  Define AFTER trade window, CLOSE ALL positions:    
if(TimeLocal()>end_time)
 after_trade_window=true;

//=====================================================================================================================
// Here we determine the market high and low since the start of the current day AND the start of the current trading day 
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


//-------------------------------------------------------------------------------------------------------
// https://docs.mql4.com/series/ihighest
//--- calculating the highest value on the 20 consecutive bars in the range
//--- from the 4th to the 23rd index inclusive on the current chart   


// Print("Previous_Day_High: ",Previous_Day_High, "; Previous_Day_Low: ", Previous_Day_Low);
   
//  if(OrderSelect(0,SELECT_BY_POS,MODE_HISTORY)==true)
//    {
//     ctm=OrderOpenTime();
//     // var1=TimeToStr(ctm,TIME_DATE|TIME_SECONDS);
//     if(ctm>0) Print("Open time for the order OrdersTotal() ", TimeToStr(ctm,TIME_DATE|TIME_SECONDS));
//     ctm=OrderCloseTime();
//     if(ctm>0) Print("Close time for the order OrdersTotal() ", ctm);
//    }
//  else
//    Print("OrderSelect failed error code is",GetLastError());
    
 //  if(OrderSelect(OrdersTotal()-1,SELECT_BY_POS,MODE_TRADES))
//    {
//     ctm=OrderOpenTime();
//     if(ctm>0) Print("Open time for the order OrdersTotal() ", TimeToStr(ctm,TIME_DATE|TIME_SECONDS));
//     ctm=OrderCloseTime();
//     if(ctm>0) Print("Open time for the order OrdersTotal() ", TimeToStr(ctm,TIME_DATE|TIME_SECONDS));
//    }
//  else
//    Print("OrderSelect failed error code is",GetLastError());
   
//---
// initial data checks
// it is important to make sure that the expert works with a normal
// chart and the user did not make any mistakes setting external 
// variables (Lots, StopLoss, TakeProfit, 
// TrailingStop) in our case, we check TakeProfit
// on a chart of less than 100 bars
//---
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
            //         if(OrderMagicNumber()==EAMagic)
            //         {
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
     if((OrderType()==OP_SELL||OrderType()==OP_BUY) && OrderMagicNumber()==EAMagic)
     //ctm=OrderOpenTime();
     //Print(" Trade: ",trade,"OrderOpenTime: ", TimeToStr(ctm,TIME_DATE|TIME_SECONDS));
     symbol_total++;
//     }
  }
}
//=========================================================================================

// Print("For symbol: ",Symbol()," --- are we in the trade window: ",in_trade_window,"; Trade allowance ok: ",nTradeAllowance, "; MaxNumberDayTrades: ",MaxNumberDayTrades,"; Open Trades: ",symbol_total, "; nDayTrades: ",nDayTrades);
Print("For symbol: ",Symbol()," in  trade window: ",in_trade_window,"; CurrentDay: ",TimeToStr(CurrentDay,TIME_DATE|TIME_SECONDS),"; PreviousDay: ",TimeToStr(PreviousDay,TIME_DATE|TIME_SECONDS));
// Print("symbol_total: ",symbol_total);
// Print("Last Trade ", TimeToStr(ctm,TIME_DATE|TIME_SECONDS));
// Print("Currency: ", Symbol(), "; OrdersTotal: ", total,"; symbol_total: ",symbol_total, "; Is symbol_total<1:  ",symbol_total<1,"; Is Bid<support: " , Bid<support, "; Is Ask>resistance: ",Ask>resistance, "; Are we in the trade window: ",in_trade_window);
// Print("nTradeAllowance: ", nTradeAllowance);
// ========================================================================================
   bool       valid_buy_trigger=false;
   bool       valid_sell_trigger=false;
   double    current_buy_stoploss=Bid-StopLoss*Point;
   double    current_buy_takeprofit =Bid+TakeProfit*Point;
   double    current_sell_stoploss=Ask+StopLoss*Point;
   double    current_sell_takeprofit =Ask-TakeProfit*Point;   
   //  Calculate the valid triggers:
   //  For a SELL ask must be above resistance.
   //  We must be in the trade window.
   //  The previous bar must have CLOSED BELOW the resistance.
   //  Resistance is > 0.
   //  There are no OPEN positions.
   //  We are inside our trade allowance for the day
   valid_sell_trigger=Ask>StratHigh && in_trade_window && previous_high<StratHigh && StratHigh>0 && symbol_total<1 && InTradeAllowance;// && Ask > period_high;
   Print("valid_sell_trigger: ", valid_sell_trigger,"; Ask>StratHigh: ",Ask>StratHigh,"; in_trade_window: ",in_trade_window,"; previous_high<StratHigh: ", previous_high<StratHigh,"; stop loss: ", current_buy_stoploss,"; take profit: ",current_buy_takeprofit);   
   //  For a BUY, bid must be BELOW support..
   //  We must be in the trade window.
   //  The previous bar must have CLOSED ABOVE  the support.
   //  Support is > 0.
   //  There are no OPEN positions.
   //  We are inside our trade allowance for the day
   valid_buy_trigger=Bid<StratLow && in_trade_window && previous_low>StratLow  && symbol_total<1 && InTradeAllowance;// && Bid < period_low;
   Print("valid_buy_trigger: ", valid_buy_trigger,"; Bid<StratLow: ",Bid<StratLow,"; in_trade_window: ",in_trade_window,"; previous_low>StratLow: ", previous_low>StratLow,"; stop loss: ", current_sell_stoploss,"; take profit: ",current_sell_takeprofit);
   
  // int          cnt,ticket;

   //int          total=0;//,total;
  
   if(valid_sell_trigger || valid_buy_trigger)
     {
      //--- no opened orders identified
     // Print(total
      if(AccountFreeMargin()<(1000*Lots))
        {
         Print("We have no money. Free Margin = ",AccountFreeMargin());
         return;
        }
      //--- check for long position (BUY) possibility
     if(valid_sell_trigger)
        {
        //Print("SELL!");
         Print("Symbol: ",Symbol(),"; OPSELL: ",OP_SELL,"; Lots: ", Lots,"; Bid: ",Bid,"; Slippage: ",Slippage,"; stop loss: ", current_sell_stoploss,"; take profit: ",current_sell_takeprofit,"AE Capital, S&R sample",EAMagic,0);
         ticket=OrderSend(Symbol(),OP_SELL,Lots,Bid,Slippage,current_sell_stoploss,current_sell_takeprofit,"AE Capital, S&R sample",EAMagic,0,Red);
         if(ticket>0)
           {
            if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
               Print("SELL order opened : ",OrderOpenPrice());
           }
         else
            Print("Error opening SELL order : ",GetLastError());
         return;
        }
      //--- check for short position (SELL) possibility
   if( valid_buy_trigger)
        {
        Print("BUY!");//---
        
        ticket=OrderSend(Symbol(),OP_BUY,Lots,Ask,Slippage,current_buy_stoploss,current_sell_takeprofit,"AE Capital, S&R sample",EAMagic,0,Green);
        //--- ticket=OrderSend(Symbol(),OP_SELL,Lots,Bid,3,0,Bid-TakeProfit*Point,"S&R sample",16384,0,Red);
         if(ticket>0)
           {
            if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
               Print("BUY order opened : ",OrderOpenPrice());
           }
         else
            Print("Error opening BUY order : ",GetLastError());
        }
      //--- exit from the "no opened orders" block
      return;
     }
//--- it is important to enter the market correctly, but it is more important to exit it correctly...   
   for(cnt=0;cnt<total;cnt++)
     {
      if(!OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES))
         continue;
      if(OrderType()<=OP_SELL &&   // check for opened position 
         OrderSymbol()==Symbol())  // check for symbol
        {
         //--- long position is opened
         if(OrderType()==OP_BUY)
           {
            //--- should it be closed?
            // if(MacdCurrent>0 && MacdCurrent<SignalCurrent && MacdPrevious>SignalPrevious && 
            //    MacdCurrent>(MACDCloseLevel*Point))
            //   {
            //    //--- close order and exit
            //    if(!OrderClose(OrderTicket(),OrderLots(),Bid,3,Violet))
            //       Print("OrderClose error ",GetLastError());
            //    return;
            //   }
            //--- check for trailing stop
            if(TrailingStop>0)
              {
               if(Bid-OrderOpenPrice()>Point*TrailingStop)
                 {
                  if(OrderStopLoss()<Bid-Point*TrailingStop)
                    {
                     //--- modify order and exit
                     if(!OrderModify(OrderTicket(),OrderOpenPrice(),Bid-Point*TrailingStop,OrderTakeProfit(),0,Green))
                        Print("OrderModify error ",GetLastError());
                     return;
                    }
                 }
              }
              if (after_trade_window){              
                ticket=OrderClose(OrderTicket(),Lots,Bid,Slippage,Red);
                if(ticket>0)
                  {
                    if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                      Print("Closed LONG position after trade window, SELL order ",OrderTicket(), " at ", Bid); 
                  }
                else {
                      Print("Error closing LONG position : ",GetLastError());
                    }

                }
           }
         else // go to short position
           {
            //--- should it be closed?
            // if(MacdCurrent<0 && MacdCurrent>SignalCurrent && 
            //    MacdPrevious<SignalPrevious && MathAbs(MacdCurrent)>(MACDCloseLevel*Point))
            //   {
            //    //--- close order and exit
            //    if(!OrderClose(OrderTicket(),OrderLots(),Ask,3,Violet))
            //       Print("OrderClose error ",GetLastError());
            //    return;
            //   }
            //--- check for trailing stop
            if(TrailingStop>0)
              {
               if((OrderOpenPrice()-Ask)>(Point*TrailingStop))
                 {
                  if((OrderStopLoss()>(Ask+Point*TrailingStop)) || (OrderStopLoss()==0))
                    {
                     //--- modify order and exit
                     if(!OrderModify(OrderTicket(),OrderOpenPrice(),Ask+Point*TrailingStop,OrderTakeProfit(),0,Red))
                        Print("OrderModify error ",GetLastError());
                     return;
                    }
                 }
              }
            if (after_trade_window){
              ticket = OrderClose(OrderTicket(),Lots,Ask,Slippage,Red);
              if(ticket>0)
                {
                  if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                    Print("Close SHORT after trade window, buy back order ",OrderTicket(), " at ", Ask);; 
                }
              else {
                    Print("Error CLOSING SHORT order : ",GetLastError());
                  }

              }
           }
        }
     }

//---
  }
//+------------------------------------------------------------------+
