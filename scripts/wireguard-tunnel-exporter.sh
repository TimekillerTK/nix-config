#!/usr/bin/env bash
set -euo pipefail

# NOTE: Exports wireguard tunnel health (wg0 up/handshake/bytes) and a leak check
# as a Prometheus textfile for the node_exporter textfile collector.

out="/var/lib/node-exporter-textfile/wireguard.prom"
tmp="${out}.tmp"
ip_check_url="https://icanhazip.com"

curl_ip() {
  if [ -n "${1:-}" ]; then
    incus exec "${1}" -- curl -fsS --max-time 5 "${ip_check_url}" 2>/dev/null | tr -d '[:space:]'
  else
    curl -fsS --max-time 5 "${ip_check_url}" 2>/dev/null | tr -d '[:space:]'
  fi
}

{
  if dump="$(incus exec qbt-wireguard -- wg show wg0 dump 2>/dev/null)"; then
    peer_line="$(printf '%s\n' "${dump}" | tail -n +2 | head -n1)"
    if [ -n "${peer_line}" ]; then
      IFS=$'\t' read -r _pub _psk _ep _allowed latest_hs rx tx _ka <<< "${peer_line}"
      printf 'wireguard_interface_up{interface="wg0"} 1\n'
      printf 'wireguard_latest_handshake_seconds{interface="wg0"} %s\n' "${latest_hs:-0}"
      printf 'wireguard_received_bytes_total{interface="wg0"} %s\n' "${rx:-0}"
      printf 'wireguard_sent_bytes_total{interface="wg0"} %s\n' "${tx:-0}"
    else
      printf 'wireguard_interface_up{interface="wg0"} 0\n'
    fi
  else
    printf 'wireguard_interface_up{interface="wg0"} 0\n'
  fi

  host_ip="$(curl_ip "")"
  wg_ip="$(curl_ip qbt-wireguard)"
  qbt_ip="$(curl_ip qbittorrent)"

  if [ -n "${host_ip}" ] && [ -n "${wg_ip}" ] && [ -n "${qbt_ip}" ]; then
    printf 'wireguard_leak_check_up 1\n'
    if [ "${wg_ip}" = "${host_ip}" ]; then
      printf 'wireguard_tunnel_leak_detected 1\n'
    else
      printf 'wireguard_tunnel_leak_detected 0\n'
    fi
    if [ "${qbt_ip}" != "${wg_ip}" ]; then
      printf 'wireguard_client_leak_detected 1\n'
    else
      printf 'wireguard_client_leak_detected 0\n'
    fi
  else
    printf 'wireguard_leak_check_up 0\n'
  fi
} > "${tmp}"
mv "${tmp}" "${out}"
