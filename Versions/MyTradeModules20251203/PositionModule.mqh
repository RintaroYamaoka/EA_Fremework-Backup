//+------------------------------------------------------------------+
//|                                               PositionModule.mqh |
//|                                                   RintaroYamaoka |
//|              https://www.instagram.com/void0ntrick/?locale=ja_JP |
//+------------------------------------------------------------------+
#property copyright "RintaroYamaoka"
#property link      "https://www.instagram.com/void0ntrick/?locale=ja_JP"

//+------------------------------------------------------------------+
// Positionクラス
//+------------------------------------------------------------------+
class C_Position
{
public:
    struct POSITION
    {
        ulong ticket;
        bool is_long;
        double lot;
        double price;
        double sl;
        double tp;
        double profit;
    }; 
    
    C_Position(ulong magic, string symbol);
    int CopyStArray(POSITION &st[]);

private:
    ulong _magic;
    string _symbol;
    POSITION _pos[]; 
    
    int _UpdatePosData();   
};

// コンストラクタ
C_Position::C_Position(ulong magic, string symbol)
    :_magic(magic), _symbol(symbol)
{
    ArrayResize(_pos,0);
}

// ポジション情報を構造体配列にコピーし、ポジション数を戻り値に返す
int C_Position::CopyStArray(POSITION &st[])
{
    int positions = _UpdatePosData();
    if(positions <= 0) return positions;
        
    ArrayResize(st,positions);
    
    for(int i = 0; i < positions; i++)
    {
        st[i].ticket  = _pos[i].ticket;    
        st[i].is_long = _pos[i].is_long;
        st[i].lot     = _pos[i].lot;
        st[i].price   = _pos[i].price;
        st[i].sl      = _pos[i].sl;
        st[i].tp      = _pos[i].tp;
        st[i].profit  = _pos[i].profit;
    }
    return positions;   
}

// ポジション情報を取得、構造体配列に格納し、EAのポジション数を戻り値に返す
int C_Position::_UpdatePosData()
{
    int count = 0;
    int positions = PositionsTotal();
    if(positions <= 0) return positions;
    
    ArrayResize(_pos,positions);
    
    for(int i = 0; i < positions; i++)
    {
        ulong selected_ticket = PositionGetTicket(i);
        if( PositionSelectByTicket(selected_ticket))
        {
            if(PositionGetString(POSITION_SYMBOL) != _symbol) continue;
            if(PositionGetInteger(POSITION_MAGIC) != _magic) continue;
            
            _pos[count].ticket  = selected_ticket;    
            _pos[count].is_long = ( PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
            _pos[count].lot     = PositionGetDouble(POSITION_VOLUME);
            _pos[count].price   = PositionGetDouble(POSITION_PRICE_OPEN);
            _pos[count].sl      = PositionGetDouble(POSITION_SL);
            _pos[count].tp      = PositionGetDouble(POSITION_TP);
            _pos[count].profit  = PositionGetDouble(POSITION_PROFIT);
            count += 1;  
        }
        else 
        {
            Print("警告 ",__FUNCTION__," ポジション選択失敗 errorcode=",GetLastError());
            ResetLastError();
        }    
    }
    
    ArrayResize(_pos,count);
    return count;
}