//+------------------------------------------------------------------+
//|                                        LimitedTest FixedBars.mqh |
//|                                                   RintaroYamaoka |
//|              https://www.instagram.com/void0ntrick/?locale=ja_JP |
//+------------------------------------------------------------------+
#property copyright "RintaroYamaoka"
#property link      "https://www.instagram.com/void0ntrick/?locale=ja_JP"

#include "..\\Versions\\MyTradeModules20251109\\EAFrame.mqh"
#include "..\\Versions\\MyTradeModules20251109\\OrderModule.mqh"
#include "..\\Versions\\MyTradeModules20251109\\PositionModule.mqh"
//+------------------------------------------------------------------+
// 限定的検証 固定バー本数での手仕舞いテスト用モジュール
//+------------------------------------------------------------------+

// テスト専用パラメータ
input int Test_FixedBars = 10;

class C_ExitFixedBars : public C_ExitBase
{
private:
    C_Order *order;
    C_Position *pos;
    string symbol;
    ENUM_TIMEFRAMES period;
    
    struct ENTRY_INFO
    {
        ulong ticket;
        datetime entry_time;
        int entry_bar;
    };
    
    ENTRY_INFO info[];

public:
    C_ExitFixedBars(C_Order *_order, C_Position *_pos, string _symbol, ENUM_TIMEFRAMES _period)
    {
        order = _order;
        pos = _pos;
        symbol = _symbol;
        period = _period;
    }
    
    
    void Process() override
    {
        C_Position::POSITION p[];
        int total = pos.CopyStArray(p);
        if(total <= 0) return;
        
        datetime last_bar_time = iTime(symbol, period, 0); 
        
        for(int i = 0; i < total; i++)
        {
            PositionSelectByTicket(p[i].ticket);
            int open_bar_index = iBarShift(symbol, period, PositionGetInteger(POSITION_TIME));
            int current_bar = iBarShift(symbol, period, last_bar_time);
            
            if(open_bar_index - current_bar >= Test_FixedBars)
            {
                order.Close((int)p[i].ticket);
            }
        }
    }
};

