//+------------------------------------------------------------------+
//|                                                      EAFrame.mqh |
//|                                                   RintaroYamaoka |
//|              https://www.instagram.com/void0ntrick/?locale=ja_JP |
//+------------------------------------------------------------------+
#property copyright "RintaroYamaoka"
#property link      "https://www.instagram.com/void0ntrick/?locale=ja_JP"

//+------------------------------------------------------------------+
// EAFrameクラス
//+------------------------------------------------------------------+
class C_EAFrame
{
public:
    C_EAFrame(ulong magic_no, string symbol , ENUM_TIMEFRAMES time_frame)
    {
        magic = magic_no;
        sym = symbol;
        period = time_frame;
    }
    virtual ~C_EAFrame(){}
    virtual void OnTickMethod() = 0;
    
protected:
    ulong magic;
    string sym;
    ENUM_TIMEFRAMES period;    
};