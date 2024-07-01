//+------------------------------------------------------------------+
//| Properties                                                       |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, trustfultrading"
#property link      "https://www.trustfultrading.com"
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
static input long   InpMagicnumber     = 5555353;   // magic number
static input double InpLotsize         = 0.01;     
input group "=== Trading ==="
input double InpTriggerLvl     = 2.0;   // trigger level as factor of ATR
input double InpStopLossATR    = 5.0;   // stop loss as factor of ATR (0=off)
enum TP_MODE_ENUM{
  TP_MODE_ATR,  // tp as factor of ATR
  TP_MODE_MA    // tp at MA
};
input TP_MODE_ENUM InpTPMode = TP_MODE_ATR; // tp mode
input double InpTakeProfitATR = 4.0;        // tp as factor of ATR (0=off)
input bool InpCloseBySignal   = false;      // close trades by opposite signal
input group "=== Moving Average ==="
input int InpPeriodMA         = 21;         // MA period
input group "=== Average True Range ==="
input int InpPeriodATR        = 21;         // ATR period

//+------------------------------------------------------------------+
//| Global Variable                                                  |
//+------------------------------------------------------------------+
int handleMA;
int handleATR;
double bufferMA[];
double bufferATR[];
MqlTick tick;
CTrade trade;
CPositionInfo position;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit(){

   // check user inputs
   if(!CheckInputs()) {return INIT_PARAMETERS_INCORRECT;}

   // set magic number to trade object
   trade.SetExpertMagicNumber(InpMagicnumber);

   // create indicator handles
   handleMA = iMA(_Symbol, PERIOD_CURRENT, InpPeriodMA, 0, MODE_SMA, PRICE_CLOSE);
   if(handleMA == INVALID_HANDLE){
      Alert("Failed to create MA handle");
      return INIT_FAILED;
   }
   handleATR = iATR(_Symbol, PERIOD_CURRENT, InpPeriodATR);
   if(handleATR == INVALID_HANDLE){
      Alert("Failed to create ATR handle");
      return INIT_FAILED;
   }
   
   // set buffers as series
   ArraySetAsSeries(bufferMA, true);
   ArraySetAsSeries(bufferATR, true);

   // draw MA indicator on chart
   ChartIndicatorDelete(NULL, 0, "MA(" + IntegerToString(InpPeriodMA) + ")");
   ChartIndicatorAdd(NULL, 0, handleMA);
   ChartIndicatorDelete(NULL, 0, "ATR(" + IntegerToString(InpPeriodATR) + ")");
   ChartIndicatorAdd(NULL, 0, handleATR);

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert Deinitialization Function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason){

  // release indicator handle
  if(handleMA != INVALID_HANDLE) {
    ChartIndicatorDelete(NULL, 0, "MA(" + IntegerToString(InpPeriodMA) + ")");
    IndicatorRelease(handleMA);
  }
  if(handleATR != INVALID_HANDLE) {
    ChartIndicatorDelete(NULL, 1, "ATR(" + IntegerToString(InpPeriodATR) + ")");
    IndicatorRelease(handleATR);
  }
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick(){

  // get current tick
  if(!SymbolInfoTick(_Symbol, tick)) {
      Print("Failed to get current tick");
      return;
  }

  // get MA and ATR values
  int values = CopyBuffer(handleMA, 0, 0, 1, bufferMA) + CopyBuffer(handleATR, 0, 0, 1, bufferATR);
  if(values != 2) {
      Print("Failed to get indicator values");
      return;
  }
  double MA = bufferMA[0];
  double ATR = bufferATR[0];
  Comment("MA: ", MA, " ATR: ", ATR);

  // count open positions
  int cntBuy, cntSell;
  CountOpenPositions(cntBuy, cntSell);

// check for a new buy position
if(cntBuy==0 && tick.ask <= MA-ATR*InpTriggerLvl) {

  // close sell trade
  if(InpCloseBySignal){ClosePositions(false);}

  // calculate sl/tp
  double sl = InpStopLossATR==0 ? 0 : tick.bid - ATR*InpStopLossATR;
  double tp = InpTPMode==TP_MODE_MA ? 0 : InpTakeProfitATR==0 ? 0 : ATR*InpTakeProfitATR;

  // normalize price
  if (!NormalizePrice(sl)) { return; }
  if (!NormalizePrice(tp)) { return; }


  // open buy position
  trade.PositionOpen(_Symbol,ORDER_TYPE_BUY,InpLotsize,tick.ask,sl,tp,"MA Pullback EA");

}

// check for a new sell position
if(cntSell==0 && tick.bid >= MA+ATR*InpTriggerLvl) {

  // close sell trade
  if (InpCloseBySignal) { ClosePositions(true); }

  // calculate sl/tp
  double sl = InpStopLossATR==0 ? 0 : tick.ask + ATR*InpStopLossATR;
  double tp = InpTPMode==TP_MODE_MA ? 0 : InpTakeProfitATR==0 ? 0 : tick.bid - ATR*InpTakeProfitATR;

  // normalize price
  if (!NormalizePrice(sl)) { return; }
  if (!NormalizePrice(tp)) { return; }


  // open sell position
  trade.PositionOpen(_Symbol,ORDER_TYPE_SELL,InpLotsize,tick.bid,sl,tp,"MA Pullback EA");
}

// check position take profit at MA
if(cntBuy>0 && InpTPMode==TP_MODE_MA && tick.bid >= MA) { ClosePositions(true); }
if(cntSell>0 && InpTPMode==TP_MODE_MA && tick.ask <= MA) { ClosePositions(false); }


DrawObjects(MA,ATR);
}


//+------------------------------------------------------------------+
//| Custom functions                                                 |
//+------------------------------------------------------------------+

bool CheckInputs(){

    if(InpMagicnumber <= 0){
      Alert("Wrong input: Magicnumber <= 0");
      return false;
    }   
    if(InpLotsize <= 0){
      Alert("Wrong input: Lot Size<= 0");
      return false;
    }   
    if(InpTriggerLvl <= 0){
      Alert("Wrong input: Trigger level <= 0");
      return false;
    }
    if(InpStopLossATR <= 0){
      Alert("Wrong input: Magicnumber <= 0"); 
      return false;
    }
    if(InpTPMode==TP_MODE_ATR && InpTakeProfitATR < 0){
      Alert("Wrong input: Take profit < 0");
      return false;
    }
    if(InpPeriodMA <= 1) {
      Alert("Wrong input: MA period <= 1");
      return false;
    }
    if(InpPeriodATR <= 1) {
      Alert("Wrong input: ATR period <= 1");
      return false;
    }


    return true;
}

// normalize price
bool NormalizePrice(double &price) {

    double tickSize = 0;
    if (!SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE, tickSize)) {
        Print("Failed to get tick size");
        return false;
    }
    price = NormalizeDouble((price/tickSize)*tickSize, _Digits);

    return true;
}


