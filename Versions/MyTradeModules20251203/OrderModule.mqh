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
    C_Order(ulong magic,int slippage,string symbol);
                            
    void Entry(bool in_long,double lot,double sl_points,double tp_points);
    void Close(ulong ticket);
    void ModifySLTP(ulong ticket, double sl, double tp); 
    
private:
    ulong _magic;                         // マジックナンバー
    int   _slippage;                       // 許容スリッページ
    string _symbol;                       // シンボル
    ENUM_ORDER_TYPE_FILLING _fill_type;    // フィルポリシータイプ     
 
    ENUM_ORDER_TYPE_FILLING _GetFillType();
    void _Order(MqlTradeRequest &req, MqlTradeResult &res);        
};

//+------------------------------------------------------------------+
// コンストラクタ フィルポリシーを取得 静的な値の保持
C_Order::C_Order(ulong magic_no,
                 int slippage,
                 string symbol)
    :_magic(magic_no),
     _slippage(slippage),
     _symbol(symbol)
{   
    string fill;
    switch( _fill_type = _GetFillType())
    {
        case ORDER_FILLING_FOK:fill = "ORDER_FILLING_FOK"; break;    
        case ORDER_FILLING_IOC:fill = "ORDER_FILLING_IOC"; break;   
        case ORDER_FILLING_RETURN:fill = "ORDER_FILLING_RETURN"; break;
        default:fill = "ERROR"; break;
    }
    
    Print( "コンストラクタ完了　",__FUNCTION__," FillingType:", fill);
}

//+------------------------------------------------------------------+
// 新規エントリー 
void C_Order::Entry(bool in_long,double lot,double sl_points,double tp_points)
{
    // リクエストと結果の宣言と初期化
    MqlTradeRequest request = {};
    MqlTradeResult result = {};
    
    // リクエストのパラメータ
    request.action = TRADE_ACTION_DEAL;    // 取引操作タイプ
    request.symbol = _symbol;                  // シンボル
    request.volume = lot;                  // ボリューム
    request.deviation = _slippage;              // 許容スリッページ
    request.magic = _magic;                 // 注文のMagicNumber
    request.type_filling = _fill_type;      // フィルポリシーのタイプ
        
    // 現在価格を取得
    double ask = SymbolInfoDouble(_symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_symbol, SYMBOL_BID);
    
    // 注文シグナルから売買方向を設定　
    if(in_long == true)
    {
        request.price = ask;
        request.type = ORDER_TYPE_BUY;
    }
    else
    {
        request.price = bid;
        request.type = ORDER_TYPE_SELL;
    }
    
    // SL,TP設定
    if(sl_points > 0 || tp_points > 0)
    {
        // ブローカーが定める最小SL,TP幅(points)を取得
        int stop_level = (int)SymbolInfoInteger(_symbol, SYMBOL_TRADE_STOPS_LEVEL);
        if(stop_level < 0)
        {
            PrintFormat("警告　%s stop_level < 0.", __FUNCTION__);
            stop_level = 0;
        }
        
        else if(stop_level > 0)
        {
            if(sl_points > 0 && sl_points < stop_level)
            {
                PrintFormat("警告　%s SLが最小距離(%dpt)未満", __FUNCTION__, stop_level);
                return;
            }
            if(tp_points > 0 && tp_points < stop_level)
            {
                PrintFormat("警告　%s TPが最小距離(%dpt)未満", __FUNCTION__, stop_level);
                return;
            }    
        }
        
        int digits = (int)SymbolInfoInteger(_symbol, SYMBOL_DIGITS);    // 小数点以下の桁数
        double point = SymbolInfoDouble(_symbol, SYMBOL_POINT);       // 1pointあたりの価格差(価格単位)
        
        if(in_long == true)
        {
            if(sl_points > 0)request.sl = NormalizeDouble(ask - sl_points * point, digits);
            if(tp_points > 0)request.tp = NormalizeDouble(ask + tp_points * point, digits);  
        }       
        else
        {
            if(sl_points > 0)request.sl = NormalizeDouble(bid + sl_points * point, digits);
            if(tp_points > 0)request.tp = NormalizeDouble(bid - tp_points * point, digits);  
        }                     
    }   
                                          
    _Order(request, result);
}   

//+------------------------------------------------------------------+
// ポジション決済
void C_Order::Close(ulong ticket)
{   
    // ポジション選択と整合性チェック 
    if(!PositionSelectByTicket(ticket))
    {
        PrintFormat("警告 %s 不明なticket:%d errorcode=%d", __FUNCTION__, ticket, GetLastError());
        ResetLastError();
        return;
    }                                           
    if(_symbol != PositionGetString(POSITION_SYMBOL) || _magic != PositionGetInteger(POSITION_MAGIC))   
    {    
        PrintFormat("警告 %s 不明なポジション ticket=%d", __FUNCTION__, ticket);
        return;
    }

    // 注文パラメータ設定
    MqlTradeRequest request = {};
    MqlTradeResult  result = {}; 
    
    // 操作パラメータの設定   
    request.action = TRADE_ACTION_DEAL;                     // 取引操作タイプ
    request.position = ticket;                              // ポジションチケット
    request.symbol = _symbol;                               // シンボル
    request.volume = PositionGetDouble(POSITION_VOLUME);    // ポジションボリューム
    request.deviation = _slippage;                          // 許容スリッページ
    request.magic = _magic;                                 // ポジションのMagicNumber
    request.type_filling = _fill_type;                      // フィルポリシー
       
    ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);    // ポジションタイプ
 
    // 注文シグナル、ポジションタイプ判定　注文タイプと価格の設定
    if(type == POSITION_TYPE_BUY)
    {
        request.price = SymbolInfoDouble(_symbol, SYMBOL_BID);
        request.type = ORDER_TYPE_SELL;
    }
    else if(type == POSITION_TYPE_SELL)
    {
        request.price = SymbolInfoDouble(_symbol, SYMBOL_ASK);
        request.type = ORDER_TYPE_BUY;
    }
     
    _Order(request,result);
}

