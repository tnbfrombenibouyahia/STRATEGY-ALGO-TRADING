//+------------------------------------------------------------------+
//|                                         Candlestick strategy.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

//+------------------------------------------------------------------+
//| Defines                                                          |
//+------------------------------------------------------------------+
#define NR_CONDITIONS 2            // number of conditions 

//+------------------------------------------------------------------+
//| Include                                                          |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>

//+------------------------------------------------------------------+
//| Global Variable                                                  |
//+------------------------------------------------------------------+
enum MODE{
   OPEN=0,  
   HIGH=1,  
   LOW=2,   
   CLOSE=3, 
   RANGE=4,
   BODY=5,
   RATIO=6,
   VALUE=7,
};

enum INDEX{
   INDEX_0=0,
   INDEX_1=1,
   INDEX_2=2,
   INDEX_3=3,
};

enum COMPARE {
   GREATER,
   LESS,
};

struct CONDITION{
   bool active;
   MODE modeA;
   INDEX idxA;
   COMPARE comp;
   MODE modeB;
   INDEX idxB;
   double value;
   
   CONDITION() : active(false){};
};

CONDITION con[NR_CONDITIONS];                                   // condition array
MqlTick currentTick;                                            // current tick of the symbol
CTrade trade;                                                   // object to open/close positions


//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
input group "====== General =======";
static input long       InpMagicnumber = 12345123545;           // magicnumber

enum LOT_MODE_ENUM {
    LOT_MODE_FIXED,     // fixed lots
    LOT_MODE_MONEY,     // lots based on money
    LOT_MODE_PCT_ACCOUNT // lots based on % of account
};

input LOT_MODE_ENUM InpLotMode = LOT_MODE_FIXED; // lot mode
static input double     InpLots        = 0.01;                  // lots / money / %
input int               InpStopLoss    = 100;                   // Stop loss in points (0 = Off)
input int               InpTakeProfit  = 200;                   // Takle Profit in points (O=Off)

input group "====== Condition 1 =======";
input bool              InpCon1Active  = true;                  // Active
input MODE              InpCon1ModeA   = OPEN;                  // Mode A
input INDEX             InpCon1IndexA  = INDEX_1;               // Index A
input COMPARE           InpCon1Compare = GREATER;               // compare
input MODE              InpCon1ModeB   = CLOSE;                 // Mode B
input INDEX             InpCon1IndexB  = INDEX_1;               // Index B
input double            InpCon1Value   = 0;                     // Value

input group "====== Condition 2 =======";
input bool              InpCon2Active  = false;                 // Active
input MODE              InpCon2ModeA   = OPEN;                  // Mode A
input INDEX             InpCon2IndexA  = INDEX_1;               // Index A
input COMPARE           InpCon2Compare = GREATER;               // compare
input MODE              InpCon2ModeB   = CLOSE;                 // Mode B
input INDEX             InpCon2IndexB  = INDEX_1;               // Index B
input double            InpCon2Value   = 0;                     // Value


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   // set inputs (before we check inputs)
   SetInputs();
   
   // check inputs
   if(!CheckInputs()) {return INIT_PARAMETERS_INCORRECT;}
   
   // set magicnumber
   trade.SetExpertMagicNumber(InpMagicnumber);

   return(INIT_SUCCEEDED);
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
  // check if current tick is a new bar open tick
  if(!IsNewBar()){return;}
  
  //get current symbol tick
  if(!SymbolInfoTick(_Symbol,currentTick)){Print("Faled to get current tick");return;}
  
  // count open positions
  int cntBuy, cntSell;
  if(!CountOpenPositions(cntBuy,cntSell)){Print("Failed to get count open positions");return;}
  
  // check for new buy position
  if(cntBuy==0 && CheckAllConditions(true)) {
  
   // calculate stop loss and take profit
   double sl = InpStopLoss==0 ? 0 : currentTick.bid - InpStopLoss *_Point;
   double tp = InpTakeProfit==0 ? 0 : currentTick.bid + InpTakeProfit *_Point;
   if(!NormalizePrice(sl)){return;}
   if(!NormalizePrice(tp)){return;}

   // calculate lots
   double lots;
   if (!CalculateLots(currentTick.bid-sl,lots)){return;}
   
   trade.PositionOpen(_Symbol,ORDER_TYPE_BUY,lots,currentTick.ask,sl,tp,"CandlePatternEA");
  }
  // check for new sell position
  if(cntSell==0 && CheckAllConditions(false)) {
  
   // calculate stop loss and take profit
   double sl = InpStopLoss==0 ? 0 : currentTick.ask + InpStopLoss *_Point;
   double tp = InpTakeProfit==0 ? 0 : currentTick.ask - InpTakeProfit *_Point;
   if(!NormalizePrice(sl)){return;}
   if(!NormalizePrice(tp)){return;}

   // calculate lots
   double lots;
   if (!CalculateLots(sl-currentTick.ask,lots)){return;}
   
   trade.PositionOpen(_Symbol,ORDER_TYPE_SELL,lots,currentTick.bid,sl,tp,"CandlePatternEA");
  }
   
}

