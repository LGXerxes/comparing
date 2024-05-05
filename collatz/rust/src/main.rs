use std::fmt::Display;
use std::fs::File;
use std::fs::OpenOptions;
use std::io::BufWriter;
use std::io::Write;
use std::sync::mpsc;
use std::sync::mpsc::{Receiver, Sender};
use std::thread::JoinHandle;
use std::time::Instant;

use clap::ArgAction;
use clap::Parser;

/// Search for a pattern in a file and display the lines that contain it.
#[derive(Parser, Debug)]
struct Cli {
    #[arg(short, long, default_value_t = 8)]
    threads: u64,
    #[arg(short, long, default_value_t = 10_000)]
    size: u64,
    #[arg(short, long, default_value_t = 3)]
    runs: usize,
    #[arg(short, long, default_value_t = true,action = ArgAction::Set,)]
    logger: bool,
}

fn main() {
    let args = Cli::parse();

    let total_time = Instant::now();

    for _ in 0..args.runs {
        count_u64_nocache(args.size, args.threads, args.logger);
    }

    let duration = total_time.elapsed() / (args.runs as u32);
    println!("Average time: {:?}", duration);
}

fn count_u64_nocache(max: u64, num_threads: u64, file_logger: bool) {
    let (rx, handles) = setup_u64_nocache(max, num_threads);

    let rx_total = logger(rx, file_logger);

    for handle in handles {
        handle.join().unwrap();
    }

    let total = rx_total.recv().unwrap();

    println!("total was: {total}")
}

pub fn u64_nocache(n: u64) -> usize {
    let mut current = n;
    let mut len = 0;

    while current != 1 {
        len += 1;

        if &current & 1 == 0 {
            current /= 2;
        } else {
            current = current * 3 + 1;
        }
    }

    len
}

fn setup_u64_nocache(max: u64, num_threads: u64) -> (Receiver<(u64, usize)>, Vec<JoinHandle<()>>) {
    let (tx, rx): (Sender<(u64, usize)>, Receiver<(u64, usize)>) = mpsc::channel();

    let handles: Vec<JoinHandle<()>> = (0..num_threads)
        .map(|i| {
            let mut start = (&max * i) / num_threads;
            let end = (&max * (i + 1)) / num_threads;

            if start < 2 {
                start = 2
            }

            let thread_tx = tx.clone();

            std::thread::spawn(move || {
                for j in start..end {
                    let seq = u64_nocache(j.clone());
                    thread_tx.send((j, seq)).unwrap();
                }
                drop(thread_tx);
            })
        })
        .collect();
    return (rx, handles);
}

fn logger<T>(rx: Receiver<(T, usize)>, file_logger: bool) -> mpsc::Receiver<usize>
where
    T: Display + Send + 'static,
{
    let (tx_total, rx_total) = std::sync::mpsc::channel();

    std::thread::spawn(move || {
        let mut writer: Option<BufWriter<File>> = None;

        if file_logger {
            let file = OpenOptions::new()
                .write(true)
                .create(true)
                .truncate(true)
                .open("log_countRust.txt")
                .unwrap();

            writer = Some(BufWriter::new(file));
        }

        let mut total = 0;

        while let Ok(received) = rx.recv() {
            let (number, len) = received;
            total += len;

            if let Some(writer) = writer.as_mut() {
                write!(writer, "{}:{}\n", number, len).unwrap();
            }
        }
        let _ = tx_total.send(total);
    });

    return rx_total;
}
