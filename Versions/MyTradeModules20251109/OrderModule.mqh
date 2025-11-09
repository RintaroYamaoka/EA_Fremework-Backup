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
                            
    void Entry(bool in_long,double lot,double sl_points,double tp_points);
    void Close(int ticket); 
    

private:
    ulong magic;                          // マジックナンバー
    int   slip;                           // 許容スリッページ
    string sym;                           // シンボル
    ENUM_ORDER_TYPE_FILLING fill_type;    // フィルポリシータイプ     
 
    ENUM_ORDER_TYPE_FILLING _GetFillType();
    void _Order(MqlTradeRequest &req, MqlTradeResult &res);        
};

//+------------------------------------------------------------------+
// コンストラクタ フィルポリシーを取得 静的な値の保持
C_Order::C_Order(ulong magic_no,int slipage,string symbol)
{
    magic = magic_no;
    slip  = slipage;
    sym   = symbol;
   
    string fill;
    switch(fill_type = _GetFillType())
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
    request.symbol = sym;                  // シンボル
    request.volume = lot;                  // ボリューム
    request.deviation = slip;              // 許容スリッページ
    request.magic = magic;                 // 注文のMagicNumber
    request.type_filling = fill_type;      // フィルポリシーのタイプ
        
    // 現在価格を取得
    double ask = SymbolInfoDouble(sym, SYMBOL_ASK);
    double bid = SymbolInfoDouble(sym, SYMBOL_BID);
    
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
        int stop_level = (int)SymbolInfoInteger(sym, SYMBOL_TRADE_STOPS_LEVEL);
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
        
        int digits = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);    // 小数点以下の桁数
        double point = SymbolInfoDouble(sym, SYMBOL_POINT);       // 1pointあたりの価格差(価格単位)
        
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
        PrintFormat("警告 %s 不明なポジション ticket=%d", __FUNCTION__, ticket);
        return;
    }

    // 注文パラメータ設定
    MqlTradeRequest request = {};
    MqlTradeResult  result = {}; 
    
    // 操作パラメータの設定   
    request.action = TRADE_ACTION_DEAL;                     // 取引操作タイプ
    request.position = ticket;                              // ポジションチケット
    request.symbol = sym;                                   // シンボル
    request.volume = PositionGetDouble(POSITION_VOLUME);    // ポジションボリューム
    request.deviation = slip;                               // 許容スリッページ
    request.magic = magic;                                  // ポジションのMagicNumber
    request.type_filling = fill_type;                       // フィルポリシー
       
    ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);    // ポジションタイプ
 
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
     
    _Order(request,result);
}

//+------------------------------------------------------------------+
// フィルポリシーを取得
ENUM_ORDER_TYPE_FILLING C_Order::_GetFillType()
{
    long fill = SymbolInfoInteger(sym, SYMBOL_FILLING_MODE);

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
