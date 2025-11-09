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
    C_LotSize(string symbol, double risk_percent, double WFA_max_loss);
    double GetLotSize();

private:
    string sym;               // シンボル
    double risk_per;          // リスクパーセント(1%の場合0.01)
    double balance;           // 口座残高
    double max_loss;          // ウォークフォワードテストで得た1lotあたりの最大損失額    
};

// コンストラクタ
C_LotSize::C_LotSize(string symbol, double risk_percent, double WFA_max_loss)
{
    sym = symbol;
    risk_per = risk_percent;
    balance = AccountInfoDouble(ACCOUNT_BALANCE);
    max_loss = WFA_max_loss;
    
    Print("コンストラクタ完了 ", __FUNCTION__, "初期口座残高=", balance);
}

// メイン関数
double C_LotSize::GetLotSize()
{     
    double min_lot = SymbolInfoDouble(sym, SYMBOL_VOLUME_MIN);
    double max_lot = SymbolInfoDouble(sym, SYMBOL_VOLUME_MAX);
    double step = SymbolInfoDouble(sym, SYMBOL_VOLUME_STEP);    // ロットの刻み幅
    
    balance  = AccountInfoDouble(ACCOUNT_BALANCE);
    
    double lot = risk_per * balance / max_loss;   
    
    if(lot < min_lot)
        Print( "警告 ", __FUNCTION__, "ロットサイズが最小ロット未満" );
    if(lot > max_lot)
        Print( "警告 ", __FUNCTION__, "ロットサイズが最大ロットをオーバー" );
        
    double ret = MathFloor(lot / step) * step;
    ret = NormalizeDouble(ret, (int)MathLog10(1.0 / step));
    
    PrintFormat("LotSize算出結果 %s 基準資金額=%f リスク設定=%f LotSize=%f", __FUNCTION__, balance, risk_per, ret);
    return ret;      
}