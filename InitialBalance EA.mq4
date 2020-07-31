//+------------------------------------------------------------------------------------------------------------------+
//|                                                                        Support_Resistance_EA.mq4 |
//|                                                             Copyright 20200716,Christo Strydom. |
//|                                                                      christo.w.strydom@gmail.com  |
//| This expert advisor calls the custom indicator "Support and Resistance (Barry)"|
//+--------------------------------------------------------------------------------+
#property copyright   "Christo Strydom"
#property link        "christo.w.strydom@gmail.com"
extern int EAMagic = 16384; //EA's magic number parameter
input double TakeProfit    =200; // 2000 for USDZAR
input double Lots          =0.1; // Trade size
input double StopLoss      =300; // Hard stop, 3000 for USDZAR, The stop loss is not MANAGED
input double Slippage      =3;
input double TrailingStop  =0; // 0 for NO trailing stop
input int StartHour        =8; // Start strategy AFTER this hour
input int StartMinute      =0;
input int EndHour          =14; // Start strategy AFTER this hour
input int EndMinute        =0;

input int InitialBalanceStartHour =8; // Measure Initial balance from this hour
input int InitialBalanceStartMinute =0; // Measure Initial balance from InitialBalanceStartHour hour plus InitialBalanceStartMinute
input int InitialBalanceEndHour =8; // Measure Initial balance up until this hour
input int InitialBalanceEndMinute =0; // Measure Initial balance up intil InitialBalanceEndHour hour plus InitialBalanceEndMinute
input int StartMinute      =0;
input int EndHour          =14; // Start strategy AFTER this hour
input int EndMinute        =0;
input int MaxNumberDayTrades = 1;
// int CountSymbolPositions=0;
double resistance; // =iCustom(NULL,0,"Support and Resistance (Barry)",0,0);
double support; // =iCustom(NULL,0,"Support and Resistance (Barry)",1,0);
double previous_resistance;
double previous_support;
double Previous_Day_High=iHigh(Symbol(),PERIOD_D1,1);
double Previous_Day_Low=iLow(Symbol(),PERIOD_D1,1);

// Calculate tome of daay values:

//datetime ctm;




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

