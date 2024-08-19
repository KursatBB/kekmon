#!/bin/bash

# İzlemek istediğiniz ağ arayüzü
interface="eth0"

# Yenileme süresi (saniye)
interval=1
sec=1

# Toplamlar için değişkenler
total_in_kbps=0
total_out_kbps=0
total_in_mbps=0
total_out_mbps=0
total_in_mbits=0
total_out_mbits=0

# Başlık
printf "%-4s %-12s %-12s %-12s %-12s %-12s %-12s\n" "Sec" "KB/s In" "KB/s Out" "MB/s In" "MB/s Out" "Mbit/s In" "Mbit/s Out"

# Eski veri sayacı başlangıcı
old_in=$(cat /sys/class/net/$interface/statistics/rx_bytes)
old_out=$(cat /sys/class/net/$interface/statistics/tx_bytes)

# Çıkışta ortalamayı hesaplayan fonksiyon
function calculate_average {
    echo
    echo "Araç sonlandırıldı. Ortalama değerler hesaplanıyor..."

    avg_in_kbps=$(awk "BEGIN {printf \"%.3f\", $total_in_kbps / $sec}")
    avg_out_kbps=$(awk "BEGIN {printf \"%.3f\", $total_out_kbps / $sec}")
    avg_in_mbps=$(awk "BEGIN {printf \"%.3f\", $total_in_mbps / $sec}")
    avg_out_mbps=$(awk "BEGIN {printf \"%.3f\", $total_out_mbps / $sec}")
    avg_in_mbits=$(awk "BEGIN {printf \"%.3f\", $total_in_mbits / $sec}")
    avg_out_mbits=$(awk "BEGIN {printf \"%.3f\", $total_out_mbits / $sec}")

    echo
    printf "Ortalama KB/s In: %s\n" "$avg_in_kbps"
    printf "Ortalama KB/s Out: %s\n" "$avg_out_kbps"
    printf "Ortalama MB/s In: %s\n" "$avg_in_mbps"
    printf "Ortalama MB/s Out: %s\n" "$avg_out_mbps"
    printf "Ortalama Mbit/s In: %s\n" "$avg_in_mbits"
    printf "Ortalama Mbit/s Out: %s\n" "$avg_out_mbits"
}

# Script sonlandırıldığında ortalama hesaplama
trap calculate_average EXIT

while true
do
    sleep $interval

    # Yeni veri sayacı
    new_in=$(cat /sys/class/net/$interface/statistics/rx_bytes)
    new_out=$(cat /sys/class/net/$interface/statistics/tx_bytes)

    # Fark hesaplama
    in_diff=$((new_in - old_in))
    out_diff=$((new_out - old_out))

    # Baytları KB, MB ve Mbit'e çevirme ve virgül ile ayırma (ilk 3 ondalık basamak)
    in_kbps=$(awk "BEGIN {printf \"%.3f\", $in_diff / 1024}")
    out_kbps=$(awk "BEGIN {printf \"%.3f\", $out_diff / 1024}")

    in_mbps=$(awk "BEGIN {printf \"%.3f\", $in_diff / 1024 / 1024}")
    out_mbps=$(awk "BEGIN {printf \"%.3f\", $out_diff / 1024 / 1024}")

    in_mbits=$(awk "BEGIN {printf \"%.3f\", $in_diff * 8 / 1024 / 1024}")
    out_mbits=$(awk "BEGIN {printf \"%.3f\", $out_diff * 8 / 1024 / 1024}")

    # Çıktı (printf ile hizalı)
    printf "%-4d %-12s %-12s %-12s %-12s %-12s %-12s\n" "$sec" "$in_kbps" "$out_kbps" "$in_mbps" "$out_mbps" "$in_mbits" "$out_mbits"
    
    # Toplamları hesapla
    total_in_kbps=$(awk "BEGIN {print $total_in_kbps + $in_kbps}")
    total_out_kbps=$(awk "BEGIN {print $total_out_kbps + $out_kbps}")
    total_in_mbps=$(awk "BEGIN {print $total_in_mbps + $in_mbps}")
    total_out_mbps=$(awk "BEGIN {print $total_out_mbps + $out_mbps}")
    total_in_mbits=$(awk "BEGIN {print $total_in_mbits + $in_mbits}")
    total_out_mbits=$(awk "BEGIN {print $total_out_mbits + $out_mbits}")

    sec=$((sec + 1))

    # Eski sayacı güncelle
    old_in=$new_in
    old_out=$new_out
done
