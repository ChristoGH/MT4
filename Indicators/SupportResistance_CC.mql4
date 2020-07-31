//+------------------------------------------------------------------+
//|                            Support and Resistance Custom Caller  |
//|                               Copyright � 2004  Christo Strydom  |
//|                                     christo.w.strydom@gmail.com  |
//|                                                       13/7/2020  |
//+------------------------------------------------------------------+
#property copyright "Click here: Barry Stander"
#property link      "http://myweb.absa.co.za/stander/4meta/"

#property indicator_chart_window
#property indicator_buffers 2
#property indicator_color1 DeepSkyBlue
#property indicator_color2 DeepSkyBlue
//---- buffers
double ExternalMapBuffer1[];
double ExternalMapBuffer2[];
double val1;
double val2;
int i;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+  
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+  
int init()
  {
//---- drawing settings
   SetIndexArrow(0, 119);
   SetIndexArrow(1, 119);
//----  
   SetIndexStyle(0, DRAW_LINE);
   SetIndexDrawBegin(0, i-1);
   SetIndexBuffer(0, ExternalMapBuffer1);
   SetIndexLabel(0,"Resistance");
//----    
   SetIndexStyle(1,DRAW_LINE);
   SetIndexDrawBegin(1,i-1);
   SetIndexBuffer(1, ExternalMapBuffer2);
   SetIndexLabel(1,"Support");
//---- 
   return(0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int start()
  { 
   i = Bars;
   while(i >= 0)
     {
       val1 =iFractals(NULL, 0, MODE_UPPER, i);
       //----
       if(val1 > 0) 
           ExternalMapBuffer1[i] = High[i];
       else
           ExternalMapBuffer1[i] = ExternalMapBuffer1[i+1];
       val2 = iFractals(NULL, 0, MODE_LOWER, i);
       //----
       if(val2 > 0) 
           ExternalMapBuffer2[i] = Low[i];
       else
           ExternalMapBuffer2[i] = ExternalMapBuffer2[i+1];
       i--;
     }   
   return(0);
  }
//+------------------------------------------------------------------+