//+------------------------------------------------------------------+
//|                             TestMA ver2 LimitedTest RSIEntry.mq5 |
//|                                                   RintaroYamaoka |
//|              https://www.instagram.com/void0ntrick/?locale=ja_JP |
//+------------------------------------------------------------------+
#property copyright "RintaroYamaoka"
#property link      "https://www.instagram.com/void0ntrick/?locale=ja_JP"
#property version   "2.00"

#include "Modules\\Frame.mqh"
#include "..\\..\\Versions\\TestModules20251109\\LimitedTest_RSIEntry.mqh"

class C_Frame_RSIEntry : public C_Frame
{
public:
    C_Frame_RSIEntry(ulong magic_no, string symbol, ENUM_TIMEFRAMES time_frame,
                          int slippage, double lot, int ma_period)
        : C_Frame(magic_no, symbol, time_frame, slippage, lot, ma_period)
    {
        // 親クラスで生成されたEntryを差し替え
        if(buy != NULL) delete buy;
        buy = new C_RSIBuy(&order, &position, &bar, sym, period);
        if(sell != NULL) delete sell;
        sell = new C_RSISell(&order, &position, &bar, sym, period);
    }    
};

// ポインタ宣言
C_Frame_RSIEntry *ea = NULL;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   ea = new C_Frame_RSIEntry(MagicNo, _Symbol, Timeframe, Slippage, LotSize, MAPeriod);
   Print("TestMA ver2 LimitedTest BreakoutEntry Initialized.");                 
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
        Print("TestEA ver2 LimitedTest BreakoutEntry Deinitialized.");
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
