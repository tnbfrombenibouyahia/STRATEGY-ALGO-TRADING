//+------------------------------------------------------------------+
//|                                       Bollingerbandarbitrage.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"


input group "Bollinger Bands"
input ENUM_TIMEFRAMES bbTimeframe = PERIOD_H4;
input int bbPeriod = 20;
input double bbStd = 2;
input ENUM_APPLIED_PRICE bbAppPrice = PRICE_CLOSE;

input group "Filtre de tendance"
input ENUM_TIMEFRAMES maTimeframe = PERIOD_H4;
input int maPeriod = 200;
input ENUM_MA_METHOD maMethod = MODE_SMA;
input ENUM_APPLIED_PRICE maAppPrice = PRICE_CLOSE;

int bbHandle, maHandle; 


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---

   bbHandle = iBands(_Symbol,bbTimeframe,bbPeriod,1,bbStd,bbAppPrice);
   maHandle = iMA(_Symbol,maTimeframe,maPeriod,0,maMethod,maAppPrice);
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   
  }
//+------------------------------------------------------------------+
