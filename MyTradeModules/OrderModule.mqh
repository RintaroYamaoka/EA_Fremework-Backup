//+------------------------------------------------------------------+
//|                                                  OrderModule.mqh |
//|                                                   RintaroYamaoka |
//|              https://www.instagram.com/void0ntrick/?locale=ja_JP |
//+------------------------------------------------------------------+
#property copyright "RintaroYamaoka"
#property link      "https://www.instagram.com/void0ntrick/?locale=ja_JP"

//+------------------------------------------------------------------+
//注文執行クラス
//+------------------------------------------------------------------+
class C_Order
{
public:
    C_Order(ulong magic_no,int slipage,string symbol);
                            
    void Entry(bool in_long,double lot,double sl_range,double tp_range);
    void Close(int ticket); 
    

private:
    ulong magic;    // マジックナンバー
    int   slip;     // 許容スリッページ
    string sym;     // シンボル 
    
    ENUM_ORDER_TYPE_FILLING GetFillType();        
};

//+------------------------------------------------------------------+
// コンストラクタ フィルポリシーを取得 静的な値の保持
C_Order::C_Order(ulong magic_no,int slipage,string symbol)
{
    magic = magic_no;
    slip  = slipage;
    sym   = symbol;
   
    string fill_name;
    switch( GetFillType())
    {
        case ORDER_FILLING_FOK:    fill_name = "ORDER_FILLING_FOK"; break;    
        case ORDER_FILLING_IOC:    fill_name = "ORDER_FILLING_IOC"; break;   
        case ORDER_FILLING_RETURN: fill_name = "ORDER_FILLING_RETURN"; break;
        default:                   fill_name = "ERROR"; break;
    }
    
    Print( "コンストラクタ完了　",__FUNCTION__," FillingType:", fill_name );
}

//+------------------------------------------------------------------+
// 新規エントリー 
void C_Order::Entry(bool in_long,double lot,double sl_range,double tp_range)
{
    // リクエストと結果の宣言と初期化
    MqlTradeRequest request = {};
    MqlTradeResult  result  = {};
    
    // リクエストのパラメータ
    request.action       = TRADE_ACTION_DEAL;    // 取引操作タイプ
    request.symbol       = sym;                  // シンボル
    request.volume       = lot;                  // ボリューム
    request.deviation    = slip;                 // 許容スリッページ
    request.magic        = magic;                // 注文のMagicNumber
    request.type_filling = GetFillType();        // フィルポリシーのタイプ
    
    // 現在価格を取得
    double ask          = SymbolInfoDouble(sym, SYMBOL_ASK);
    double bid          = SymbolInfoDouble(sym, SYMBOL_BID);
    
    // 注文シグナルから売買方向を設定　
    if(in_long == true)
    {
        request.price = ask;
        request.type  = ORDER_TYPE_BUY;
    }
    else
    {
        request.price = bid;
        request.type  = ORDER_TYPE_SELL;
    }
    
    // SL,TP設定
    if(sl_range > 0 || tp_range > 0)
    {
        int digits = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);    // 小数点以下の桁数
        double point = SymbolInfoDouble(sym, SYMBOL_POINT);       // 1pointあたりの価格差(価格単位)
        
        // ブローカーが定める最小ストップ幅(points)を取得
        int stop_level = (int)SymbolInfoInteger(sym, SYMBOL_TRADE_STOPS_LEVEL);
        
        // stop_levelが取得できれば、+50points、取得失敗した場合は150pointsを最小オフセット幅とする
        double min_price_offset = (stop_level > 0 ? stop_level : 150) * point + 50 * point;
        if (sl_range > 0 && sl_range < min_price_offset) 
            sl_range = min_price_offset;
        if(tp_range > 0 && tp_range < min_price_offset)    
            tp_range = min_price_offset;
            
        // 注文方向別にSL,TPの価格を設定 
        double sl_price;
        double tp_price;
           
        if(in_long == true)
        {
            sl_price = NormalizeDouble(bid - sl_range, digits);
            tp_price = NormalizeDouble(bid + tp_range, digits);
            
            if(sl_range > 0 && tp_range > 0)
            {
                request.sl = sl_price;
                request.tp = tp_price;
            }
            else if(sl_range > 0 && tp_range <= 0)
                request.sl = sl_price;
            else if(sl_range <= 0 && tp_range > 0)
                request.tp = tp_price;
        }       
        else
        {
            sl_price = NormalizeDouble(ask + sl_range, digits);
            tp_price = NormalizeDouble(ask - tp_range, digits);
            
            if(sl_range > 0 && tp_range > 0)      
            {
                request.sl = sl_price;
                request.tp = tp_price;
            }
            else if(sl_range > 0 && tp_range <= 0)
                request.sl = sl_price;
            else if(sl_range <= 0 && tp_range > 0)
                request.tp = tp_price;
        }                     
    }   
                                        
    // リクエストの送信
    if( !OrderSend(request, result))
    {    
        PrintFormat("警告　%s OrderSend error. errorcode=%d", __FUNCTION__, GetLastError());
        ResetLastError();
    }    
    // retcodeチェック
    else if(result.retcode != TRADE_RETCODE_DONE && result.retcode != TRADE_RETCODE_PLACED)
        PrintFormat("警告　%s　Entry order rejected. retcode=%u (%s)", __FUNCTION__, result.retcode, result.comment);
    else
        PrintFormat("エントリー注文成功　%s　retcode=%u  deal=%I64u  order=%I64u", __FUNCTION__, result.retcode, result.deal, result.order);
}   

