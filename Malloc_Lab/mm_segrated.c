/*
 * mm-naive.c - The fastest, least memory-efficient malloc package.
 * 
 * In this naive approach, a block is allocated by simply incrementing
 * the brk pointer.  A block is pure payload. There are no headers or
 * footers.  Blocks are never coalesced or reused. Realloc is
 * implemented directly using mm_malloc and mm_free.
 *
 * NOTE TO STUDENTS: Replace this header comment with your own header
 * comment that gives a high level description of your solution.
 */
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <unistd.h>
#include <string.h>

#include "mm.h"
#include "memlib.h"

/*********************************************************
 * NOTE TO STUDENTS: Before you do anything else, please
 * provide your team information in the following struct.
 ********************************************************/
team_t team = {
    /* Team name */
    "segregated_free_listscode",
    /* First member's full name */
    "ZhangXiaodong",
    /* First member's email address */
    "xiaodongzhang97@gmail.com",
    /* Second member's full name (leave blank if none) */
    "",
    /* Second member's email address (leave blank if none) */
    ""
};

/* single word (4) or double word (8) alignment */
#define ALIGNMENT 8

/* rounds up to the nearest multiple of ALIGNMENT */
#define ALIGN(size) (((size) + (ALIGNMENT-1)) & ~0x7)


#define SIZE_T_SIZE (ALIGN(sizeof(size_t)))

#define WSIZE     4
#define DSIZE     8
#define LISTMAX   16 

#define INITCHUNKSIZE (1<<6)
#define CHUNKSIZE (1<<12)

#define MAX(x, y) ((x) > (y) ? (x) : (y))
#define MIN(x, y) ((x) < (y) ? (x) : (y))

#define PACK(size, alloc) ((size) | (alloc))


#define GET(p)            (*(unsigned int *)(p))
#define PUT(p, val)       (*(unsigned int *)(p) = (val))

#define GET_SIZE(p)  (GET(p) & ~0x7)
#define GET_ALLOC(p) (GET(p) & 0x1)

#define HDRP(ptr) ((char *)(ptr) - WSIZE)
#define FTRP(ptr) ((char *)(ptr) + GET_SIZE(HDRP(ptr)) - DSIZE)

#define NEXT_BLKP(ptr) ((char *)(ptr) + GET_SIZE((char *)(ptr) - WSIZE))
#define PREV_BLKP(ptr) ((char *)(ptr) - GET_SIZE((char *)(ptr) - DSIZE))

#define SET_PTR(p, ptr) (*(unsigned int *)(p) = (unsigned int)(ptr))    //设置分离空块列表  

#define PRED_PTR(ptr) ((char *)(ptr))     //下一个空块的二级指针
#define SUCC_PTR(ptr) ((char *)(ptr) + WSIZE)   //上一个空块的二级指针

#define PRED(ptr) (*(char **)(ptr))        //下一个空块的指针
#define SUCC(ptr) (*(char **)(SUCC_PTR(ptr)))   //上一个空块的指针

char *heap_listp = NULL;

void *segregated_free_lists[LISTMAX];

static void insert_node(void *ptr, size_t size){    //插入空块
    int listnum = 0;
    void *next_ptr = NULL;
    void *last_ptr = NULL;

    while((listnum < LISTMAX -1 ) && (size > 1)){   //寻找大小合适的类，否则就放最后一类
        size >>= 1;
        listnum++;
    }
    next_ptr = segregated_free_lists[listnum];    //在该类里找到合适的位置，保持从小到大
    while((next_ptr != NULL) && (size > GET_SIZE(HDRP(next_ptr)))){
        last_ptr = next_ptr;
        next_ptr = PRED(next_ptr);
    }

    if(next_ptr != NULL){
        if(last_ptr != NULL){       //插在中间
            SET_PTR(PRED_PTR(ptr), next_ptr);
            SET_PTR(SUCC_PTR(next_ptr), ptr);

            SET_PTR(SUCC_PTR(ptr), last_ptr);
            SET_PTR(PRED_PTR(last_ptr), ptr);
        }
        else{                       //插在链首
            SET_PTR(PRED_PTR(ptr), next_ptr);
            SET_PTR(SUCC_PTR(next_ptr), ptr);
            SET_PTR(SUCC_PTR(ptr), NULL);
            segregated_free_lists[listnum] = ptr;
        }
    }
    else{
        if(last_ptr != NULL){       //插在链尾
            SET_PTR(PRED_PTR(ptr), NULL);
            SET_PTR(SUCC_PTR(ptr), last_ptr);
            SET_PTR(PRED_PTR(last_ptr), ptr);
        }   
        else{                       //空链插入
            SET_PTR(PRED_PTR(ptr), NULL);
            SET_PTR(SUCC_PTR(ptr), NULL);
            segregated_free_lists[listnum] = ptr;
        }
    }
}

