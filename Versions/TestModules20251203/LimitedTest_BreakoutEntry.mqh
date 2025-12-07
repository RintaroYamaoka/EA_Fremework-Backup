//+------------------------------------------------------------------+
//|                                    LimitedTest BreakoutEntry.mqh |
//|                                                   RintaroYamaoka |
//|              https://www.instagram.com/void0ntrick/?locale=ja_JP |
//+------------------------------------------------------------------+
#property copyright "RintaroYamaoka"
#property link      "https://www.instagram.com/void0ntrick/?locale=ja_JP"

#include "..\\..\\Versions\\MyTradeModules20251203\\EAFrame.mqh"
#include "..\\..\\Versions\\MyTradeModules20251203\\OrderModule.mqh"
#include "..\\..\\Versions\\MyTradeModules20251203\\PositionModule.mqh"
#include "..\\..\\Versions\\MyTradeModules20251203\\SignalModule.mqh"
//+------------------------------------------------------------------+
// 限定的検証 エントリー差し替えテスト用モジュール（トレンドフォロー戦略）
//+------------------------------------------------------------------+

// テスト専用パラメータ

input int Test_Breakout_Bars = 5;
input double Test_LotSize = 1.0;    

class C_TestBreakEntry : public C_EntryBase
{
private:
    C_Order *_order;
    C_Position *_position;
    C_BarData *_bar_data;
    string _symbol;
    ENUM_TIMEFRAMES _period;
    bool _pos_check;
    double _lot;
    datetime _last_time;
    
public:
    C_TestBreakEntry(C_Order *order, 
                     C_Position *position,
                     C_BarData *bar_data,
                     string symbol,
                     ENUM_TIMEFRAMES period,
                     bool pos_check = true)
        : _order(order),
          _position(position),
          _bar_data(bar_data),
          _symbol(symbol),
          _period(period),
          _pos_check(pos_check),
          _lot(Test_LotSize),
          _last_time(0)
    {
    }
    
    
    void Process() override
    {
        // 新バー確定時のみ実行
        MqlRates current_bar;
        _bar_data.GetStInfo(0, current_bar);
        if (current_bar.time == _last_time) return;
        _last_time = current_bar.time;

        // ポジションチェック
        C_Position::POSITION p[];
        int pos_count = _position.CopyStArray(p);
        if(_pos_check && pos_count > 0) return;
        
        // 高値安値ライン取得 
        double highest = -DBL_MAX;
        double lowest = DBL_MAX;
        for(int i=2; i<=Test_Breakout_Bars + 1; i++)
        {
            double high = iHigh(_symbol, _period, i);
            double low = iLow(_symbol, _period, i);
            if(high > highest) highest = high;
            if(low > lowest) lowest = low;
        }

        // エントリー判定（ブレイクアウト）
        double close = iClose(_symbol, _period, 1);
        if(close > highest)
        {
            _order.Entry(true, _lot, 0, 0);
            Print("Buy Execute: 高値ブレイクアウト");
        }
        if(close < lowest)
        {
            _order.Entry(false, _lot, 0, 0);
            Print("Sell Execute: 安値ブレイクアウト");
        }
    }
};


