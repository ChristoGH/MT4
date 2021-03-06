//+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
//|                                                                                                                                         Support_Resistance_EA.mq4 |
//|                                                                                                                             Copyright 20200716,Christo Strydom. |
//|                                                                                                                                      christo.w.strydom@gmail.com  |
//| This expert advisor no longer  calls the custom indicator "Support and Resistance (Barry)", but uses the same methodology |
//+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
#property copyright   "Christo Strydom"
#property link        "christo.w.strydom@gmail.com"
input double Lots          =0.1; // Trade size
input double TrailingStop  =0; // 0 for NO trailing stop
input double Slippage      =3;
input double TakeProfit    =200; // 2000 for USDZAR
input double StopLoss      =300; // Hard stop, 3000 for USDZAR, The stop loss is not MANAGED
input int StartHour        =9; // Start strategy AFTER this hour
input int StartMinute      =0;
input int EndHour          =14; // Start strategy AFTER this hour
input int EndMinute        =0;
input int MaxNumberDayTrades = 1;

extern int EAMagic = 16384; //EA's magic number parameter
datetime CurrentDay =iTime(Symbol(),PERIOD_D1,0);


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

   datetime start_time=CurrentDay+(60*60*StartHour)+(60*StartMinute);
   datetime end_time=CurrentDay+(60*60*EndHour)+(60*EndMinute);
   int          start_shift=iBarShift(Symbol(),PERIOD_M1,start_time-60);  // 
   int          iHi=iHighest(Symbol(),PERIOD_M1,MODE_HIGH,start_shift,1); //
   int          iLo=iLowest(Symbol(),PERIOD_M1,MODE_LOW,start_shift,1); //
   int          index=0;
   int          trade;
   int          order_type; // Used to determine the order type of the previous trade.
   int          nBuyTrades=0;
   int          nSellTrades=0;
   double    period_high, period_low;
   double    previous_close= iClose(Symbol(),PERIOD_M1,1);   
   bool       in_trade_window=false;
   bool       after_trade_window=false;
   bool       InTradeAllowance=true;  // InTradeAllowance is set to true.  It will only be set false once nDayTrades>=MaxNumberDayTrades   
  //===================================================================================================
  //  Define in_trade_window, a boolean operator which is true only if we are inside the hours defined by StartHour and EndHour
  //  To do: convert all to seconds, so that comparison will include StartMinute

if(TimeLocal()>=start_time&&TimeLocal()<=end_time)
 in_trade_window=true;

//  Define AFTER trade window, CLOSE ALL positions:    
if(TimeLocal()>end_time)
 after_trade_window=true;
 
if(iHi!=-1) 
{
period_high=High[iHi];
} 
else 
{
period_high=-1;
}

if(iLo!=-1) 
{
period_low=Low[iLo];
} 
else 
{
period_low=-1;
}
//Print("start_time: ",TimeToStr(start_time,TIME_DATE|TIME_SECONDS),"; end_time: ", TimeToStr(end_time,TIME_DATE|TIME_SECONDS), "; TimeLocal: ",TimeToStr(TimeLocal(),TIME_DATE|TIME_SECONDS) );
//Print(" TimeLocal: ",TimeToStr(TimeLocal(),TIME_DATE|TIME_SECONDS), "; iHi: ",iHi, "; iLo: ",iLo,"; start_shift: ",start_shift, "; in_trade_window: ", in_trade_window, "; period_high: ", period_high, "; period_low: ",period_low);



// ====================================================================================================
// In the below setup: 
// 1) we won't trade  the same support or resistance twice and
// 2) we trade only higher resistances and lower supports.

// Find the LOWEST appropriate the resistance:

int       total_bars =iBars(Symbol(),0);
int       count_bars=total_bars;
double resistance=0;
double support=0;
double fractal;
while(count_bars >0&&resistance==0)
  {  
    index =   total_bars - count_bars+1;  // Start at 1!
//  The following starts iterating BACKWARDS from the before most recent bar:
    fractal = iFractals(NULL, 0, MODE_UPPER, index);
    //Print(
    //Print("CurrentDay: ",TimeToStr(CurrentDay,TIME_DATE|TIME_SECONDS),"; i = ",i,"; Bars: ",Bars,"; Fractal = ",Fractal, "; CurrentResistance: ",CurrentResistance, "; CountHighs: ", CountHighs);
    //----
    if(fractal > 0 && High[index]>period_high) 
        {
        resistance = High[index];
        }
    count_bars--;
   }

