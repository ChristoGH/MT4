//+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
//|                                                                                                                                         Support_Resistance_EA.mq4 |
//|                                                                                                                             Copyright 20200716,Christo Strydom. |
//|                                                                                                                                      christo.w.strydom@gmail.com  |
//| This expert advisor no longer  calls the custom indicator "Support and Resistance (Barry)", but uses the same methodology |
//+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
// #include <WinUser32.mqh>//---

//#include "SnR_EA.mqh"
#property copyright   "Christo Strydom"
#property link        "christo.w.strydom@gmail.com"
#include "SnR_EA.mqh"

input double Lots          =0.1; // Trade size
input double TrailingStop  =0; // 0 for NO trailing stop
input int Slippage      =3;
input double TakeProfit    =2000; // 2000 for USDZAR
input double StopLoss      =3000; // Hard stop, 3000 for USDZAR, The stop loss is not MANAGED
input int StartHour        =9; // Start strategy AFTER this hour
input int StartMinute      =0;
input int EndHour          =14; // Start strategy AFTER this hour
input int EndMinute        =0;
input int MaxNumberDayTrades = 1;
input int SnR_HoursLookBack = 24;
// = values for HLineCreate from https://docs.mql4.com/constants/objectconstants/enum_object/obj_hline 
input string          InpName="HLine";     // Line name
input int             InpPrice=25;         // Line price, %

datetime             EveryLastActiontime;
datetime             TradeWindowLastActiontime;
extern int EAMagic = 16384; //EA's magic number parameter
string      sell_comment="SnREA_Resistance";
string      buy_comment="SnRBalanceEA_Support";   

// Input values for line drawing:
input string          MidNightName="MidNight";     // Line name
input string          TradingDayStart="TradingDayStart";     // Line name
input color           TradingDayStartColor=clrSteelBlue;     // Line color
input string          TradingDayEnd="TradingDayEnd";     // Line name
input color           TradingDayEndColor=clrSienna;     // Line color
input int               InpDate=25;          // Event date, %
input color           InpColor=clrRed;     // Line color
input color           SnRColor=clrYellow; //
//input ENUM_LINE_STYLE InpStyle=STYLE_DASH; // Line style
//input ENUM_LINE_STYLE SnRStyle=STYLE_DOT; // Line style
//input int             InpWidth=1;          // Line width
//input bool            InpBack=false;       // Background line
//input bool            InpSelection=true;   // Highlight to move
//input bool            InpHidden=true;      // Hidden in the object list
//input long            InpZOrder=0;         // Priority for mouse click
//input int              SnRwidth=1;           // line width 
//input bool            SnRback=false;        // in the background 
//input bool            SnRselection=true;    // highlight to move 
//input bool            SnRray_left=false;    // line's continuation to the left 
//input bool            SnRray_right=false;   // line's continuation to the right 
//put bool            SnRhidden=true;       // hidden in the object list 
//input long            SnRz_order=0;

string                  StrategyName="SnR_EA";
// =https://www.mql5.com/en/forum/300801=================================================================================================================================

// = This function was lifted from https://docs.mql4.com/constants/objectconstants/enum_object/obj_hline ============================================================
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
   datetime current_day_time =iTime(Symbol(),PERIOD_D1,0);  // The start time 00:00:00 of the CURRENT day
   datetime start_time=current_day_time+(60*60*StartHour)+(60*StartMinute);
   datetime end_time=current_day_time+(60*60*EndHour)+(60*EndMinute);
   datetime localTime=TimeLocal();
   int          start_shift=iBarShift(Symbol(),PERIOD_M1,start_time-60);  // 
   int          day_shift=iBarShift(Symbol(),PERIOD_M1,current_day_time);  // Number of 'shifts' of the current bar type to the start of the day
   int          in_trade_shift_hi=iHighest(Symbol(),PERIOD_M1,MODE_HIGH,start_shift,1); // Number of shifts  from current bar to HIGHEST bar in trade window
   int          in_trade_shift_lo=iLowest(Symbol(),PERIOD_M1,MODE_LOW,start_shift,1); // Number of shifts  from current bar to LOWEST bar in trade window
   int          premarket_shift_hi=iHighest(Symbol(),PERIOD_M1,MODE_HIGH,day_shift,1); // Number of shifts from current bar to HIGHEST bar in pre market window
   int          premarket_shift_lo=iLowest(Symbol(),PERIOD_M1,MODE_LOW,day_shift,1); //  Number of shifts from current bar to LOWEST bar in pre market window 
   int          index=0;
   int          trade;
   int          order_type; // Used to determine the order type of the previous trade.
   int          nBuyTrades=0;
   int          nSellTrades=0;
   double    period_high=0;
   double    period_low=0;
   double    previous_close= iClose(Symbol(),PERIOD_M1,1);
   double    previous_high= iHigh(Symbol(),PERIOD_M1,1);
   double    previous_low= iLow(Symbol(),PERIOD_M1,1);         
   bool       in_trade_window=false;
