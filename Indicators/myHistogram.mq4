//+------------------------------------------------------------------+
//|                                                  myHistogram.mq4 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#property indicator_chart_window
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
input int               period_MA1=20;       // Averaging period of iMA1 
input int               period_MA2=14;       // Averaging period of iMA2 
//---- indicator buffers
double      MA1[];
double      MA2[];
//---- handles for indicators
int         iMA1_handle;
int         iMA2_handle;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   ObjectsDeleteAll(0,-1,-1);
   ChartRedraw();
   iMA1_handle=iMA(_Symbol,_Period,period_MA1,0,MODE_SMA,PRICE_CLOSE);
   iMA2_handle=iMA(_Symbol,_Period,period_MA2,0,MODE_SMA,PRICE_CLOSE);
   ArraySetAsSeries(MA1,true);
   ArraySetAsSeries(MA2,true);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   ArraySetAsSeries(time,true);
   
   CopyBuffer(iMA1_handle,0,0,1,MA1);
   CopyBuffer(iMA2_handle,0,0,1,MA2);

   DrawHistogram(true,"iMA("+(string)period_MA1+")=",MA1[0],time[0],_Digits);
   DrawHistogram(false,"iMA("+(string)period_MA2+")=",MA2[0],time[0],_Digits);

//--- Shift the diagrams to a new bar
   if(time[0]>prevTimeBar) // define a new bar arrival
     {
      prevTimeBar=time[0];
      // pass through all graphical objects
      for(int obj=ObjectsTotal(0,-1,-1)-1;obj>=0;obj--)
        {
         string obj_name=ObjectName(0,obj,-1,-1);               // get a name of a found object
         if(obj_name[0]==R)                                     // search for the histogram element prefix
           {                                                    // if the histogram element is found
            ObjectSetInteger(0,obj_name,OBJPROP_TIME,           // set a new coordinate value
                             0,time[0]);                        // for "0" anchor point
            string str=ObjectGetString(0,obj_name,OBJPROP_TEXT);// read the variable from the object property
            string strint=StringSubstr(str,1);                  // separate a substring from the received variable
            long n=StringToInteger(strint);                     // convert the string into a long variable
            ObjectSetInteger(0,obj_name,OBJPROP_TIME,           // calculate the new coordinate value
                             1,time[0]+hsize*n);                // for "1" anchor point
            ObjectSetInteger(0,obj_name,OBJPROP_COLOR,
                             color_R_passive);                  // change the color of the shifted histogram element
           }
         if(obj_name[0]==L)
           {
            ObjectSetInteger(0,obj_name,OBJPROP_TIME,0,time[0]);
            string str=ObjectGetString(0,obj_name,OBJPROP_TEXT);
            string strint=StringSubstr(str,1);
            long n=StringToInteger(strint);
            ObjectSetInteger(0,obj_name,OBJPROP_TIME,1,time[0]-hsize*n);
            ObjectSetInteger(0,obj_name,OBJPROP_COLOR,color_L_passive);
           }
        }
      ChartRedraw();
     }
   return(rates_total);
  }