#include "cachelab.c"
#include <getopt.h>
#include <unistd.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int s,S,b,E;
int hitNum,missNum,evictionNum;
int curtime = 0;		//表示当前时间，用于标记每个记录最后一次被访问的时间

typedef struct {
	int valid;
	int tag;
	int time_stamp;		//最后一次被访问的时间
}Cache_Line;

typedef struct {
	Cache_Line *lines;
}Cache_Set;

typedef struct {
	Cache_Set *sets;
}Cache;

Cache cache;

void cache_initiate() {					//初始化cache
	cache.sets = (Cache_Set *) malloc(sizeof(Cache_Set) * S);
	for (int i = 0; i < S; i++) {
		Cache_Set set;
		set.lines = (Cache_Line *)malloc(sizeof(Cache_Line) * E);
		cache.sets[i] = set;
		for (int j = 0; j < E; j++) {
			Cache_Line line;
			line.valid = 0;
			line.tag = -1;				//tag的初值必须保证和所有可能地址的tag不同
			line.time_stamp = 0;
			set.lines[j] = line;
		}
	}
}

void simulate(unsigned int address) {
	int setindex = (address >> b) & ((-1U) >> (64-s));	//求组索引
	int tag = address >> (b+s);			//求标签值

	int min_stamp = INT_MAX;			//找最小的时间标签进行替换，即最久未用的记录
	int min_stamp_index = -1;			

	for(int i=0; i<E; ++i){				//在指定组中找到标签匹配的行
		if(cache.sets[setindex].lines[i].tag == tag){
			cache.sets[setindex].lines[i].time_stamp = curtime;
			hitNum++;
			return ;
		}
	}

	for(int i=0; i<E; ++i){				//在指定组中找空行存储
		if(cache.sets[setindex].lines[i].valid == 0){
			cache.sets[setindex].lines[i].valid = 1;
			cache.sets[setindex].lines[i].tag = tag;
			cache.sets[setindex].lines[i].time_stamp = curtime;
			missNum++;
			return;
		}
	}

	missNum++;
	evictionNum++;

	for (int i = 0; i < E; ++i){		//在指定组中找到最久未用的空行进行替换
		if(cache.sets[setindex].lines[i].time_stamp < min_stamp){
			min_stamp = cache.sets[setindex].lines[i].time_stamp;
			min_stamp_index = i;
		}
	}
	cache.sets[setindex].lines[min_stamp_index].tag = tag;
	cache.sets[setindex].lines[min_stamp_index].time_stamp = curtime;
	return ;
	
}

void PrintUsage() {		//打印帮助信息
	printf("Usage: ./csim [-h] [-v] -s <s> -E <E> -b <b> -t <tracefile>\n");
	printf("-s: number of set index(2^s sets)\n");
	printf("-E: number of lines per set\n");
	printf("-b: number of block offset bits\n");
	printf("-t: trace file name\n");
}

int main(int argc, char** argv) {
	Cache cache;

	char* trace;	//输入文件
	char input;		//参数
	hitNum = 0;
	missNum = 0;
	evictionNum = 0;
	
	while ((input = getopt(argc, argv, "s:E:b:t:vh")) != -1) {
		switch (input)
		{
		case 's':
			s = atoi(optarg);
			break;
		case 'E':
			E = atoi(optarg);
			break;
		case 'b':
			b = atoi(optarg);
			break;
		case 't':
			trace = optarg;
			break;
		case 'v':
			PrintUsage();
			break;
		case 'h':
			PrintUsage();
			break;
		default:
			PrintUsage();
			break;
		}
	}

	S = 1 << s;

	cache_initiate();
	FILE* file;
	char command;
	unsigned int address;
	int size;
	file = fopen(trace, "r");
	while (fscanf(file, "%c %xu,%d\n", &command, &address, &size) > 0) {
		curtime++;
		switch (command) {
		case 'L':
			simulate(address);
			break;
		case 'M':
			simulate(address);		//M操作需要访问两次
			simulate(address);
			break;
		case 'S':
			simulate(address);
			break;
		default:
			break;
		}
	}
	fclose(file);
	printSummary(hitNum, missNum, evictionNum);
	return 0;
}
