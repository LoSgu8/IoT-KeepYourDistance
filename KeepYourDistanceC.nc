/*
	KeepYourDistanceC.nc
	Project 1 - Keep Your Distance
	Giacomo Sguotti
	10667547
*/

/*
	Error descriptions:
		- ERR1 AMControl not started successfully
		- ERR2 MilliTimer fired but locked is true
		- ERR3 length of the received msg is different from the kyd_msg_t
			struct size
		- ERR4 received a sender_id not in range(0,MOTE_NUMBER-1)

	When a mote is in the proximity area of another mote and receives 10
	consecutive messages from that mote it prints "RECEIVERID SENDERID".
*/

#include "Timer.h"
#include "printf.h"
#include "Message.h"
#define MOTE_NUMBER 3

module KeepYourDistanceC @safe() {
	uses {
		interface Timer<TMilli> as MilliTimer;
    	interface Boot;
    	interface Receive;
    	interface AMSend;
    	interface SplitControl as AMControl;
    	interface Packet;
  }
}

implementation {
	message_t packet;
	uint16_t previous_msg_n[MOTE_NUMBER];
	uint16_t n = 1;
	uint8_t counters[MOTE_NUMBER];
	uint8_t i;
	bool locked;

	// --------- Boot.booted() ---------
	event void Boot.booted() {
		// initialize counters previous_msg_n elements to 0
		for (i=0; i<MOTE_NUMBER; i++)
			previous_msg_n[i] = 0;
		for (i=0; i<MOTE_NUMBER; i++)
			counters[i] = 0;

    call AMControl.start();
  }

  // --------- AMControl.startDone() ---------
  event void AMControl.startDone(error_t err) {
  	if (err == SUCCESS) {
  		// starts a periodic 500ms Timer
  		call MilliTimer.startPeriodic(500);
  	} else {
  		printf("ERR1\n");
  		call AMControl.start(); // start AMControl again in case of error
  	}
  }

  event void AMControl.stopDone(error_t err) {
  	// do nothing
  }

  // --------- MilliTimer.fired() ---------
  event void MilliTimer.fired() {
  	// SENDING BROADCAST MSG
  	if (locked) {
  		printf("ERR2\n");
  		return;
  	} else {

  		kyd_msg_t* rcm = (kyd_msg_t*)call Packet.getPayload(&packet, sizeof(kyd_msg_t));

  		if (rcm == NULL) {
  			return; // ERR
  		}

  		// include the sender id in the message
  		rcm->sender_id = TOS_NODE_ID;

  		rcm->msg_n = n;
  		// increase n or reset
  		if (n == 2^16 - 1) {
  			n=0;
  		} else {
  			n++;
  		}

  		// send it in broadcast
  		//printf("Mote #%u: sending\n", TOS_NODE_ID);
  		if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(kyd_msg_t)) == SUCCESS) {
				locked = TRUE;
	    }

  	}
  }

  // --------- Receive.receive() ---------
  event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len) {
  	if (len != sizeof(kyd_msg_t)) {
  		printf("ERR3\n");
  	} else {
  		kyd_msg_t* rcm = (kyd_msg_t*)payload;
  		if (rcm->sender_id >= 0 && rcm->sender_id < MOTE_NUMBER+1) {
  			if (rcm->msg_n == previous_msg_n[rcm->sender_id-1] + 1) { // check if consecutive
  				counters[i-1] = counters[i-1] + 1;
  			} else {
  				counters[i-1] = 0;
  			}
  			previous_msg_n[rcm->sender_id-1] = rcm->msg_n;
  		} else {
  			printf("ERR4 %u\n", rcm->sender_id); // mote ID not expected
  		}
  	}
  	return bufPtr;
  }

  // --------- AMSend.sendDone() ---------
  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    if (&packet == bufPtr) {
 	  	locked = FALSE;
    }
  }
}