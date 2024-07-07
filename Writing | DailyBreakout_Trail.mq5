//+------------------------------------------------------------------+
//|                                            Breakout trailing.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade/Trade.mqh>
CTrade trade;

input group " Trading parameters"
input double positionSize = 0.1; 

int bars;
double lastCandleLow, lastCandleHigh;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {


  return (INIT_SUCCEEDED);  
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
  
  
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
    
    double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);

    int totalBars = iBars(_Symbol,PERIOD_D1);          // recevoir le nombre de bougie dans le graphique

    // tout les jours quand il y aur aune bougie, on va faire une fonction if 
    // qui nous donnera les information suivante une seul fois par jour.

    if(bars != totalBars){

      bars = totalBars;

      lastCandleHigh = iHigh(_Symbol, PERIOD_D1,1);
      lastCandleLow = iLow(_Symbol, PERIOD_D1,1);

       if(ask < lastCandleHigh && bid > lastCandleLow) {
            trade.BuyStop(positionSize, lastCandleHigh, _Symbol);
            trade.SellStop(positionSize, lastCandleLow, _Symbol);
       }
      // on fait appel au trailingstop ici même si le code est dans le void en dessous. 
      trailingStop();
    }

  }
//+------------------------------------------------------------------+

// une fonction void pour le trailing stop en deghors de on tick
void trailingStop(){
// on est obliger de refaire des variables pour toutes les variables qui ne sont pas global comme le ask et le bid
  double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
  double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);

// on  va faire une boucle for, on va determiner si c'est une vente ou achat car pas le même trailking
// i position total -1, en mql5 l'index 0 est égal a la premiere valeur. comme en python. 
// donc pour avoir 
 

}
