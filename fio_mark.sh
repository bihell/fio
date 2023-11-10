#!/bin/bash

# 脚本项目地址：https://github.com/bihell/fio
# 该项目是为了方便在我的课程《TrueNAS SCALE 终极教程》进行各种磁盘布局的性能测试开发的，课程地址：https://www.bilibili.com/cheese/play/ss6060
# 模拟了 CrystalDiskMark 的测试方式，方便使用参考对比。如果对 fio 参数或者其他方面有疑问，可以到项目上提 issue 给我。脚本的使用方法以及更新可以看项目的描述。

# 默认参数
LOOP=5
SIZE=1g
RUNTIME=60s
TYPE=default

read_arg() {
    case "$1" in
    fast)
        RUNTIME=10s
        ;;
    all)
        TYPE=all
        ;;
    ssd)
        TYPE=ssd
        ;;
    *)
        if [ -d "$1" ]; then
            TEST_DIR=$1
        fi
        ;;
    esac
}

# 检查参数
for var in "$@"; do
    read_arg $var
done
if [ -z "$TEST_DIR" ]; then
    echo "测试路径错误或未输入！"
    exit 1
fi

# 测试命令
fio_general="sudo fio --directory=$TEST_DIR --size=$SIZE --runtime=$RUNTIME --time_based --ramp_time=5s --ioengine=libaio --direct=1 --stonewall --verify=0 --group_reporting=1 --output-format=json --output \"$TEST_DIR/fio_result\" \
--name=read,RND4K-Q1T1 --rw=randread --iodepth=1 --bs=4k --numjobs=1 \
--name=write,RND4K-Q1T1 --rw=randwrite --iodepth=1 --bs=4k --numjobs=1 \
--name=read,SEQ1M-Q8T1 --rw=read --iodepth=8 --bs=1M --numjobs=1 \
--name=write,SEQ1M-Q8T1 --rw=write --iodepth=8 --bs=1M --numjobs=1"
fio_default="--name=read,SEQ1M-Q1T1 --rw=read --iodepth=1 --bs=1M --numjobs=1 \
             --name=write,SEQ1M-Q1T1 --rw=write --iodepth=1 --bs=1M --numjobs=1 \
             --name=read,RND4K-Q32T1 --rw=randread --iodepth=32 --bs=4k --numjobs=1 \
             --name=write,RND4K-Q32T1 --rw=randwrite --iodepth=32 --bs=4k --numjobs=1"
fio_nvme="--name=read,SEQ128K-Q32T1 --rw=read --iodepth=32 --bs=128k --numjobs=1 \
          --name=write,SEQ128K-Q32T1 --rw=write --iodepth=32 --bs=128k --numjobs=1 \
          --name=read,RND4K-Q32T16 --rw=randread --iodepth=32 --bs=4k --numjobs=16 \
          --name=write,RND4K-Q32T16 --rw=randwrite --iodepth=32 --bs=4k --numjobs=16 "

# JQ 查询
jq_general='def read_bw(name): [.jobs[] | select(.jobname==name).read.bw] | add / 1024 |floor|tostring;
            def write_bw(name): [.jobs[] | select(.jobname==name).write.bw] | add / 1024 | floor|tostring;
            def read_iops(name): [.jobs[] | select(.jobname==name).read.iops] | add | floor|tostring;
            def write_iops(name): [.jobs[] | select(.jobname==name).write.iops] | add | floor|tostring;
            def job_summary(name): name+","+"read,bw"+","+read_bw(name),name+","+"write,bw"+","+write_bw(name),name+","+"read,io"+","+read_iops(name),name+","+"write,io"+","+write_iops(name);
            job_summary("read,RND4K-Q1T1"),job_summary("write,RND4K-Q1T1"),
            job_summary("read,SEQ1M-Q8T1"),job_summary("write,SEQ1M-Q8T1")'
jq_default=',job_summary("read,SEQ1M-Q1T1"),job_summary("write,SEQ1M-Q1T1"),
            job_summary("read,RND4K-Q32T1"),job_summary("write,RND4K-Q32T1")'
jq_nvme=',job_summary("read,SEQ128K-Q32T1"),job_summary("write,SEQ128K-Q32T1"),
         job_summary("read,RND4K-Q32T16"),job_summary("write,RND4K-Q32T16")'

# 根据类型执行相应的命令段
if [[ "$TYPE" == "default" ]]; then
    command="$fio_general $fio_default"
    query="$jq_general $jq_default"
    echo "Executing Default test:"
    eval "$command"
elif [[ "$TYPE" == "ssd" ]]; then
    command="$fio_general $fio_nvme"
    query="$jq_general $jq_nvme"
    echo "Executing SSD test:"
    eval "$command"
elif [[ "$TYPE" == "all" ]]; then
    command="$fio_general $fio_default $fio_nvme"
    query="$jq_general $jq_default $jq_nvme"
    echo "Executing ALL test:"
    eval "$command"
fi

# 解析输出
jq -r "$query" "$TEST_DIR/fio_result" | awk -F',' '{
    key = $2;
    if ($1 == "read" && $3 == "read") {
        if ($4 == "bw") read_bw[key] = $5;
        if ($4 == "io") read_io[key] = $5;
    }
    if ($1 == "write" && $3 == "write") {
        if ($4 == "bw") write_bw[key] = $5;
        if ($4 == "io") write_io[key] = $5;
    }
}
END {
    printf("%15s %15s %15s %15s %15s\n", "", "Read [MB/s]", "Read [IOPS]", "Write [MB/s]", "Write [IOPS]");
    for (key in read_bw) {
        printf("%15s %15s %15s %15s %15s\n", key, read_bw[key], read_io[key], write_bw[key], write_io[key]);
    }
}'

# 清理文件
sudo rm $TEST_DIR/read,* $TEST_DIR/write,* $TEST_DIR/fio_result