void OnTick(void)
  {
   double Fractal;
   double HighArray[];
   double LowArray[];
   int       i = Bars;
   int       nDayTrades=0;
   int       trade;
   int    cnt,ticket;
   int    total=0;//,total;
   int    symbol_total=0;//,total;
   bool   in_trade_window=false;
   bool   after_trade_window=false;
   datetime CurrentDay =iTime(Symbol(),PERIOD_D1,0);
   datetime PreviousDay =iTime(Symbol(),PERIOD_D1,1);
   bool InTradeAllowance=true;  // InTradeAllowance is set to true.  It will only be set false once nDayTrades>=MaxNumberDayTrades
  //  Define in trade window, good for trading:
   // Print(" Current minute is: ", Minute(), " Current hour is: ", Hour(), "; Current Day: ", CurrentDay);
   if((Hour()-1)>=StartHour  && (Hour()-1)<=EndHour)
    in_trade_window=true;

  //  Define AFTER trade window, CLOSE ALL positions:    
   if((Hour()-1)>=EndHour+1)
    after_trade_window=true;
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
//--- to simplify the coding and speed up access data are put into internal variables
resistance=iCustom(NULL,0,"Support and Resistance (Barry)",0,0);
support=iCustom(NULL,0,"Support and Resistance (Barry)",1,0);
//=======================================================================================
Print("CurrentDay: ",TimeToStr(CurrentDay,TIME_DATE|TIME_SECONDS), ";  Barry support =", support, ";  Barry resistance =", resistance);    

int CountHighs=0;
int CountLows=0;
double CurrentResistance=0;
double CurrentSupport=0;
i=0;
while(i <Bars&&CountHighs<6)
  {   
    Fractal = iFractals(NULL, 0, MODE_UPPER, i);
    //Print("CurrentDay: ",TimeToStr(CurrentDay,TIME_DATE|TIME_SECONDS),"; i = ",i,"; Bars: ",Bars,"; Fractal = ",Fractal, "; CurrentResistance: ",CurrentResistance, "; CountHighs: ", CountHighs);
    //----
    if(Fractal > 0) 
        {
        if(CurrentResistance==0)
           {
              CountHighs++;
              CurrentResistance=High[i];
           }
        else if(High[i]>CurrentResistance)
                 {
                    CountHighs++;                 
                    HighArray[CountHighs] = High[i];
                    CurrentResistance=High[i];
                 }
           }
    i++; 
  }

i=0;
while(i <Bars&&CountLows<6)
  {   
    Fractal = iFractals(NULL, 0, MODE_LOWER, i);
    //Print("CurrentDay: ",TimeToStr(CurrentDay,TIME_DATE|TIME_SECONDS),"; i = ",i,"; Bars: ",Bars,"; Fractal = ",Fractal, "; CurrentSupport: ",CurrentSupport, "; CountLows: ", CountLows);    
    //----
    if(Fractal > 0) 
        {

        if(CurrentSupport==0)
           {
              CountLows++;
              CurrentSupport=Low[i];
           }
        else 
           {
              if(Low[i]<CurrentSupport)
                 {
                    CountLows++;                 
                    LowArray[CountLows] = Low[i];
                    CurrentSupport=Low[i];
                 }
           }

        }
    i++;
  }

Print("CurrentDay: ",TimeToStr(CurrentDay,TIME_DATE|TIME_SECONDS),"; Support = ",LowArray[1], "; Resistance = ", HighArray[1], ",  Barry support =", support, ",  Barry resistance =", resistance);    

//Print("CurrentDay: ",TimeToStr(CurrentDay,TIME_DATE|TIME_SECONDS),"; Current Resistance: ", HighArray[1], "; Previous Resistance: ", HighArray[2]);
//   

   
 // ======================================================================================
 // Calculate here the number of completed trades for thee CURRENT day.  Starting at the most recent trade it goes back until OrderCloseTime()<CurrentDay
nDayTrades=0;
 for(trade=OrdersHistoryTotal()-1;trade>=0;trade--)
    {
     //Print("Trade number: ", trade);
     if(OrderSelect(trade,SELECT_BY_POS,MODE_HISTORY)==true)
       {
         //EA_OrderOpenTime=OrderOpenTime();
         //EA_OrderCloseTime=OrderCloseTime();
         if((OrderCloseTime()>=CurrentDay)&&(OrderSymbol()==Symbol()))
         {
          nDayTrades++;
          InTradeAllowance=MaxNumberDayTrades>nDayTrades;
         };
        //if(OOT>0) Print("OrdersTotal: ",hstTotal,"; Close time for the order:  ",trade," is: ",TimeToStr(OOT,TIME_DATE|TIME_SECONDS), );
       }
     else
       Print("OrderSelect failed error code is: ",GetLastError(), "; with trade: ", trade);
     if((OrderCloseTime()<CurrentDay)||(!InTradeAllowance))
     {
      break;
     }
//     if(MaxNumberDayTrades<=nDayTrades){
//     break;
//    }
    }
// Print("For loop - nDayTrades: ",nDayTrades);
//=========================================================================================
// Calculate the number of open trades for the current Symbol, this produces symbol_total which is not allowed to be > 1
for(trade=OrdersTotal()-1;trade>=0;trade--)
{
  if(!OrderSelect(trade,SELECT_BY_POS,MODE_TRADES))
//  ctm=OrderOpenTime();
  //Print(" Trade: ",trade,"OrderOpenTime: ", TimeToStr(ctm,TIME_DATE|TIME_SECONDS));  
  continue;
if(OrderSymbol()==Symbol())
{
  if((OrderType()==OP_SELL||OrderType()==OP_BUY) && OrderMagicNumber()==EAMagic)
  //ctm=OrderOpenTime();
  //Print(" Trade: ",trade,"OrderOpenTime: ", TimeToStr(ctm,TIME_DATE|TIME_SECONDS));
  symbol_total++;
  }
}
//=========================================================================================

// Print("For symbol: ",Symbol()," --- are we in the trade window: ",in_trade_window,"; Trade allowance ok: ",nTradeAllowance, "; MaxNumberDayTrades: ",MaxNumberDayTrades,"; Open Trades: ",symbol_total, "; nDayTrades: ",nDayTrades);
//Print("For symbol: ",Symbol()," in  trade window: ",in_trade_window,"; CurrentDay: ",TimeToStr(CurrentDay,TIME_DATE|TIME_SECONDS),"; PreviousDay: ",TimeToStr(PreviousDay,TIME_DATE|TIME_SECONDS), "; MaxNumberDayTrades: ",MaxNumberDayTrades,"; InTradeAllowance: ",InTradeAllowance, "; Open Trades: ",symbol_total, "; nDayTrades: ",nDayTrades); 
// Print("symbol_total: ",symbol_total);
// Print("Last Trade ", TimeToStr(ctm,TIME_DATE|TIME_SECONDS));
// Print("Currency: ", Symbol(), "; OrdersTotal: ", total,"; symbol_total: ",symbol_total, "; Is symbol_total<1:  ",symbol_total<1,"; Is Bid<support: " , Bid<support, "; Is Ask>resistance: ",Ask>resistance, "; Are we in the trade window: ",in_trade_window);
// Print("nTradeAllowance: ", nTradeAllowance);
  
   if(symbol_total<1&&InTradeAllowance)
     {
      //--- no opened orders identified
     // Print(total
      if(AccountFreeMargin()<(1000*Lots))
        {
         Print("We have no money. Free Margin = ",AccountFreeMargin());
         return;
        }
      //--- check for long position (BUY) possibility
      if(Ask>resistance && in_trade_window)
        {
        //Print("SELL!");
         Print("Symbol: ",Symbol(),"; OPSELL: ",OP_SELL,"; Lots: ", Lots,"; Bid: ",Bid,"; Slippage: ",Slippage,"; stop los: ", Bid+StopLoss*Point,"; take profit: ",Bid-TakeProfit*Point,"AE Capital, S&R sample",16384,0);
         ticket=OrderSend(Symbol(),OP_SELL,Lots,Bid,Slippage,Bid+StopLoss*Point,Bid-TakeProfit*Point,"AE Capital, S&R sample",16384,0,Red);
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
      if(Bid<support && in_trade_window)
        {
        Print("BUY!");//---
        
        ticket=OrderSend(Symbol(),OP_BUY,Lots,Ask,Slippage,Ask-StopLoss*Point,Ask+TakeProfit*Point,"AE Capital, S&R sample",16384,0,Green);
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
