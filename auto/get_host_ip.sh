#!/bin/bash

# Get host ip4 of interface eth0/en0/eth1.

# For linux, eth0 inet.
ifconfig eth0 >/dev/null 2>/dev/null && ip -4 addr show scope global dev eth0| grep inet| awk '{print $2}' && exit 0

# For linux, eth1 inet.
ifconfig eth1 >/dev/null 2>/dev/null && ip -4 addr show scope global dev eth1| grep inet| awk '{print $2}' && exit 0

# For macOS, en0 inet.
ifconfig en0 inet >/dev/null 2>/dev/null && ifconfig en0 inet| grep inet| awk '{print $2}' && exit 0

echo "No IP found"
exit 1
