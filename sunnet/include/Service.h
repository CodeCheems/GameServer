#pragma once
#include <queue>
#include <thread>
#include "Msg.h"

using namespace std;

class Service {
public:
	uint32_t id; //唯一id
	shared_ptr<string> type;//类型
	bool isExiting = false;//是否正在退出
	queue<shared_ptr<BaseMsg>> msgQueue;//消息列表
	pthread_spinlock_t queueLock; // 锁
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