//+------------------------------------------------------------------+
//| Custom funtions                                                  |
//+------------------------------------------------------------------+
void SetInputs() {

   // condition 1 
   con[0].active       = InpCon1Active;
   con[0].modeA        = InpCon1ModeA;
   con[0].idxA         = InpCon1IndexA;
   con[0].comp         = InpCon1Compare;
   con[0].modeB        = InpCon1ModeB;
   con[0].idxB         = InpCon1IndexB;
   con[0].value        = InpCon1Value;
   
   // condition 2
   con[1].active       = InpCon2Active;
   con[1].modeA        = InpCon2ModeA;
   con[1].idxA         = InpCon2IndexA;
   con[1].comp         = InpCon2Compare;
   con[1].modeB        = InpCon2ModeB;
   con[1].idxB         = InpCon2IndexB;
   con[1].value        = InpCon2Value;
      
}


bool CheckInputs(){

   if(InpMagicnumber<=0) {
      Alert("Wrong input: Magicnumber <= 0");
      return false;
   }
   if (InpLotMode==LOT_MODE_FIXED && (InpLots <= 0 || InpLots > 10)){
      Alert("Lots <= 0 or > 10");
      return false;
   }
   if (InpLotMode==LOT_MODE_MONEY && (InpLots <= 0 || InpLots > 1000)) {
      Alert("Lots <= 0 or > 1000");
      return false;
   }
   if (InpLotMode==LOT_MODE_PCT_ACCOUNT && (InpLots <= 0 || InpLots > 5)) {
      Alert("Lots <= 0 or > 5");
      return false;
   }
   if ((InpLotMode==LOT_MODE_MONEY || InpLotMode==LOT_MODE_PCT_ACCOUNT) && InpStopLoss==0){
      Alert("Selected lot mode needs a stop loss");
      return false;
   }
   if(InpStopLoss<0) {
      Alert("Wrong input: Stop Loss < 0");
      return false;
   }
   if(InpTakeProfit<0) {
      Alert("Wrong input: Take Profit <=0");
      return false;
   }
   
   // check conditions +++
   
   return true;
}



bool CheckAllConditions(bool buy_sell)
{
   // check each condition
   for(int i=0; i<NR_CONDITIONS;i++) {
      if(!CheckOneCondition(buy_sell,i)){return false;}
   }

   return true;
}


