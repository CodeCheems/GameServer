#pragma once
#include <queue>
#include <thread>
#include "Msg.h"

using namespace std;

class Service {
public:
	uint32_t id; //Ψһid
	shared_ptr<string> type;//����
	bool isExiting = false;//�Ƿ������˳�
	queue<shared_ptr<BaseMsg>> msgQueue;//��Ϣ�б�
	pthread_spinlock_t queueLock; // ��
	bool inGlobal = false;
	pthread_spinlock_t inGlobalLock;

	Service();
	~Service();
	void OnInit();
	void OnMsg(shared_ptr<BaseMsg> msg);
	void OnExit();

	void PushMsg(shared_ptr<BaseMsg> msg);
	bool ProcessMsg();
	void ProcessMsgs(int max);

	void SetInGlobal(bool isIn);
private:
	shared_ptr<BaseMsg> PopMsg();
};