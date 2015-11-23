//+------------------------------------------------------------------+
//|                                                      nonfarm.mq4 |
//|                                                 Mikhail Zavoloka |
//|                                              http://mzavoloka.ru |
//+------------------------------------------------------------------+
#property copyright "Mikhail Zavoloka"
#property link      "http://mzavoloka.ru"
#property version   "1.1"
#property strict

#include "../Include/stdlib.mqh"

int orderTicket;

extern int StopLossAmountInPoints = 200;
extern int TrailingAmountInPoints = 200;
extern int TakeProfitAmountInPoints = 1000;
extern int PendingOrderOffsetInPoints = 200;

extern int RiskPerTradeInPercents = 20;

extern bool Debug = false;
extern int DebugDay = 1;
extern int DebugHour = 13;

extern bool Trailing = true;
extern bool TrailingTillOpenPrice = true;

extern bool CancelOppositeOrder = true;

int buystopTicket = 0;
int sellstopTicket = 0;

MqlDateTime nonfarmDates[];


int OnInit()
{
    EventSetTimer( 60 );
    ReadNonfarmData();

    return( INIT_SUCCEEDED );
}

void OnTick()
{
    if( TimeToTradeNonfarm() )
    {
        if( !OrdersAlreadyPlaced() )
        {
            buystopTicket = PlaceBuystop();
            sellstopTicket = PlaceSellstop();

            if( buystopTicket == -1
                ||
                sellstopTicket == -1 )
            {
                Alert( ErrorDescription( GetLastError() ) );
            }
        }
        else
        {
            if( CancelOppositeOrder
                &&
                buystopTicket > 0
                &&
                sellstopTicket > 0 )
            {
                if( OrderSelect( buystopTicket, SELECT_BY_TICKET )
                    &&
                    SelectedOrderIsActive() )
                {
                    OrderDelete( sellstopTicket );
                    sellstopTicket = 0;
                }

                if( OrderSelect( sellstopTicket, SELECT_BY_TICKET )
                    &&
                    SelectedOrderIsActive() )
                {
                    OrderDelete( buystopTicket );
                    buystopTicket = 0;
                }
            }

            if( Trailing )
            {
                Trail();
            }
        }
    }
    else
    {
        buystopTicket = 0;
        sellstopTicket = 0;
    }

    return;
}

bool TimeToTradeNonfarm()
{
    if( Debug )
    {
        if( Day() == DebugDay
            &&
            Hour() >= DebugHour
            &&
            Hour() <= 23 )
        {
            return true;
        }
    }

    for( int i = 0; i < ArraySize( nonfarmDates ); i++ )
    {
        if( Year() == nonfarmDates[i].year
            &&
            Month() == nonfarmDates[i].mon
            &&
            Day() == nonfarmDates[i].day
            &&
            Hour() >= nonfarmDates[i].hour + 5 // Syncing data's EST time with Alpari's Moscow time
            &&
            Hour() <= 23
          )
        {
            return true;
        }
    }
    return false;
}

void OnDeinit( const int reason )
{
    EventKillTimer();
}

int PlaceBuystop()
{
    double price = Ask + PendingOrderOffsetInPoints * Point;
    double stoploss = price - StopLossAmountInPoints * Point;
    double takeprofit = price + TakeProfitAmountInPoints * Point;
    datetime expiration = StrToTime( Year() + "." + Month() + "." + Day() + " 23:00" );

    int order_ticket = OrderSend(
        Symbol(),
        OP_BUYSTOP,
        LotSize(),
        price,
        1,
        stoploss,
        takeprofit,
        "buystop",
        12345,
        expiration,
        OrderColor( OP_BUYSTOP )
    );

    return order_ticket;
}

int PlaceSellstop()
{
    double price = Bid - PendingOrderOffsetInPoints * Point;
    double stoploss = price + StopLossAmountInPoints * Point;
    double takeprofit = price - TakeProfitAmountInPoints * Point;
    datetime expiration = StrToTime( Year() + "." + Month() + "." + Day() + " 23:00" );

    int order_ticket = OrderSend(
        Symbol(),
        OP_SELLSTOP,
        LotSize(),
        price,
        1,
        stoploss,
        takeprofit,
        "buystop",
        12345,
        expiration,
        OrderColor( OP_SELLSTOP )
    );

    return order_ticket;
}

bool OrdersAlreadyPlaced()
{
    return( buystopTicket > 0
            ||
            sellstopTicket > 0 );
}

double LotSize()
{
    double riskAmount = AccountEquity() * RiskPerTradeInPercents / 100;
    double tickValue = MarketInfo( Symbol(), MODE_TICKVALUE );
    if( Point == 0.01 || Point == 0.00001 ) tickValue *= 10;
    double lotSize = riskAmount / StopLossAmountInPoints / tickValue;

    lotSize = Clamp( lotSize, MarketInfo( Symbol(), MODE_MINLOT ), MarketInfo( Symbol(), MODE_MAXLOT ) );

    if( MarketInfo( Symbol(), MODE_LOTSTEP ) == 0.1 )
    {
        lotSize = NormalizeDouble( lotSize, 1 );
    }
    else
    {
        lotSize = NormalizeDouble( lotSize, 2 );
    }

    return lotSize;
}

