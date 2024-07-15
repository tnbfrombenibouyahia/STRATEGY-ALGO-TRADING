//+------------------------------------------------------------------+
//|                                         LondonbreakoutBrieuc.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade/Trade.mqh>
CTrade trade;


input group "Paramètres Trading"
input double stoploss = 20;
input double takeprofit = 40;

input group"Paramètres de risque"
input double RiskInPct = 0.5;

double SL = stoploss*_Point*10;
double TP = takeprofit*_Point*10;

input group "Filtres"
input int maPeriod = 50;
input ENUM_TIMEFRAMES maTimeframe = PERIOD_H1;
input ENUM_MA_METHOD maMethod = MODE_EMA;  
input ENUM_APPLIED_PRICE maPrice = PRICE_CLOSE;

input bool isMaFilter = true;

datetime londonOpen,londonClose;

bool isLondonOpen;
int maHandle;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---

   maHandle=iMA(_Symbol, maTimeframe, maPeriod, 0, maMethod, maPrice);
   
   
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

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   timeStructure();


   if(TimeCurrent() > londonOpen && TimeCurrent() < londonClose && !isLondonOpen){
   
      int asianSessionLowestBar = iLowest(_Symbol,PERIOD_H1,MODE_LOW,10,1);
      int asianSessionHighestBar = iHighest(_Symbol,PERIOD_H1,MODE_HIGH,10,1);
      
      
   
      double asianSessionLow = iLow(_Symbol, PERIOD_H1,asianSessionLowestBar);
      double asianSessionHigh = iLow(_Symbol, PERIOD_H1,asianSessionHighestBar);
      
      ObjectCreate(ChartID(),"London Open",OBJ_VLINE,0,londonOpen,0);
      ObjectCreate(ChartID(),"Asian Open",OBJ_VLINE,0,TimeCurrent()-PeriodSeconds(PERIOD_H1)*10,0);
      
      ObjectCreate(ChartID(),"Asian High",OBJ_HLINE,0,TimeCurrent()-PeriodSeconds(PERIOD_H1)*10,asianSessionHigh);
      ObjectCreate(ChartID(),"Asian Low ",OBJ_HLINE,0,TimeCurrent()-PeriodSeconds(PERIOD_H1)*10,asianSessionLow);
      
      double ma[];
      CopyBuffer(maHandle,0,0,1,ma);
      
      if(isMaFilter){
      
         if(ask > ma[0])
            trade.BuyStop(positionSizeCalculator(),asianSessionHigh,_Symbol,asianSessionHigh-SL,asianSessionHigh+TP,ORDER_TIME_SPECIFIED,londonClose);
            
         if(bid < ma[0])
            trade.SellStop(positionSizeCalculator(),asianSessionLow,_Symbol,asianSessionLow+SL,asianSessionLow-TP,ORDER_TIME_SPECIFIED,londonClose);
         
      }
      else{
      
            trade.BuyStop(positionSizeCalculator(),asianSessionHigh,_Symbol,asianSessionHigh-SL,asianSessionHigh+TP,ORDER_TIME_SPECIFIED,londonClose);
            trade.SellStop(positionSizeCalculator(),asianSessionLow,_Symbol,asianSessionLow+SL,asianSessionLow-TP,ORDER_TIME_SPECIFIED,londonClose);  
      }
      
      isLondonOpen = true;
   
   }
   
     if(TimeCurrent() > londonClose && isLondonOpen){
   
      isLondonOpen = false;
   
   }
   
   }
//+------------------------------------------------------------------+

void timeStructure(){

   MqlDateTime structLondonOpen;
   TimeCurrent(structLondonOpen);
   
   structLondonOpen.hour = 9;
   structLondonOpen.min = 0;
   structLondonOpen.sec = 0;
   
   londonOpen = StructToTime(structLondonOpen);
   
   
   MqlDateTime structLondonClose;
   TimeCurrent(structLondonClose);
   
   structLondonClose.hour = 18;
   structLondonClose.min = 0;
   structLondonClose.sec = 0;
   
   londonClose = StructToTime(structLondonClose);
}

double positionSizeCalculator(){

   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickValue = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
   double lotStep = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   double riskInCurrency = AccountInfoDouble(ACCOUNT_BALANCE)*RiskInPct/100;
   
   double riskLotStep = SL/tickSize*lotStep*tickValue;
   
   double positionSize = MathFloor(riskInCurrency/riskLotStep)*lotStep;

   return positionSize;
   
 } 
 
