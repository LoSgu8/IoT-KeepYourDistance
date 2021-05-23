/*
	KeepYourDistanceAppC.nc
	Project 1 - Keep Your Distance
	Giacomo Sguotti
	10667547
*/

#define NEW_PRINTF_SEMANTICS
#include "printf.h"
#include "Message.h"

configuration KeepYourDistanceAppC {
}

implementation {
	components MainC, KeepYourDistanceC as App;
	components new TimerMilliC();
	components new AMSenderC(AM_KYD_MSG);
	components new AMReceiverC(AM_KYD_MSG);
	components ActiveMessageC;
	components PrintfC;
	components SerialStartC;

	App.Boot -> MainC.Boot;
	App.MilliTimer -> TimerMilliC;
	App.Receive -> AMReceiverC;
	App.AMSend -> AMSenderC;
  App.AMControl -> ActiveMessageC;
  App.Packet -> AMSenderC;
}