#!/bin/bash

function usage {
    echo "Kullanım: $0 <ağ_arayüzü> <yenileme_süresi>"
    echo "Örnek: $0 ens160 1"
    exit 1
}

if [[ $# -ne 2 ]]; then
    echo "Hata: Eksik argümanlar."
    usage
fi

interface=$1
interval=$2

if [[ ! -d /sys/class/net/$interface ]]; then
    echo "Hata: Belirtilen ağ arayüzü ($interface) mevcut değil."
    exit 1
fi

if ! [[ $interval =~ ^[0-9]+$ ]]; then
    echo "Hata: Yenileme süresi ($interval) geçerli bir pozitif sayı olmalıdır."
    exit 1
fi

sec=1
total_in_kbps=0
total_out_kbps=0
total_in_mbps=0
total_out_mbps=0
total_in_mbits=0
total_out_mbits=0

printf "%-4s %-12s %-12s %-12s %-12s %-12s %-12s\n" "Sec" "KB/s In" "KB/s Out" "MB/s In" "MB/s Out" "Mbit/s In" "Mbit/s Out"

old_in=$(cat /sys/class/net/$interface/statistics/rx_bytes)
old_out=$(cat /sys/class/net/$interface/statistics/tx_bytes)

function calculate_average {
    echo
    echo "Araç sonlandırıldı. Ortalama değerler hesaplanıyor..."

    if [[ $sec -eq 1 ]]; then
        echo "Yeterli veri yok, ölçümler yapılmadı."
        exit 0
    fi

    avg_in_kbps=$(awk "BEGIN {printf \"%.3f\", $total_in_kbps / ($sec - 1)}")
    avg_out_kbps=$(awk "BEGIN {printf \"%.3f\", $total_out_kbps / ($sec - 1)}")
    avg_in_mbps=$(awk "BEGIN {printf \"%.3f\", $total_in_mbps / ($sec - 1)}")
    avg_out_mbps=$(awk "BEGIN {printf \"%.3f\", $total_out_mbps / ($sec - 1)}")
    avg_in_mbits=$(awk "BEGIN {printf \"%.3f\", $total_in_mbits / ($sec - 1)}")
    avg_out_mbits=$(awk "BEGIN {printf \"%.3f\", $total_out_mbits / ($sec - 1)}")

    echo
    printf "Ortalama KB/s In: %s\n" "$avg_in_kbps"
    printf "Ortalama KB/s Out: %s\n" "$avg_out_kbps"
    printf "Ortalama MB/s In: %s\n" "$avg_in_mbps"
    printf "Ortalama MB/s Out: %s\n" "$avg_out_mbps"
    printf "Ortalama Mbit/s In: %s\n" "$avg_in_mbits"
    printf "Ortalama Mbit/s Out: %s\n" "$avg_out_mbits"
}

trap calculate_average EXIT

while true
do
    sleep $interval

    new_in=$(cat /sys/class/net/$interface/statistics/rx_bytes)
    new_out=$(cat /sys/class/net/$interface/statistics/tx_bytes)

    in_diff=$((new_in - old_in))
    out_diff=$((new_out - old_out))

    if [[ $in_diff -lt 0 || $out_diff -lt 0 ]]; then
        echo "Hata: Negatif fark tespit edildi. Veriler sıfırlanmış olabilir."
        exit 1
    fi

    in_kbps=$(awk "BEGIN {printf \"%.3f\", $in_diff / 1024}")
    out_kbps=$(awk "BEGIN {printf \"%.3f\", $out_diff / 1024}")

    in_mbps=$(awk "BEGIN {printf \"%.3f\", $in_diff / 1024 / 1024}")
    out_mbps=$(awk "BEGIN {printf \"%.3f\", $out_diff / 1024 / 1024}")

    in_mbits=$(awk "BEGIN {printf \"%.3f\", $in_diff * 8 / 1024 / 1024}")
    out_mbits=$(awk "BEGIN {printf \"%.3f\", $out_diff * 8 / 1024 / 1024}")

    printf "%-4d %-12s %-12s %-12s %-12s %-12s %-12s\n" "$sec" "$in_kbps" "$out_kbps" "$in_mbps" "$out_mbps" "$in_mbits" "$out_mbits"

    total_in_kbps=$(awk "BEGIN {print $total_in_kbps + $in_kbps}")
    total_out_kbps=$(awk "BEGIN {print $total_out_kbps + $out_kbps}")
    total_in_mbps=$(awk "BEGIN {print $total_in_mbps + $in_mbps}")
    total_out_mbps=$(awk "BEGIN {print $total_out_mbps + $out_mbps}")
    total_in_mbits=$(awk "BEGIN {print $total_in_mbits + $in_mbits}")
    total_out_mbits=$(awk "BEGIN {print $total_out_mbits + $out_mbits}")

    sec=$((sec + 1))

    old_in=$new_in
    old_out=$new_out
done
