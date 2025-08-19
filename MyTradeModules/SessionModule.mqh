//+------------------------------------------------------------------+
//|                                                SessionModule.mqh |
//|                                                   RintaroYamaoka |
//|              https://www.instagram.com/void0ntrick/?locale=ja_JP |
//+------------------------------------------------------------------+
#property copyright "RintaroYamaoka"
#property link      "https://www.instagram.com/void0ntrick/?locale=ja_JP"

//+------------------------------------------------------------------+
// TradeSessionクラス
//+------------------------------------------------------------------+
class C_TradeSession
{
public:
    C_TradeSession(bool sun, bool mon,bool tue,bool wed,bool thu,bool fri, bool sat );
                   
    bool IsActiveDay();
    bool IsActiveHour(int start_hour, int end_hour);
    bool IsActiveSession(int start_hour, int end_hour);    // 曜日と時間帯を同時判定（時間帯固定） 
    void PrintSettings();
    
private:
    bool day[7];
};

// コンストラクタ トレード許可曜日を設定
C_TradeSession::C_TradeSession(bool sun,bool mon,bool tue,bool wed,bool thu,bool fri,bool sat)                             
{
    ArrayInitialize(day,false);

    day[SUNDAY]    = sun;
    day[MONDAY]    = mon;
    day[TUESDAY]   = tue;
    day[WEDNESDAY] = wed;
    day[THURSDAY]  = thu;
    day[FRIDAY]    = fri;
    day[SATURDAY]  = sat;
    
    PrintSettings();    
}

// 現在がトレード許可曜日か判定
bool C_TradeSession::IsActiveDay()
{
    // 定義済み構造体型に現在日時を格納
    MqlDateTime now;    
    TimeToStruct(TimeCurrent(), now);
    
    // 現在日時と対応する曜日のbool値を返す
    return day[now.day_of_week];
}

// 現在がトレード許可時間帯か判定
bool C_TradeSession::IsActiveHour(int start_hour,int end_hour)
{
    if(start_hour == 24) start_hour = 0;
    if(end_hour == 24) end_hour = 0;
    
    if(start_hour < 0 || start_hour > 23 || end_hour < 0 || end_hour > 23)
    {    
        Print("警告 ",__FUNCTION__," トレード時間設定が不正です");
        return false;
    }
    
    // 現在時刻設定
    datetime current_dt = TimeCurrent();
    MqlDateTime dt;
    
    TimeToStruct(current_dt,dt);
    int current_hour = dt.hour;
    
    // 日を跨ぐ時間帯に対応
    if(start_hour <= end_hour )
        return (current_hour >= start_hour && current_hour < end_hour);
    else
        return (current_hour >= start_hour || current_hour < end_hour);    
}

// 曜日と時間帯を同時判定（時間帯固定)
bool C_TradeSession::IsActiveSession(int start_hour,int end_hour)
{
    return IsActiveDay() && IsActiveHour(start_hour, end_hour);
}

void C_TradeSession::PrintSettings(void)
{
    string names[] = {"Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"};
    string flags   = "曜日設定:";
    
    for(int i = 0; i < 7; i++)
    {
        flags += names[i] + "=" + (day[i] ? "true" : "false");
        if(i < 6) flags += ", ";
    }
        
    Print(flags);    
}