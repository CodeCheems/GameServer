#pragma once
#include <vector>
#include "Worker.h"

class Sunnet {
public:
	static Sunnet* inst;
	Sunnet();
	void Start();

	void Wait();

private:
	int WORKER_NUM = 3;
	vector<Worker*> workers;
	vector<thread*> workerThreads;
	void StartWorker();
};
