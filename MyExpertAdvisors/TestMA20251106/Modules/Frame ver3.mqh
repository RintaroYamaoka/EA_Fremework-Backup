//+------------------------------------------------------------------+
//|                                                   Frame ver3.mqh |
//|                                                   RintaroYamaoka |
//|              https://www.instagram.com/void0ntrick/?locale=ja_JP |
//+------------------------------------------------------------------+
#property copyright "RintaroYamaoka"
#property link      "https://www.instagram.com/void0ntrick/?locale=ja_JP"

//　トレードモジュール
#include "..\\..\\..\\Versions\\MyTradeModules20251203\\EAFrame.mqh"
#include "..\\..\\..\\Versions\\MyTradeModules20251203\\OrderModule.mqh"
#include "..\\..\\..\\Versions\\MyTradeModules20251203\\SignalModule.mqh"
#include "..\\..\\..\\Versions\\MyTradeModules20251203\\PositionModule.mqh"
#include "..\\..\\..\\Versions\\MyTradeModules20251203\\SessionModule.mqh"

// パラメータ
input ulong MagicNo = 20251106;
input int Slippage = 10;
input ENUM_TIMEFRAMES Timeframe = PERIOD_H1;
input int MAPeriod = 5;
input double LotSize = 1.0;
input double Fixed_SLTP = 0;

// EAフレーム
class C_Frame : public C_EAFrameBase
{
protected:
    // 固定インフラ
    C_Order _order;
    C_Position _position;
    C_BarData _bar_data;
    
    // ロジック
    C_FilterBase *_filter;
    C_EntryBase *_entry;
    C_ExitBase *_exit;
    
    // インジケータ（内部生成）
    C_Indicator *_ma;
   
public:
    C_Frame(ulong magic_no, string symbol, ENUM_TIMEFRAMES time_frame,
            int slippage, double lot, int ma_period,
            C_FilterBase* filter,
            C_EntryBase* entry,
            C_ExitBase* exit)
                       
        : C_EAFrameBase(magic_no, symbol, time_frame),
          _order(magic_no, slippage, symbol),
          _position(magic_no, symbol),
          _bar_data(symbol, time_frame),
          _filter(filter),
          _entry(entry),
          _exit(exit)
    {  
        // インジケータ生成
        int handle = iMA(symbol, time_frame, ma_period, 0, MODE_SMA, PRICE_CLOSE);
        _ma = new C_Indicator(handle);
        
        PrintFormat("C_EAFramework Initialized: %s, TF=%s, MA=%d",
                    symbol, EnumToString(time_frame), ma_period);
    }
    
    
    virtual ~C_Frame()
    {
        if(_ma) delete _ma;
        if(_entry) delete _entry;
        if(_exit) delete _exit;
        if(_filter) delete _filter;
    }  
    
    
    void OnTickMethod() override
    {
        _exit.Process();
        C_Position::POSITION p[];
        if(_position.CopyStArray(p) > 0) return;
        _entry.Process();
    }            
};

// エントリーロジック
class C_Entry : public C_EntryBase
{
private:
    C_Order *_order;
    C_BarData *_bar_data;
    C_Indicator *_ma;
    C_FilterBase *_filter;
    
    double _lot;

public:
    C_Entry(C_Order *order, 
            C_BarData *bar_data,
            C_Indicator *ma,
            C_FilterBase *filter,
            double lot)
                  
        : _order(order),
          _bar_data(bar_data),
          _ma(ma),
          _filter(filter),
          _lot(lot)
    {
    }


    void Process() override
    {
        if(!_filter.Check()) return;
        
        MqlRates bar1, bar2;
        _bar_data.GetStInfo(1, bar1);
        _bar_data.GetStInfo(2, bar2);
        
        double ma1 = _ma.GetValue(0, 1), ma2 = _ma.GetValue(0, 2);
        if(bar2.close <= ma2 && bar1.close > ma1)
        {
            _order.Entry(true, _lot, Fixed_SLTP, Fixed_SLTP);
            Print("Buy Execute: SMA上抜け");
            return;
        }
        if(bar2.close >= ma2 && bar1.close < ma1)
        {
            _order.Entry(false, _lot, Fixed_SLTP, Fixed_SLTP);
            Print("Sell Execute: SMA下抜け");
            return;
        }
    }         
};

// 決済ロジック
class C_Exit : public C_ExitBase
{
private:
    C_Order *_order;
    C_Position *_position;
    C_BarData *_bar_data;
    C_Indicator *_ma;

public:
    C_Exit(C_Order *order,
           C_Position *position,
           C_BarData *bar_data,
           C_Indicator *ma)
        : _order(order),
          _position(position),
          _bar_data(bar_data),
          _ma(ma)
     {
     }
     
     
     void Process() override
     {
         C_Position::POSITION p[];
         if(_position.CopyStArray(p) <= 0) return;
         
         MqlRates bar1, bar2;
         _bar_data.GetStInfo(1, bar1);
         _bar_data.GetStInfo(2, bar2);
         double ma1 = _ma.GetValue(0, 1), ma2 = _ma.GetValue(0, 2);
         
         if((p[0].is_long && bar2.close >= ma2 && bar1.close < ma1)||
         (!p[0].is_long && bar2.close <= ma2 && bar1.close > ma1))
         {
             _order.Close(p[0].ticket);
             Print("Exit: 反対シグナルで決済");
         }
     }                   
};

// フィルター
class C_BasicFilter : public C_FilterBase
{
private:
    C_TradeSession _session;


public:
    C_BasicFilter()
        : _session(false,true,true,true,true,false,false)
    {
    }
    
    
    bool Check() override
    {
        return _session.IsActiveDay();
    }        
};