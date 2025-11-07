//+------------------------------------------------------------------+
//|                                  TestMA LimitedTest FixedBar.mq5 |
//|                                                   RintaroYamaoka |
//|              https://www.instagram.com/void0ntrick/?locale=ja_JP |
//+------------------------------------------------------------------+
#property copyright "RintaroYamaoka"
#property link      "https://www.instagram.com/void0ntrick/?locale=ja_JP"
#property version   "1.00"

#include "..\\..\\Versions\\MyTradeModules20251030\\EAFrame.mqh"
#include "..\\..\\Versions\\MyTradeModules20251030\\OrderModule.mqh"
#include "..\\..\\Versions\\MyTradeModules20251030\\PositionModule.mqh"
#include "..\\..\\Versions\\MyTradeModules20251030\\SessionModule.mqh"
#include "..\\..\\Versions\\MyTradeModules20251030\\SignalModule.mqh"

input ulong MagicNo = 20251106;
input int Slippage = 10;
input ENUM_TIMEFRAMES Timeframe = PERIOD_H1;
input int MAPeriod = 5;
input double LotSize = 1.0;

// EAのインスタンス宣言（グローバル領域）
class C_TestMA;
C_TestMA *ea = NULL;


class C_TestMA : public C_EAFrame
{
private:
    C_Order        order;
    C_Position     position;
    C_TradeSession session;
    C_Indicator   *ma;
    C_BarData      bar;

public:
    // コンストラクタ
    C_TestMA(ulong magic_no, string symbol, ENUM_TIMEFRAMES tf)
        : C_EAFrame(magic_no, symbol, tf),
          order(magic_no, Slippage, symbol),
          position(magic_no, symbol),
          session(false, true, true, true, true, false, false), // 金曜除外
          bar(symbol, tf)
    {
        int handle = iMA(symbol, tf, MAPeriod, 0, MODE_SMA, PRICE_CLOSE);
        if(handle == INVALID_HANDLE)
        {
            Print("警告: iMAハンドル取得に失敗しました。");
        }
        ma = new C_Indicator(handle);

        PrintFormat("C_TestMA 初期化完了: Symbol=%s, Timeframe=%s, MAPeriod=%d",
                    symbol, EnumToString(tf), MAPeriod);
    }

    
    // デストラクタ
    virtual ~C_TestMA()
    {
        if(ma != NULL)
        {
            delete ma;
            ma = NULL;
        }
        Print("C_TestMA 正常終了。");
    }

    
    // メインロジック
    void OnTickMethod() override
    {
        // 新バー確定時のみ実行
        static datetime last_time = 0;
        MqlRates current_bar;
        bar.GetStInfo(0, current_bar);
        if (current_bar.time == last_time)
            return;
        last_time = current_bar.time;

        // バー情報取得（1本前と2本前）
        MqlRates bar1, bar2;
        bar.GetStInfo(1, bar1);
        bar.GetStInfo(2, bar2);

        // MA値取得
        double ma1 = ma.GetValue(0, 1);
        double ma2 = ma.GetValue(0, 2);
        if (ma1 < 0 || ma2 < 0)
            return;

        // クロス判定
        bool cross_up = (bar2.close <= ma2 && bar1.close > ma1);
        bool cross_down = (bar2.close >= ma2 && bar1.close < ma1);

        // ポジション確認
        C_Position::POSITION pos[];
        int pos_count = position.CopyStArray(pos);

        bool has_long = false;
        bool has_short = false;
        int long_ticket = -1, short_ticket = -1;

        for (int i = 0; i < pos_count; i++)
        {
            if(pos[i].is_long)
            {
                has_long = true;
                long_ticket = (int)pos[i].ticket;
            }
            else
            {
                has_short = true;
                short_ticket = (int)pos[i].ticket;
            }
        }

        // クロスアップ（上抜け）
        if (cross_up)
        {
            if(has_short)
                order.Close(short_ticket);
            if(!has_long && session.IsActiveDay())
                order.Entry(true, LotSize, 0, 0);

            int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
            PrintFormat("クロスアップ発生 Close=%.*f SMA=%.*f", digits, bar1.close, digits, ma1);
        }

        // クロスダウン（下抜け）
        if (cross_down)
        {
            if(has_long)
                order.Close(long_ticket);
            if(!has_short && session.IsActiveDay())
                order.Entry(false, LotSize, 0, 0);

            int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
            PrintFormat("クロスダウン発生 Close=%.*f SMA=%.*f", digits, bar1.close, digits, ma1);
        }
    }
};
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    ea = new C_TestMA(MagicNo, _Symbol, Timeframe);
    Print("TestMA Initialized.");
    return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    if(ea != NULL) delete ea;
    Print("TestEA Deinitialized.");
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    if(ea != NULL) ea.OnTickMethod();
}
//+------------------------------------------------------------------+
