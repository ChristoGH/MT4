//+------------------------------------------------------------------+
//|                                                       SnR_EA.mqh |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict
color           IBMidNightColor=clrMaroon; //
color           IBHighColor=clrGreenYellow;
color           IBLowColor=clrGreenYellow;
color            IBColor=clrGreenYellow;
string          IBMidNightName="MidNight";     // Line name
string          IBTradingDayStart="TradingDayStart";     // Line name
color           IBTradingDayStartColor=clrSteelBlue;     // Line color
string          IBTradingDayEnd="TradingDayEnd";     // Line name
color           IBTradingDayEndColor=clrSienna;     // Line color
int               IBInpDate=25;          // Event date, %
color           IBInpColor=clrRed;     // Line color
string         IinitialBalance_Start="IinitialBalance Start";
string         IinitialBalance_End="IinitialBalance End";

ENUM_LINE_STYLE InpStyle=STYLE_DASH; // Line style
ENUM_LINE_STYLE SnRStyle=STYLE_DOT; // Line style
ENUM_LINE_STYLE IBSnRStule=STYLE_SOLID;
int             InpWidth=1;          // Line width
bool            InpBack=false;       // Background line
bool            InpSelection=true;   // Highlight to move
bool            InpHidden=true;      // Hidden in the object list
long            InpZOrder=0;         // Priority for mouse click
int              SnRwidth=1;           // line width 
int              IBSnRwidth=1;           // line width 
bool            SnRback=false;        // in the background 
bool            SnRselection=true;    // highlight to move 
bool            SnRray_left=false;    // line's continuation to the left 
bool            SnRray_right=false;   // line's continuation to the right 
bool            SnRhidden=true;       // hidden in the object list 
long            SnRz_order=0;

//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
// #define MacrosHello   "Hello, world!"
// #define MacrosYear    2010
//+------------------------------------------------------------------+
//| DLL imports                                                      |
//+------------------------------------------------------------------+
// #import "user32.dll"
//   int      SendMessageA(int hWnd,int Msg,int wParam,int lParam);
// #import "my_expert.dll"
//   int      ExpertRecalculate(int wParam,int lParam);
// #import
//+------------------------------------------------------------------+
//| EX5 imports                                                      |
//+------------------------------------------------------------------+
// #import "stdlib.ex5"
//   string ErrorDescription(int error_code);
// #import
//+------------------------------------------------------------------+

 //        if(!TrendCreate(0,        // chart's ID 
 //                   IB_Resistance_Name,  // line name 
//                  0,      // subwindow index 
//                   IB_StartTime,           // first point time 
 //                  IB_Resistance,          // first point price 
//                    end_time,           // second point time 
//                    IB_Resistance,          // second point price 
 //                   IBHighColor,        // line color 
//                    SnRStyle, // line style 
//                    SnRwidth,           // line width 
//                    SnRback,        // in the background 
//                    SnRselection,    // highlight to move 
//                    SnRray_left,    // line's continuation to the left 
//                    SnRray_right,   // line's continuation to the right 
//                    SnRhidden,       // hidden in the object list 
//                    SnRz_order))
//                    {
//                    return;
//                    }         
//         if(!TrendCreate(0,        // chart's ID 
//                    IB_Support_Name,  // line name 
//                    0,      // subwindow index 
//                    IB_StartTime,           // first point time 
//                    IB_Support,          // first point price 
//                    end_time,           // second point time 
//                    IB_Support,          // second point price /
//                    IBLowColor,        // line color 
//                    SnRStyle, // line style 
//                    SnRwidth,           // line width 
//                    SnRback,        // in the background 
//                    SnRselection,    // highlight to move 
//                    SnRray_left,    // line's continuation to the left 
//                    SnRray_right,   // line's continuation to the right 
//                    SnRhidden,       // hidden in the object list 
//                    SnRz_order))
//                    {
//                    return;
//                    }                
                     
bool trade_window_fn(datetime start_time_input, datetime end_time_input){
   if(Time[0]>=start_time_input&&Time[0]<end_time_input)
         return(true);
         else
         return(false);
}

