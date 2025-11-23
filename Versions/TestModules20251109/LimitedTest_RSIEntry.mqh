//+------------------------------------------------------------------+
//|                                         LimitedTest RSIEntry.mqh |
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
// 限定的検証 エントリー差し替えテスト用モジュール（カウンタートレンド戦略）
//+------------------------------------------------------------------+

// テスト専用パラメータ
input int Test_RSI_MAperiod = 14;
input int Test_RSI_BuyLevel = 30;
input int Test_RSI_SellLevel = 70;
input int Test_LotSize = 1;

class C_RSIBuy : public C_BuyBase
{
private:
    C_Order *order;
    C_Position *pos;
    C_BarData *bar;
    double lot;
    datetime last_time;
    bool pos_check;
    
    C_Indicator *rsi;
    int rsi_handle;
    
public:
    C_RSIBuy(C_Order *_order, C_Position *_position, C_BarData *_bar, 
                  string _sym, ENUM_TIMEFRAMES _period, bool position_check = true) 
    {
        order = _order;
        pos = _position;
        bar = _bar;
        last_time = 0;
        pos_check = position_check;
        
        rsi_handle = iRSI(_sym, _period, Test_RSI_MAperiod, PRICE_CLOSE);
        rsi = new C_Indicator(rsi_handle);
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
         
        double rsi_val = rsi.GetValue(0, 1);
        if(rsi_val <= Test_RSI_BuyLevel)
        {
            order.Entry(true, Test_LotSize, 0, 0);
            Print("Buy Execute: RSI買いシグナル");
        }
    }
};

class C_RSISell : public C_SellBase
{
private:
    C_Order *order;
    C_Position *pos;
    C_BarData *bar;
    double lot;
    datetime last_time;
    bool pos_check;
    
    C_Indicator *rsi;
    int rsi_handle;
    
public:
    C_RSISell(C_Order *_order, C_Position *_position, C_BarData *_bar, 
                  string _sym, ENUM_TIMEFRAMES _period, bool position_check = true) 
    {
        order = _order;
        pos = _position;
        bar = _bar;
        last_time = 0;
        pos_check = position_check;
        
        rsi_handle = iRSI(_sym, _period, Test_RSI_MAperiod, PRICE_CLOSE);
        rsi = new C_Indicator(rsi_handle);
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
         
        double rsi_val = rsi.GetValue(0, 1);

        if(rsi_val >= Test_RSI_SellLevel)
        {
            order.Entry(false, Test_LotSize, 0, 0);
            Print("Sell Execute: RSI売りシグナル");
        }
    }
};
