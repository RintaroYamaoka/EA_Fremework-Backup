//+------------------------------------------------------------------+
//|                            TestMA ver2 LimitedTest FixedSLTP.mq5 |
//|                                                   RintaroYamaoka |
//|              https://www.instagram.com/void0ntrick/?locale=ja_JP |
//+------------------------------------------------------------------+
#property copyright "RintaroYamaoka"
#property link      "https://www.instagram.com/void0ntrick/?locale=ja_JP"
#property version   "2.00"

#include "..\\..\\Versions\\TestModules20251109\\LimitedTest_FixedSLTPClose.mqh"
#include "Modules\\Frame.mqh"

class C_Frame_LimitedFixedSLTP : public C_Frame
{
public:
    C_Frame_LimitedFixedSLTP(ulong magic_no, string symbol, ENUM_TIMEFRAMES time_frame,
                             int slippage, double lot, int ma_period)
        : C_Frame(magic_no, symbol, time_frame, slippage, lot, ma_period)
    {
        // 親クラスで生成されたexitを差し替え
        if(exit != NULL) delete exit;
        exit = new C_ExitFixedSLTP(&order, &position);
    }    
};

// ポインタ宣言
C_Frame_LimitedFixedSLTP *ea = NULL;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   ea = new C_Frame_LimitedFixedSLTP(MagicNo, _Symbol, Timeframe, Slippage, LotSize, MAPeriod);
   Print("TestMA ver2 LimitedFixedSLTP Initialized.");                 
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
        Print("TestEA ver2 LimitedFixedSLTP Deinitialized.");
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