static void delete_node(void *ptr){
    int listnum = 0;
    size_t size = GET_SIZE(HDRP(ptr));

    while((listnum < LISTMAX - 1) && (size > 1)){   //跳转至该块大小所属的链
        size >>= 1;
        listnum++;
    }

    if(PRED(ptr) != NULL){      
        if(SUCC(ptr) != NULL){  //上下都不为空
            SET_PTR(SUCC_PTR(PRED(ptr)), SUCC(ptr));
            SET_PTR(PRED_PTR(SUCC(ptr)), PRED(ptr));
        }
        else{                   //删除链首
            SET_PTR(SUCC_PTR(PRED(ptr)), NULL);
            segregated_free_lists[listnum] = PRED(ptr);
        }
    }  
    else{
        if(SUCC(ptr) != NULL){      //删除链尾
            SET_PTR(PRED_PTR(SUCC(ptr)), NULL);
        }
        else{                       //删除链中最后一个
            segregated_free_lists[listnum] = NULL;
        }
    }
}

static void *coalesced(void *bp){           //合并空块
    size_t prev_alloc = GET_ALLOC(FTRP(PREV_BLKP(bp)));     //前一块有效位
    size_t next_alloc = GET_ALLOC(HDRP(NEXT_BLKP(bp)));     //后一块有效位
    size_t size = GET_SIZE(HDRP(bp));                       //当前块大小

    if(prev_alloc && next_alloc){       //前后块均非空
        return bp;
    }
    else if(prev_alloc && !next_alloc){     //后块为空
        delete_node(bp);
        delete_node(NEXT_BLKP(bp));
        size += GET_SIZE(HDRP(NEXT_BLKP(bp)));
        PUT(HDRP(bp), PACK(size, 0));
        PUT(FTRP(bp), PACK(size, 0));
    }
    else if(!prev_alloc && next_alloc){     //前块为空
        delete_node(bp);
        delete_node(PREV_BLKP(bp));
        size += GET_SIZE(HDRP(PREV_BLKP(bp)));  //加上前块大小
        PUT(FTRP(bp), PACK(size, 0));           //修改尾块
        PUT(HDRP(PREV_BLKP(bp)), PACK(size, 0));    //修改块头
        bp = PREV_BLKP(bp); //bp变为前块的有效部分
    }
    else{
        delete_node(bp);
        delete_node(PREV_BLKP(bp));
        delete_node(NEXT_BLKP(bp));
        size += GET_SIZE(HDRP(NEXT_BLKP(bp))) + GET_SIZE(HDRP(PREV_BLKP(bp))); //给当前块加上前后两块的大小
        PUT(HDRP(PREV_BLKP(bp)), PACK(size, 0));    //修改前块头
        PUT(FTRP(NEXT_BLKP(bp)), PACK(size, 0));    //修改后块尾
        bp = PREV_BLKP(bp);                         //bp前块有效部分
    }
    insert_node(bp, size);  //插入新块
    return bp;      //返回bp
}

static void *extend_heap(size_t words){         
    char *bp;
    size_t size;

    size = (words % 2) ? (words + 1) * WSIZE : words * WSIZE;   //将size变为WSIZE的整数倍
    if((long)(bp = mem_sbrk(size)) == -1){      //增加堆大小,bp变为之前的块尾
        return NULL;
    }

    PUT(HDRP(bp), PACK(size, 0));       //修改块尾变为新块
    PUT(FTRP(bp), PACK(size, 0));
    PUT(HDRP(NEXT_BLKP(bp)), PACK(0,1));    //增加新块尾

    insert_node(bp, size);      //将扩增的块作为新增空块插入

    return coalesced(bp);       //合并块尾和之前的空块
}


static void place(void *bp, size_t asize)   //修改有效位
{
    size_t size = GET_SIZE(HDRP(bp));
    size_t remain = size - asize;   //剩余空间
    delete_node(bp);             //从空表中删除该节点
    if (remain < 2*DSIZE) {      //如果剩余空间小于两倍的DSIZE则直接分配
        PUT(HDRP(bp),PACK(size,1)); 
        PUT(FTRP(bp),PACK(size,1));
    } 
    else{   //剩余空间足够多需要分离后面的空块
        PUT(HDRP(bp),PACK(asize,1));    
        PUT(FTRP(bp),PACK(asize,1));
        PUT(HDRP(NEXT_BLKP(bp)),PACK(remain,0));
        PUT(FTRP(NEXT_BLKP(bp)),PACK(remain,0));
        insert_node(NEXT_BLKP(bp), remain);
    }
}