bool CheckOpenOrders(const string OrderComment){
   //We need to scan all the open and pending orders to see if there is there is any
   //OrdersTotal return the total number of market and pending orders
   //What we do is scan all orders and check if they are of the same symbol of the one where the EA is running
   for( int i = 0 ; i < OrdersTotal() ; i++ ) {
      //We select the order of index i selecting by position and from the pool of market/pending trades
      //OrderSelect( i, SELECT_BY_POS, MODE_TRADES );
      if ( OrderSelect(i,  SELECT_BY_POS, MODE_TRADES)){continue;} 
      //If the pair of the order (OrderSymbol() is equal to the pair where the EA is running (Symbol()) then return true
     //comment = OrderComment();
      if((OrderSymbol() == Symbol())&&(OrderComment==OrderComment)) return(true);
   }
   //If the loop finishes it mean there were no open orders for that pair
   return(false);
}
 
void deleteallpendingorders(int magic){
   for(int i=0;i<OrdersTotal();i++){
     if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)){continue;}
     if(OrderSymbol()==Symbol() && OrderMagicNumber()==magic && ((OrderType()==OP_BUYSTOP) || (OrderType()==OP_SELLSTOP) || (OrderType()==OP_BUYLIMIT) || (OrderType()==OP_SELLLIMIT))){
       OrderDelete(OrderTicket());
     }   
   }
}

double trade_window(const datetime trade_window_start_time,const datetime trade_window_end_time)
  {
//---
   int result=0; // not in trade window.
//--- check position
   if(TimeLocal()>=trade_window_start_time&&TimeLocal()<=trade_window_end_time)
    result=1;

   if(TimeLocal()>trade_window_end_time)
    result=2;
   
   return(result);
  }


// =https://www.mql5.com/en/forum/300801=================================================================================================================================

bool TrendCreate(const long            chart_ID=0,        // chart's ID 
                 const string          name="TrendLine",  // line name 
                 const int             sub_window=0,      // subwindow index 
                 datetime              time1=0,           // first point time 
                 double                price1=0,          // first point price 
                 datetime              time2=0,           // second point time 
                 double                price2=0,          // second point price 
                 const color           clr=clrRed,        // line color 
                 const ENUM_LINE_STYLE style=STYLE_SOLID, // line style 
                 const int             width=1,           // line width 
                 const bool            back=false,        // in the background 
                 const bool            selection=true,    // highlight to move 
                 const bool            ray_left=false,    // line's continuation to the left 
                 const bool            ray_right=false,   // line's continuation to the right 
                 const bool            hidden=true,       // hidden in the object list 
                 const long            z_order=0)         // priority for mouse click 
  { 
//--- set anchor points' coordinates if they are not set 
   ChangeTrendEmptyPoints(time1,price1,time2,price2); 
//--- reset the error value 
   ResetLastError(); 
//--- create a trend line by the given coordinates 
   if(!ObjectCreate(chart_ID,name,OBJ_TREND,sub_window,time1,price1,time2,price2)) 
     { 
      Print(__FUNCTION__, 
            ": failed to create a trend line! Error code = ",GetLastError()); 
      return(false); 
     } 
//--- set line color 
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr); 
//--- set line display style 
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style); 
//--- set line width 
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width); 
//--- display in the foreground (false) or background (true) 
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back); 
//--- enable (true) or disable (false) the mode of moving the line by mouse 
//--- when creating a graphical object using ObjectCreate function, the object cannot be 
//--- highlighted and moved by default. Inside this method, selection parameter 
//--- is true by default making it possible to highlight and move the object 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection); 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection); 
//--- enable (true) or disable (false) the mode of continuation of the line's display to the left 
   ObjectSetInteger(chart_ID,name,OBJPROP_RAY_LEFT,ray_left); 
//--- enable (true) or disable (false) the mode of continuation of the line's display to the right 
   ObjectSetInteger(chart_ID,name,OBJPROP_RAY_RIGHT,ray_right); 
//--- hide (true) or display (false) graphical object name in the object list 
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden); 
//--- set the priority for receiving the event of a mouse click in the chart 
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order); 
  // ObjectSetText(name, name, 8, "Arial", clr);
//--- successful execution 
   return(true); 
  } 


