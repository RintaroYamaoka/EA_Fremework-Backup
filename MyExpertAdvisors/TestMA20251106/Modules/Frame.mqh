//+------------------------------------------------------------------+
//|                                                        Frame.mqh |
//|                                                   RintaroYamaoka |
//|              https://www.instagram.com/void0ntrick/?locale=ja_JP |
//+------------------------------------------------------------------+
#property copyright "RintaroYamaoka"
#property link      "https://www.instagram.com/void0ntrick/?locale=ja_JP"

#include "..\\..\\..\\Versions\\MyTradeModules20251109\\EAFrame.mqh"

#include "Parameter.mqh"
#include "Filter.mqh"
#include "Buy.mqh"
#include "Sell.mqh"
#include "Exit.mqh"

// EAフレーム
class C_Frame : public C_EAFrame
{
protected:
    C_Order order;
    C_Position position;
    C_BarData bar;
    
    C_Indicator *ma;
    C_FilterBase *filter;
    C_BuyBase *buy;
    C_SellBase *sell;
    C_ExitBase *exit;
    
    datetime last_time;

public:
    C_Frame(ulong magic_no, string symbol, ENUM_TIMEFRAMES time_frame,
            int slippage, double lot, int ma_period)
        : C_EAFrame(magic_no, symbol, time_frame),
          order(magic_no, slippage, symbol),
          position(magic_no, symbol),
          bar(symbol, time_frame)
    {
        last_time = 0;
        
        // インジケータ生成
        int handle = iMA(symbol, time_frame, ma_period, 0, MODE_SMA, PRICE_CLOSE);
        ma = new C_Indicator(handle);
        
        // フィルタ・売買・決済ロジックの生成と配線
        filter = new C_BasicFilter();
        buy = new C_Buy(&order, &bar, ma, filter, lot);
        sell = new C_Sell(&order, &bar, ma, filter, lot);
        exit = new C_Exit(&order, &position, &bar, ma);
        
        PrintFormat("C_EAFramework Initialized: %s, TF=%s, MA=%d",
                    symbol, EnumToString(time_frame), ma_period);
    }
    
    
    virtual ~C_Frame()
    {
        if(ma) delete ma;
        if(buy) delete buy;
        if(sell) delete sell;
        if(exit) delete exit;
        if(filter) delete filter;
    }  
    
    
    void OnTickMethod() override
    {
        exit.Process();
        C_Position::POSITION p[];
        if(position.CopyStArray(p) > 0) return;
        buy.Process();
        sell.Process();
    }            
};


