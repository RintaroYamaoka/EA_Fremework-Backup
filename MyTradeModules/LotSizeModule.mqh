//+------------------------------------------------------------------+
//|                                                LotSizeModule.mqh |
//|                                                   RintaroYamaoka |
//|              https://www.instagram.com/void0ntrick/?locale=ja_JP |
//+------------------------------------------------------------------+
#property copyright "RintaroYamaoka"
#property link      "https://www.instagram.com/void0ntrick/?locale=ja_JP"

//+------------------------------------------------------------------+
// LotSizeクラス
//+------------------------------------------------------------------+
class C_LotSize
{
public:
    enum RISK_MODE
    {
        MODE_STATIC,    // 静的残高（単利運用)
        MODE_DYNAMIC    // 動的残高(複利運用)
    };

    C_LotSize(string symbol, double risk_percent);
    double GetLotSize(double sl_points,RISK_MODE mode = MODE_STATIC);

private:
    string    sym;               // シンボル
    double    risk_per;          // リスクパーセント
    double    static_balance;    // 初期口座残高 
};

// コンストラクタ
C_LotSize::C_LotSize(string symbol, double risk_percent)
{
    sym            = symbol;
    risk_percent   = risk_per;
    static_balance = AccountInfoDouble(ACCOUNT_BALANCE);
    
    Print("コンストラクタ完了 ", __FUNCTION__, "初期口座残高=", static_balance);
}

// メイン関数
double C_LotSize::GetLotSize(double sl_points, RISK_MODE mode = MODE_STATIC)
{
    if(sl_points <= 0) return 0;
    
    double min_lot = SymbolInfoDouble(sym, SYMBOL_VOLUME_MIN);
    double max_lot = SymbolInfoDouble(sym, SYMBOL_VOLUME_MAX);
    double step    = SymbolInfoDouble(sym, SYMBOL_VOLUME_STEP);    // ロットの刻み幅
    
    // MODE別処理
    double balance;
    string mode_log;
    if(mode == MODE_STATIC)
    {
        balance  = static_balance;
        mode_log = "MODE_STATIC";
    }     
    else 
    {
        balance  = AccountInfoDouble(ACCOUNT_BALANCE);
        mode_log = "MODE_DYNAMIC";
    }    
    
    // 損失許容額
    double risk_amount = balance * (risk_per / 100);
    
    // 1pointの損益額
    double point_value = SymbolInfoDouble(sym, SYMBOL_TRADE_TICK_VALUE);
    
    // ロットサイズ算出
    double row_lot = risk_amount / (sl_points * point_value);
    double lot_size = MathFloor(row_lot / step) * step;
    
    if(lot_size < min_lot)
        Print( "警告 ", __FUNCTION__, "ロットサイズが最小ロット未満" );
    if(lot_size > max_lot)
        Print( "警告 ", __FUNCTION__, "ロットサイズが最大ロットをオーバー" );
        
    double ret = NormalizeDouble(lot_size, 2);
    PrintFormat("LotSize算出結果 %s %s 基準資金額=%d リスク設定=%d% LotSize=%d", __FUNCTION__, mode_log, balance, ret);
    return ret;      
}