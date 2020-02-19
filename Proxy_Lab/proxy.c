#include <stdio.h>
#include "csapp.h"
#include <limits.h>
/* Recommended max cache and object sizes */
#define MAX_CACHE_SIZE 1049000
#define MAX_OBJECT_SIZE 102400

/* You won't lose style points for including this long line in your code */
static const char *user_agent_hdr = "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:10.0.3) Gecko/20120305 Firefox/10.0.3\r\n";

typedef struct {
	char cache_uri[MAXLINE];	//uri
    char cache_obj[MAX_OBJECT_SIZE]; 	//uri中的资源
    int timestamp;	   //时间戳
    int isEmpty;	   //是否被占用

    int readerNum;     //读者数量
    sem_t rnMutex;     //对读者数量的访问互斥

    sem_t wMutex;      //写互斥

}Cache_block;	//缓存块

typedef struct {
    Cache_block cache_blocks[10]; //缓存块
}Cache;		//缓存

Cache cache;
int curtime = 0;		//当前时间，用于标记每个cache块最后一次被访问的时间

void cache_init(){
	for(int i=0; i<10; i++){
		cache.cache_blocks[i].timestamp = 0;
		cache.cache_blocks[i].isEmpty = 1;
		cache.cache_blocks[i].readerNum = 0;
		Sem_init(&cache.cache_blocks[i].rnMutex, 0, 1);		//初始化信号量，线程共享，资源数量为1

		Sem_init(&cache.cache_blocks[i].wMutex, 0, 1);		//初始化信号量，线程共享，资源数量为1
	}
}

void readPre(int i){					//读前操作
	P(&cache.cache_blocks[i].rnMutex);	//占据读者数量修改权
	if(cache.cache_blocks[i].readerNum == 0){	//如果是第一个读者，则同时需要占据写权
		P(&cache.cache_blocks[i].wMutex);
	}
	cache.cache_blocks[i].readerNum++;	//修改读者数量
	V(&cache.cache_blocks[i].rnMutex);	//释放修改读者权
}

void readAft(int i){					//读后操作
	P(&cache.cache_blocks[i].rnMutex);	//占据读者数量修改权
	cache.cache_blocks[i].readerNum--;	//修改读者数量
	if(cache.cache_blocks[i].readerNum == 0){	//如果是最后一个读者则释放写权
		V(&cache.cache_blocks[i].wMutex);
	}
	V(&cache.cache_blocks[i].rnMutex);	//释放读者数量修改权
}

void writePre(int i){			//写前操作，占据写权
    P(&cache.cache_blocks[i].wMutex);
}

void writeAft(int i){			//写后操作，释放写权
    V(&cache.cache_blocks[i].wMutex);
}

int cache_find(char *uri){		//寻找是否缓存，如果缓存则返回缓存块编号，否则返回-1
	int pos = -1;
	for(int i=0; i<10; i++){
		readPre(i);
		if((cache.cache_blocks[i].isEmpty == 0) && (strcmp(uri, cache.cache_blocks[i].cache_uri) == 0)){
			pos = i;
			break;
		}
		readAft(i);
	}
	return pos;
}

int cache_eviction(){			//寻找一个缓存位，如果找不到则找到最久未用的替换掉
	int min = INT_MAX;
	int minIndex = -1;

	int hasEmpty = -1;
	for(int i=0; i<10; i++){
		readPre(i);
		if(cache.cache_blocks[i].isEmpty == 1){
			hasEmpty = i;
			readAft(i);
			break;
		}
		readAft(i);
	}

	if(hasEmpty != -1){		//找到了空的缓存位
		return hasEmpty;
	}
	
	for(int i=0; i<10; i++){	//找最久未用的块替换
		readPre(i);
		if(cache.cache_blocks[i].timestamp < min){
			minIndex = i;
			min = cache.cache_blocks[i].timestamp;
		}
		readAft(i);
	}
	return minIndex;
}

void cache_uri(char *uri, char *buf){		//缓存一个uri及其资源
	int i = cache_eviction();	//寻找一个合适的块缓存

	writePre(i);
	strcpy(cache.cache_blocks[i].cache_uri, uri);
	strcpy(cache.cache_blocks[i].cache_obj, buf);
	cache.cache_blocks[i].isEmpty = 0;
	cache.cache_blocks[i].timestamp = curtime;	//更新最后一次使用时间
	writeAft(i);
}

void parse_uri(char *uri, char *hostname, char *filename, int *port){		//解析URI
	*port = 80;
	char *pos1 = strstr(uri, "//");	//http://之后的内容
	pos1 = (pos1!=NULL) ? pos1+2:uri;
	char *pos2 = strstr(pos1, ":");	//冒号之后的内容，紧跟着端口号

	if(pos2 != NULL){	//有端口号
		*pos2 = '\0'; 
		sscanf(pos1, "%s", hostname);	//主机名
		sscanf(pos2+1, "%d%s", port,filename);	//端口号和文件路径
	}
	else{	//没有端口号
		pos2 = strstr(pos1, "/");	//找到文件路径和主机名的分割点
		if(pos2 != NULL){
			*pos2 = '\0';
			sscanf(pos1, "%s",hostname);	//主机名
			*pos2 = '/';
			sscanf(pos2, "%s", filename);	//文件路径
		}
		else{	//只有主机名
			sscanf(pos1, "%s", hostname);
		}
	}
}

