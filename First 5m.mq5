//+------------------------------------------------------------------+
//|                                           High Low First Bar.mq5 |
//|                              Copyright © 2019, Vladimir Karputov |
//|                                           http://wmua.ru/slesar/ |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2023, GM"
#property version   "1.0"
#property indicator_chart_window
#property indicator_buffers 0
#property indicator_plots   0
////--- plot High
//#property indicator_label1  "High"
//#property indicator_type1   DRAW_ARROW
//#property indicator_color1  clrTomato
//#property indicator_style1  STYLE_SOLID
//#property indicator_width1  1
////--- plot Low
//#property indicator_label2  "Low"
//#property indicator_type2   DRAW_ARROW
//#property indicator_color2  clrSlateBlue
//#property indicator_style2  STYLE_SOLID
//#property indicator_width2  1
//--- input parameters
//input ushort   InpHighCode = 119; // Symbol code to draw "High"
//input ushort   InpLowCode = 119; // Symbol code to draw "Low"
//--- indicator buffers
//double         HighBuffer[];
//double         LowBuffer[];
//---

input ENUM_TIMEFRAMES            tf = PERIOD_CURRENT;
input bool                       enableD = true;
input bool                       enableW = true;
input bool                       enableMN = true;
input datetime                   data = D'2023.8.14';
input bool                       shortMode = false;
input int                        input_start = 0;
input int                        input_end = 0;
input bool                       useOC = true;
input bool                       useHL = true;
input color                      color_up_1 = clrLime;
input color                      color_up_2 = clrRoyalBlue;
input color                      color_dn_1 = clrRed;
input color                      color_dn_2 = clrOrange;
input bool                       drawSR = false;
input bool                       drawProjections1 = true;
input bool                       drawProjections2 = true;
input bool                       input_extendLines = true;
input double                     proj_size = 0.15;
input int                        WaitMilliseconds  = 500000;  // Timer (milliseconds) for recalculation

int            day_of_year;
datetime       first_bar, start_bar, end_bar;
double         first_high;
double         first_low;
double         first_open;
double         first_close;
bool           extendLines;

datetime       arrayTime[];
double         arrayOpen[], arrayHigh[], arrayLow[], arrayClose[];
string         valor;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
//--- indicator buffers mapping
//   SetIndexBuffer(0, HighBuffer, INDICATOR_DATA);
//   SetIndexBuffer(1, LowBuffer, INDICATOR_DATA);
////--- setting a code from the Wingdings charset as the property of PLOT_ARROW
//   PlotIndexSetInteger(0, PLOT_ARROW, InpHighCode);
//   PlotIndexSetInteger(1, PLOT_ARROW, InpLowCode);
////--- set the vertical shift of arrows in pixels
//   PlotIndexSetInteger(0, PLOT_ARROW_SHIFT, -5);
//   PlotIndexSetInteger(1, PLOT_ARROW_SHIFT, 5);
//---
   day_of_year = -1;
   first_bar = 0;    // "0" -> D'1970.01.01 00:00';
   first_high = 0.0;
   first_low = 0.0;
   first_close = 0.0;
   first_open = 0.0;

   ObjectsDeleteAll(0, "first5m_");

   _updateTimer = new MillisecondTimer(WaitMilliseconds, false);
   EventSetMillisecondTimer(WaitMilliseconds);

   if (enableD) _lastOK = Update(PERIOD_D1);
   if (enableW) _lastOK = Update(PERIOD_W1);
   if (enableMN) _lastOK = Update(PERIOD_MN1);

   if (shortMode)
      extendLines = false;