void ChangeTrendEmptyPoints(datetime &time1,double &price1, 
                            datetime &time2,double &price2) 
  { 
//--- if the first point's time is not set, it will be on the current bar 
   if(!time1) 
      time1=TimeCurrent(); 
//--- if the first point's price is not set, it will have Bid value 
   if(!price1) 
      price1=SymbolInfoDouble(Symbol(),SYMBOL_BID); 
//--- if the second point's time is not set, it is located 9 bars left from the second one 
   if(!time2) 
     { 
      //--- array for receiving the open time of the last 10 bars 
      datetime temp[10]; 
      CopyTime(Symbol(),Period(),time1,10,temp); 
      //--- set the second point 9 bars left from the first one 
      time2=temp[0]; 
     } 
//--- if the second point's price is not set, it is equal to the first point's one 
   if(!price2) 
      price2=price1; 
  } 



// =TrendDelete=================================================================================================================================
bool TrendDelete(const long   chart_ID=0,       // chart's ID 
                 const string name="TrendLine") // line name 
  { 
//--- reset the error value 
   ResetLastError(); 
//--- delete a trend line 
   if(!ObjectDelete(chart_ID,name)) 
     { 
      Print(__FUNCTION__, 
            ": failed to delete a trend line! Error code = ",GetLastError()); 
      return(false); 
     } 
//--- successful execution 
   return(true); 
  } 


//+------------------------------------------------------------------+
//| Create the vertical line                                         |
//+------------------------------------------------------------------+
bool VLineCreate(const long            chart_ID=0,        // chart's ID
                 const string          name="VLine",      // line name
                 const int             sub_window=0,      // subwindow index
                 datetime              time=0,            // line time
                 const color           clr=clrRed,        // line color
                 const ENUM_LINE_STYLE style=STYLE_SOLID, // line style
                 const int             width=1,           // line width
                 const bool            back=false,        // in the background
                 const bool            selection=true,    // highlight to move
                 const bool            hidden=true,       // hidden in the object list
                 const long            z_order=0)         // priority for mouse click
  {
//--- if the line time is not set, draw it via the last bar
   if(!time)
      time=TimeCurrent();
//--- reset the error value
   ResetLastError();
//--- create a vertical line
   if(!ObjectCreate(chart_ID,name,OBJ_VLINE,sub_window,time,0))
     {
      Print(__FUNCTION__,
            ": failed to create a vertical line! Error code = ",GetLastError());
      return(false);
     }
//--- set line color
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- set line display style
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
//--- set line width
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width);
//--- display in the foreground (false) or background (true)
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of moving the line by mouse
//--- when creating a graphical object using ObjectCreate function, the object cannot be
//--- highlighted and moved by default. Inside this method, selection parameter
//--- is true by default making it possible to highlight and move the object
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
//--- hide (true) or display (false) graphical object name in the object list
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- successful execution
   return(true);
  }


bool VLineDelete(const long   chart_ID=0,   // chart's ID
                 const string name="VLine") // line name
  {
//--- reset the error value
   ResetLastError();
//--- delete the vertical line
   if(!ObjectDelete(chart_ID,name))
     {
      Print(__FUNCTION__,
            ": failed to delete the vertical line! Error code = ",GetLastError());
      return(false);
     }
//--- successful execution
   return(true);
  }
  
bool HLineCreate(const long            chart_ID=0,        // chart's ID
                 const string          name="HLine",      // line name
                 const int             sub_window=0,      // subwindow index
                 double                price=0,           // line price
                 const color           clr=clrRed,        // line color
                 const ENUM_LINE_STYLE style=STYLE_SOLID, // line style
                 const int             width=1,           // line width
                 const bool            back=false,        // in the background
                 const bool            selection=true,    // highlight to move
                 const bool            hidden=true,       // hidden in the object list
                 const long            z_order=0)         // priority for mouse click
  {
//--- if the price is not set, set it at the current Bid price level
   if(!price)
      price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
//--- reset the error value
   ResetLastError();
//--- create a horizontal line
   if(!ObjectCreate(chart_ID,name,OBJ_HLINE,sub_window,0,price))
     {
      Print(__FUNCTION__,
            ": failed to create a horizontal line! Error code = ",GetLastError());
      return(false);
     }
//--- set line color
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- set line display style
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
//--- set line width
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width);
//--- display in the foreground (false) or background (true)
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of moving the line by mouse
//--- when creating a graphical object using ObjectCreate function, the object cannot be
//--- highlighted and moved by default. Inside this method, selection parameter
//--- is true by default making it possible to highlight and move the object
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
//--- hide (true) or display (false) graphical object name in the object list
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- successful execution
   return(true);
  }


