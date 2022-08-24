#pragma once
#include <thread>

//class Sunnet;
using namespace std;

class Worker {
public:
	int id;
	int eachNum;
	void operator()();
};