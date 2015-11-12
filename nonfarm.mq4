//+------------------------------------------------------------------+
//|                                                      nonfarm.mq4 |
//|                                                 Mikhail Zavoloka |
//|                                              http://mzavoloka.ru |
//+------------------------------------------------------------------+
#property copyright "Mikhail Zavoloka"
#property link      "http://mzavoloka.ru"
#property version   "0.01"
#property strict

int orderTicket;


int OnInit()
{
    EventSetTimer( 60 );
    return( INIT_SUCCEEDED );
}


void OnTick()
{
    if ( IsItFirstFridayOfTheMonth() )
    {
        orderTicket = OrderSend( Symbol(), OP_SELLSTOP, 0.01, 0.0001, 1, StopLossLevel(), 0, "Eternal Order", 12345, 0, Green );
        OrderSelect( orderTicket, SELECT_BY_TICKET );
        OrderModify( orderTicket, OrderOpenPrice(), StopLossLevel(), OrderTakeProfit(), OrderExpiration() );
    }
}

void OnTimer()
{
}
  
double StopLossLevel()
{
    return( Bid - Gap * 0.0001 );
}

bool IsItFirstFridayOfTheMonth()
{
    if( Day() <= 7
        &&
        DayOfWeek() == 5
        &&
        Month != 7 // It seems that they have a holiday in July
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
    OrderDelete( orderTicket, Green );
}
