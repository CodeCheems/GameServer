#include "Sunnet.h"

int main()
{
	new Sunnet();
	Sunnet::inst->Start();
	auto pingType = make_shared<string>("ping");
	uint32_t ping1 = Sunnet::inst->NewService(pingType);
	uint32_t ping2 = Sunnet::inst->NewService(pingType);
	uint32_t pong = Sunnet::inst->NewService(pingType);
	auto msg1 = Sunnet::inst->MakeMsg(ping1, new char[3]{ 'h','i','\0' }, 3);
	auto msg2 = Sunnet::inst->MakeMsg(ping2, new char[4]{ 'h','e','y','\0' }, 4);
	Sunnet::inst->Send(pong, msg1);
	Sunnet::inst->Send(pong, msg2);
	Sunnet::inst->Wait();
	return 0;
}