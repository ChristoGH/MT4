//+------------------------------------------------------------------+
//|                                 Previous Support and Resistance  |
//|                               Copyright � 2004  Christo Strydom  |
//|                          christo.w.strydom@gmail.com  |
//+------------------------------------------------------------------+
#property copyright "Click here: Barry Stander"
#property link      "http://myweb.absa.co.za/stander/4meta/"

#property indicator_chart_window
#property indicator_buffers 2
#property indicator_color1 Red
#property indicator_color2 Blue
//---- buffers
double current_resistance;
double current_support;
double previous_resistance;
double previous_support;
int i, max_bars;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+  
int init()
  {
//---- initial values
   current_resistance=iCustom(NULL,0,"Support and Resistance (Barry)",0,0);
   current_support=iCustom(NULL,0,"Support and Resistance (Barry)",1,0);
//---- 
   return(0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int start()
  { 
   i = 0;
   max_bars = Bars;
   previous_resistance=iCustom(NULL,0,"Support and Resistance (Barry)",0,i);
   previous_support=iCustom(NULL,0,"Support and Resistance (Barry)",1,i);   
   while(i <max_bars||previous_resistance!=current_resistance)
     {
         previous_resistance=iCustom(NULL,0,"Support and Resistance (Barry)",0,i);
         i++;
     }
   i = 0;
   previous_resistance=iCustom(NULL,0,"Support and Resistance (Barry)",0,i);
   previous_support=iCustom(NULL,0,"Support and Resistance (Barry)",1,i);        
   while(i <max_bars||previous_support!=current_support)
     {
         previous_support=iCustom(NULL,0,"Support and Resistance (Barry)",1,i);
         i++;
     }          
   return(0);
  }
//+------------------------------------------------------------------+