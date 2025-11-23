//+------------------------------------------------------------------+
//|                                    LimitedTest BreakoutEntry.mqh |
//|                                                   RintaroYamaoka |
//|              https://www.instagram.com/void0ntrick/?locale=ja_JP |
//+------------------------------------------------------------------+
#property copyright "RintaroYamaoka"
#property link      "https://www.instagram.com/void0ntrick/?locale=ja_JP"

#include "..\\..\\Versions\\MyTradeModules20251109\\EAFrame.mqh"
#include "..\\..\\Versions\\MyTradeModules20251109\\OrderModule.mqh"
#include "..\\..\\Versions\\MyTradeModules20251109\\PositionModule.mqh"
#include "..\\..\\Versions\\MyTradeModules20251109\\SignalModule.mqh"
//+------------------------------------------------------------------+
// 限定的検証 エントリー差し替えテスト用モジュール（トレンドフォロー戦略）
//+------------------------------------------------------------------+

// テスト専用パラメータ

input int Test_Breakout_Bars = 5;
input double Test_LotSize = 1.0;    

class C_BreakoutBuy : public C_BuyBase
{
private:
    C_Order *order;
    C_Position *pos;
    C_BarData *bar;
    string sym;
    ENUM_TIMEFRAMES period;
    double lot;
    bool pos_check;
    datetime last_time;
    
public:
    C_BreakoutBuy(C_Order *_order, C_Position *_position, C_BarData *_bar,
                  string _symbol, ENUM_TIMEFRAMES _period, bool position_check = true)
    {
        order = _order;
        pos = _position;
        bar = _bar;
        sym = _symbol;
        period = _period;
        lot = Test_LotSize;
        pos_check = position_check; 
        last_time = 0;
    }
    
    
    void Process() override
    {
        // 新バー確定時のみ実行
        MqlRates current_bar;
        bar.GetStInfo(0, current_bar);
        if (current_bar.time == last_time) return;
        last_time = current_bar.time;

        // ポジションチェック
        C_Position::POSITION p[];
        int pos_count = pos.CopyStArray(p);
        if(pos_check && pos_count > 0) return;
         
        double highest = -DBL_MAX;
        for(int i=2; i<=Test_Breakout_Bars + 1; i++)
        {
            double v = iHigh(sym, period, i);
            if(v > highest) highest = v;
        }

        // 終値が最高値を超えたらブレイクアウト
        double close = iClose(sym, period, 1);

        if(close > highest)
        {
            order.Entry(true, lot, 0, 0);
            Print("Buy Execute: 高値ブレイクアウト");
        }
    }
};

class C_BreakoutSell : public C_SellBase
{
private:
    C_Order *order;
    C_Position *pos;
    C_BarData *bar;
    string sym;
    ENUM_TIMEFRAMES period;
    double lot;
    bool pos_check;
    datetime last_time;
    
public:
    C_BreakoutSell(C_Order *_order, C_Position *_position, C_BarData *_bar,
                  string _symbol, ENUM_TIMEFRAMES _period, bool position_check = true)
    {
        order = _order;
        pos = _position;
        bar = _bar;
        sym = _symbol;
        period = _period;
        lot = Test_LotSize;
        pos_check = position_check;
        last_time = 0; 
    }
    
    
    void Process() override
    {
        // 新バー確定時のみ実行
        MqlRates current_bar;
        bar.GetStInfo(0, current_bar);
        if (current_bar.time == last_time) return;
        last_time = current_bar.time;

        // ポジションチェック
        C_Position::POSITION p[];
        int pos_count = pos.CopyStArray(p);
        if(pos_check && pos_count > 0) return;
        
        double lowest = DBL_MAX;

        for(int i = 2; i <= Test_Breakout_Bars + 1; i++)
        {
            double v = iLow(sym, period, i);
            if(v < lowest)
                lowest = v;
        }

        // 終値が最低値を超えたらブレイクアウト
        double close = iClose(sym, period, 1);
        if(close < lowest)
        {
            order.Entry(false, lot, 0, 0);
            Print("Sell Execute: 安値ブレイクアウト");
        }
    }
};
