/*
	KeepYourDistanceC.nc
	Project 1 - Keep Your Distance
	Giacomo Sguotti
	10667547
*/

/*
	When a mote is in the proximity area of another mote and receives 10
	consecutive messages from that mote it prints "RECEIVERID SENDERID".
	
	Error descriptions:
		- ERR1 AMControl not started successfully
		- ERR2 MilliTimer fired but locked is true
		- ERR3 length of the received msg is different from the kyd_msg_t
			struct size
		- ERR4 received a sender_id not in range(0,MOTE_NUMBER-1)
		- ERR5 the created kyd_msg_t* is NULL	
*/

#include "Timer.h"
#include "printf.h"
#include "Message.h"

#define MOTE_NUMBER 15

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
	uint16_t previous_msg_n[MOTE_NUMBER]; // previous_msg_n[i-1] stores the last msg_n received from mote i
	uint16_t n = 1; // local msg_n to be sent each time Timer fires
	uint8_t counters[MOTE_NUMBER]; // counters[i-1] stores the number of consecutive msgs received from mote i
	uint8_t i;
	bool locked;

	// --------- Boot.booted() ---------
	event void Boot.booted() {
		// set all counters and previous_msg_n elements to 0
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
  		//printf("ERR1\n");
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
  			printf("ERR5\n");
  			return; // ERR
  		}

  		// include the sender id in the message
  		rcm->sender_id = TOS_NODE_ID;

  		rcm->msg_n = n;
  		
  		n++; // if it reaches 2^16-1 restarts from 0
  		// ATTENTION: the reset of n could lead to false alarms
  		// to minimize the probability of their occurence I used an unint16_t instead of an uint_8_t
  		
  		
  		// send it in broadcast
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
  		//printf("R %u from %u\n", rcm->msg_n, rcm->sender_id);
  		if (rcm->sender_id >= 0 && rcm->sender_id < MOTE_NUMBER+1) {
  			if (rcm->msg_n == previous_msg_n[rcm->sender_id-1] + 1) { // check if consecutive
  				if (counters[rcm->sender_id-1] == 255) { // to avoid false alarms when uint_8 restarts from 0, set it to 11 (does not trigger the alarm)
  					counters[rcm->sender_id-1] = 11;
  					//printf("W %u %u\n", TOS_NODE_ID, rcm->sender_id); // WARNING : motes remained close for a while (2 minutes) despite the alarm
  				} else {
  					counters[rcm->sender_id-1] = counters[rcm->sender_id-1] + 1;
  					//printf("C %u\n", counters[rcm->sender_id-1]);
  				}
  				
  				if (counters[rcm->sender_id-1] == 10){
  					
  					printf("A %u %u\n", TOS_NODE_ID, rcm->sender_id); // ALARM TRIGGERED
  				}
  			} else {
  				counters[rcm->sender_id-1] = 0;
  			}
  			previous_msg_n[rcm->sender_id-1] = rcm->msg_n;
  			printf("M %u R %u F %u\n", TOS_NODE_ID, rcm->msg_n, rcm->sender_id);
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