//+------------------------------------------------------------------+
//|                                   LimitedTest FixedSLTPClose.mqh |
//|                                                   RintaroYamaoka |
//|              https://www.instagram.com/void0ntrick/?locale=ja_JP |
//+------------------------------------------------------------------+
#property copyright "RintaroYamaoka"
#property link      "https://www.instagram.com/void0ntrick/?locale=ja_JP"

#include "..\\..\\Versions\\MyTradeModules20251109\\EAFrame.mqh"
#include "..\\..\\Versions\\MyTradeModules20251109\\OrderModule.mqh"
#include "..\\..\\Versions\\MyTradeModules20251109\\PositionModule.mqh"
//+------------------------------------------------------------------+
// 限定的検証 固定SLTPでの手仕舞いテスト用モジュール
//+------------------------------------------------------------------+

// テスト専用パラメータ
input int Test_FixedSLTP_Points = 300;

class C_TestFixedSLTPClose : public C_ExitBase
{
private:
    C_Order *_order;
    C_Position *_position;

public:
    C_TestFixedSLTPClose(C_Order *order, C_Position *position)
        : _order(order), _position(position)
    {
    }
    
    
    void Process() override
    {
        // ポジションが無ければ何もしない
        C_Position::POSITION p[];
        int total = _position.CopyStArray(p);
        if(total <= 0) return;
        
        for(int i = 0; i < total; i++)
        {
            if(p[i].sl != 0 || p[i].tp != 0)
            {
                PrintFormat("警告　%s EA本体がSLTPを設定している可能性があります:Ticket=%d SL=%.1f / TP=%.1f "
                            , __FUNCTION__, p[i].ticket, p[i].sl, p[i].tp);           
                continue;
            }
            
            // SLTP未設定→テスト値設定
            if(p[i].sl == 0 && p[i].tp == 0)
            {
                double sl = 0, tp = 0;
                if(p[i].is_long)
                {
                    sl = p[i].price - Test_FixedSLTP_Points * _Point;
                    tp = p[i].price + Test_FixedSLTP_Points * _Point;
                }
                else
                {
                    sl = p[i].price + Test_FixedSLTP_Points * _Point;
                    tp = p[i].price - Test_FixedSLTP_Points * _Point;
                }
                
                _order.ModifySLTP(p[i].ticket, sl, tp);
            }                     
        }  
    }
};