//===============================================================================================================
// Find the HIGHEST appropriate support  (the NEXT support to be tested):
count_bars=total_bars;    
while(count_bars >0&&support==0)
  {  
    index =   total_bars - count_bars+1;  // Start at 1!
//  The following starts iterating BACKWARDS from the before most recent bar:    
    fractal = iFractals(NULL, 0, MODE_LOWER, index);
    
    if(fractal > 0 && Low[index]<period_low) 
        {
        support = Low[index];
        //Print(" TimeLocal: ",TimeToStr(TimeLocal(),TIME_DATE|TIME_SECONDS), "; fractal: ", fractal, "; support: ", support, "; index: ",index);
        }
    count_bars--;
   }

 // ======================================================================================
 // Calculate here the number of completed trades for the CURRENT day and CURRENT sumbol.  Starting at the most recent trade it goes back until OrderCloseTime()<CurrentDay.
int nDayTrades;
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
          order_type=OrderType(); // order_type = 0, bought;  order_type = 1, sold; 
//          order_stoploss =OrderStopLoss();
        
          if(order_type==0)
          {
          nBuyTrades++;
          }
          if(order_type==1)
          {
          nSellTrades++;
          }
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
// Calculate the number of open trades for the current Symbol, this produces symbol_total which is not allowed to be > 1
int  symbol_total=0;//,total;
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

// ========================================================================================
bool       valid_buy_trigger=false;
bool       valid_sell_trigger=false;

//  Calculate the valid triggers:
//  For a SELL ask must be above resistance.
//  We must be in the trade window.
//  The previous bar must have CLOSED BELOW the resistance.
//  Resistance is > 0.
//  There are no OPEN positions.
//  We are inside our trade allowance for the day
valid_sell_trigger=Ask>resistance && in_trade_window && previous_close<resistance && resistance>0 && symbol_total<1 && InTradeAllowance && Ask > period_high;
//  For a BUY, bid must be BELOW support..
//  We must be in the trade window.
//  The previous bar must have CLOSED ABOVE  the support.
//  Support is > 0.
//  There are no OPEN positions.
//  We are inside our trade allowance for the day
valid_buy_trigger=Bid<support && in_trade_window && previous_close>support && support>0 && symbol_total<1 && InTradeAllowance && Bid < period_low;
Print(" TimeLocal: ",TimeToStr(TimeLocal(),TIME_DATE|TIME_SECONDS),"; Bid: ", Bid,  ";Ask: ", Ask, "; period_high: ",period_high,"; period_low: ", period_low,"; previous_close: ",previous_close, "; support: ", support, "; resistance: ", resistance, "; symbol_total, ", symbol_total);
 
if(valid_sell_trigger)
{
Print(" TimeLocal: ",TimeToStr(TimeLocal(),TIME_DATE|TIME_SECONDS), "; SELL =================================================");
Print(" TimeLocal: ",TimeToStr(TimeLocal(),TIME_DATE|TIME_SECONDS), ";Ask: ", Ask, "; period_high: ",period_high," ; previous_close: ",previous_close, "; resistance: ", resistance, "; symbol_total, ", symbol_total);
Print(" TimeLocal: ",TimeToStr(TimeLocal(),TIME_DATE|TIME_SECONDS), ";Sell at: ", Bid);

}

if(valid_buy_trigger)
{
Print(" TimeLocal: ",TimeToStr(TimeLocal(),TIME_DATE|TIME_SECONDS), "; BUY =================================================");
Print(" TimeLocal: ",TimeToStr(TimeLocal(),TIME_DATE|TIME_SECONDS), ";Bid : ", Bid, "; period_low: ", period_low,"; previous_close: ",previous_close, "; support: ", support, "; symbol_total, ", symbol_total);
Print(" TimeLocal: ",TimeToStr(TimeLocal(),TIME_DATE|TIME_SECONDS), ";Buy at: ", Ask);
}


// =========================================================================================
// The code below is the EXECUTION engine:
//  It asks first if there is an opoen trade in the current symbol.  If yes do NOTHING.
//  Are we inside our predefined macimum number of trades (CLOSED positions) for the day.  If yes proceed.
   int          cnt,ticket;
   double    current_buy_stoploss=Bid-StopLoss*Point;
   double    current_buy_takeprofit =Ask+TakeProfit*Point;
   double    current_sell_stoploss=Ask+StopLoss*Point;
   double    current_sell_takeprofit =Bid-TakeProfit*Point;
   int          total=0;//,total;
         
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



}