// count open positions
void CountOpenPositions(int &cntBuy, int &cntSell){

    cntBuy = 0;
    cntSell = 0;
    int total = PositionsTotal();
    for(int i = total-1; i >= 0; --i) {
        position.SelectByIndex(i);
            if(position.Magic() == InpMagicnumber){
                if(position.PositionType()==POSITION_TYPE_BUY) {cntBuy++;}
                if(position.PositionType()==POSITION_TYPE_SELL) {cntSell++;}
        }
    }
}


// close positions
void ClosePositions(bool buy_sell) {

    int total = PositionsTotal();
    for (int i = total - 1; i >= 0; --i) {
        position.SelectByIndex(i);
        if (position.Magic() == InpMagicnumber) {
            if (buy_sell && position.PositionType() == POSITION_TYPE_SELL) continue;
            if (!buy_sell && position.PositionType() == POSITION_TYPE_BUY) continue;
            trade.PositionClose(position.Ticket());
        }
    }
}



// draw trigger levels above and beneath the MA
void DrawObjects(double maValue, double atrValue) {

    ObjectDelete(NULL, "TriggerBuy");
    ObjectCreate(NULL, "TriggerBuy", OBJ_HLINE, 0, 0, maValue + atrValue * InpTriggerLvl);
    ObjectSetInteger(NULL, "TriggerBuy", OBJPROP_COLOR, clrBlue);

    ObjectDelete(NULL, "TriggerSell");
    ObjectCreate(NULL, "TriggerSell", OBJ_HLINE, 0, 0, maValue - atrValue * InpTriggerLvl);
    ObjectSetInteger(NULL, "TriggerSell", OBJPROP_COLOR, clrBlue);

}

