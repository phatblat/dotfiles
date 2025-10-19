#!/usr/bin/env fish
# Lists open ports for the current user.
#
# Example output:
# iTunes     510 phatblat   31u  IPv4 0xcfa44781ca3f1385      0t0  TCP *:49277 (LISTEN)
# iTunes     510 phatblat   34u  IPv4 0xcfa44781ca3f405d      0t0  TCP *:daap (LISTEN)
# iTunes     510 phatblat   35u  IPv6 0xcfa44781c24c2c15      0t0  TCP *:daap (LISTEN)
# TextMate   518 phatblat   34u  IPv6 0xcfa44781c25d56d5      0t0  TCP localhost:52698 (LISTEN)
# ARDAgent   524 phatblat   10u  IPv6 0xcfa44781c25d7c15      0t0  TCP *:net-assistant (LISTEN)
# 2BUA8C4S2  913 phatblat   19u  IPv4 0xcfa44781d1608385      0t0  TCP localhost:6258 (LISTEN)
# 2BUA8C4S2  913 phatblat   20u  IPv6 0xcfa44781c24ee155      0t0  TCP localhost:6258 (LISTEN)
# 2BUA8C4S2  913 phatblat   21u  IPv4 0xcfa44781ccb46a8d      0t0  TCP localhost:6263 (LISTEN)
# 2BUA8C4S2  913 phatblat   22u  IPv6 0xcfa44781c24ee6d5      0t0  TCP localhost:6263 (LISTEN)
# SoftRAID_  930 phatblat    3u  IPv4 0xcfa44781d08b805d      0t0  TCP *:49504 (LISTEN)
# SoftRAID_  930 phatblat    6u  IPv6 0xcfa44781c25d5c15      0t0  TCP *:49504 (LISTEN)
# BetterTou  989 phatblat   14u  IPv4 0xcfa44781c92afe6d      0t0  TCP *:53427 (LISTEN)
# BetterTou  989 phatblat   15u  IPv6 0xcfa44781c24b56d5      0t0  TCP *:53427 (LISTEN)
# Dropbox   1339 phatblat  125u  IPv6 0xcfa44781c25d4155      0t0  TCP *:17500 (LISTEN)
# Dropbox   1339 phatblat  126u  IPv4 0xcfa44781cd7eaa8d      0t0  TCP *:17500 (LISTEN)
# Dropbox   1339 phatblat  149u  IPv4 0xcfa44781d1fa6a8d      0t0  TCP localhost:17600 (LISTEN)
# Dropbox   1339 phatblat  154u  IPv4 0xcfa44781cd7eb385      0t0  TCP localhost:17603 (LISTEN)
# java      4968 phatblat  115u  IPv6 0xcfa44781c25d76d5      0t0  TCP *:51298 (LISTEN)
function openports
    lsof -i | grep LISTEN
end