//---
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {

   delete(_updateTimer);

   ObjectsDeleteAll(0, "first5m_");

   ChartRedraw();

}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total, const int prev_calculated, const int begin, const double &price[]) {
   return (1);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Update(ENUM_TIMEFRAMES p_tf) {



   string tf_name = GetTimeFrame(p_tf);
   string line_up = "up_" + tf_name + "_";
   string line_dn = "dn_" + tf_name + "_";
   ENUM_LINE_STYLE line_style = STYLE_DASH;
   int line_width = 1;
   ObjectsDeleteAll(0, "first5m_" + "up_" + tf_name);
   ObjectsDeleteAll(0, "first5m_" + "dn_" + tf_name);
//if (tf_name == "D1")
//   line_style = STYLE_DOT;
//else if (tf_name == "W1")
//   line_style = STYLE_DASH;
//else if (tf_name == "MN1")
//   line_style = STYLE_DASH;

   if (tf_name == "D1")
      line_width = 1;
   else if (tf_name == "W1")
      line_width = 3;
   else if (tf_name == "MN1")
      line_width = 5;

   int totalRates = SeriesInfoInteger(NULL, p_tf, SERIES_BARS_COUNT);

   int barra = iBarShift(NULL, p_tf, data, 0);

   int tempVar = CopyLow(NULL, p_tf, 0, barra, arrayLow);
   tempVar = CopyClose(NULL, p_tf, 0, barra, arrayClose);
   tempVar = CopyHigh(NULL, p_tf, 0, barra, arrayHigh);
   tempVar = CopyOpen(NULL, p_tf, 0, barra, arrayOpen);
   tempVar = CopyTime(NULL, p_tf, 0, barra, arrayTime);

   ArrayReverse(arrayLow);
   ArrayReverse(arrayClose);
   ArrayReverse(arrayHigh);
   ArrayReverse(arrayOpen);
   ArrayReverse(arrayTime);

   ArraySetAsSeries(arrayOpen, true);
   ArraySetAsSeries(arrayLow, true);
   ArraySetAsSeries(arrayClose, true);
   ArraySetAsSeries(arrayHigh, true);
   ArraySetAsSeries(arrayTime, true);

   for(int i = 0; i < ArraySize(arrayTime); i++) {
      MqlDateTime STime;
      TimeToStruct(arrayTime[i], STime);
      if(STime.day_of_year != day_of_year) {
         day_of_year = STime.day_of_year;
         first_bar = arrayTime[i];
         first_high = arrayHigh[i];
         first_low = arrayLow[i];
         first_open = arrayOpen[i];
         first_close = arrayClose[i];
      } else if(first_bar == arrayTime[i]) {
         first_bar = arrayTime[i];
         day_of_year = STime.day_of_year;
         first_high = arrayHigh[i];
         first_low = arrayLow[i];
         first_open = arrayOpen[i];
         first_close = arrayClose[i];
      }

      if (shortMode) {
         start_bar = iTime(NULL, PERIOD_CURRENT, 0) + PeriodSeconds(PERIOD_CURRENT) * input_start;
         end_bar = iTime(NULL, PERIOD_CURRENT, 0) + PeriodSeconds(PERIOD_CURRENT) * input_end;

      } else {
         start_bar = first_bar;
         end_bar = iTime(NULL, PERIOD_CURRENT, 0);
      }
      //if (first_high >= close[rates_total - 1]) {
      if (drawSR) {
         ObjectCreate(0, "first5m_" + line_up + i, OBJ_TREND, 0, start_bar, line_up, end_bar, line_up);
         ObjectCreate(0, "first5m_" + line_dn + i, OBJ_TREND, 0, start_bar, line_dn, end_bar, line_dn);
      }

      ObjectSetInteger(0, "first5m_" + line_up + i, OBJPROP_COLOR, clrRed);
      ObjectSetInteger(0, "first5m_" + line_dn + i, OBJPROP_COLOR, clrLime);
      //}

      if (drawProjections1) {
         if (first_close >= first_open) {
            if (useHL) {
               ObjectCreate(0, "first5m_" + line_up + "proj1_h_" + i, OBJ_TREND, 0, start_bar, first_high + first_high * proj_size / 100, end_bar, first_high + first_high * proj_size / 100);
               ObjectSetInteger(0, "first5m_" + line_up + "proj1_h_" + i, OBJPROP_COLOR, color_up_2);
               ObjectSetInteger(0, "first5m_" + line_up + "proj1_h_" + i, OBJPROP_STYLE, STYLE_DASH);
               ObjectSetInteger(0, "first5m_" + line_up + "proj1_h_" + i, OBJPROP_RAY_RIGHT, extendLines);
               ObjectSetInteger(0, "first5m_" + line_up + "proj1_h_" + i, OBJPROP_WIDTH, line_width);
               valor = "Start:" + first_bar +
                       "\nTimeframe: " + tf_name +
                       "\nPrice: " + DoubleToString(first_high + first_high * proj_size / 100, 2) +
                       "\nType: High";
               ObjectSetString(0, "first5m_" + line_up + "proj1_h_" + i, OBJPROP_TOOLTIP, valor);

               ObjectCreate(0, "first5m_" + line_up + "proj1_l_" + i, OBJ_TREND, 0, start_bar, first_low + first_low * proj_size / 100, end_bar, first_low + first_low * proj_size / 100);
               ObjectSetInteger(0, "first5m_" + line_up + "proj1_l_" + i, OBJPROP_COLOR, color_up_2);
               ObjectSetInteger(0, "first5m_" + line_up + "proj1_l_" + i, OBJPROP_STYLE, STYLE_DASH);
               ObjectSetInteger(0, "first5m_" + line_up + "proj1_l_" + i, OBJPROP_RAY_RIGHT, extendLines);
               ObjectSetInteger(0, "first5m_" + line_up + "proj1_l_" + i, OBJPROP_WIDTH, line_width);
               valor = "Start:" + first_bar +
                       "\nTimeframe: " + tf_name +
                       "\nPrice: " + DoubleToString(first_low + first_low * proj_size / 100, 2) +
                       "\nType: Low";
               ObjectSetString(0, "first5m_" + line_up + "proj1_l_" + i, OBJPROP_TOOLTIP, valor);
            }
            if (useOC) {
               ObjectCreate(0, "first5m_" + line_up + "proj1_c_" + i, OBJ_TREND, 0, start_bar, first_close + first_close * proj_size / 100, end_bar, first_close + first_close * proj_size / 100);
               ObjectSetInteger(0, "first5m_" + line_up + "proj1_c_" + i, OBJPROP_COLOR, color_up_1);
               ObjectSetInteger(0, "first5m_" + line_up + "proj1_c_" + i, OBJPROP_STYLE, STYLE_DASH);
               ObjectSetInteger(0, "first5m_" + line_up + "proj1_c_" + i, OBJPROP_RAY_RIGHT, extendLines);
               ObjectSetInteger(0, "first5m_" + line_up + "proj1_c_" + i, OBJPROP_WIDTH, line_width);
               valor = "Start:" + first_bar +
                       "\nTimeframe: " + tf_name +
                       "\nPrice: " + DoubleToString(first_close + first_close * proj_size / 100, 2) +
                       "\nType: Close";
               ObjectSetString(0, "first5m_" + line_up + "proj1_c_" + i, OBJPROP_TOOLTIP, valor);

               ObjectCreate(0, "first5m_" + line_up + "proj1_o_" + i, OBJ_TREND, 0, start_bar, first_open + first_open * proj_size / 100, end_bar, first_open + first_open * proj_size / 100);
               ObjectSetInteger(0, "first5m_" + line_up + "proj1_o_" + i, OBJPROP_COLOR, color_up_1);
               ObjectSetInteger(0, "first5m_" + line_up + "proj1_o_" + i, OBJPROP_STYLE, STYLE_DASH);
               ObjectSetInteger(0, "first5m_" + line_up + "proj1_o_" + i, OBJPROP_RAY_RIGHT, extendLines);
               ObjectSetInteger(0, "first5m_" + line_up + "proj1_o_" + i, OBJPROP_WIDTH, line_width);
               valor = "Start:" + first_bar +
                       "\nTimeframe: " + tf_name +
                       "\nPrice: " + DoubleToString(first_open + first_open * proj_size / 100, 2) +
                       "\nType: Open";
               ObjectSetString(0, "first5m_" + line_up + "proj1_o_" + i, OBJPROP_TOOLTIP, valor);
            }
         } else {
            if (useHL) {
               ObjectCreate(0, "first5m_" + line_dn + "proj1_h_" + i, OBJ_TREND, 0, start_bar, first_high - first_high * proj_size / 100, end_bar, first_high - first_high * proj_size / 100);
               ObjectSetInteger(0, "first5m_" + line_dn + "proj1_h_" + i, OBJPROP_COLOR, color_dn_2);
               ObjectSetInteger(0, "first5m_" + line_dn + "proj1_h_" + i, OBJPROP_STYLE, STYLE_DASH);
               ObjectSetInteger(0, "first5m_" + line_dn + "proj1_h_" + i, OBJPROP_RAY_RIGHT, extendLines);
               ObjectSetInteger(0, "first5m_" + line_dn + "proj1_h_" + i, OBJPROP_WIDTH, line_width);
               valor = "Start:" + first_bar +
                       "\nTimeframe: " + tf_name +
                       "\nPrice: " + DoubleToString(first_high - first_high * proj_size / 100, 2) +
                       "\nType: High";
               ObjectSetString(0, "first5m_" + line_dn + "proj1_h_" + i, OBJPROP_TOOLTIP, valor);

               ObjectCreate(0, "first5m_" + line_dn + "proj1_l_" + i, OBJ_TREND, 0, start_bar, first_low - first_low * proj_size / 100, end_bar, first_low - first_low * proj_size / 100);
               ObjectSetInteger(0, "first5m_" + line_dn + "proj1_l_" + i, OBJPROP_COLOR, color_dn_2);
               ObjectSetInteger(0, "first5m_" + line_dn + "proj1_l_" + i, OBJPROP_STYLE, STYLE_DASH);
               ObjectSetInteger(0, "first5m_" + line_dn + "proj1_l_" + i, OBJPROP_RAY_RIGHT, extendLines);
               ObjectSetInteger(0, "first5m_" + line_dn + "proj1_l_" + i, OBJPROP_WIDTH, line_width);
               valor = "Start:" + first_bar +
                       "\nTimeframe: " + tf_name +
                       "\nPrice: " + DoubleToString(first_low - first_low * proj_size / 100, 2) +
                       "\nType: Low";
               ObjectSetString(0, "first5m_" + line_dn + "proj1_l_" + i, OBJPROP_TOOLTIP, valor);
            }
            if (useOC) {
               ObjectCreate(0, "first5m_" + line_dn + "proj1_o_" + i, OBJ_TREND, 0, start_bar, first_open - first_open * proj_size / 100, end_bar, first_open - first_open * proj_size / 100);
               ObjectSetInteger(0, "first5m_" + line_dn + "proj1_o_" + i, OBJPROP_COLOR, color_dn_1);
               ObjectSetInteger(0, "first5m_" + line_dn + "proj1_o_" + i, OBJPROP_STYLE, STYLE_DASH);
               ObjectSetInteger(0, "first5m_" + line_dn + "proj1_o_" + i, OBJPROP_RAY_RIGHT, extendLines);
               ObjectSetInteger(0, "first5m_" + line_dn + "proj1_o_" + i, OBJPROP_WIDTH, line_width);
               valor = "Start:" + first_bar +
                       "\nTimeframe: " + tf_name +
                       "\nPrice: " + DoubleToString(first_open - first_open * proj_size / 100, 2) +
                       "\nType: Open";
               ObjectSetString(0, "first5m_" + line_dn + "proj1_o_" + i, OBJPROP_TOOLTIP, valor);

               ObjectCreate(0, "first5m_" + line_dn + "proj1_c_" + i, OBJ_TREND, 0, start_bar, first_close - first_close * proj_size / 100, end_bar, first_close - first_close * proj_size / 100);
               ObjectSetInteger(0, "first5m_" + line_dn + "proj1_c" + i, OBJPROP_COLOR, color_dn_1);
               ObjectSetInteger(0, "first5m_" + line_dn + "proj1_c_" + i, OBJPROP_STYLE, STYLE_DASH);
               ObjectSetInteger(0, "first5m_" + line_dn + "proj1_c_" + i, OBJPROP_RAY_RIGHT, extendLines);
               ObjectSetInteger(0, "first5m_" + line_dn + "proj1_c_" + i, OBJPROP_WIDTH, line_width);
               valor = "Start:" + first_bar +
                       "\nTimeframe: " + tf_name +
                       "\nPrice: " + DoubleToString(first_close - first_close * proj_size / 100, 2) +
                       "\nType: Close";
               ObjectSetString(0, "first5m_" + line_dn + "proj1_c_" + i, OBJPROP_TOOLTIP, valor);
            }
         }
      }
   }
//      if (drawProjections2) {
//         ObjectCreate(0, "first5m_up_proj2_" + i, OBJ_TREND, 0, first_bar, line_up + line_up * proj_size / 100, iTime(NULL, PERIOD_CURRENT, 0), line_up + line_up * proj_size / 100);
//         ObjectSetInteger(0, "first5m_up_proj2_" + i, OBJPROP_COLOR, clrRed);
//         ObjectSetInteger(0, "first5m_up_proj2_" + i, OBJPROP_STYLE, STYLE_DASH);
//
//         ObjectCreate(0, "first5m_dn_proj2_" + i, OBJ_TREND, 0, first_bar, line_dn - line_dn * proj_size / 100, iTime(NULL, PERIOD_CURRENT, 0), line_dn - line_dn * proj_size / 100);
//         ObjectSetInteger(0, "first5m_dn_proj2_" + i, OBJPROP_COLOR, clrLime);
//         ObjectSetInteger(0, "first5m_dn_proj2_" + i, OBJPROP_STYLE, STYLE_DASH);
//      }

//HighBuffer[i] = first_high;
//LowBuffer[i] = first_low;


   ChartRedraw();

   return true;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class MillisecondTimer {

 private:
   int               _milliseconds;
 private:
   uint              _lastTick;

 public:
   void              MillisecondTimer(const int milliseconds, const bool reset = true) {
      _milliseconds = milliseconds;

      if(reset)
         Reset();
      else
         _lastTick = 0;
   }

 public:
   bool              Check() {
      uint now = getCurrentTick();
      bool stop = now >= _lastTick + _milliseconds;

      if(stop)
         _lastTick = now;

      return(stop);
   }

 public:
   void              Reset() {
      _lastTick = getCurrentTick();
   }

 private:
   uint              getCurrentTick() const {
      return(GetTickCount());
   }

};

bool _lastOK = false;
MillisecondTimer *_updateTimer;

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer() {
   CheckTimer();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckTimer() {
   EventKillTimer();

   if(_updateTimer.Check() || !_lastOK) {
      if (enableD) _lastOK = Update(PERIOD_D1);
      if (enableW) _lastOK = Update(PERIOD_W1);
      if (enableMN) _lastOK = Update(PERIOD_MN1);
      //Print("PVT calculated");
      EventSetMillisecondTimer(WaitMilliseconds);

      _updateTimer.Reset();
   } else {
      EventSetTimer(1);
   }
}
//+------------------------------------------------------------------+

//+---------------------------------------------------------------------+
//| GetTimeFrame function - returns the textual timeframe               |
//+---------------------------------------------------------------------+
string GetTimeFrame(int lPeriod) {
   switch(lPeriod) {
   case PERIOD_M1:
      return("M1");
   case PERIOD_M2:
      return("M2");
   case PERIOD_M3:
      return("M3");
   case PERIOD_M4:
      return("M4");
   case PERIOD_M5:
      return("M5");
   case PERIOD_M6:
      return("M6");
   case PERIOD_M10:
      return("M10");
   case PERIOD_M12:
      return("M12");
   case PERIOD_M15:
      return("M15");
   case PERIOD_M20:
      return("M20");
   case PERIOD_M30:
      return("M30");
   case PERIOD_H1:
      return("H1");
   case PERIOD_H2:
      return("H2");
   case PERIOD_H3:
      return("H3");
   case PERIOD_H4:
      return("H4");
   case PERIOD_H6:
      return("H6");
   case PERIOD_H8:
      return("H8");
   case PERIOD_H12:
      return("H12");
   case PERIOD_D1:
      return("D1");
   case PERIOD_W1:
      return("W1");
   case PERIOD_MN1:
      return("MN1");
   }
   return IntegerToString(lPeriod);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
