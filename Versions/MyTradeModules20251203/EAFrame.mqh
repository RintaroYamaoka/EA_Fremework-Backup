//+------------------------------------------------------------------+
//|                                                      EAFrame.mqh |
//|                                                   RintaroYamaoka |
//|              https://www.instagram.com/void0ntrick/?locale=ja_JP |
//+------------------------------------------------------------------+
#property copyright "RintaroYamaoka"
#property link      "https://www.instagram.com/void0ntrick/?locale=ja_JP"

// 完全なコンストラクタDIでフレームモジュールの差し変えを可能にするアセンブリ方式

// 固定インフラ（Order, Position, BarData, Indicator など）はフレーム継承先で保持
// ロジック（Entry, Exit, Filter など）は外部からDI（注入）する
// EA本体 .mq5 は「部品を組み立てるだけ」でロジックが完成する
// 各ロジックはフレームのメソッド（契約）に従って Process() を実装する

//+------------------------------------------------------------------+
// EAFrame 抽象基底クラス
//+------------------------------------------------------------------+

// EA共通の基底クラス。フレームの状態（magic, symbol, timeframe）を保持し、実行フローの入口を定義する。
class C_EAFrameBase
{
public:
    C_EAFrameBase(ulong magic, string symbol , ENUM_TIMEFRAMES period)
        : _magic(magic),
          _symbol(symbol),
          _period(period)
    {
    }
    
    virtual ~C_EAFrameBase(){}
  
    virtual void OnTickMethod() = 0;
    
protected:
    ulong _magic;
    string _symbol;
    ENUM_TIMEFRAMES _period;    
};

//+------------------------------------------------------------------+
// 行動インターフェース
//+------------------------------------------------------------------+

// すべてのロジック部品（Entry/Exit）が従うべき共通インターフェース。
// 状態を持たず、Process() の実装のみを契約として要求する。
class C_ActionBase
{
public:
    virtual void Process() = 0;   
    virtual string Name() { return "Action"; }  
};

class C_EntryBase : public C_ActionBase
{
    virtual string Name() override { return "Entry"; }
};

class C_ExitBase : public C_ActionBase
{
    virtual string Name() override { return "Exit"; }
};


//+------------------------------------------------------------------+
// プラグインインターフェース
//+------------------------------------------------------------------+
// プラグインはEAFrame継承先が持ち、行動（Action）内部で呼び出す
// プラグインはすべて任意（NULL許容）。テスト用フレームや単独Entryの実行を妨げない

class C_FilterBase
{
public:
    virtual bool Check() = 0;   
    virtual string Name(){ return "Filter"; }
};

class C_LotSizerBase
{
public:
    virtual double GetLot() = 0;
    virtual string Name(){ return "LotSizer"; }
};

class C_SLTPBase
{
public:
    virtual void GetSLTP(double &sl, double &tp) = 0;
    virtual string Name(){ return "SLTP"; }
};

