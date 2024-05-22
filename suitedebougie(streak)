//+------------------------------------------------------------------+
//| Properties                                                       |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, lazzizcorp"
#property version   "1.00"

//+------------------------------------------------------------------+
//| Includes                                                         |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
input group "=== General ==="
static input long   InpMagicNumber     = 6738172638;   // magic number
static input double InpLotSize         = 0.01;     // lot size
input group "=== Trading ==="
input ENUM_TIMEFRAMES  InpTimeframe    = PERIOD_M5;   // timeframe
input int              InpStreak       = 3;           // candle streak
input int              InpSizeFilter   = 0;           // size filter in points (0=off)
input int              InpStopLoss     = 200;         // stop loss in points (0=off)
input int              InpTakeProfit   = 0;           // take profit in points (0=off)
input int              InpTimeExitHour = 22;          // time exit hour (-1=off)

//+------------------------------------------------------------------+
//| Global Variable                            |
//+------------------------------------------------------------------+
MqlTick tick;
CTrade trade;
CPositionInfo position;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit(){

  if(!CheckInputs()) return(INIT_PARAMETERS_INCORRECT);

  // set magicnumber to trade object
  trade.SetExpertMagicNumber(InpMagicNumber);

  return(INIT_SUCCEEDED);
}


//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick(){

    // check if current tick is a bar open tick
    if(!IsNewBar()){return;}

    // get current tick
    if(!SymbolInfoTick(_Symbol, tick)){
    Print("Failed to get current tick");
    return;
    }

    // count open positions
    int cntBuy=0, cntSell=0;
    CountPositions(cntBuy, cntSell);

    // check for new buy position
    if(cntBuy==0 && CheckBars(true)){

      // calculate sl and tp
      double sl = InpStopLoss==0 ? 0 : tick.bid - InpStopLoss * _Point;
      double tp = InpTakeProfit==0 ? 0 : tick.bid + InpTakeProfit * _Point;

      // normalize price
      if(!NormalizePrice(sl)){return;}
      if(!NormalizePrice(tp)){return;}

      // open buy position
      trade.PositionOpen(_Symbol, ORDER_TYPE_BUY, InpLotSize, tick.ask, sl, tp, "StreakEA");
    }

    // check for new sell position
    if(cntSell==0 && CheckBars(false)){

      // calculate sl and tp
      double sl = InpStopLoss==0 ? 0 : tick.ask + InpStopLoss * _Point;
      double tp = InpTakeProfit==0 ? 0 : tick.ask - InpTakeProfit * _Point;

      // normalize price
      if(!NormalizePrice(sl)){return;}
      if(!NormalizePrice(tp)){return;}

      // open sell position
      trade.PositionOpen(_Symbol, ORDER_TYPE_SELL, InpLotSize, tick.bid, sl, tp, "StreakEA");
    }

    // check for time exit
    MqlDateTime dt;
    TimeCurrent(dt);
    if(dt.hour==InpTimeExitHour && dt.min<3){
        ClosePositions(true);
        ClosePositions(false);
    }

}



//+------------------------------------------------------------------+
//|  Custom Functions                                                |
//+------------------------------------------------------------------+

bool CheckInputs(){

    if(InpMagicNumber <= 0){
        Alert("Wrong input: magic number <= 0");
        return false;
    }
    if(InpLotSize<=0){
        Alert("Wrong input: lot size <= 0");
        return false;
    }
    if(InpTimeframe==PERIOD_CURRENT){
        Alert("Wrong input: timeframe can't be 'period current'");
        return false;
    }
    if(InpStreak<=0){
       Alert("Wrong input: streak <= 0");
        return false;
    }
    if(InpSizeFilter<0){
       Alert("Wrong input: size filter < 0");
        return false;
    }
    if(InpStopLoss<0){
       Alert("Wrong input: stop loss < 0");
        return false;
    }
    if(InpTakeProfit<0){
       Alert("Wrong input: take profit < 0");
        return false;
    }
    if(InpTimeExitHour<-1 || InpTimeExitHour>23){
       Alert("Wrong input: time exit <-1 or time exite >23");
        return false;
    }
    
  return true;
}


// check if we have a new bar open tick 
bool IsNewBar() {

  static datetime previousTime = 0;
  datetime currentTime = iTime(_Symbol, PERIOD_CURRENT, 0);
  if(previousTime != currentTime) {
    previousTime = currentTime;
    return true;
  }
  return false;
} 


// count open positions
void CountPositions(int &cntBuy, int &cntSell) {

    cntBuy = 0;
    cntSell = 0;
    int total = PositionsTotal();
    for(int i=total-1; i>=0; i--) {
      position.SelectByIndex(i);
      if(position.Magic()==InpMagicNumber) {
        if(position.PositionType()==POSITION_TYPE_BUY) cntBuy++;
        if(position.PositionType()==POSITION_TYPE_SELL) cntSell++;
    }
  }
}


// check bars
bool CheckBars(bool buy_sell){

  // get bars
  MqlRates rates[];
  ArraySetAsSeries(rates,true);
  if(!CopyRates(_Symbol, InpTimeframe, 0, InpStreak+1, rates)){
    Print("Failed to get rates");
    return false;
  }
  // check condition
  for(int i=InpStreak; i>0; i--){
    bool isGreen = rates[i].open < rates[i].close;
    double size = MathAbs(rates[i].open - rates[i].close);
    if(buy_sell && (isGreen || (InpSizeFilter>0 && size<InpSizeFilter* _Point))){return false;}
    if(buy_sell && (isGreen || (InpSizeFilter>0 && size<InpSizeFilter* _Point))){ return false;}
  }

  return true;
}


bool NormalizePrice(double &price){

    double tickSize=0;
    if(!SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE, tickSize)){
        Print("Failed to get tick size");
        return false;
    }
    price = NormalizeDouble((price/tickSize)*tickSize, _Digits);
    return true;
}


// close positions
void ClosePositions(bool buy_sell){

    int total = PositionsTotal();
    for(int i=total-1; i>=0; i--){
        position.SelectByIndex(i);
        if(position.Magic()==InpMagicNumber){
            if(buy_sell && position.PositionType()==POSITION_TYPE_SELL){continue;}
            if(!buy_sell && position.PositionType()==POSITION_TYPE_BUY){continue;}
            trade.PositionClose(position.Ticket());
        }
    }
}
