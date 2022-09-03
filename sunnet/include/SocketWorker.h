#pragma once
using namespace std;
#include <sys/epoll.h>
#include <memory>
#include "Conn.h"

class SocketWorker {
public:
	void Init();
	void operator()();

	void AddEvent(int fd);
	void RemoveEvent(int fd);
	void ModifyEvent(int fd, bool epollOut);
private:
	int epollFd;

	void OnEvent(epoll_event ev);
	void OnAccept(shared_ptr<Conn> conn);
	void OnRw(shared_ptr<Conn> conn, bool r, bool w);
};