#pragma once
using namespace std;

class BaseMsg {
public:
	enum TYPE {
		SERVICE = 1;
	};
	uint8_t type;
	char load[999999]{};
	virtual ~BaseMsg() {};
};