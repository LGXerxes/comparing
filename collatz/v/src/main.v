module main

import flag
import time
import os

struct Message {
	number u64
	seqlen u32
}

fn Message.new(number u64, seqlen u32) Message {
	return Message{
		number: number
		seqlen: seqlen
	}
}

fn collatz(n u64) u32 {
	mut current := n
	mut len := u32(0)

	for current > 1 {
		len += 1

		// get from cache

		if current & 1 == 0 {
			current /= 2
		} else {
			current = current * 3 + 1
		}
	}

	return len
}

fn setup(max u64, num_threads u8) (chan Message, []thread) {
	channel := chan Message{}

	mut threads := []thread{}

	for t in 0 .. num_threads {
		mut start := max * t / num_threads
		end := max * (t + 1) / num_threads

		if start < 2 {
			start = 2
		}

		threads << go fn (start u64, end u64, channel chan Message, thread_num int) {
			// println('Strating thread ${thread_num}, with ${start}-${end}')
			for j in start .. end {
				seq := collatz(j)
				channel <- Message.new(j, seq)
			}
		}(start, end, channel, t)
	}
	return channel, threads
}

fn logger(channel chan Message, file_logger bool) chan u32 {
	total_chan := chan u32{}

	spawn fn [channel, total_chan, file_logger] () {
		mut file := ?os.File(none)
		mut buff := []u8{}

		if file_logger {
			buff = []u8{len: 0, cap: 60000}
			file = os.open_file('log_countV.txt', 'w') or { panic('what1') }
		}

		mut total := u32(0)

		for {
			seq := <-channel or { break }
			total += seq.seqlen

			if mut f := file {
				buff << '${seq.number}:${seq.seqlen}'.bytes()

				if buff.len >= 50000 {
					f.write(buff) or { panic('what') }
					buff.clear()
				}
			}
		}

		if mut f := file {
			if buff.len >= 0 {
				f.write(buff) or { panic('what') }
			}
		}

		total_chan <- total
	}()

	return total_chan
}

fn count_u64_nocache(total u64, num_threads u8, file_logger bool) {
	channel, threads := setup(total, u8(num_threads))

	total_channel := logger(channel, file_logger)
	for t in threads {
		t.wait()
	}
	channel.close()

	tot := <-total_channel
	println('total was: ${tot}')
}

fn main() {
	mut fp := flag.new_flag_parser(os.args)
	thread_count := fp.int('threads', 0, 8, 'quantity of threads')
	tot := fp.int('size', 0, 10_000, 'calculate until')
	reruns := fp.int('runs', 0, 3, 'quantity of runs')
	file_logger := fp.bool('logger', 0, true, 'capture responses to file')

	start_time := time.now()

	for _ in 0 .. reruns {
		count_u64_nocache(u64(tot), u8(thread_count), file_logger)
	}

	average := time.since(start_time) / reruns

	println('Average time: ${time.Duration(average)}')
}
