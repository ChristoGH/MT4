//+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
//|                                                                                                                                         Support_Resistance_EA.mq4 |
//|                                                                                                                             Copyright 20200716,Christo Strydom. |
//|                                                                                                                                      christo.w.strydom@gmail.com  |
//| This expert advisor no longer  calls the custom indicator "Support and Resistance (Barry)", but uses the same methodology |
//+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
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
input int MaxNumberDayTrades = 1;
// int CountSymbolPositions=0;
double resistance; // =iCustom(NULL,0,"Support and Resistance (Barry)",0,0);
double support; // =iCustom(NULL,0,"Support and Resistance (Barry)",1,0);
double previous_resistance;
double previous_support;
double Previous_Day_High=iHigh(Symbol(),PERIOD_D1,1);
double Previous_Day_Low=iLow(Symbol(),PERIOD_D1,1);

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
   double    Fractal;
   double    order_stoploss;
   double    current_buy_stoploss=Bid-StopLoss*Point;
   double    current_buy_takeprofit =Ask+TakeProfit*Point;
   double    current_sell_stoploss=Ask+StopLoss*Point;
   double    current_sell_takeprofit =Bid-TakeProfit*Point;
   double    HighArray[6];
   double    LowArray[6];
   double    previous_close= iClose(Symbol(),PERIOD_M1,1);
   int          i = Bars;
   int          nDayTrades=0;
   int          trade;
   int          cnt,ticket;
   int          total=0;//,total;
   int          symbol_total=0;//,total;
   int          order_type; // Used to determine the order type of the previous trade.
   bool       in_trade_window=false;
   bool       after_trade_window=false;
   bool       InTradeAllowance=true;  // InTradeAllowance is set to true.  It will only be set false once nDayTrades>=MaxNumberDayTrades
   bool       ValidSupport=true;  // Is there a support BELOW to trade off?   
   bool       ValidResistance=true;  // Is there a resistance ABOVE to trade off?
   bool       valid_buy_trigger=false;
   bool       valid_sell_trigger=false;
   datetime CurrentDay =iTime(Symbol(),PERIOD_D1,0);
   datetime PreviousDay =iTime(Symbol(),PERIOD_D1,1);

  //  Define in_trade_window, a boolean operator which is true only if we are inside the hours defined by StartHour and EndHour
  //  To do: convert all to seconds, so that comparison will include StartMinute

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
// ======================================================================================
// The following is DEPRECATED.  These values are no longer required and is overwritten further down:
resistance=iCustom(NULL,0,"Support and Resistance (Barry)",0,0);
support=iCustom(NULL,0,"Support and Resistance (Barry)",1,0);
//=======================================================================================
//Print("CurrentDay: ",TimeToStr(CurrentDay,TIME_DATE|TIME_SECONDS), ";  Barry support =", support, ";  Barry resistance =", resistance);    

int CountHighs=0;
int CountLows=0;
int Index = 0;
double CurrentResistance=0;
double CurrentSupport=0;
int total_bars =iBars(Symbol(),PERIOD_H1);
i=total_bars;

while(i >0&&CountHighs<6)
  {  
    Index =   total_bars - i;
    Fractal = iFractals(NULL, 0, MODE_UPPER, Index);
    //Print(
    //Print("CurrentDay: ",TimeToStr(CurrentDay,TIME_DATE|TIME_SECONDS),"; i = ",i,"; Bars: ",Bars,"; Fractal = ",Fractal, "; CurrentResistance: ",CurrentResistance, "; CountHighs: ", CountHighs);
    //----
    if(Fractal > 0) 
        {
    
        if(CurrentResistance==0)
           {
              CurrentResistance=High[Index];
              HighArray[CountHighs] =CurrentResistance;
           }
        else if(High[Index]>CurrentResistance)
                 {
                    CurrentResistance=High[Index];                           
                    HighArray[CountHighs] = CurrentResistance;
                 }
        CountHighs++;    
           }
    i--; 
  }

Index=0;
i=total_bars;

while(i >0&&CountLows<6)
  {
    Index =   total_bars - i +1; 
    Fractal = iFractals(NULL, 0, MODE_LOWER, Index);
    //Print("CurrentDay: ",TimeToStr(CurrentDay,TIME_DATE|TIME_SECONDS),"; i = ",i,"; Bars: ",Bars,"; Fractal = ",Fractal, "; CurrentSupport: ",CurrentSupport, "; CountLows: ", CountLows);    
    //----
    if(Fractal > 0) 
        {

        if(CurrentSupport==0)
           {
              CurrentSupport=Low[Index];
              LowArray[CountLows] =CurrentSupport;
              //Print("CountLows: ",CountLows,"; CurrentSupport: ",CurrentSupport,";  LowArray[CountLows]: ", LowArray[CountLows]);
           }
        else 
           {
              if(Low[Index]<CurrentSupport)
                 {
                    CurrentSupport=Low[Index];                    
                    LowArray[CountLows] =CurrentSupport;
                 }
         CountLows++;        
          }

        }
    i--;
  }

