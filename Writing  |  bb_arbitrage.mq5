//+------------------------------------------------------------------+
//|                                       Bollingerbandarbitrage.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade/Trade.mqh>
CTrade trade;

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

input group "Trading"
input double positionSize = 0.1;
input int stopLoss = 200;
input int takeProfit = 200; // Nouveau paramètre de take profit

double SL, TP;

int bbHandle, maHandle;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
    // Initialisation des indicateurs
    bbHandle = iBands(_Symbol, bbTimeframe, bbPeriod, 1, bbStd, bbAppPrice);
    maHandle = iMA(_Symbol, maTimeframe, maPeriod, 0, maMethod, maAppPrice);
    SL = stopLoss * _Point;
    TP = takeProfit * _Point;
    return (INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
    // Code de déinitialisation si nécessaire
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
    // Vérification des prix actuels
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double lastCandleClosePrice = iClose(_Symbol, bbTimeframe, 1);

    // Buffers pour les bandes de Bollinger et la moyenne mobile
    double bbUpper[], bbLower[], bbBase[], ma[];

    CopyBuffer(bbHandle, BASE_LINE, 0, 1, bbBase);
    CopyBuffer(bbHandle, UPPER_BAND, 0, 1, bbUpper);
    CopyBuffer(bbHandle, LOWER_BAND, 0, 1, bbLower);
    CopyBuffer(maHandle, 0, 0, 1, ma);

    // Vérification des conditions d'ouverture de position
    if (lastCandleClosePrice > bbUpper[0] && !isTradeOpen(_Symbol, POSITION_TYPE_SELL) && bid < ma[0])
    {
        trade.Sell(positionSize, _Symbol, bid, bid + SL, bid - TP);
    }
    if (lastCandleClosePrice < bbLower[0] && !isTradeOpen(_Symbol, POSITION_TYPE_BUY) && ask > ma[0])
    {
        trade.Buy(positionSize, _Symbol, ask, ask - SL, ask + TP);
    }

    // Vérification des conditions de clôture de position
    if (PositionSelect(_Symbol))
    {
        double posPrice = PositionGetDouble(POSITION_PRICE_OPEN);
        long posType = PositionGetInteger(POSITION_TYPE);

        if (posType == POSITION_TYPE_SELL && bid < bbBase[0])
        {
            trade.PositionClose(PositionGetInteger(POSITION_TICKET));
        }
        else if (posType == POSITION_TYPE_BUY && ask > bbBase[0])
        {
            trade.PositionClose(PositionGetInteger(POSITION_TICKET));
        }
    }
  }
//+------------------------------------------------------------------+

// Fonction pour vérifier si une position est ouverte
bool isTradeOpen(string symbol, long positionType)
{
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if (PositionSelect(i) && PositionGetString(POSITION_SYMBOL) == symbol && PositionGetInteger(POSITION_TYPE) == positionType)
        {
            return true;
        }
    }
    return false;
}
