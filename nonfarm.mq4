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

int buystopTicket = 0;
int sellstopTicket = 0;


int OnInit()
{
    EventSetTimer( 60 );
    return( INIT_SUCCEEDED );
}

void OnTick()
{
    if( IsItFirstFridayOfTheMonth()
        &&
        !WereThereOrdersPlacedToday()
        &&
        TimeCurrent() >= StrToTime( Year() + "." + Month() + "." + Day() + " 15:00" ) )
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
    if( !IsItFirstFridayOfTheMonth() )
    {
        buystopTicket = 0;
        sellstopTicket = 0;
    }
    else
    {
        return;
    }
}

bool IsItFirstFridayOfTheMonth()
{
    if( Day() <= 7
        &&
        DayOfWeek() == 5
        &&
        Month() != 7 // It seems that they have a holiday in July
      )
    {
        return true;
    }
    else
    {
        return false;
    }
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
    double expiration = StrToTime( Year() + "." + Month() + "." + Day() + " 23:00" );

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
    double expiration = StrToTime( Year() + "." + Month() + "." + Day() + " 23:00" );

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

bool WereThereOrdersPlacedToday()
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
