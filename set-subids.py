#!/usr/bin/env python3

with open("/etc/subuid", "w") as f:
    for uid in range(1000, 65536):
        f.write("%d:%d:65536\n" %(uid,uid*65536))

with open("/etc/subgid", "w") as f:
    for uid in range(1000, 65536):
        f.write("%d:%d:65536\n" %(uid,uid*65536))