/* 
 * mm_init - initialize the malloc package.
 */
int mm_init(void)
{
    if((heap_listp = mem_sbrk(4*WSIZE)) == (void *)-1){
        return -1;
    }
    
    PUT(heap_listp, 0);                             //对齐块（和结尾块凑一组）
    PUT(heap_listp + (1*WSIZE), PACK(DSIZE, 1));    //序言块头
    PUT(heap_listp + (2*WSIZE), PACK(DSIZE, 1));    //序言块尾
    PUT(heap_listp + (3*WSIZE), PACK(0,1));         //结尾块
    heap_listp += (2*WSIZE);                        //让堆指针指向序言块两块中的后一块

    int listnum;
    for(listnum = 0; listnum < LISTMAX; listnum++){     //初始化分离空闲链表
        segregated_free_lists[listnum] = NULL;
    }
    if(extend_heap(CHUNKSIZE/WSIZE) == NULL){
        return -1;
    }
    return 0;
}


/* 
 * mm_malloc - Allocate a block by incrementing the brk pointer.
 *     Always allocate a block whose size is a multiple of the alignment.
 */
void *mm_malloc(size_t size)
{
    size_t asize;
    size_t extendsize;
    char *bp = NULL;

    if(size == 0){
        return NULL;
    }

    if(size <= DSIZE){      //申请空间不足两个双字节的不足，大于的保证是双字节的整数倍
        asize = 2*DSIZE;
    }
    else{
        asize = DSIZE * ((size + 2*DSIZE - 1) / DSIZE);
    }

    size_t esize = size;
    int listnum;
    for(listnum = 0; listnum < LISTMAX; listnum++){     
        if((esize <= 1) && (segregated_free_lists[listnum] != NULL)){   //找到链
            bp = segregated_free_lists[listnum];            
            while((bp != NULL) && (size > GET_SIZE(HDRP(bp)))){     //找到合适的
                bp = PRED(bp);
            }
        }
        esize >>= 1;
    }

    if(bp != NULL){     //找到第一个符合的空间，进行分配
        place(bp, asize);
        return bp;
    }

    extendsize = MAX(asize, CHUNKSIZE);      //扩展空间
    if((bp = extend_heap(extendsize/WSIZE)) == NULL){   
        return NULL;
    }
    place(bp, asize);       //在扩展空间中分配
    return bp;
}

/*
 * mm_free - Freeing a block does nothing.
 */
void mm_free(void *ptr)
{
    size_t size = GET_SIZE(HDRP(ptr));  //需要释放的空间大小

    PUT(HDRP(ptr), PACK(size, 0));      //修改头尾
    PUT(FTRP(ptr), PACK(size, 0));      

    insert_node(ptr, size); //添加空块

    coalesced(ptr);     //合并空块
}

/*
 * mm_realloc - Implemented simply in terms of mm_malloc and mm_free
 */
void *mm_realloc(void *ptr, size_t size)
{
    if (ptr == NULL){           
       return mm_malloc(size);  //空块则直接申请
    }
    if (size == 0) {    //为零则直接释放
       mm_free(ptr);
       return NULL;
    }
    size_t oldsize = GET_SIZE(HDRP(ptr));
    if(size == oldsize){    //申请大小一样则直接返回当前空间
        return ptr;
    }
    else if(size < oldsize){     //申请空间大小小于当前空间，则释放多余空间
        PUT(HDRP(ptr), PACK(size, 1));
        PUT(FTRP(ptr), PACK(size, 1));

        PUT(FTRP(ptr) + WSIZE, PACK(oldsize - size, 0));
        PUT(FTRP(ptr) + oldsize - size, PACK(oldsize - size, 0));
        insert_node(FTRP(ptr) + 2*WSIZE, oldsize-size);     //将多余空间插入空块
        return ptr;
    }
    else{
        void *newptr;
        newptr = mm_malloc(size);   //重新申请空间
        if (newptr == NULL){
            return NULL;
        }
        memcpy(newptr, ptr, oldsize - DSIZE);      //内存复制，去掉头和尾的长度
        mm_free(ptr);       //释放旧空间
        return newptr;
    }
    
}
