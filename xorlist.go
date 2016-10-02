package main

import (
	"errors"
	"fmt"
	"sync"
	"unsafe"
)

type KQueueNode struct {
	par  *KQueueNode
	cont string
}

type KQueue struct {
	mu    sync.Mutex
	front *KQueueNode
	tail  *KQueueNode
	qlen  int
	name  string
}

func (kq *KQueue) InitKQ(qname string) error {
	kq.front = nil
	kq.tail = kq.front
	kq.name = qname
	return nil
}

func pxor(p1, p2 *KQueueNode) unsafe.Pointer {
	tp1 := unsafe.Pointer(p1)
	tp2 := unsafe.Pointer(p2)

	tx := uintptr(tp1) ^ uintptr(tp2)
	return unsafe.Pointer(tx)
}

//在链表尾部添加节点，这会影响到原来的尾部节点的指针域，也会影响到头节点的指针域
func (kq *KQueue) Push(body string) error {

	node := KQueueNode{}
	node.cont = body
	kq.mu.Lock()

	if kq.front == nil && kq.tail == nil {
		kq.front = &node
		kq.tail = kq.front
		node.par = nil
	} else {
		tp := pxor(kq.tail, kq.front)
		node.par = (*KQueueNode)(tp)

		//同时要修改kq.tail.par, kq.front.par

		//tt是kq.tail的前一个节点的指针
		tt := pxor(kq.tail.par, kq.front)
		//根据插入元素的地址重新计算kq.tail的指针域
		tap := pxor((*KQueueNode)(tt), &node)
		kq.tail.par = (*KQueueNode)(tap)

		//tf是kq.front的下一个节点指针
		tf := pxor(kq.front.par, kq.tail)
		//尾部新添加了一个元素，所以头节点的指针域要根据新加节点的地址更新
		tfp := pxor(&node, (*KQueueNode)(tf))
		kq.front.par = (*KQueueNode)(tfp)

		kq.tail = &node
	}
	kq.qlen++
	kq.mu.Unlock()
	return nil
}

//删除链表的头节点，这会影响到尾部节点的指针域，还会影响到当前头节点的下一个节点的指针域
func (kq *KQueue) Shift() (string, error) {

	kq.mu.Lock()
	var node *KQueueNode
	defer func() {
		node = nil
		kq.mu.Unlock()
	}()

	if kq.front == kq.tail && kq.front == nil {
		return "", errors.New("KQueue is empty")
	}

	if kq.front == kq.tail && kq.front != nil {
		node = kq.front
		kq.front = nil
		kq.tail = nil
	} else {
		node = kq.front

		//头节点下一个节点的位置
		tt := pxor(kq.tail, node.par)
		tap := (*KQueueNode)(tt)

		//头节点的下两个节点的位置
		tn := pxor(tap.par, kq.front)
		tnn := (*KQueueNode)(tn)
		kq.front = tap

		//尾几点的头一个节点的位置
		tf := pxor(kq.tail.par, node)
		tfp := (*KQueueNode)(tf)

		//tp为更新后的尾节点的指针域
		tp := pxor(tfp, tap)
		kq.tail.par = (*KQueueNode)(tp)

		//tp为更新后的头节点的指针域
		tp = pxor(kq.tail, tnn)
		kq.front.par = (*KQueueNode)(tp)
	}
	kq.qlen--
	return node.cont, nil

}

func (kq *KQueue) Dump() {
	nodec := kq.front
	nodep := kq.tail

	if nodec != nil {
		fmt.Printf("%s ", nodec.cont)
	} else {
		return
	}
	noden := (*KQueueNode)(pxor(nodep, nodec.par))
	for noden != kq.front {
		fmt.Printf("%s ", noden.cont)
		nodep = nodec
		nodec = noden
		noden = (*KQueueNode)(pxor(nodep, nodec.par))
	}
	fmt.Println()
}

func main() {
	var kqs = KQueue{}
	kqs.InitKQ("test xor linked list")
	kqs.Push("A")
	kqs.Push("B")
	kqs.Push("C")
	kqs.Push("D")
	kqs.Push("E")
	kqs.Push("F")
	kqs.Push("G")
	kqs.Push("H")

	kqs.Dump()

	s, _ := kqs.Shift()
	fmt.Println("delete:", s)
	s, _ = kqs.Shift()
	fmt.Println("delete:", s)
	s, _ = kqs.Shift()
	fmt.Println("delete:", s)
	s, _ = kqs.Shift()
	fmt.Println("delete:", s)

	kqs.Dump()

}
