//+------------------------------------------------------------------+
//|                                                         Exit.mqh |
//|                                                   RintaroYamaoka |
//|              https://www.instagram.com/void0ntrick/?locale=ja_JP |
//+------------------------------------------------------------------+
#property copyright "RintaroYamaoka"
#property link      "https://www.instagram.com/void0ntrick/?locale=ja_JP"

#include "..\\..\\..\\Versions\\MyTradeModules20251109\\EAFrame.mqh"
#include "..\\..\\..\\Versions\\MyTradeModules20251109\\OrderModule.mqh"
#include "..\\..\\..\\Versions\\MyTradeModules20251109\\PositionModule.mqh"
#include "..\\..\\..\\Versions\\MyTradeModules20251109\\SignalModule.mqh"

#include "Parameter.mqh"

class C_Exit : public C_ExitBase
{
private:
    C_Order *order;
    C_Position *pos;
    C_BarData *bar;
    C_Indicator *ma;
    
public:
    C_Exit(C_Order *_order, C_Position *_pos, C_BarData *_bar, C_Indicator *_ma)
    {
        order = _order;
        pos = _pos;
        bar = _bar;
        ma = _ma;
    }
    
    
    void Process() override
    {
        if(_Check()) _Execute();    
    }
    
    
    bool _Check()           
    {
        C_Position::POSITION p[];
        if(pos.CopyStArray(p) <= 0) return false;
    
        MqlRates bar1, bar2;
        bar.GetStInfo(1, bar1);
        bar.GetStInfo(2, bar2);
        double ma1 = ma.GetValue(0, 1), ma2 = ma.GetValue(0, 2);
        
        if(p[0].is_long && bar2.close >= ma2 && bar1.close < ma1) return true;
        else if(!p[0].is_long && bar2.close <= ma2 && bar1.close > ma1 ) return true;
        else return false;
    }
    
    
    void _Execute()
    {
        C_Position::POSITION p[];
        int n = pos.CopyStArray(p);
        if(n < 0) return;
        
        order.Close(p[0].ticket);
        Print("Exit: 反対シグナルで決済");
    }
};
