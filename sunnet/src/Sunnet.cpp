#include <iostream>
#include "Sunnet.h"
#include <assert.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

using namespace std;


Sunnet* Sunnet::inst;
Sunnet::Sunnet() {
	inst = this;
}

void Sunnet::Start() {
	cout << "Hello Sunnet" << endl;
	pthread_rwlock_init(&servicesLock, NULL);
	pthread_spin_init(&globalLock, PTHREAD_PROCESS_PRIVATE);
	pthread_cond_init(&sleepCond, NULL);
	pthread_mutex_init(&sleepMtx, NULL);
	assert(pthread_rwlock_init(&connsLock, NULL) == 0);
	StartWorker();
	StartSocket();
}

void Sunnet::StartWorker() {
	for (int i = 0; i < WORKER_NUM; i++)
	{
		cout << "start worker thread:" << i << endl;
		Worker* worker = new Worker();
		worker->id = i;
		worker->eachNum = 2<<i;
		thread* wt = new thread(*worker);
		workers.push_back(worker);
		workerThreads.push_back(wt);
	}
}

void Sunnet::StartSocket() {
	socketWorker = new SocketWorker();
	socketWorker->Init();
	socketThread = new thread(*socketWorker);
}

void Sunnet::Wait() {
	if (workerThreads[0]){
		workerThreads[0]->join();
	}
}

uint32_t Sunnet::NewService(shared_ptr<string> type) {
	auto srv = make_shared<Service>();
	srv->type = type;
	pthread_rwlock_wrlock(&servicesLock); {
		srv->id = maxId;
		maxId++;
		services.emplace(srv->id, srv);
	}
	pthread_rwlock_unlock(&servicesLock);
	srv->OnInit();
	return srv->id;
}

shared_ptr<Service> Sunnet::GetService(uint32_t id) {
	shared_ptr<Service> srv = NULL;
	pthread_rwlock_rdlock(&servicesLock); {
		unordered_map<uint32_t, shared_ptr<Service>>::iterator iter = services.find(id);
		if (iter != services.end()) {
			srv = iter->second;
		}
	}
	pthread_rwlock_unlock(&servicesLock);
	return srv;
}

void Sunnet::KillService(uint32_t id) {
	shared_ptr<Service> srv = GetService(id);
	if (!srv) {
		return;
	}
	srv->OnExit();
	srv->isExiting = true;
	pthread_rwlock_wrlock(&servicesLock); {
		services.erase(id);
	}
	pthread_rwlock_unlock(&servicesLock);
}

shared_ptr<Service> Sunnet::PopGlobalQueue() {
	shared_ptr<Service> srv = NULL;
	pthread_spin_lock(&globalLock); {
		if (!globalQueue.empty()) {
			srv = globalQueue.front();
			globalQueue.pop();
			globalLen--;
		}
	}
	pthread_spin_unlock(&globalLock);
	return srv;
}

void Sunnet::PushGlobalQueue(shared_ptr<Service> srv) {
	pthread_spin_lock(&globalLock); {
		globalQueue.push(srv);
		globalLen++;
	}
	pthread_spin_unlock(&globalLock);
}
void Sunnet::Send(uint32_t toId, shared_ptr<BaseMsg> msg) {
	shared_ptr<Service> tosrv = GetService(toId);
	if (!tosrv) {
		cout << "send fail ,tosrv not exist toId:" << toId << endl;
		return;
	}
	tosrv->PushMsg(msg);
	bool hasPush = false;
	pthread_spin_lock(&tosrv->inGlobalLock); {
		if (!tosrv->inGlobal) {
			PushGlobalQueue(tosrv);
			tosrv->inGlobal = true;
			hasPush = true;
		}
	}
	pthread_spin_unlock(&tosrv->inGlobalLock);
	if (hasPush) {
		CheckAndWeakUp();
	}
}

shared_ptr<BaseMsg> Sunnet::MakeMsg(uint32_t source, char* buff, int len) {
	auto msg = make_shared<ServiceMsg>();
	msg->type = BaseMsg::TYPE::SERVICE;
	msg->source = source;
	msg->buff = shared_ptr<char>(buff);
	msg->size = len;
	return msg;
}
void Sunnet::WorkerWait() {
	pthread_mutex_lock(&sleepMtx);
	sleepCount++;
	pthread_cond_wait(&sleepCond, &sleepMtx);
	sleepCount--;
	pthread_mutex_unlock(&sleepMtx);
}
void Sunnet::CheckAndWeakUp() {
	//unsafe
	if (sleepCount == 0) {
		return;
	}
	if (WORKER_NUM - sleepCount <= globalLen) {
		cout << "weakup" << endl;
		pthread_cond_signal(&sleepCond);
	}
}

int Sunnet::AddConn(int fd, uint32_t id, Conn::TYPE type) {
	auto conn = make_shared<Conn>();
	conn->fd = fd;
	conn->serviceId = id;
	conn->type = type;
	pthread_rwlock_wrlock(&connsLock); 
	{
		conns.emplace(fd, conn);
	}
	pthread_rwlock_unlock(&connsLock);
	return fd;
}

shared_ptr<Conn> Sunnet::GetConn(int fd) {
	shared_ptr<Conn> conn = NULL;
	pthread_rwlock_rdlock(&connsLock); {
		unordered_map<uint32_t, shared_ptr<Conn>>::iterator iter = conns.find(fd);
		if (iter != conns.end()) {
			conn = iter->second;
		}
	}
	pthread_rwlock_unlock(&connsLock);
	return conn;
}

bool Sunnet::RemoveConn(int fd) {
	int result;
	pthread_rwlock_wrlock(&connsLock); {
		result = conns.erase(fd);
	}
	pthread_rwlock_unlock(&connsLock);
	return result == 1;
}

int Sunnet::Listen(uint32_t port, uint32_t serviceId) {
	int listenFd = socket(AF_INET, SOCK_STREAM, 0);

}

