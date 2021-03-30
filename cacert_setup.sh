#!/system/bin/sh
mkdir -m 700 /data/local/tmp/cacerts
cp /etc/security/cacerts/* /data/local/tmp/cacerts
mount -t tmpfs tmpfs /etc/security/cacerts
cp /data/local/tmp/cacerts/* /etc/security/cacerts/
cp /data/local/tmp/c8750f0d.0 /etc/security/cacerts/
chown root:root /etc/security/cacerts/*
chmod 644 /etc/security/cacerts/*
chcon u:object_r:system_file:s0 /etc/security/cacerts/*