//+------------------------------------------------------------------+
// ポジションのSLTP変更
void C_Order::ModifySLTP(ulong ticket, double sl_price, double tp_price)
{
    // ポジション選択と整合性チェック
    if(!PositionSelectByTicket(ticket))
    {
        PrintFormat("警告 %s 不明なticket:%d errorcode=%d", __FUNCTION__, ticket, GetLastError());
        ResetLastError();
        return;
    }
    
    if(_symbol != PositionGetString(POSITION_SYMBOL) || _magic != PositionGetInteger(POSITION_MAGIC))   
    {    
        PrintFormat("警告 %s 不明なポジション ticket=%d", __FUNCTION__, ticket);
        return;
    }
    
    // ブローカーが定める最小SL,TP幅(points)を取得
    int stop_level = (int)SymbolInfoInteger(_symbol, SYMBOL_TRADE_STOPS_LEVEL);
    if(stop_level < 0)
    {
        PrintFormat("警告　%s stop_level < 0.", __FUNCTION__);
        stop_level = 0;
    }
    
    // 現在価格・ティック情報取得
    double bid = SymbolInfoDouble(_symbol, SYMBOL_BID);
    double ask = SymbolInfoDouble(_symbol, SYMBOL_ASK);
    double point = SymbolInfoDouble(_symbol, SYMBOL_POINT);
    int digits = (int)SymbolInfoInteger(_symbol, SYMBOL_DIGITS);
    
    ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

    if(stop_level > 0)
    {
        double min_dist = stop_level * point;
        double mkt_price = (type == POSITION_TYPE_BUY ? bid : ask);
        
        if(sl_price != 0.0 && MathAbs(mkt_price - sl_price) < min_dist)
        {
            PrintFormat("警告 %s SLが最小距離(%dpt)未満 ticket=%d", __FUNCTION__, stop_level, ticket);
            return;
        }
        if(tp_price != 0.0 && MathAbs(mkt_price - tp_price) < min_dist)
        {
            PrintFormat("警告 %s TPが最小距離(%dpt)未満 ticket=%d", __FUNCTION__, stop_level, ticket);
            return;
        }
    }
    
    if(sl_price != 0.0)
        sl_price = NormalizeDouble(sl_price, digits);
    if(tp_price != 0.0)
        tp_price = NormalizeDouble(tp_price, digits);
    
    // 注文リクエスト準備（SL/TP変更専用）
    MqlTradeRequest request = {};
    MqlTradeResult  result  = {};

    request.action = TRADE_ACTION_SLTP;    // SL/TP変更
    request.position = ticket;             // ポジションチケット
    request.symbol = _symbol;              // シンボル
    request.magic = _magic;                // MagicNumber
    request.sl = sl_price;                 // 新SL（0なら変更しない）
    request.tp = tp_price;                 // 新TP（0なら変更しない）    
    
    // TRADE_ACTION_SLTPでは無視されるが、統一のため
    request.deviation   = _slippage;
    request.type_filling = _fill_type;

    _Order(request, result);    
}

//+------------------------------------------------------------------+
// フィルポリシーを取得
ENUM_ORDER_TYPE_FILLING C_Order::_GetFillType()
{
    long fill = SymbolInfoInteger(_symbol, SYMBOL_FILLING_MODE);

    // ビット判定
    if((fill & ORDER_FILLING_IOC) != 0) return ORDER_FILLING_IOC;
    if((fill & ORDER_FILLING_FOK) != 0) return ORDER_FILLING_FOK;
    
    Print("警告 ", __FUNCTION__, "　FillingType不明 ORDER_FILLING_IOCを設定");
    return ORDER_FILLING_IOC;
}

//+------------------------------------------------------------------+
// 注文執行
void C_Order::_Order(MqlTradeRequest &req, MqlTradeResult &res)
{
    if(!OrderSend(req, res))
    {    
        PrintFormat("警告　%s OrderSend error. errorcode=%d", __FUNCTION__, GetLastError());
        ResetLastError();
    }    
    // retcodeチェック
    else if(res.retcode != TRADE_RETCODE_DONE && res.retcode != TRADE_RETCODE_PLACED)
        PrintFormat("警告　%s　Order rejected. retcode=%u (%s)", __FUNCTION__, res.retcode, res.comment);
    else
        PrintFormat("注文成功　%s　retcode=%u  deal=%I64u  order=%I64u", __FUNCTION__, res.retcode, res.deal, res.order);
}
