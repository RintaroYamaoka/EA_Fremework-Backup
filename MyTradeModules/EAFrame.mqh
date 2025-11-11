//+------------------------------------------------------------------+
//|                                                      EAFrame.mqh |
//|                                                   RintaroYamaoka |
//|              https://www.instagram.com/void0ntrick/?locale=ja_JP |
//+------------------------------------------------------------------+
#property copyright "RintaroYamaoka"
#property link      "https://www.instagram.com/void0ntrick/?locale=ja_JP"

// MyTradeModulesアップデート 2025/11/09
// 行動状態クラス、エントリーフィルタークラスを追加し、状態遷移方式の設計に変更。
// OrderModuleにModyfySLTP追加 Closeの第1引数ticketの型をintからulongに変更。 2025/11/11
//+------------------------------------------------------------------+
// EAFrameクラス(継承元)
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

//+------------------------------------------------------------------+
// 行動状態クラス(継承元)
//+------------------------------------------------------------------+
class C_ActionBase
{
public:
    virtual bool Check() = 0;    // 条件判定
    virtual void Execute() = 0;  // 実行処理
    virtual string Name() { return "Action"; }
};

class C_BuyBase : public C_ActionBase
{
    virtual string Name() override { return "Buy"; }
};

class C_SellBase : public C_ActionBase
{
    virtual string Name() override { return "Sell"; }
};

class C_ExitBase : public C_ActionBase
{
    virtual string Name() override { return "Exit"; }
};

//+------------------------------------------------------------------+
// エントリーフィルタークラス 
//+------------------------------------------------------------------+
class C_FilterBase
{
public:
    virtual bool CheckAll() = 0;    // 全条件のチェック
    virtual string Name(){ return "Filter"; }
};