double Clamp( double number, double lower, double upper )
{
    return MathMax( lower, MathMin( number, upper ) );
}

void ReadNonfarmData()
{
    string filename = "nonfarmdata.csv";
    string filepath = filename;

    int filehandle = FileOpen( filepath, FILE_CSV );
    if( filehandle != INVALID_HANDLE )
    {
        while( !FileIsEnding( filehandle ) )
        {
            string month = MonthNameToNumber( FileReadString( filehandle ) );
            string day   = FileReadString( filehandle );
            string year  = FileReadString( filehandle );
            string time  = FileReadString( filehandle );

            MqlDateTime nonfarmDate;
            TimeToStruct(
                StrToTime( year + "." + month + "." + day + " " + time ),
                nonfarmDate
            );
            
            ArrayResize( nonfarmDates, ArraySize( nonfarmDates ) + 1 );
            nonfarmDates[ ArraySize( nonfarmDates ) - 1 ] = nonfarmDate;
        }
        FileClose( filehandle );
    }
    else
    {
        Alert( "Failed to open the file ", filepath, " | Error: ", GetLastError() );
    }

    return;
}

string MonthNameToNumber( string monthName )
{
         if( monthName == "Jan" ) { return "01"; }
    else if( monthName == "Feb" ) { return "02"; }
    else if( monthName == "Mar" ) { return "03"; }
    else if( monthName == "Apr" ) { return "04"; }
    else if( monthName == "May" ) { return "05"; }
    else if( monthName == "Jun" ) { return "06"; }
    else if( monthName == "Jul" ) { return "07"; }
    else if( monthName == "Aug" ) { return "08"; }
    else if( monthName == "Sep" ) { return "09"; }
    else if( monthName == "Oct" ) { return "10"; }
    else if( monthName == "Nov" ) { return "11"; }
    else if( monthName == "Dec" ) { return "12"; }
    else {
        Alert( "Wrong month name at MonthNameToNumber(). Error: ", GetLastError() );
        return "";
    }
}

void Trail()
{
    if( buystopTicket > 0 )
    {
        if( OrderSelect( buystopTicket, SELECT_BY_TICKET ) )
        {
            TrailSelectedOrder();
        }
        else
        {
            Alert( "Wrong buystop ticket in Trail(): ", buystopTicket );
        }
    }

    if( sellstopTicket > 0 )
    {
        if( OrderSelect( sellstopTicket, SELECT_BY_TICKET ) )
        {
            TrailSelectedOrder();
        }
        else
        {
            Alert( "Wrong sellstop ticket in Trail(): ", sellstopTicket );
        }
    }
    
    return;
}

void TrailSelectedOrder()
{
    if( SelectedOrderIsActive()
        &&
        !DontTrailFurther() )
    {
        double trailingOffsetPosition;
        double oldStoploss = OrderStopLoss();
        double stoploss = oldStoploss;

        if( OrderType() == OP_BUY )
        {
            trailingOffsetPosition = Bid - TrailingAmountInPoints * Point;
            if( stoploss < trailingOffsetPosition )
            {
                stoploss = trailingOffsetPosition;
            }
        }
        else if( OrderType() == OP_SELL )
        {
            trailingOffsetPosition = Ask + TrailingAmountInPoints * Point;
            if( stoploss > trailingOffsetPosition )
            {
                stoploss = trailingOffsetPosition;
            }
        }

        if( stoploss != oldStoploss )
        {
            OrderModify( OrderTicket(), OrderClosePrice(), stoploss, OrderTakeProfit(), 0, OrderColor( OP_BUY ) );
        }
    }

    return;
}

bool DontTrailFurther()
{
    if( TrailingTillOpenPrice
        &&
        ( OrderType() == OP_BUY
          &&
          OrderStopLoss() >= OrderOpenPrice()
          ||
          OrderType() == OP_SELL
          &&
          OrderStopLoss() <= OrderOpenPrice() ) )
    {
        return true;
    }
    else
    {
        return false;
    }
}

bool SelectedOrderIsActive()
{
    return( OrderCloseTime() == 0
            &&
            ( OrderType() == OP_BUY
              ||
              OrderType() == OP_SELL ) );
}

int OrderColor( int orderType )
{
    if( orderType == OP_BUY
        ||
        orderType == OP_BUYSTOP
        ||
        orderType == OP_BUYLIMIT )
    {
        return Green;
    }
    else if( orderType == OP_SELL
        ||
        orderType == OP_SELLSTOP
        ||
        orderType == OP_SELLLIMIT )
    {
        return Red;
    }
    else
    {
        Alert( "Wrong order type in OrderColor(): ", orderType );
        return 0;
    }
}
