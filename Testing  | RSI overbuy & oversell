//+------------------------------------------------------------------+
//|                                             RSIretourmoyenne.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"


//achat en survente et vente en surachat

#include <Trade/Trade.mqh>
CTrade trade;

input ENUM_TIMEFRAMES timeframeRSI = PERIOD_H4;
input int periodRSI = 14;
input ENUM_APPLIED_PRICE prixRSI = PRICE_CLOSE;
input double Lots = 0.01;
input double stoploss = 20;
input double takeprofit = 40;

double SL = stoploss*_Point*10;
double TP = takeprofit*_Point*10;

int rsiHandle;
bool TradeEnCours = false;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---

    rsiHandle = iRSI(_Symbol,timeframeRSI,periodRSI,prixRSI); 
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

   double prixAchat = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double prixVente = SymbolInfoDouble(_Symbol,SYMBOL_BID);
      
   double rsi[];
   CopyBuffer(rsiHandle,0,0,1,rsi);
   
   if(rsi[0] < 30 && TradeEnCours == false){
   
      Print(" RSI en survente = achat");
      trade.Buy(Lots,_Symbol,prixAchat,prixAchat - SL, prixAchat + TP);
      TradeEnCours = true;
   }
   
    if(rsi[0] > 70 && TradeEnCours == false){
   
      Print(" RSI en surachat = vente");
      trade.Sell(Lots,_Symbol,prixVente,prixVente + SL, prixAchat - TP);
      TradeEnCours = true;
   }
   
   if(PositionsTotal() == 0){
      TradeEnCours = false;
   }
      
}
//+------------------------------------------------------------------+
