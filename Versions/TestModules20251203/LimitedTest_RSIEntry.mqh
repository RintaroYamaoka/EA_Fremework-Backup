//+------------------------------------------------------------------+
//|                                         LimitedTest RSIEntry.mqh |
//|                                                   RintaroYamaoka |
//|              https://www.instagram.com/void0ntrick/?locale=ja_JP |
//+------------------------------------------------------------------+
#property copyright "RintaroYamaoka"
#property link      "https://www.instagram.com/void0ntrick/?locale=ja_JP"

#include "..\\..\\Versions\\MyTradeModules20251203\\EAFrame.mqh"
#include "..\\..\\Versions\\MyTradeModules20251203\\OrderModule.mqh"
#include "..\\..\\Versions\\MyTradeModules20251203\\SignalModule.mqh"
#include "..\\..\\Versions\\MyTradeModules20251203\\PositionModule.mqh"
//+------------------------------------------------------------------+
// 限定的検証 エントリー差し替えテスト用モジュール（カウンタートレンド戦略）
//+------------------------------------------------------------------+

// テスト専用パラメータ
input int Test_RSI_MAperiod = 14;
input int Test_RSI_BuyLevel = 30;
input int Test_RSI_SellLevel = 70;
input int Test_LotSize = 1;

class C_TestRSIEntry : public C_EntryBase
{
private:
    C_Order *_order;
    C_Position *_position;
    C_BarData *_bar_data;
    double _lot;
    bool _pos_check;
    datetime _last_time;
    
    C_Indicator *_rsi;
    int _rsi_handle;
    
public:
    C_TestRSIEntry(C_Order *order, C_Position *position, C_BarData *bar_data, 
                  string symbol, ENUM_TIMEFRAMES period, bool pos_check = true) 
        : _order(order),
          _position(position),
          _bar_data(bar_data),
          _lot(Test_LotSize),
          _pos_check(pos_check),
          _last_time(0)
    {    
        _rsi_handle = iRSI(symbol, period, Test_RSI_MAperiod, PRICE_CLOSE);
        _rsi = new C_Indicator(_rsi_handle);
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
         
        // エントリーロジック
        double rsi_val = _rsi.GetValue(0, 1);
        if(rsi_val <= Test_RSI_BuyLevel)
        {
            _order.Entry(true, Test_LotSize, 0, 0);
            Print("Buy Execute: RSI買いシグナル");
        }
        if(rsi_val >= Test_RSI_SellLevel)
        {
            _order.Entry(false, Test_LotSize, 0, 0);
            Print("Sell Execute: RSI売りシグナル");
        }
    }
};
