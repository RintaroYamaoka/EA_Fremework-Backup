//+------------------------------------------------------------------+
//|                                         LimitedTest FixedBar.mqh |
//|                                                   RintaroYamaoka |
//|              https://www.instagram.com/void0ntrick/?locale=ja_JP |
//+------------------------------------------------------------------+
#property copyright "RintaroYamaoka"
#property link      "https://www.instagram.com/void0ntrick/?locale=ja_JP"

#include "..\\Versions\\MyTradeModules20251030\\OrderModule.mqh"
#include "..\\Versions\\MyTradeModules20251030\\PositionModule.mqh"

//+------------------------------------------------------------------+
// 限定的検証 固定本数での手仕舞いテスト用クラス
//+------------------------------------------------------------------+
class C_ExitByBars
{
public: 
    C_ExitByBars(ulong magic_no, string sym, ENUM_TIMEFRAMES tf, int bars, int slip);
    
    // OnTick()の先頭に挿入し、エントリー後に設定本数経過したポジションを決済する
    // EAロジック内の決済処理の無効化を忘れないこと
    void CheckAndCloseByBars();
    
private:
    ulong magic;
    string symbol;
    ENUM_TIMEFRAMES timeframe;
    int exit_bars;
    int slippage;
    C_Order order;
    C_Position position;
    
    int _BarsSince(datetime entry_time);    // 経過バー数を算出
};

//+------------------------------------------------------------------+
// コンストラクタ (内部合成)
C_ExitByBars::C_ExitByBars(ulong magic_no,string sym,ENUM_TIMEFRAMES tf,int bars,int slip)
    : magic(magic_no),
      symbol(sym),
      timeframe(tf),
      exit_bars(bars),
      slippage(slip),
      order(magic_no, slip, sym),
      position(magic_no, sym)
{
     Print("コンストラクタ完了",__FUNCTION__);  
}
      
//+------------------------------------------------------------------+
void C_ExitByBars::CheckAndCloseByBars()
{
    C_Position::POSITION pos[];
    int count = position.CopyStArray(pos);
    if(count <= 0) return;
    
    datetime now_bar = iTime(symbol, timeframe, 0);
    
    for(int i = 0; i < count; i++)
    {
        ulong ticket = pos[i].ticket;
        if(!PositionSelectByTicket(ticket)) continue;
        
        datetime entry_time = (datetime)PositionGetInteger(POSITION_TIME);
        int elapsed = _BarsSince(entry_time);
        
        if(elapsed >= exit_bars)
        {
            order.Close((int)ticket);
            PrintFormat("経過バーによる決済　%s チケットNo=%d ", __FUNCTION__, ticket);
        }
    }
}

//+------------------------------------------------------------------+
// 経過バー数算出
int C_ExitByBars::_BarsSince(datetime entry_time)
{
    int bar_index = iBarShift(symbol, timeframe, entry_time, false);
    if(bar_index == -1) return 0;
    return bar_index;
}