//+------------------------------------------------------------------+
// ポジション決済
void C_Order::Close(int ticket)
{   
    // ポジション選択と整合性チェック 
    if(!PositionSelectByTicket(ticket))
    {
        PrintFormat("警告 %s 不明なticket:%d errorcode=%d", __FUNCTION__, ticket, GetLastError());
        ResetLastError();
        return;
    }                                           
    if(sym != PositionGetString(POSITION_SYMBOL) || magic != PositionGetInteger(POSITION_MAGIC))   
    {    
        Print("警告 ", __FUNCTION__, "不明なポジション　ticket:", ticket);
        return;
    }

    // 注文パラメータ設定
    MqlTradeRequest request = {};
    MqlTradeResult  result  = {}; 
    
    // 操作パラメータの設定   
    request.action       = TRADE_ACTION_DEAL;                  // 取引操作タイプ
    request.position     = ticket;                             // ポジションチケット
    request.symbol       = sym;                                // シンボル
    request.volume       = PositionGetDouble(POSITION_VOLUME); // ポジションボリューム
    request.deviation    = slip;                               // 許容スリッページ
    request.magic        = magic;                              // ポジションのMagicNumber
    request.type_filling = GetFillType();                      // フィルポリシー
     
    ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);   // ポジションタイプ
 
    // 注文シグナル、ポジションタイプ判定　注文タイプと価格の設定
    if(type == POSITION_TYPE_BUY)
    {
        request.price = SymbolInfoDouble(sym, SYMBOL_BID);
        request.type  = ORDER_TYPE_SELL;
    }
    else if(type == POSITION_TYPE_SELL)
    {
        request.price = SymbolInfoDouble(sym, SYMBOL_ASK);
        request.type  = ORDER_TYPE_BUY;
    }
     
    // リクエストの送信　リクエストの送信に失敗した場合、エラーコードを出力
    if(!OrderSend(request, result))
        PrintFormat( "警告　%s OrderSend error. errorcode=%d", __FUNCTION__, GetLastError() );        
    // retcodeチェック   
    else if(result.retcode != TRADE_RETCODE_DONE && result.retcode != TRADE_RETCODE_PLACED)
        PrintFormat("警告　%s Order rejected. retcode=%u (%s)", __FUNCTION__, result.retcode, result.comment);
    else    
        PrintFormat("決済注文成功　%s retcode=%u deal=%I64u order=%I64u", __FUNCTION__, result.retcode, result.deal, result.order);
}

//+------------------------------------------------------------------+
// フィルポリシーを取得
ENUM_ORDER_TYPE_FILLING C_Order::GetFillType()
{
    long fill_type = SymbolInfoInteger(sym, SYMBOL_FILLING_MODE);

    // ビット判定
    if((fill_type & ORDER_FILLING_IOC) != 0) return ORDER_FILLING_IOC;
    if((fill_type & ORDER_FILLING_FOK) != 0) return ORDER_FILLING_FOK;
    
    Print("警告 ", __FUNCTION__, "　FillingType不明 ORDER_FILLING_ICOを設定");
    return ORDER_FILLING_IOC;
}