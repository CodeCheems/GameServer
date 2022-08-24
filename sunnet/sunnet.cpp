#include <iostream>
#include "sunnet.h"
using namespace std;


Sunnet* Sunnet::inst;
Sunnet::Sunnet() {
	inst = this;
}

void Sunnet::Start() {
	cout << "Hello Sunnet" << endl;
	StartWorker();
}

void Sunnet::StartWorker() {
	for (int i = 0; i < WORKER_NUM; i++)
	{
		cout << "start worker thread:" << i << endl;
		Worker* worker = new Worker();
		worker->id = i;
		worker->eachNum = 2 << i;
		thread* wt = new thread(*worker);
		workers.push_back(worker);
		workerThreads.push_back(wt);
	}
}

void Sunnet::Wait() {

}

