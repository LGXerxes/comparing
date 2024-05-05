package main

import (
	"bufio"
	"flag"
	"fmt"
	"log"
	"os"
	"sync"
	"time"
)

type Message struct {
	number uint64
	seqlen uint32
}

func New(number uint64, seqlen uint32) Message {
	return Message{
		number: number,
		seqlen: seqlen,
	}
}

func collatz(n uint64) uint32 {
	len := uint32(0)

	for n > 1 {
		len += 1

		// get from cache

		if n&1 == 0 {
			n /= 2
		} else {
			n = n*3 + 1
		}
	}

	return len
}

func setup(max uint64, num_threads int) (chan Message, *sync.WaitGroup) {
	channel := make(chan Message)

	threads := &sync.WaitGroup{}

	for t := 0; t < num_threads; t++ {
		threads.Add(1)
		start := max * uint64(t) / uint64(num_threads)
		end := max * uint64((t + 1)) / uint64(num_threads)

		if start < 2 {
			start = 2
		}

		go func(start, end uint64, channel chan Message, thread_num int) {
			defer threads.Done()
			// fmt.Printf("Starting thread %d, with %d-%d\n", thread_num, start, end)
			for j := start; j < end; j++ {
				// Your code here
				seq := collatz(j)
				channel <- New(j, seq)
			}
		}(start, end, channel, t)
	}
	return channel, threads
}

func logger(channel chan Message, file_logger bool) (*sync.WaitGroup, chan uint32) {
	wg := &sync.WaitGroup{}
	wg.Add(1)

	total_chan := make(chan uint32, 1)

	go func(channel chan Message) {

		var file *os.File
		var writer *bufio.Writer
		var err error

		if file_logger {
			file, err = os.OpenFile("log_countGo.txt", os.O_WRONLY|os.O_CREATE, 0666)
			if err != nil {
				log.Fatal(err)
			}
			defer file.Close()

			writer = bufio.NewWriter(file)
			defer writer.Flush()
		}

		defer wg.Done()

		total := uint32(0)

		for {
			seq, ok := <-channel
			if !ok {
				break
			}
			total += seq.seqlen

			if file_logger {
				_, err = fmt.Fprintf(writer, "%d:%d\n", seq.number, seq.seqlen)
				if err != nil {
					log.Fatal(err)
				}
			}

		}
		total_chan <- total
	}(channel)

	return wg, total_chan
}

func count_u64_nocache(total uint64, num_threads int, file_logger bool) {
	channel, threads := setup(total, num_threads)

	l, total_chan := logger(channel, file_logger)

	threads.Wait()

	close(channel)

	l.Wait()
	tot := <-total_chan
	fmt.Printf("total was: %v\n", tot)
}

func main() {
	// Define flags
	// need to be set in this specfic order? lol
	threadCount := flag.Int("threads", 8, "quantity of threads")
	tot := flag.Uint64("size", 10000, "calculate until")
	reruns := flag.Int("runs", 3, "quantity of runs")
	file_logger := flag.Bool("logger", true, "capture responses to file")

	// Parse the flags
	flag.Parse()

	startTimeTotal := time.Now()

	for i := 0; i < *reruns; i++ {
		count_u64_nocache(*tot, *threadCount, *file_logger)
	}

	average := int(time.Since(startTimeTotal)) / *reruns

	fmt.Printf("Average time: %v\n", time.Duration(average))
}
