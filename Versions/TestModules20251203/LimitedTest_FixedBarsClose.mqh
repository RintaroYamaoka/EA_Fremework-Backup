//+------------------------------------------------------------------+
//|                                   LimitedTest FixedBarsClose.mqh |
//|                                                   RintaroYamaoka |
//|              https://www.instagram.com/void0ntrick/?locale=ja_JP |
//+------------------------------------------------------------------+
#property copyright "RintaroYamaoka"
#property link      "https://www.instagram.com/void0ntrick/?locale=ja_JP"

#include "..\\..\\Versions\\MyTradeModules20251109\\EAFrame.mqh"
#include "..\\..\\Versions\\MyTradeModules20251109\\OrderModule.mqh"
#include "..\\..\\Versions\\MyTradeModules20251109\\PositionModule.mqh"
//+------------------------------------------------------------------+
// 限定的検証 固定バー本数での手仕舞いテスト用モジュール
//+------------------------------------------------------------------+

// テスト専用パラメータ
input int Test_FixedBars = 10;

class C_TestFixedBarsClose : public C_ExitBase
{
private:
    C_Order *_order;
    C_Position *_position;
    string _symbol;
    ENUM_TIMEFRAMES _period;
    
    struct ENTRY_INFO
    {
        ulong ticket;
        datetime entry_time;
        int entry_bar;
    };
    
    ENTRY_INFO info[];

public:
    C_TestFixedBarsClose(C_Order *order, 
                         C_Position *position,
                         string symbol, 
                         ENUM_TIMEFRAMES period)
        : _order(order),
          _position(position),
          _symbol(symbol),
          _period(period)
    {
    }
    
    
    void Process() override
    {
        C_Position::POSITION p[];
        int total = _position.CopyStArray(p);
        if(total <= 0) return;
        
        datetime last_bar_time = iTime(_symbol, _period, 0); 
        
        for(int i = 0; i < total; i++)
        {
            PositionSelectByTicket(p[i].ticket);
            int open_bar_index = iBarShift(_symbol, _period, PositionGetInteger(POSITION_TIME));
            int current_bar = iBarShift(_symbol, _period, last_bar_time);
            
            if(open_bar_index - current_bar >= Test_FixedBars)
            {
                _order.Close((int)p[i].ticket);
            }
        }
    }
};