//Print("Bar count on the ', Symbol(),' is ",iBars(Symbol(),PERIOD_H1));
//Print("CurrentDay: ",TimeToStr(CurrentDay,TIME_DATE|TIME_SECONDS), ";  HighArray 0: ", HighArray[0],   ";  HighArray 1: ",HighArray[1], ";  HighArray 2: ", HighArray[2], ";  HighArray 3: ", HighArray[3],  ";  HighArray 4: ",HighArray[4], ";  HighArray 5: ", HighArray[5],   ";  HighArray 6: ",HighArray[6]);    



// LowArray[1] = Barry Support;  HighArray[1] = Barry Resistance;
// LowArray[2] = Is the next LOWEST support;  HighArray[2] = Is the next LOWEST Resistance;
// 
// Print("CurrentDay: ",TimeToStr(CurrentDay,TIME_DATE|TIME_SECONDS),"; Previous Support = ",LowArray[2], "; Previous Resistance = ", HighArray[2], ",  Barry support =", support, ",  Barry resistance =", resistance);    

// Print("CurrentDay: ",TimeToStr(CurrentDay,TIME_DATE|TIME_SECONDS),"; Current Resistance: ", HighArray[1], "; Previous Resistance: ", HighArray[2]);
//   

   
 // ======================================================================================
 // Calculate here the number of completed trades for the CURRENT day and CURRENT sumbol.  Starting at the most recent trade it goes back until OrderCloseTime()<CurrentDay.

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
//          order_type=OrderType(); // order_type = 0, bought;  order_type = 1, sold; 
//          order_stoploss =OrderStopLoss();
//          
//          if(order_type==0)
//          {
//          current_buy_stoploss = order_stoploss;
//          }
//          if(order_type==1)
//          {
//          current_sell_stoploss = order_stoploss;
//          }
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

//=========================================================================================
// Adjust the support and resistance based on nDayTrades.  For nDayTrades = 0, support=LowArray[1] and resistance = HighArray[1]

//  The question is now, for BUYING again during the same day, after at least one LONG trade has closed, is there a support level LOWER than the stoploss of that LONG trade?
//  Vice versa,  for SELLING again during the same day after at least one SHORT trade has closed, is there a resistance level HIGHER than the stoploss of that SHORT trade?

//  The current_buy_stoploss is the stoploss price of the most recent LONG trade.  We should not go long ABOVE this level.
//  The next LONG trade should be triggered at a support LOWER than the previous long trade AND lower than the lowes stoploss for the day which should be == current_buy_stoploss.
//  It comes down to asking is there a support LOWER than the current_buy_stoploss.  That becomes the new trigger for a new LONG trade.

//  SIMILARLY, the current_sell_stoploss is the stoploss price of the most recent SHORT trade.  We should not go short BELOW this level.
//  The next SHORT trade should be triggered at a resistance HIGHER than the previous short trade AND higher than the highest short stoploss for the day which (if all worked correctly) should be == current_sell_stoploss.
//  It comes down to asking is there a resistance HIGHER than the current_sell_stoploss.  That becomes the  trigger for a new SHORT trade.

//  In what follows we ask first if there has been a closed trade for the day.  If not we simply tade on the level 1 support and resistance.
//  If there has been a trade we look 'left' for the next supports and resistances but ONLY those
//   1.  Beyond the most recently used 


if(nDayTrades>0)
{
 for(i=0;i<=6;i++)
 {
    if(LowArray[nDayTrades+i]<LowArray[nDayTrades+i-1]-StopLoss*Point)
    {
    support=LowArray[nDayTrades+i];
    }
   if(HighArray[nDayTrades+i]>HighArray[nDayTrades+i-1]+StopLoss*Point)
    {
    resistance = HighArray[nDayTrades+i];
    } 
else
{
   if(LowArray[nDayTrades+i]<previous_close)
       {
       support=LowArray[nDayTrades+i];
       }
   if(HighArray[nDayTrades+i]>previous_close)
       {
      resistance = HighArray[nDayTrades+1];
       }
}
}
}
Print("CurrentDay: ",TimeToStr(CurrentDay,TIME_DATE|TIME_SECONDS), "; Symbol: ",Symbol(),"; previous_close: ",previous_close,"; current support: ",support,"; support level 0: ",LowArray[0],"; support level 1: ",LowArray[1],"; current resistance: ",resistance, ";  resistance level 0: ", HighArray[0],   ";  resistance level 1: ",HighArray[1]);    



