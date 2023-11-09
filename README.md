# 一、介绍
该项目是为了方便在我的课程[《TrueNAS SCALE 终极教程》](https://www.bilibili.com/cheese/play/ss6060)中进行各种磁盘布局的性能测试开发的，模拟了CrystalDiskMark几个测试项目。在 fio 参数上有任何疑问或者需求可以给我提 issue ，欢迎 pr。

# 二、项目依赖

目前仅支持类 Unix 环境，依赖软件[fio](https://github.com/axboe/fio)和[jq](https://github.com/jqlang/jq)

## 2.1 Debian/Ubuntu 依赖安装

```bash
sudo apt install fio jq -y
```

# 2.2 CentOS 系列依赖安装

```bash
sudo yum install fio jq -y
```

# 三、使用

直接下载`fio_mark.sh`文件，或者克隆到本地

```bash
# 克隆项目
git clone https://github.com/bihell/fio
```

开始测试，注意把`/mnt/test`替换为你要测试的路径。

> 程序每个测试项单任务文件大小为1G，循环跑5次。
>
> 注意：参数设定上要比CrystalDiskMark严格些，如果你跑 ssd 可能会占用很多时间，一般默认测试即可。

```Bash
# 默认测试：只要输入测试路径即可，对应CrystalDiskMark的默认测试（耗时短）
TrueNas-➜  ~ sudo bash fio_mark.sh /mnt/Stripe1
[sudo] password for admin:
Executing Default test:
                    Read [MB/s]     Read [IOPS]    Write [MB/s]    Write [IOPS]]
     SEQ1M-Q8T1            2234            2227             408             406
    RND4K-Q32T1             133           34084              15            4022
     SEQ1M-Q1T1            2283            2282             864             863
     RND4K-Q1T1             129           33113              79           20331
     
# SSD 测试：只要多输入个参数`ssd`，对应CrystalDiskMark的 NVME 测试（耗时长）
TrueNas-➜  ~ sudo bash fio_mark.sh /mnt/test ssd

# 一起测：输入`all`参数则CrystalDiskMark的 NVME 和 SDD 测试一起测（耗时很长）
TrueNas-➜  ~ sudo bash fio_mark.sh /mnt/test all

# 如果只是想看看能不能跑通，请增加`test`参数
TrueNas-➜  ~ sudo bash fio_mark.sh /mnt/test test
```



