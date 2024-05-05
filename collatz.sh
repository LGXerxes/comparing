#! /bin/bash


cd collatz/go
echo "building go"
go build
echo "moving to bins"
rm -f ../../bins/collatz_go
mv -f collatz_go ../../bins


cd ../rust
# cargo build
cargo build --release
echo "building rust"
rm -f ../../bins/collatz_rust
# mv -f target/debug/collatz_rust ../../bins
mv -f target/release/collatz_rust ../../bins

cd ../v
echo "building v"
v . -prod -o collatz_v
# v . -prod -gc none -o collatz_v
rm -f ../../bins/collatz_v
mv -f collatz_v ../../bins

cd ../../bins
./run_all.sh
