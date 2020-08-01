//+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
//|                                                                                                                                         Support_Resistance_EA.mq4 |
//|                                                                                                                             Copyright 20200716,Christo Strydom. |
//|                                                                                                                                      christo.w.strydom@gmail.com  |
//| This expert advisor no longer  calls the custom indicator "Support and Resistance (Barry)", but uses the same methodology |
//+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
#property copyright   "Christo Strydom"
#property link        "christo.w.strydom@gmail.com"

input int StartHour        =8; // Start strategy AFTER this hour
input int StartMinute      =0;
input int EndHour          =14; // Start strategy AFTER this hour
input int EndMinute        =0;
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
   int          iHi=iHighest(Symbol(),PERIOD_M1,MODE_HIGH,start_shift,1);
   int          iLo=iLowest(Symbol(),PERIOD_M1,MODE_LOW,start_shift,1);
   int          index=0;
   double    period_high, period_low;
   bool       in_trade_window=false;
   bool       after_trade_window=false;
   
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
Print("start_time: ",TimeToStr(start_time,TIME_DATE|TIME_SECONDS),"; end_time: ", TimeToStr(end_time,TIME_DATE|TIME_SECONDS), "; TimeLocal: ",TimeToStr(TimeLocal(),TIME_DATE|TIME_SECONDS) );
Print(" TimeLocal: ",TimeToStr(TimeLocal(),TIME_DATE|TIME_SECONDS), "; iHi: ",iHi, "; iLo: ",iLo,"; start_shift: ",start_shift, "; in_trade_window: ", in_trade_window, "; period_high: ", period_high, "; period_low: ",period_low);
}


// ====================================================================================================
// Find the LOWEST appropriate the resistance:

int       total_bars =iBars(Symbol(),0);
int       count_bars=total_bars;
double resistance==0;
double support==0;

while(count_bars >0&&resistance==0)
  {  
    index =   total_bars - count_bars+1;  // Start at 1!
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

count_bars=0;    


// Finde the HIGHEST appropriate support:
while(count_bars >0&&support==0)
  {  
    index =   total_bars - count_bars+1;  // Start at 1!
    fractal = iFractals(NULL, 0, MODE_LOWER, index);
    //Print(
    //Print("CurrentDay: ",TimeToStr(CurrentDay,TIME_DATE|TIME_SECONDS),"; i = ",i,"; Bars: ",Bars,"; Fractal = ",Fractal, "; CurrentResistance: ",CurrentResistance, "; CountHighs: ", CountHighs);
    //----
    if(fractal > 0 && Low[index]<period_low) 
        {
        support = Low[index];
        }
    count_bars--;
   }

Print(" TimeLocal: ",TimeToStr(TimeLocal(),TIME_DATE|TIME_SECONDS), "; in_trade_window: ", in_trade_window, "; period_high: ", period_high, "; period_low: ",period_low, "; support: ", support, "; resistance: ", resistance);