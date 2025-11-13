//+------------------------------------------------------------------+
//|                                                  TestMA ver2.mq5 |
//|                                                   RintaroYamaoka |
//|              https://www.instagram.com/void0ntrick/?locale=ja_JP |
//+------------------------------------------------------------------+
#property copyright "RintaroYamaoka"
#property link      "https://www.instagram.com/void0ntrick/?locale=ja_JP"
#property version   "2.00"

#include "..\\..\\Versions\\MyTradeModules20251109\\EAFrame.mqh"
#include "Modules\\Frame.mqh"

// ポインタ宣言
C_Frame *ea = NULL;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   ea = new C_Frame(MagicNo, _Symbol, Timeframe, Slippage, LotSize, MAPeriod);
   Print("TestMA ver2 Initialized.");                 
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    if(ea != NULL)
    {
        delete ea;
        Print("TestEA ver2 Deinitialized.");
    }
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    if(ea != NULL) ea.OnTickMethod();
}
//+------------------------------------------------------------------+
