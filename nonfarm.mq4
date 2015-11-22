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
extern int TakeProfitAmountInPoints = 500;
extern int PendingOrderOffsetInPoints = 200;

extern int RiskPerTradeInPercents = 3;

extern bool Debug = false;
extern int DebugDay;
extern int DebugHour;

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
    if( TimeToTradeNonfarm()
        &&
        !OrdersAlreadyPlaced() )
    {
        buystopTicket = PlaceBuystop();
        sellstopTicket = PlaceSellstop();

        if( buystopTicket == -1
            ||
            sellstopTicket == -1 )
        {
            Alert( ErrorDescription( GetLastError() ) );
        }
        return;
    }
    if( !TimeToTradeNonfarm() )
    {
        buystopTicket = 0;
        sellstopTicket = 0;
    }
    else
    {
        return;
    }
}

bool TimeToTradeNonfarm()
{
    if( Debug )
    {
        if( Day() == DebugDay
            &&
            Hour() >= DebugHour
            &&
            Hour() <= 23
          )
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
        Green
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
        Red
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
    //string terminal_data_path = TerminalInfoString( TERMINAL_DATA_PATH );
    //string filepath = terminal_data_path + "\\MQL4\\Files\\" + filename;
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
        Print( "Failed to open the file ", filepath, " | Error: ", GetLastError() );
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
        Print( "Wrong month name at MonthNameToNumber(). Error: ", GetLastError() );
        return "";
    }
}

    //for( int i = 0; i < ArraySize( nonfarmDates ); i++ )
    //{
    //    Print( nonfarmDates[i].year, nonfarmDates[i].mon, nonfarmDates[i].day, nonfarmDates[i].hour, nonfarmDates[i].min );
    //}