//   bool       after_trade_window=false;
   bool       InTradeAllowance=true;  // InTradeAllowance is set to true.  It will only be set false once nDayTrades>=MaxNumberDayTrades
   int          cnt;
   int          ticket=0;
   int          total=0;//,total;
   int          resistance_index=0;
   double    support=0;
   double   minimum_resistance=0;
   double   resistance=0;
   int         minimum_resistance_index=0;
   
  //===================================================================================================
  //  Define in_trade_window, a boolean operator which is true only if we are inside the hours defined by StartHour and EndHour
  //  To do: convert all to seconds, so that comparison will include StartMinute
//Print("Current bar for Symbol() H1: ",iTime(Symbol(),PERIOD_M1,start_shift), "; TimeToStr(start_time,TIME_DATE|TIME_SECONDS): ",TimeToStr(start_time,TIME_DATE|TIME_SECONDS), "; start_shift: ", start_shift, "; ",  iOpen(Symbol(),PERIOD_M1,start_shift),", ",
//                                      iHigh(Symbol(),PERIOD_M1,start_shift),", ",  iLow(Symbol(),PERIOD_M1,start_shift),", ",
//                                      iClose(Symbol(),PERIOD_M1,start_shift),", ", iVolume(Symbol(),PERIOD_M1,start_shift),
//                                      "; period_high: ",iHigh(Symbol(),PERIOD_M1,iHi),
//                                       "; period_low: ",iLow(Symbol(),PERIOD_M1,iLo));

