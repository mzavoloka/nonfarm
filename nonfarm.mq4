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

extern int StopLossAmountInPoints = 50;
bool WereThereOrdersPlacedToday = false;

int OnInit()
{
    EventSetTimer( 60 );
    return( INIT_SUCCEEDED );
}


void OnTick()
{
    if ( !IsItFirstFridayOfTheMonth() )
    {
        WereThereOrdersPlacedToday = false;
    }
    if ( IsItFirstFridayOfTheMonth() && !WereThereOrdersPlacedToday )
    {
        orderTicket = OrderSend( Symbol(), OP_BUY, 0.1, Ask, 1, DetermineStopLoss( OP_BUY ), DetermineTakeProfit( OP_BUY ), "Buy Order", 12345, 0, Green );
        WereThereOrdersPlacedToday = true;
        if( orderTicket == -1 )
        {
            Alert( ErrorDescription( GetLastError() ) );
        }
        return;
    }
    else
    {
        return;
    }
}

void OnTimer()
{
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

double DetermineStopLoss( int operation )
{
    if( operation == OP_BUY ) // operation == OP_BUYSTOP ...
    {
        return( Bid - StopLossAmountInPoints * Point );
    }
    else
    {
        Alert( "Error" );
        return 0;
    }
}

double DetermineTakeProfit( int operation )
{
    if( operation == OP_BUY ) // operation == OP_BUYSTOP ...
    {
        return( Bid + StopLossAmountInPoints * Point * 2 );
    }
    else
    {
        Alert( "Error" );
        return 0;
    }
}

//bool WereThereOrdersPlacedToday()
//{
//    OrderSelect( OrdersTotal() - 1, SELECT_BY_POS, MODE_TRADES )
//    OrderOpenTime();
//    OrderSelect( OrdersTotal() - 1, SELECT_BY_POS, MODE_HISTORY )
//
//    return( 
//            ||
//            
//           );
//}
