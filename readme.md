Reproducing [issue](https://github.com/ziglang/zig/issues/15226):

```
git clone https://github.com/ianic/issue_15226
cd issue_15226
zig build && zig-out/bin/server& ; sleep 1;  zig-out/bin/client ; kill %1
```
