/*
	Message.h
	Project 1 - Keep Your Distance
	Giacomo Sguotti
	10667547
*/
#ifndef MESSAGE_H
#define MESSAGE_H

typedef nx_struct kyd_msg {
	nx_uint8_t sender_id;
} kyd_msg_t;

enum {
  AM_KYD_MSG = 6,
};

#endif
