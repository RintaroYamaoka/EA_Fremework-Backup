//+------------------------------------------------------------------+
//|                                                          Buy.mqh |
//|                                                   RintaroYamaoka |
//|              https://www.instagram.com/void0ntrick/?locale=ja_JP |
//+------------------------------------------------------------------+
#property copyright "RintaroYamaoka"
#property link      "https://www.instagram.com/void0ntrick/?locale=ja_JP"

#include "..\\..\\..\\Versions\\MyTradeModules20251109\\EAFrame.mqh"
#include "..\\..\\..\\Versions\\MyTradeModules20251109\\OrderModule.mqh"
#include "..\\..\\..\\Versions\\MyTradeModules20251109\\SignalModule.mqh"

#include "Parameter.mqh"

class C_Buy : public C_BuyBase
{
private:
    C_Order *order;
    C_BarData *bar;
    C_Indicator *ma;
    C_FilterBase *filter;
    double lot;

public:
    C_Buy(C_Order *_order, C_BarData *_bar, C_Indicator *_ma, C_FilterBase *_filter, double _lot)
    {
        order=_order; bar=_bar; ma=_ma; filter=_filter; lot=_lot;
    }
    
    
    void Process() override
    {
        if(_Check()) _Execute();    
    }
    
    
    bool _Check()
    {
        if(!filter.CheckAll()) return false;
        
        MqlRates bar1, bar2;
        bar.GetStInfo(1, bar1);
        bar.GetStInfo(2, bar2);
        
        double ma1 = ma.GetValue(0, 1), ma2 = ma.GetValue(0, 2);
        
        // MA上抜けした時のみシグナルを返す
        return (bar2.close <= ma2 && bar1.close > ma1);
    }
    
    
    void _Execute()
    {
        order.Entry(true, lot, Fixed_SLTP, Fixed_SLTP);
        Print("Buy Execute: SMA上抜け");
    }              
};
