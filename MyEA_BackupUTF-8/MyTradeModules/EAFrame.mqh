//+------------------------------------------------------------------+
//|                                                      EAFrame.mqh |
//|                                                   RintaroYamaoka |
//|              https://www.instagram.com/void0ntrick/?locale=ja_JP |
//+------------------------------------------------------------------+
#property copyright "RintaroYamaoka"
#property link      "https://www.instagram.com/void0ntrick/?locale=ja_JP"

//+------------------------------------------------------------------+
// EAFrameクラス(インターフェース)
//+------------------------------------------------------------------+
class C_EAFrame
{
public:
    C_EAFrame(ulong magic_no, string _symbol , ENUM_TIMEFRAMES _period)
    {
        magic  = magic_no;
        symbol = _symbol;
        period = _period;
    }
    virtual ~C_EAFrame(){}
    virtual void OnTickMethod() = 0;
    
protected:
    ulong magic;
    string symbol;
    ENUM_TIMEFRAMES period;    
};