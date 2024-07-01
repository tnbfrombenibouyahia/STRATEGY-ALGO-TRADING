//+------------------------------------------------------------------+
//|                                          croisementMAtpauvre.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

//EMA 21 & EMA 51 achat vente croisement

#include <Trade/Trade.mqh>
CTrade trade;

input int StopLoss = 20;
input int Takeprofit = 40;

double SL = StopLoss*_Point*10;
double TP = Takeprofit*_Point*10;

int ema21Handle, ema55Handle;
bool tradeEnCours;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   tradeEnCours = false;

   ema21Handle = iMA(_Symbol,PERIOD_CURRENT,21,0,MODE_EMA,PRICE_CLOSE);
   ema55Handle = iMA(_Symbol,PERIOD_CURRENT,55,0,MODE_EMA,PRICE_CLOSE);
   
   
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
   double prixVente = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   double ema21[], ema55[];
   
   CopyBuffer(ema21Handle,0,0,2,ema21);
   CopyBuffer(ema55Handle,0,0,2,ema55);
   
   if(ema21[0] < ema55[0] && ema21[1] > ema55[1] && !tradeEnCours){
   
       Print(" croisement haussier ");
       trade.Buy(0.01,_Symbol,prixAchat,prixAchat - SL,prixAchat + TP);
       tradeEnCours = true;
      }
      
       if(ema21[0] > ema55[0] && ema21[1] < ema55[1] && !tradeEnCours){
   
       Print(" croisement baissier ");
       trade.Sell(0.01,_Symbol,prixVente,prixVente + SL, prixVente - TP);
       tradeEnCours = true;
      }
      
      if(PositionsTotal() == 0){
         tradeEnCours = false;
      }
}
//+------------------------------------------------------------------+
