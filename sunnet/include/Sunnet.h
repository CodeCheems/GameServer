#pragma once
#include <vector>
#include "Worker.h"
#include "Service.h"
#include <unordered_map>
#include "SocketWorker.h"
#include "Conn.h"

class Sunnet {
public:
	static Sunnet* inst;
	unordered_map<uint32_t, shared_ptr<Service>> services;
	uint32_t maxId = 0;//最大id
	pthread_rwlock_t servicesLock;//读写锁
	
	Sunnet();
	void Start();

	void Wait();
	uint32_t NewService(shared_ptr<string> type);
	void KillService(uint32_t id);
	void Send(uint32_t toId, shared_ptr<BaseMsg> msg);
	shared_ptr<BaseMsg> MakeMsg(uint32_t source, char* buff, int len);
	shared_ptr<Service> PopGlobalQueue();
	void PushGlobalQueue(shared_ptr<Service> srv);
	//唤醒工作线程
	void CheckAndWeakUp();
	//让工作线程等待（仅工作线程调用）
	void WorkerWait();
	//增删查
	int AddConn(int fd, uint32_t id, Conn::TYPE type);
	shared_ptr<Conn> GetConn(int fd);
	bool RemoveConn(int fd);

	//网络连接操作接口
	int Listen(uint32_t port, uint32_t serviceId);
	void CloseConn(uint32_t fd);
private:
	int WORKER_NUM = 3;
	vector<Worker*> workers;
	vector<thread*> workerThreads;
	queue<shared_ptr<Service>> globalQueue;
	int globalLen = 0;//队列长度
	pthread_spinlock_t globalLock;
	//休眠和唤醒
	pthread_mutex_t sleepMtx;
	pthread_cond_t sleepCond;
	int sleepCount = 0;
	void StartWorker();
	shared_ptr<Service> GetService(uint32_t id);

	SocketWorker* socketWorker;
	thread* socketThread;
	void StartSocket();
	unordered_map<uint32_t, shared_ptr<Conn>> conns;
	pthread_rwlock_t connsLock;
};
