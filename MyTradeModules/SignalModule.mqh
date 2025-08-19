//+------------------------------------------------------------------+
//|                                                 SignalModule.mqh |
//|                                                   RintaroYamaoka |
//|              https://www.instagram.com/void0ntrick/?locale=ja_JP |
//+------------------------------------------------------------------+
#property copyright "RintaroYamaoka"
#property link      "https://www.instagram.com/void0ntrick/?locale=ja_JP"


//+------------------------------------------------------------------+
// Indicatorクラス
//+------------------------------------------------------------------+
class C_Indicator
{
public:
    C_Indicator(int i_handle);
    ~C_Indicator();
    double GetValue(int buffer_index,int bar_index);

private:
    int handle;    // インジケータのハンドル
};

// コンストラクタ 引数にインジケータ関数を入れる
C_Indicator::C_Indicator(int i_handle)
{
    handle = i_handle;
    if(handle == INVALID_HANDLE)
        Print("警告 ",__FUNCTION__," インジケータのハンドル取得に失敗");    
}

// デストラクタ
C_Indicator::~C_Indicator()
{
    if(handle != INVALID_HANDLE)
        IndicatorRelease(handle); 
}

// メイン関数 引数:インジケーター関数指定のバッファインデックス,取得するバーのインデックス
double C_Indicator::GetValue(int buffer_index, int bar_index)
{
    double value[];
    
    // データを最新を0として時系列にセットする
    ArraySetAsSeries(value, true);
    if( CopyBuffer(handle, buffer_index, 0, bar_index + 1, value) <= bar_index)
    {
        Print("警告 ",__FUNCTION__," データ取得失敗");
        return -1;
    }
    else return value[bar_index];    //　引数で指定したデータを返す
}


//+------------------------------------------------------------------+
// BarDataクラス
//+------------------------------------------------------------------+
class C_BarData
{
public:
    C_BarData(string symbol, ENUM_TIMEFRAMES period, int bar_buffer = 100);
    void GetStInfo(int bar_index, MqlRates &st);
    
private:
    string sym;
    ENUM_TIMEFRAMES time;
    int      buffer;
    MqlRates st_bar_data[];    // 時刻、4本値、Tick出来高、スプレッド、実出来高
    
    bool UpdateMqlRates();     
};

// コンストラクタ
C_BarData::C_BarData(string symbol,ENUM_TIMEFRAMES period,int bar_buffer = 100)
{
    sym    = symbol;
    time   = period;
    buffer = bar_buffer;
    
    if(buffer <= 0)
        Print("警告 ",__FUNCTION__,"　バーデータ構造体配列数が0以下");
    else
        UpdateMqlRates();
}

// BarData取得
void C_BarData::GetStInfo(int bar_index,MqlRates &st)
{
    if(bar_index < 0 || bar_index >= buffer)
    {
        Print("警告 ",__FUNCTION__," 不正なbar_index指定によりバーデータ取得失敗");
        return;
    }
    UpdateMqlRates();
    
    st.high   = st_bar_data[bar_index].high;
    st.low    = st_bar_data[bar_index].low;
    st.open   = st_bar_data[bar_index].open;
    st.close  = st_bar_data[bar_index].close;
    st.time   = st_bar_data[bar_index].time;
    st.spread = st_bar_data[bar_index].spread;
    st.tick_volume = st_bar_data[bar_index].tick_volume;
    st.real_volume = st_bar_data[bar_index].real_volume;     
}

// 構造体配列データ格納
bool C_BarData::UpdateMqlRates()
{
    ArraySetAsSeries(st_bar_data,true);
    
    int copied = CopyRates(sym, time, 0, buffer, st_bar_data);
    if(copied <= 0)
    {
        Print("警告 ",__FUNCTION__," 価格データ取得失敗");
        return false;
    }
    else return true;
}

