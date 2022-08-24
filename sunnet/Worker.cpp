#include <iostream>
#include <unistd.h>
#include "Worker.h"
using namespace std;

void Worker::operator()() {
	while (true)
	{
		cout << "working id:" << id << endl;
		usleep(100000);
	}
}