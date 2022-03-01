#!/bin/sh
#cloud-boothook

# Fix hostname after reboot
hostnamectl hostname "${hostname}"