void build_header(char *reqHdrs, char *hostname, char *filename, int port, rio_t *client_rio){	
	char buf[MAXLINE], reqHdr[MAXLINE], othHdr[MAXLINE], hostHdr[MAXLINE];
	sprintf(reqHdr, "GET %s HTTP/1.0\r\n", filename);

	while(Rio_readlineb(client_rio, buf, MAXLINE) > 0){		//按行读取头文件信息
		if(strcmp(buf,  "\r\n") == 0){		//读到结尾
			break;
		}

		if(!strncasecmp(buf, "Host", strlen("Host"))){	//读到主机名字段
			strcpy(hostHdr, buf);
			continue;
		}
		if(!strncasecmp(buf, "Connection", strlen("Connection"))
			&& !strncasecmp(buf, "Proxy-Connection", strlen("Proxy-Connection"))
			&& !strncasecmp(buf, "User-Agent", strlen("User-Agent"))){		//其它内容

				strcat(othHdr, buf);
		}
	}
	if(strlen(hostHdr) == 0){		//如果没有主机名，将客户端主机名添加进去
		sprintf(hostHdr, "Host: %s\r\n", hostname);
	}
	//构造请求头
	sprintf(reqHdrs, "%s%s%s%s%s%s%s", 		
		reqHdr,
		hostHdr,
		"Connection: close\r\n",
		"Proxy-Connection: close\r\n",
		user_agent_hdr,
		othHdr,
		"\r\n");
	return;
}

void doit(int fd){
	int end_serverfd;		//服务器套接字接口
	char buf[MAXLINE], method[MAXLINE], uri[MAXLINE], version[MAXLINE];
	char hostname[MAXLINE], filename[MAXLINE], reqHdrs[MAXLINE];
	int port;	//端口
	rio_t rio, server_rio;	//读写

	Rio_readinitb(&rio, fd);	//初始化和客户端直接的读写
	Rio_readlineb(&rio, buf, MAXLINE);	//读取一行
	printf("Request headers:\n");	
	printf("%s", buf);

	sscanf(buf, "%s %s %s", method, uri, version);	//分离方法、URI和HTTP版本
	char curi[MAXLINE];
	strcpy(curi, uri); 	//保留完整的uri，解析uri时uri会被破坏
	if(strcasecmp(method, "GET")){
		printf("Proxy does not implement this metho\n");
		return;
	}

	int cache_index;
	if((cache_index = cache_find(curi)) != -1){		//是否有缓存块
		readPre(cache_index);
		Rio_writen(fd, cache.cache_blocks[cache_index].cache_obj, strlen(cache.cache_blocks[cache_index].cache_obj));	//直接使用缓存回写
		readAft(cache_index);

		writePre(cache_index);
		cache.cache_blocks[cache_index].timestamp = curtime;	//更新最后一次使用时间
		writeAft(cache_index);

		curtime++;		//当前时间加一
		return;
	}
	
	parse_uri(uri, hostname, filename, &port);	//解析URI提取主机名、文件路径和端口

	build_header(reqHdrs, hostname, filename, port, &rio);	//提取头部信息


	char portStr[100];	//port转字符串
	sprintf(portStr, "%d", port);
	end_serverfd = Open_clientfd(hostname, portStr);	//与服务器建立套接字

	if(end_serverfd < 0){
		printf("Connection failed\n");
		return;
	}

	Rio_readinitb(&server_rio, end_serverfd);	//初始化与服务器套接字的接口
	Rio_writen(end_serverfd, reqHdrs, strlen(reqHdrs));	//向服务器发送访问请求

	char cache_buf[MAX_OBJECT_SIZE];	//向cache写入的内容
	int bufsize = 0;		//页面的累计大小
	size_t n;
	while((n = Rio_readlineb(&server_rio, buf, MAXLINE)) != 0){	//从服务器接收数据
		printf("Proxy received %d bytes, then send\n", n);
		bufsize += n;
		if(bufsize < MAX_OBJECT_SIZE){	//累计内容小于缓存块大小则写入缓存内容
			strcat(cache_buf, buf);
		}
		Rio_writen(fd, buf, n);	//向客户端返回数据
	}
	if(bufsize < MAX_OBJECT_SIZE){	//累计内容小于缓存块大小则进行缓存
		cache_uri(curi, cache_buf);
	}
	curtime++;		//当前时间加一
	Close(end_serverfd);	//关闭与服务器的连接
}

void *thread(void *vargp){		//对等线程路线
	int connfd = (int)vargp;	//获取已建立的套接字
	Pthread_detach(pthread_self());	 	//分离自己
	doit(connfd);	//处理请求
    Close(connfd);	//关闭请求
    return NULL;
}

int main(int argc, char **argv)
{
    int listenfd, connfd;	//监听套接字和已连接套接字
    char hostname[MAXLINE], port[MAXLINE];	//主机名和端口号
    socklen_t clientlen;	//客户端协议长度
    struct sockaddr_storage clientaddr;	//客户协议地址
    pthread_t tid;	//线程ID

    if(argc != 2){	//参数不足
    	fprintf(stderr, "usage:%s <port>\n", argv[0]);
    	exit(1);
    }
    cache_init();
    Signal(SIGPIPE, SIG_IGN);
    listenfd = Open_listenfd(argv[1]);	//根据端口号建立监听套接字
    while(1){
    	clientlen = sizeof(clientaddr);	
    	connfd = Accept(listenfd, (SA *)&clientaddr, &clientlen);	//获得已连接套接字

    	Getnameinfo((SA *)&clientaddr, clientlen, hostname, MAXLINE, port, MAXLINE, 0);	//从客户端协议地址中获取主机名和端口号
    	printf("Accepted connection from (%s, %s).\n", hostname, port);		
        
        Pthread_create(&tid, NULL, thread, (void *)connfd);	//创建线程，传递参数为已连接的套接字
    	
    	// doit(connfd);	//处理请求
    	// Close(connfd);	//关闭请求
    }
    return 0;
}