//int result =trade_window(start_time,end_time);


   
   if(EveryLastActiontime!=Time[0]){
      //Code to execute once in the bar
      // Print("This code is executed only once in the bar started ",Time[0], TimeToStr(LastActiontime,TIME_DATE|TIME_SECONDS));
      EveryLastActiontime=Time[0];
      VLineDelete(0,MidNightName);
      VLineDelete(0,TradingDayStart);
      VLineDelete(0,TradingDayEnd);
      if(!VLineCreate(0,MidNightName,0,current_day_time,InpColor,InpStyle,InpWidth,InpBack,InpSelection,InpHidden,InpZOrder))
      {
      return;
      }
      if(!VLineCreate(0,TradingDayStart,0,start_time,TradingDayStartColor,InpStyle,InpWidth,InpBack,InpSelection,InpHidden,InpZOrder))
      {
      return;
      }
      if(!VLineCreate(0,TradingDayEnd,0,end_time,TradingDayEndColor,InpStyle,InpWidth,InpBack,InpSelection,InpHidden,InpZOrder))
      {
      return;
      }
      //ChartRedraw();
     // VLineDelete(0,MidNightName);
     // ChartRedraw();      
      Print("This code is executed only once in the bar started ",Time[0], TimeToStr(EveryLastActiontime,TIME_DATE|TIME_SECONDS));      
   }   

    
   if(trade_window_fn(start_time, end_time))
   {
   
      // =========================================================================================================================================
      // The following is run only inside the trade window and ONLY when a new bar was created.
      if(TradeWindowLastActiontime!=Time[0]) // && YOUR_CONDITION)
      {
         //Code to execute once in the bar
         Print("This code is executed only once in the bar started ",Time[0]);
         
         int       total_bars =iBars(Symbol(),0);
         int       count_bars=total_bars;
         //double resistance=0;

         double fractal;
         datetime current_time= iTime(Symbol(),PERIOD_M1,0);
         datetime time_diff=0;

         
         while(count_bars >0&&minimum_resistance==0&&time_diff<SnR_HoursLookBack)
           {  
             index =   total_bars - count_bars+0;  // Start at 1!
             time_diff=(current_time-iTime(Symbol(),0,index))/(60*60);
         
         //  The following starts iterating BACKWARDS from the before most recent bar:
             fractal = iFractals(NULL, 0, MODE_UPPER, index);
             //Print(
             if(fractal>0)
             {
                 //Print(" index = ",index,"; count_bars: ",count_bars,"; Fractal = ",fractal, "; TimeToStr(iTime(Symbol(),0,index): ",TimeToStr(iTime(Symbol(),0,index),TIME_DATE|TIME_SECONDS));        
             }
             //----
             if((fractal > 0) && (High[index]>previous_high)) //period_high) 
                 {
         
                 if(minimum_resistance==0)
                 {
                 minimum_resistance = High[index];
                 minimum_resistance_index=index;
                 }
                 else
                 {
                 minimum_resistance = MathMin(High[index],minimum_resistance);
                 if (minimum_resistance==High[index])
                 {
                 minimum_resistance_index=index;
                 }
                 //minimum_resistance_index=index;
                 }
         //         Print(" period_high: ",period_high," time_diff: ",time_diff, "; minimum_resistance_index: ",minimum_resistance_index,   "; minimum_resistance: ",minimum_resistance,"; time of resistance: ", TimeToStr(iTime(Symbol(),0,minimum_resistance_index),TIME_DATE|TIME_SECONDS));                
                 }
         
             count_bars--;
            }
         resistance=minimum_resistance;
         resistance_index=minimum_resistance_index;
         //===============================================================================================================
         // Find the HIGHEST appropriate support and its index  (the NEXT support to be tested):
         count_bars=total_bars;    
         double maximum_support=0;
         int maximum_support_index=0;
         int support_index=0;
         time_diff=0;
         while(count_bars >0&&maximum_support==0&&time_diff<SnR_HoursLookBack)
           {  
             index =   total_bars - count_bars+0;  // Start at 1!
             time_diff=(current_time-iTime(Symbol(),0,index))/(60*60);
         //  The following starts iterating BACKWARDS from the before most recent bar:    
             fractal = iFractals(NULL, 0, MODE_LOWER, index);
             
             if((fractal > 0) && (Low[index]<previous_low)) //period_low) 
                 {
                 if(maximum_support==0)
                 {
                 maximum_support=Low[index];
                 maximum_support_index=index;
                 }
                 else
                 {
                 maximum_support=MathMax(Low[index],maximum_support);
                 //maximum_support_index=index;
                 if (maximum_support==Low[index])
                 {
                 maximum_support_index=index;
                 }        
                 }
                 //support = Low[index];
                 //Print(" TimeLocal: ",TimeToStr(TimeLocal(),TIME_DATE|TIME_SECONDS), "; fractal: ", fractal, "; support: ", support, "; index: ",index);
                 }
             count_bars--;
            }
         support=maximum_support;
         support_index=maximum_support_index;
         
         TradeWindowLastActiontime=Time[0];
      }
      
   
      if((in_trade_shift_hi!=-1)) 
      {
      period_high=iHigh(Symbol(),PERIOD_M1,in_trade_shift_hi);
      } 
      

      if((in_trade_shift_lo!=-1))
      {
      period_low=iLow(Symbol(),PERIOD_M1,in_trade_shift_lo);
      } 
      
      // Print("TimeLocal: ",TimeToStr(TimeLocal(),TIME_DATE|TIME_SECONDS), "; current_day_time: ",TimeToStr(current_day_time,TIME_DATE|TIME_SECONDS),"; start_time: ",TimeToStr(start_time,TIME_DATE|TIME_SECONDS),"; end_time: ", "; end_time: ",TimeToStr(end_time,TIME_DATE|TIME_SECONDS),"; period_high: ", period_high, "; : ",period_low);
      // Print(" TimeLocal: ",TimeToStr(TimeLocal(),TIME_DATE|TIME_SECONDS), "; iHi: ",iHi, "; iLo: ",iLo,"; start_shift: ",start_shift, "; in_trade_window: ", in_trade_window, "; period_high: ", period_high, "; period_low: ",period_low);
      
      
      
      // ====================================================================================================
      // In the below setup: 
      // 1) we won't trade  the same support or resistance twice and
      // 2) we trade only higher resistances and lower supports.
      
      // Find the LOWEST appropriate  resistance and its index::
      if((Ask>resistance && previous_high<resistance && resistance>0)||(Bid<support && previous_low>support && support>0))
      {
         
         
         // Print(" TimeLocal: ",TimeToStr(TimeLocal(),TIME_DATE|TIME_SECONDS), "; time of resistance: ", TimeToStr(iTime(Symbol(),0,minimum_resistance_index),TIME_DATE|TIME_SECONDS), "; time of support: ", TimeToStr(iTime(Symbol(),0,maximum_support_index),TIME_DATE|TIME_SECONDS), "; minimum_resistance_index: ",minimum_resistance_index,"; maximum_support_index: ", maximum_support_index);
         // ======================================================================================
         
         //resistance=iCustom(NULL,0,"Support and Resistance (Barry)",0,0);
         //support=iCustom(NULL,0,"Support and Resistance (Barry)",1,0);
         //if(!HLineCreate(0,InpName,0,support,InpColor,InpStyle,InpWidth,InpBack,
         //      InpSelection,InpHidden,InpZOrder))
         //     {
         //      return;
         //     }
         
         
         // Print(" time_diff: ",time_diff, "; maximum_support_index: ",support_index,   "; support: ",support,"; time of support: ", TimeToStr(iTime(Symbol(),0,maximum_support_index),TIME_DATE|TIME_SECONDS));
         // Print(" time_diff: ",time_diff, "; minimum_resistance_index: ",resistance_index,   "; resistance: ",resistance,"; time of resistance: ", TimeToStr(iTime(Symbol(),0,minimum_resistance_index),TIME_DATE|TIME_SECONDS));
         
          // ======================================================================================
          // Calculate here the number of completed trades for the CURRENT day and CURRENT sumbol.  Starting at the most recent trade it goes back until OrderCloseTime()<CurrentDay.
         int nDayTrades;
         nDayTrades=0;
          for(trade=OrdersHistoryTotal()-1;trade>=0;trade--)
             {
              //Print("Trade number: ", trade);
              if(OrderSelect(trade,SELECT_BY_POS,MODE_HISTORY)==true)
              
                {
                  if(OrderMagicNumber()==EAMagic)
                  {
                  //EA_OrderOpenTime=OrderOpenTime();
                  //EA_OrderCloseTime=OrderCloseTime();
                  if((OrderCloseTime()>=current_day_time)&&(OrderSymbol()==Symbol()))
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
              if((OrderCloseTime()<current_day_time)||(!InTradeAllowance))
              {
               break;
              }
         //     if(MaxNumberDayTrades<=nDayTrades){
         //     break;
         //    }
             }
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
           if(OrderMagicNumber()==EAMagic)
           {
            if(OrderSymbol()==Symbol())
            {
              if((OrderType()==OP_SELL||OrderType()==OP_BUY) && OrderMagicNumber()==EAMagic)
              symbol_total++;
            }
         }
         }
         if (symbol_total<1 && InTradeAllowance)
         {
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
            valid_sell_trigger=Ask>resistance && in_trade_window && previous_high<resistance && resistance>0 && symbol_total<1 && InTradeAllowance && Ask > period_high;
            valid_sell_trigger=Ask>resistance && in_trade_window && previous_high<resistance && resistance>0 && symbol_total<1 && InTradeAllowance;
            //  For a BUY, bid must be BELOW support..
            //  We must be in the trade window.
            //  The previous bar must have CLOSED ABOVE  the support.
            //  Support is > 0.
            //  There are no OPEN positions.
            //  We are inside our trade allowance for the day
            valid_buy_trigger=Bid<support && in_trade_window && previous_low>support && support>0 && symbol_total<1 && InTradeAllowance && Bid < period_low;
            valid_buy_trigger=Bid<support && in_trade_window && previous_low>support && support>0 && symbol_total<1 && InTradeAllowance;
            
            //if((TimeLocal()-MathMod(TimeLocal(),60))<3)
            //{
            //Print("; TimeLocal: ",TimeToStr(TimeLocal(),TIME_DATE|TIME_SECONDS),"; MathMod(TimeLocal(),60): ",TimeToStr(MathMod(TimeLocal(),60),TIME_DATE|TIME_SECONDS), "; period_high: ",period_high,"; period_low: ", period_low,"; previous_close: ",previous_close, "; support: ", support, "; resistance: ", resistance);
            //}
            
            //Print(" TimeLocal: ",TimeToStr(TimeLocal(),TIME_DATE|TIME_SECONDS),  "; period_high: ",period_high," ; previous_close: ",previous_close, "; resistance: ", resistance, "; symbol_total, ", symbol_total);
            
            //if(valid_sell_trigger)
            //{
            //Print(" TimeLocal: ",TimeToStr(TimeLocal(),TIME_DATE|TIME_SECONDS), "; SELL =================================================");
            //Print(" TimeLocal: ",TimeToStr(TimeLocal(),TIME_DATE|TIME_SECONDS), ";Bid : ", Bid,  ";Bid : ", Ask, "; Time of High: ",iTime(Symbol(),PERIOD_M1,in_trade_shift_hi), "; Time of Low: ",iTime(Symbol(),PERIOD_M1,in_trade_shift_lo) , "; previous_close: ",previous_close, "; period_high: ",period_high, "; period_low: ", period_low, "; support: ", support, "; resistance: ", resistance);
            //Print(" TimeLocal: ",TimeToStr(TimeLocal(),TIME_DATE|TIME_SECONDS), ";Sell at: ", Bid);
            
            //}
            
            //if(valid_buy_trigger)
            //{
            //Print(" TimeLocal: ",TimeToStr(TimeLocal(),TIME_DATE|TIME_SECONDS), "; BUY =================================================");
            //Print(" TimeLocal: ",TimeToStr(TimeLocal(),TIME_DATE|TIME_SECONDS), ";Bid : ", Bid, "; period_low: ", period_low,"; previous_close: ",previous_close, "; support: ", support, "; symbol_total, ", symbol_total);
            //Print(" TimeLocal: ",TimeToStr(TimeLocal(),TIME_DATE|TIME_SECONDS), ";Buy at: ", Ask);
            //}
            
            //Print(" TimeLocal: ",TimeToStr(TimeLocal(),TIME_DATE|TIME_SECONDS), ";Bid : ", Bid,  ";Ask : ", Ask, "; Time of High: ",TimeToStr(iTime(Symbol(),PERIOD_M1,in_trade_shift_hi),TIME_DATE|TIME_SECONDS), "; Time of Low: ",TimeToStr(iTime(Symbol(),PERIOD_M1,in_trade_shift_lo),TIME_DATE|TIME_SECONDS), "; previous_close: ",previous_close, "; period_high: ",period_high, "; period_low: ", period_low, "; support: ", support, "; resistance: ", resistance);
            
            // =========================================================================================
            // The code below is the EXECUTION engine:
            //  It asks first if there is an opoen trade in the current symbol.  If yes do NOTHING.
            //  Are we inside our predefined macimum number of trades (CLOSED positions) for the day.  If yes proceed.
               //int          cnt,ticket;
               double    current_buy_stoploss=Ask-StopLoss*Point;
               double    current_buy_takeprofit =Ask+TakeProfit*Point;
               double    current_sell_stoploss=Bid+StopLoss*Point;
               double    current_sell_takeprofit =Bid-TakeProfit*Point;
               total=0;//,total;
            
             //  Print("Symbol: ",Symbol(),"; Bid: ",Bid, "; Ask: ", Ask, "; Slippage: ",Slippage,"; current_sell_stoploss: ", current_sell_stoploss,"; current_sell_takeprofit: ",current_sell_takeprofit, "; current_buy_stoploss: ", current_buy_stoploss,"; current_buy_takeprofit: ",current_buy_takeprofit);
               //Print(" TimeLocal: ",TimeToStr(TimeLocal(),TIME_DATE|TIME_SECONDS), ";Bid : ", Bid,  ";Ask : ", Ask, "; Time of High: ",TimeToStr(iTime(Symbol(),PERIOD_M1,in_trade_shift_hi),TIME_DATE|TIME_SECONDS), "; Time of Low: ",TimeToStr(iTime(Symbol(),PERIOD_M1,in_trade_shift_lo),TIME_DATE|TIME_SECONDS), "; previous_close: ",previous_close, "; period_high: ",period_high, "; period_low: ", period_low, "; support: ", support, "; resistance: ", resistance);
            
                     
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
                    Print("SELL!");
                    // int OrderSend (string symbol, int cmd, double volume, double price, int slippage, double stoploss,double takeprofit, string comment=NULL, int magic=0, datetime expiration=0, color arrow_color=CLR_NONE)
                     Print("Symbol: ",Symbol(),"; OPSELL: ",OP_SELL,"; Lots: ", Lots,"; Bid: ",Bid,"; Slippage: ",Slippage,"; current_sell_stoploss: ", current_sell_stoploss,"; take current_sell_takeprofit: ",current_sell_takeprofit,StrategyName,EAMagic,0);
                     Print(" TimeLocal: ",TimeToStr(TimeLocal(),TIME_DATE|TIME_SECONDS), ";Bid : ", Bid,  ";Ask : ", Ask, "; Time of High: ",TimeToStr(iTime(Symbol(),PERIOD_M1,in_trade_shift_hi),TIME_DATE|TIME_SECONDS), "; Time of Low: ",TimeToStr(iTime(Symbol(),PERIOD_M1,in_trade_shift_lo),TIME_DATE|TIME_SECONDS));         
                     Print(" TimeLocal: ",TimeToStr(TimeLocal(),TIME_DATE|TIME_SECONDS),  "; previous_close: ",previous_close, "; period_high: ",period_high, "; period_low: ", period_low, "; support: ", support, "; resistance: ", resistance);         
                     
                     ticket=OrderSend(Symbol(),OP_SELL,Lots,Bid,Slippage,current_sell_stoploss,current_sell_takeprofit,sell_comment,EAMagic,0,Red);
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
                    Print("Symbol: ",Symbol(),"; OPSELL: ",OP_BUY,"; Lots: ", Lots,"; Ask: ",Ask,"; Slippage: ",Slippage,"; stop loss: ", Bid+TakeProfit*Point,"; take profit: ",Bid-TakeProfit*Point,StrategyName,EAMagic,0);
                     Print(" TimeLocal: ",TimeToStr(TimeLocal(),TIME_DATE|TIME_SECONDS), ";Bid : ", Bid,  ";Ask : ", Ask, "; Time of High: ",TimeToStr(iTime(Symbol(),PERIOD_M1,in_trade_shift_hi),TIME_DATE|TIME_SECONDS), "; Time of Low: ",TimeToStr(iTime(Symbol(),PERIOD_M1,in_trade_shift_lo),TIME_DATE|TIME_SECONDS));         
                     Print(" TimeLocal: ",TimeToStr(TimeLocal(),TIME_DATE|TIME_SECONDS),  "; previous_close: ",previous_close, "; period_high: ",period_high, "; period_low: ", period_low, "; support: ", support, "; resistance: ", resistance);         
                     
                    ticket=OrderSend(Symbol(),OP_BUY,Lots,Ask,Slippage,current_buy_stoploss,current_buy_takeprofit,buy_comment,EAMagic,0,Green);
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
               } //symbol_total<1 && InTradeAllowance
            } // Ask>resistance||Bid<support
         } //in_trade_window
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
                 if (!trade_window_fn(start_time, end_time)){              
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
               if (!trade_window_fn(start_time, end_time)){
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