//=========================================================================================
// If 
// Print("CurrentDay: ",TimeToStr(CurrentDay,TIME_DATE|TIME_SECONDS),"; current_buy_stoploss",current_buy_stoploss,"; current_sell_stoploss",current_sell_stoploss,"; Current Support = ",support, "; Current Resistance = ",resistance, "; Previous Support = ",LowArray[nDayTrades], "; Previous Resistance = ", HighArray[nDayTrades]);    
//Print("Current bar for USDCHF H1: ",TimeToStr(TimeLocal(),TIME_DATE|TIME_SECONDS),", ",  iOpen(Symbol(),PERIOD_M1,0),", ",
//                                      iHigh(Symbol(),PERIOD_M1,0),", ",  iLow(Symbol(),PERIOD_M1,0),", ",
//                                      iClose(Symbol(),PERIOD_M1,1),", ", iVolume(Symbol(),PERIOD_M1,0));
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


// Debugging PRINTS:
// Print("For symbol: ",Symbol()," --- are we in the trade window: ",in_trade_window,"; Trade allowance ok: ",nTradeAllowance, "; MaxNumberDayTrades: ",MaxNumberDayTrades,"; Open Trades: ",symbol_total, "; nDayTrades: ",nDayTrades);
// Print("For symbol: ",Symbol()," in  trade window: ",in_trade_window,"; CurrentDay: ",TimeToStr(CurrentDay,TIME_DATE|TIME_SECONDS),"; PreviousDay: ",TimeToStr(PreviousDay,TIME_DATE|TIME_SECONDS), "; MaxNumberDayTrades: ",MaxNumberDayTrades,"; InTradeAllowance: ",InTradeAllowance, "; Open Trades: ",symbol_total, "; nDayTrades: ",nDayTrades); 
// Print("symbol_total: ",symbol_total);
// Print("Last Trade ", TimeToStr(ctm,TIME_DATE|TIME_SECONDS));
// Print("Currency: ", Symbol(), "; OrdersTotal: ", total,"; symbol_total: ",symbol_total, "; Is symbol_total<1:  ",symbol_total<1,"; Is Bid<support: " , Bid<support, "; Is Ask>resistance: ",Ask>resistance, "; Are we in the trade window: ",in_trade_window);
// Print("nTradeAllowance: ", nTradeAllowance);

// ========================================================================================
//  Calculate the valid triggers:
//  For a SELL ask must be above resistance.
//  We must be in the trade window.
//  The previous bar must have CLOSED BELOW the resistance.
//  Resistance is > 0.
//  There are no OPEN positions.
//  We are inside our trade allowance for the day
valid_sell_trigger=Ask>resistance && in_trade_window && previous_close<resistance && resistance>0 && symbol_total<1 && InTradeAllowance;
//  For a BUY, bid must be BELOW support..
//  We must be in the trade window.
//  The previous bar must have CLOSED ABOVE  the support.
//  Support is > 0.
//  There are no OPEN positions.
//  We are inside our trade allowance for the day
valid_buy_trigger=Bid<support && in_trade_window && previous_close>support && support>0 && symbol_total<1 && InTradeAllowance;

// =========================================================================================
// The code below is the EXECUTION engine:
//  It asks first if there is an opoen trade in the current symbol.  If yes do NOTHING.
//  Are we inside our predefined macimum number of trades (CLOSED positions) for the day.  If yes proceed.

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
        // int OrderSend (string symbol, int cmd, double volume, double price, int slippage, double stoploss,double takeprofit, string comment=NULL, int magic=0, datetime expiration=0, color arrow_color=CLR_NONE)
         Print("Symbol: ",Symbol(),"; OPSELL: ",OP_SELL,"; Lots: ", Lots,"; Bid: ",Bid,"; Slippage: ",Slippage,"; stop loss: ", Bid-TakeProfit*Point,"; take profit: ",Bid-TakeProfit*Point,"AE Capital, S&R sample",16384,0);
         ticket=OrderSend(Symbol(),OP_SELL,Lots,Bid,Slippage,current_sell_stoploss,current_sell_takeprofit,"AE Capital, S&R sample",16384,0,Red);
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
      if(valid_buy_trigger)
        {
        Print("BUY!");//---
        
        ticket=OrderSend(Symbol(),OP_BUY,Lots,Ask,Slippage,current_buy_stoploss,current_buy_takeprofit,"AE Capital, S&R sample",16384,0,Green);
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
