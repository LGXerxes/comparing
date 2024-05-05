#! /bin/bash

# echo "GO"
# ./collatz_go --size 100000 --runs 10 --logger false

# echo "V"
# ./collatz_v --size 100000 --runs 10 --logger false

# echo "RUST"
# ./collatz_rust --size 100000 --runs 10 --logger false


# v has my terrible simple buffered writer.

# echo "GO"
# ./collatz_go --size 100000 --runs 10 --logger true

# echo "V"
# ./collatz_v --size 100000 --runs 10 --logger true

# echo "RUST"
# ./collatz_rust --size 100000 --runs 10 --logger true


# INTERESTING for longer durations
echo "GO"
# dumb go flags
./collatz_go --size 10000000 --runs 3 --logger false

echo "V"
./collatz_v --size 10000000 --logger false --runs 3

echo "RUST"
./collatz_rust --size 10000000 --logger false --runs 3


# echo "GO"
# # dumb go flags
# ./collatz_go --size 10000000 --runs 2 --logger false

# echo "V"
# ./collatz_v --size 10000000 --logger false --runs 2
