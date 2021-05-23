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

	When a mote is in the proximity area of another mote and receives 10
	consecutive messages from that mote it prints "RECEIVERID SENDERID".
*/

#include "Timer.h"
#include "printf.h"
#include "Message.h"

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
	uint8_t previous_message_id = -1;
	uint8_t same_id_counter = 0;
	bool locked;

	// --------- Boot.booted() ---------
	event void Boot.booted() {
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
  	if (locked) {
  		printf("ERR2\n");
  		return;

  	} else {
  		kyd_msg_t* rcm = (kyd_msg_t*)call Packet.getPayload(&packet, sizeof(kyd_msg_t));
  		if (rcm == NULL) {
  			return;
  		}
  		// include the sender id in the message
  		rcm->sender_id = TOS_NODE_ID;
  		// send it in broadcast
  		if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(kyd_msg_t)) == SUCCESS) {
				locked = TRUE;
	    }
  	}
  }

  // --------- Receive.receive() ---------
  event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len) {
  	if (len != sizeof(kyd_msg_t)) {
  		return bufPtr;
  		printf("ERR3\n");
  	} else {
  		kyd_msg_t* rcm = (kyd_msg_t*)payload;

  		if (rcm->sender_id == previous_message_id) { // consecutive msg
  			same_id_counter++; // update the counter
  			if (same_id_counter > 9) { // print even if received more than 10 consecutive msgs
  				printf("%u %u", TOS_NODE_ID, previous_message_id);
  			}
  			} else { // non consecutive msg
  				same_id_counter = 0; // reset counter
  				previous_message_id = rcm->sender_id; // update previous msg id
  			}
  		}
  	}

  // --------- AMSend.sendDone() ---------
  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    if (&packet == bufPtr) {
 	  	locked = FALSE;
    }
  }
}