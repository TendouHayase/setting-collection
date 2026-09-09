#!/usr/bin/env bash
set -euo pipefail

CXX="${CXX:-g++}"
STD="-std=c++20"
OPT="-O2 -g"
TIMEOUT_BIN="${TIMEOUT_BIN:-/usr/bin/timeout}"
LIMIT="${LIMIT:-5}"
ITER="${1:-1000}"
START="${2:-1}"

FLAGS="$STD $OPT"
if [[ -n "${SAN:-}" ]]; then
    FLAGS="$FLAGS -fsanitize=address,undefined -fno-omit-frame-pointer"
fi

echo "[build] CXX=$CXX SAN=${SAN:-off}"
$CXX $FLAGS main.cpp  -o main
$CXX $FLAGS brute.cpp -o brute
$CXX $STD -O2 gen.cpp -o gen

for (( s = START; s < START + ITER; s++ )); do
    ./gen "$s" > in.txt

    if ! "$TIMEOUT_BIN" "$LIMIT" ./main < in.txt > out_main.txt; then
        printf '\n[FAIL] main 비정상 종료 (seed=%d)\n' "$s"
        cat in.txt
        exit 1
    fi
    if ! "$TIMEOUT_BIN" "$LIMIT" ./brute < in.txt > out_brute.txt; then
        printf '\n[FAIL] brute 비정상 종료 (seed=%d)\n' "$s"
        cat in.txt
        exit 1
    fi
    if ! diff -q --strip-trailing-cr out_main.txt out_brute.txt > /dev/null; then
        printf '\n[FAIL] 출력 불일치 (seed=%d)\n' "$s"
        echo "--- input ---";  cat in.txt
        echo "--- main ---";   cat out_main.txt
        echo "--- brute ---";  cat out_brute.txt
        exit 1
    fi

    printf '\r[ok] %d/%d (seed=%d)   ' "$(( s - START + 1 ))" "$ITER" "$s"
done

printf '\n[done] 반례 없음\n'
