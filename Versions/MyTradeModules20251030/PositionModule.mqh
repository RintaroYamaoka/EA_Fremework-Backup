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
    
    C_Position(ulong magic,string symbol);
    int CopyStArray(POSITION &st[]);

private:
    ulong magic;
    string sym;
    POSITION pos[]; 
    
    int UpdatePosData();   
};

// コンストラクタ
C_Position::C_Position(ulong magic_no,string symbol)
{
    magic = magic_no;
    sym   = symbol;
    ArrayResize(pos,0);
}

// ポジション情報を構造体配列にコピーし、ポジション数を戻り値に返す
int C_Position::CopyStArray(POSITION &st[])
{
    int positions = UpdatePosData();
    if(positions <= 0) return positions;
        
    ArrayResize(st,positions);
    
    for(int i = 0; i < positions; i++)
    {
        st[i].ticket  = pos[i].ticket;    
        st[i].is_long = pos[i].is_long;
        st[i].lot     = pos[i].lot;
        st[i].price   = pos[i].price;
        st[i].sl      = pos[i].sl;
        st[i].tp      = pos[i].tp;
        st[i].profit  = pos[i].profit;
    }
    return positions;   
}

// ポジション情報を取得、構造体配列に格納し、EAのポジション数を戻り値に返す
int C_Position::UpdatePosData()
{
    int count = 0;
    int positions = PositionsTotal();
    if(positions <= 0) return positions;
    
    ArrayResize(pos,positions);
    
    for(int i = 0; i < positions; i++)
    {
        ulong selected_ticket = PositionGetTicket(i);
        if( PositionSelectByTicket(selected_ticket))
        {
            if(PositionGetString(POSITION_SYMBOL) != sym) continue;
            if(PositionGetInteger(POSITION_MAGIC) != magic) continue;
            
            pos[count].ticket  = selected_ticket;    
            pos[count].is_long = ( PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
            pos[count].lot     = PositionGetDouble(POSITION_VOLUME);
            pos[count].price   = PositionGetDouble(POSITION_PRICE_OPEN);
            pos[count].sl      = PositionGetDouble(POSITION_SL);
            pos[count].tp      = PositionGetDouble(POSITION_TP);
            pos[count].profit  = PositionGetDouble(POSITION_PROFIT);
            count += 1;  
        }
        else 
        {
            Print("警告 ",__FUNCTION__," ポジション選択失敗 errorcode=",GetLastError());
            ResetLastError();
        }    
    }
    
    ArrayResize(pos,count);
    return count;
}