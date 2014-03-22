#!/bin/sh

contents='

[REAPER]
audioasync=3
trackupdmode=2
vstpath=Z:\\usr\\lib\\vstwin32;C:\\windows\\profiles\\'$USER'\\My Documents\\.vst;C:\\windows\\profiles\\'$USER'\\My Documents\\.config\\reaper\\vst'

echo "$contents"