bool CheckOneCondition(bool buy_sell, int i)
{
   // return true if condition is not active
   if(!con[i].active){return true;}
   
   // get bar data
   MqlRates rates[];
   ArraySetAsSeries(rates,true);
   int copied = CopyRates(_Symbol,PERIOD_CURRENT,0,4,rates);
   if(copied!=4){
      Print("Failed to get bar data. copied:",(string)copied);
      return false;
   }
   
   // set values to a and b
   double a=0;
   double b=0;
   switch(con[i].modeA){
      case OPEN:  a = rates[con[i].idxA].open; break;
      case HIGH:  a = buy_sell ? rates[con[i].idxA].high : rates[con[i].idxA].low; break;
      case LOW:   a = buy_sell ? rates[con[i].idxA].low : rates[con[i].idxA].high; break;
      case CLOSE: a = rates[con[i].idxA].close; break;
      case RANGE: a = (rates[con[i].idxA].high - rates[con[i].idxA].low) / _Point; break;
      case BODY:  a = MathAbs(rates[con[i].idxA].open - rates[con[i].idxA].close) / _Point; break;
      case RATIO: a = MathAbs(rates[con[i].idxA].open - rates[con[i].idxA].close) /
                       (rates[con[i].idxA].high - rates[con[i].idxA].low); break;
      case VALUE: a = con[i].value; break;
      default:    return false;
   }
      switch(con[i].modeB){
      case OPEN:  b = rates[con[i].idxB].open; break;
      case HIGH:  b = buy_sell ? rates[con[i].idxB].high : rates[con[i].idxB].low; break;
      case LOW:   b = buy_sell ? rates[con[i].idxB].low : rates[con[i].idxB].high; break;
      case CLOSE: b = rates[con[i].idxB].close; break;
      case RANGE: b = (rates[con[i].idxB].high - rates[con[i].idxB].low) / _Point; break;
      case BODY:  b = MathAbs(rates[con[i].idxB].open - rates[con[i].idxB].close) / _Point; break;
      case RATIO: b = MathAbs(rates[con[i].idxB].open - rates[con[i].idxB].close) /
                       (rates[con[i].idxB].high - rates[con[i].idxB].low); break;
      case VALUE: b = con[i].value; break;
      default:    return false;
   }
   
   // compare values
   if(buy_sell || (!buy_sell && con[i].modeA>=4)){
      if(con[i].comp==GREATER && a>b) {return true;}
      if(con[i].comp==LESS && a<b) {return true;} 
   }
   else{
      if(con[i].comp==GREATER && a<b) {return true;}
      if(con[i].comp==LESS && a>b) {return true;}
   
   
   }
   
   return false;
}

// check if we have a bar open tick
bool IsNewBar () {

   static datetime previousTime = 0;
   datetime currentTime = iTime(_Symbol,PERIOD_CURRENT,0);
   if(previousTime!=currentTime){
      previousTime=currentTime;
      return true;
   }
   return false;
}


// count open positions
bool CountOpenPositions(int &cntBuy, int &cntSell) {

   cntBuy  = 0;
   cntSell = 0;
   int total = PositionsTotal();
   for(int i=total-1; i>=0; i--){
   ulong ticket = PositionGetTicket(i);
   if(ticket<=0){Print("Failed to get position ticket"); return false;}
   if(!PositionSelectByTicket(ticket)){Print("Failed to select position"); return false;}
   long magic;
   if(!PositionGetInteger(POSITION_MAGIC,magic)){Print("Failed to get position magicnumber"); return false;}
   if(magic==InpMagicnumber){
      long type;
      if(!PositionGetInteger(POSITION_TYPE,type)){Print("Failed to get position type"); return false;}
      if(type==POSITION_TYPE_BUY){cntBuy++;}
      if(type==POSITION_TYPE_SELL){cntSell++;}
    }
  }
  
  return true;
}


// normalize price
bool NormalizePrice(double &price){

   double tickSize=0;
   if(!SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE,tickSize)){
      Print("Failed to get tick size");
      return false;
  }
  price =NormalizeDouble(MathRound(price/tickSize)*tickSize,_Digits);
  
  return true;
}   

// calculate lots
bool CalculateLots(double sldistance, double &lots) {

    lots = 0.0;
    if (InpLotMode==LOT_MODE_FIXED) {
        lots = InpLots;
    } 
    else{
        double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
        double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
        double volumeStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
        
        double riskMoney = InpLotMode==LOT_MODE_MONEY ? InpLots : AccountInfoDouble(ACCOUNT_EQUITY) * InpLots * 0.01;
        double moneyVolumeStep = (sldistance / tickSize) * tickValue * volumeStep;
        
        lots = MathFloor(riskMoney / moneyVolumeStep) * volumeStep;
    }
    
    // check calculated lots
    if (!CheckLots(lots)) return false;
    
    return true;
}

// check lots for min, max and step
bool CheckLots(double &lots) {

    double min = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double max = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

    if (lots < min) {
        Print("Lot size will be set to the minimum allowable volume");
        lots = min;
        return true;
    }
    if (lots > max) {
        Print("Lot size greater than the maximum allowable volume. Lots:", lots, "Max:", max);
        return false;
    }

    lots = (int)MathFloor(lots/step) * step;

    return true;
}


