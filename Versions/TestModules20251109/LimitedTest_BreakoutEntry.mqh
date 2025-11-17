//+------------------------------------------------------------------+
//|                                    LimitedTest BreakoutEntry.mqh |
//|                                                   RintaroYamaoka |
//|              https://www.instagram.com/void0ntrick/?locale=ja_JP |
//+------------------------------------------------------------------+
#property copyright "RintaroYamaoka"
#property link      "https://www.instagram.com/void0ntrick/?locale=ja_JP"

#include "..\\..\\Versions\\MyTradeModules20251109\\EAFrame.mqh"
#include "..\\..\\Versions\\MyTradeModules20251109\\OrderModule.mqh"
#include "..\\..\\Versions\\MyTradeModules20251109\\SignalModule.mqh"
#include "..\\..\\Versions\\MyTradeModules20251109\\PositionModule.mqh"
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
    C_BarData *bar;
    C_Position *pos;
    string sym;
    ENUM_TIMEFRAMES period;
    double lot;
    bool pos_check;
    
public:
    C_BreakoutBuy(C_Order *_order, C_BarData *_bar, C_Position *_position,
                  string _symbol, ENUM_TIMEFRAMES _period, bool position_check = true)
    {
        order = _order;
        bar = _bar;
        pos = _position;
        sym = _symbol;
        period = _period;
        lot = Test_LotSize;
        pos_check = position_check; 
    }
    
    
    void Process() override
    {
        C_Position::POSITION p[];
        int pos_count = pos.CopyStArray(p);
        if(pos_check && pos_count > 0) return;
         
        // 直近確定足の終値が高値をブレイクしたらエントリー
        int index = iHighest(sym, period, MODE_HIGH, Test_Breakout_Bars, 1);
        if(index < 0) return;
        
        double highest = iHigh(sym, period, index);
        if(iClose(sym, period, 1) > highest)
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
    C_BarData *bar;
    C_Position *pos;
    string sym;
    ENUM_TIMEFRAMES period;
    double lot;
    bool pos_check;
    
public:
    C_BreakoutSell(C_Order *_order, C_BarData *_bar, C_Position *_position,
                  string _symbol, ENUM_TIMEFRAMES _period, bool position_check = true)
    {
        order = _order;
        bar = _bar;
        pos = _position;
        sym = _symbol;
        period = _period;
        lot = Test_LotSize;
        pos_check = position_check; 
    }
    
    
    void Process() override
    {
        C_Position::POSITION p[];
        int pos_count = pos.CopyStArray(p);
        if(pos_check && pos_count > 0) return;
         
        // 直近確定足の終値が安値をブレイクしたらエントリー
        int index = iLowest(sym, period, MODE_LOW, Test_Breakout_Bars, 1);
        if(index < 0) return;
        
        double lowest = iLow(sym, period, index);
        if(iClose(sym, period, 1) < lowest)
        {
            order.Entry(false, lot, 0, 0);
            Print("Sell Execute: 安値ブレイクアウト");
        }
    }
};

