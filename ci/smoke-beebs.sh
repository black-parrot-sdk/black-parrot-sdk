#!/bin/bash
source $(dirname $0)/functions.sh

sim=$1; shift

suite=beebs
progs=(ndes nettle-sha256 nsichneu stringsearch1 strstr aha-compress aha-mont64 bs bubblesort cnt compress cover crc ctl-stack ctl-vector cubic dijkstra dtoa duff edn expint fac fasta fdct fibcall fir frac huffbench insertsort janne_complex jfdctint lcdnum levenshtein matmult-int mergesort miniz minver nbody nettle-aes nettle-arcfour nettle-cast128 nettle-des nettle-md5 newlib-exp newlib-log newlib-mod newlib-sqrt ns picojpeg prime qrduino qsort qurt recursion select sglib-arraybinsearch sglib-arrayheapsort sglib-arrayquicksort sglib-dllist sglib-hashtable sglib-listinsertsort sglib-listsort sglib-queue sglib-rbtree slre sqrt statemate stb_perlin tarai template trio-snprintf trio-sscanf ud whetstone wikisort)

for prog in "${progs[@]}"; do
    do_single_sim ${sim} ${suite} ${prog} 1
done

bsg_pass $(basename $0)

