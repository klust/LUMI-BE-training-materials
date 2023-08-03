# Process and thread distribution and binding

Binding:

-   Binding in Slurm:

    -   Distribute tasks across nodes and cores in the nodes

        -   Task distribution

        -   Set groups of cores that tasks can use

        -   Set groups of GPUs that tasks can use

-   Binding outside Slurm

    -   Bind MPI ranks to Slurm tasks: Renumbering possible with Cray MPICH

    -   Bind OpenMP threads to the cores available for a task (or in the batch job step)

    -   GPU binding is also possible at the level of the ROCm runtime

## What are we talking about in this session?

When running a distributed memory program, the process starter - `mpirun` or `mpiexec`
on many clusters, or `srun` on LUMI - will *distribute*  the processes over the available
nodes. Within a node, it is possible to pin or attach processes or even individual threads
in processes to one or more cores (actually hardware threads) and other resources, 
which is called process binding.

Linux has several mechanisms for that. Slurm uses cgroups or control groups to limit the 
resources that a job can use within a node and thus to isolate jobs from one another on a
node so that one job cannot deplete the resources of another job, and even uses a hierarchy
up to the task level to restrict some resources for a task (hardware threads and GPU access).
The second mechanism is processor affinity which works at the process and thread level and
can be used by the OpenMP runtime to limit thread migration. It works through affinity masks
which indicate the hardware threads that a thread or process can use.

Some of the tools in the `lumi-CPEtools` module can show the affinity mask for each thread
(or effectively the process for single-threaded processes) so you can use these tools to
study the affinity masks and check the distribution and binding of processes and threads.
The `serial_check`, `omp_check`, `mpi_check` and `hybrid_check` programs can be used to
study thread binding. In fact, `hybrid_check` can be used in all cases, but the other three
show more compact output for serial, shared memory OpenMP and single-threaded MPI processes 
resoectively. The `gpu_check` command can be used to study the steps in GPU binding.

??? Note "Credits for these programs"
    The `hybrid_check` program and its derivatives `serial_check`, 'omp_check` and `mpi_check`
    are similar to the [`xthi` program](https://support.hpe.com/hpesc/public/docDisplay?docId=a00114008en_us&docLocale=en_US&page=Run_an_OpenMP_Application.html)
    used in the 4-day comprehensive LUMI course organised by the LUST in collaboration with 
    HPE Cray and AMD. Its main source of inspiration is a very similar program,
    `acheck`, written by HArvey Richardson of HPE Cray and used in an earlier course,
    but it is a complete rewrite of that application.

    One of the advantages of `hybrid_check` and its derivatives is that the output is 
    sorted internally already and hence is more readable. The tool also has various extensions,
    e.g., putting some load on the CPU cores so that you can in some cases demonstrate thread
    migration as the Linux scheduler tries to distribute the load in a good way.

    The `gpu_check` program builds upon the 
    [`hello_jobstep` program from ORNL](https://code.ornl.gov/olcf/hello_jobstep/-/tree/master)
    with several extensions implemented by the LUST.

    (ORNL is the national lab that operates Frontier, an exascale supercomputer based on the same
    node type as LUMI-G.)

In this section we will consider process and thread distribution and binding at several levels:

-   When creating an allocation, Slurm will already reserve resources at the node level, but this
    has been discussed already in the Slurm session of the course.

-   When creating a job step, Slurm will distribute the tasks over the available resources,
    bind them to CPUs and depending on how the job step was started, bind them to a subset of the
    GPUs available to the task on the node it is running on.

-   With Cray MPICH, you can change the binding between MPI ranks and Slurm tasks. Normally MPI rank *i*
    would be assigned to task *i*  in the job step, but sometimes there are reasons to change this.
    The mapping options offered by Cray MPICH are more powerful than what can be obtained with the 
    options to change the task distribution in Slurm.

-   The OpenMP runtime also uses library calls and environment variables to redistribute and pin threads
    within the subset of hardware threads available to the process. Note that different compilers
    use different OpenMP runtimes so the default behaviour will not be the same for all compilers,
    and on LUMI is different for the Cray compiler compared to the GNU and AMD compilers.

-   Finally, the ROCm runtime also can limit the use of GPUs by a process to a subset of the ones that
    are available to the process through the use of the `ROCR_VISIBLE_DEVICES` environment variable.

Binding only makes sense on job-exclusive nodes as only then you have full control over all available 
resources. On "allocatable by resource" partitions you usually do not know which resources are available.
The advanced Slurm binding options that we will discuss do not work in those cases, and the options offered
by the MPICH, OpenMP and ROCm runtimes may work very unpredictable. 

!!! Warning
    Note also that some `srun` options that we have seen (sometimes already given at the `sbatch` or `salloc` level
    but picket up by `srun`) already do a simple binding, so those options **cannot be combined** with the options
    that we will discuss in this session. This is the case for `--cpus-per-task`, `--gpus-per-task` and `--ntasks-per-gpu`. 
    In fact, the latter two options will also change the numbering of the GPUs visible to the ROCm runtime, so 
    using `ROCR_VISIBLE_DEVICES` may also lead to surprises!


## Why do I need this?

As we have seen in the ["LUMI Architecture" session of this course](01_Architecture.md) and is discussed into
even more detail in some other courses lectures in Belgium (in particular the
["Supercomputers for Starters" course](https://klust.github.io/SupercomputersForStarters/) given twice a year at VSC@UAntwerpen),
modern supercomputer nodes have increasingly a very hierarchical architecture.  This hierarchical architecture is extremely
pronounced on the AMD EPYC architecture used in LUMI but is also increasingly showing up with Intel processors and the ARM
server processors, and is also relevant but often ignored in GPU clusters.

A proper binding of resources to the application is becoming more and more essential for good performance and 
scalability on supercomputers. 

-   Memory locality is very important, and even if an application would be written to take the NUMA character
    properly into account at the thread level, a bad mapping of these threads to the cores may result into threads
    having to access memory that is far away (with the worst case on a different socket) extensively.

    Memory locality at the process level is easy as usually processes share little or no memory. So if you would have
    an MPI application where each rank needs 14 GB of memory and so only 16 ranks can run on a regular node, then it is
    essential to ensure that these ranks are spread out nicely over the whole node, with one rank per CCD. The default of 
    Slurm when allocating 8 single-thread tasks on a node would be to put them all on the first CCD, which would give
    very poor performance as a lot of memory accesses would have to go across sockets.

-   If threads in a process don't have sufficient memory locality it may be very important to run all threads 
    in as few L3 cache domains as possible, ideally just one, as otherwise you risk having a lot of conflicts
    between the different L3 caches that require resolution and can slow down the process a lot.

    This already shows that there is no single works-for-all solution, because if those threads would use all memory on a 
    node and each have good memory locality then it would be better to spread them out as much possible. You really need
    to understand your application to do proper resource mapping, and the fact that it can be so application-dependent is 
    also why Slurm and the various runtimes cannot take care of it automatically.

-   In some cases it is important on the GPU nodes to ensure that tasks are nicely spread out over CCDs with each task
    using the GPU (GCD) that is closest to the CCD the task is running on. This is certainly the case if the application
    would rely on cache-coherent access to GPU memory from the CPU.

-   With careful mapping of MPI ranks on nodes you can often reduce the amount of inter-node data transfer in favour of the
    faster intra-node transfers. This requires some understanding of the communication pattern of your MPI application.


## Core numbering

Linux core numbering is not hierarchical and may look a bit strange. This is because Linux core numbering was fixed
before hardware threads were added, and later on hardware threads were simply added to the numbering scheme.

As is usual with computers, numbering starts from 0. Core 0 is the first hardware thread (or we could say the actual core)
of the first CCD (CCD 0) of the first NUMA domain (NUMA domain 0) of the first socket (socket 0). Core 1 is then the second
core of the same CCD, and so on, going over all cores in a CCD, then NUMA domain and then socket. So on LUMI-C, core 0 till 63
are on the first socket and core 64 till 127 on the second one. The numbering of the second hardware thread of each core - we could
say the virtual core - then starts where the numbering of the actual cores ends, so 64 for LUMI-G (which has only one socket per node)
or 128 for LUMI-C. This has the advantage that if hardware threading is turned off at the BIOS/UEFI level, the numbering of the actual 
cores does not change. 

On LUMI G, core 0 and its second hardware thread 64 are reserved by the low noise mode and cannot be used by Slurm or applications.
This is done to help reduce OS jitter which can kill scalability of large parallel applications. However, it also creates an assymetry
that is hard to deal with. (For this reason they chose to disable the first core of every CCD on Frontier, so core 0, 8, 16, ... and 
corresponding hardware threads 64, 72, ..., but on LUMI this is not yet the case).

Note that even with `--hiint=nomulthread` the hardware threads will still be turned on at the hardware level and be visible in the 
OS (e.c., in `/proc/cpuinfo`). In fact, the batch job step will use them, but they will not be used by applications in job steps
started with subsequent `srun` commands.

??? technical "Slurm under-the-hoods example"
    We will use the Linux `lstopo` and `taskset` commands to study how a job step sees the system
    and how task affinity is used to manage the CPUs for a task. Consider the job script:

    ``` bash linenums="1" 
    #!/bin/bash
    #SBATCH --job-name=cpu-numbering-demo1
    #SBATCH --output %x-%j.txt
    #SBATCH --account=project_46YXXXXXX
    #SBATCH --partition=small
    #SBATCH --ntasks=1
    #SBATCH --cpus-per-task=16
    #SBATCH --hint=nomultithread
    #SBATCH --time=5:00
    
    module load LUMI/22.12 partition/C lumi-CPEtools/1.1-cpeGNU-22.12
    
    cat << EOF > task_lstopo_$SLURM_JOB_ID
    #!/bin/bash
    echo "Task \$SLURM_LOCALID"                            > output-\$SLURM_JOB_ID-\$SLURM_LOCALID
    echo "Output of lstopo:"                              >> output-\$SLURM_JOB_ID-\$SLURM_LOCALID
    lstopo                                                >> output-\$SLURM_JOB_ID-\$SLURM_LOCALID
    echo "Taskset of current shell: \$(taskset -p \$\$)"  >> output-\$SLURM_JOB_ID-\$SLURM_LOCALID
    EOF
    
    chmod +x ./task_lstopo_$SLURM_JOB_ID
    
    echo -e "\nFull lstopo output in the job:\n$(lstopo)\n\n"
    echo -e "Taskset of the current shell: $(taskset -p $$)\n"
    
    echo "Running two tasks on 4 cores each, extracting parts from lstopo output in each:"
    srun -n 2 -c 4 ./task_lstopo_$SLURM_JOB_ID
    echo
    cat output-$SLURM_JOB_ID-0
    echo
    cat output-$SLURM_JOB_ID-1
    
    echo -e "\nRunning hybrid_check in the same configuration::"
    srun -n 2 -c 4 hybrid_check -r
    
    /bin/rm task_lstopo_$SLURM_JOB_ID output-$SLURM_JOB_ID-0 output-$SLURM_JOB_ID-1
    ```
        
    It creates a small test program that we will use to run lstopo and gather its output
    on two tasks with 4 cores each. All this is done in a job allocation with 16 cores on the 
    `small` partition.
    
    Let's first look at the output of the `lstopo` and `taskset` commands run in the batch
    job step:
    
    ```
    Full lstopo output in the job:
    Machine (251GB total)
      Package L#0
        Group0 L#0
          NUMANode L#0 (P#0 31GB)
        Group0 L#1
          NUMANode L#1 (P#1 31GB)
          HostBridge
            PCIBridge
              PCI 41:00.0 (Ethernet)
                Net "nmn0"
        Group0 L#2
          NUMANode L#2 (P#2 31GB)
          HostBridge
            PCIBridge
              PCI 21:00.0 (Ethernet)
                Net "hsn0"
        Group0 L#3
          NUMANode L#3 (P#3 31GB)
      Package L#1
        Group0 L#4
          NUMANode L#4 (P#4 31GB)
          L3 L#0 (32MB)
            L2 L#0 (512KB) + L1d L#0 (32KB) + L1i L#0 (32KB) + Core L#0
              PU L#0 (P#65)
              PU L#1 (P#193)
            L2 L#1 (512KB) + L1d L#1 (32KB) + L1i L#1 (32KB) + Core L#1
              PU L#2 (P#66)
              PU L#3 (P#194)
            L2 L#2 (512KB) + L1d L#2 (32KB) + L1i L#2 (32KB) + Core L#2
              PU L#4 (P#67)
              PU L#5 (P#195)
            L2 L#3 (512KB) + L1d L#3 (32KB) + L1i L#3 (32KB) + Core L#3
              PU L#6 (P#68)
              PU L#7 (P#196)
            L2 L#4 (512KB) + L1d L#4 (32KB) + L1i L#4 (32KB) + Core L#4
              PU L#8 (P#69)
              PU L#9 (P#197)
            L2 L#5 (512KB) + L1d L#5 (32KB) + L1i L#5 (32KB) + Core L#5
              PU L#10 (P#70)
              PU L#11 (P#198)
            L2 L#6 (512KB) + L1d L#6 (32KB) + L1i L#6 (32KB) + Core L#6
              PU L#12 (P#71)
              PU L#13 (P#199)
          L3 L#1 (32MB)
            L2 L#7 (512KB) + L1d L#7 (32KB) + L1i L#7 (32KB) + Core L#7
              PU L#14 (P#72)
              PU L#15 (P#200)
            L2 L#8 (512KB) + L1d L#8 (32KB) + L1i L#8 (32KB) + Core L#8
              PU L#16 (P#73)
              PU L#17 (P#201)
            L2 L#9 (512KB) + L1d L#9 (32KB) + L1i L#9 (32KB) + Core L#9
              PU L#18 (P#74)
              PU L#19 (P#202)
            L2 L#10 (512KB) + L1d L#10 (32KB) + L1i L#10 (32KB) + Core L#10
              PU L#20 (P#75)
              PU L#21 (P#203)
            L2 L#11 (512KB) + L1d L#11 (32KB) + L1i L#11 (32KB) + Core L#11
              PU L#22 (P#76)
              PU L#23 (P#204)
            L2 L#12 (512KB) + L1d L#12 (32KB) + L1i L#12 (32KB) + Core L#12
              PU L#24 (P#77)
              PU L#25 (P#205)
            L2 L#13 (512KB) + L1d L#13 (32KB) + L1i L#13 (32KB) + Core L#13
              PU L#26 (P#78)
              PU L#27 (P#206)
            L2 L#14 (512KB) + L1d L#14 (32KB) + L1i L#14 (32KB) + Core L#14
              PU L#28 (P#79)
              PU L#29 (P#207)
        Group0 L#5
          NUMANode L#5 (P#5 31GB)
          L3 L#2 (32MB) + L2 L#15 (512KB) + L1d L#15 (32KB) + L1i L#15 (32KB) + Core L#15
            PU L#30 (P#88)
            PU L#31 (P#216)
        Group0 L#6
          NUMANode L#6 (P#6 31GB)
        Group0 L#7
          NUMANode L#7 (P#7 31GB)
    
    Taskset of the current shell: pid 39383's current affinity mask: 100fffe0000000000000000000000000100fffe0000000000000000
    ```
    
    Note the way the cores are represented. 
    There are 16 lines the lines `L2 ... + L1d ... + L1i ... + Core ...` that represent the
    16 cores requested. Note that `lstopo` numbers those cores from 0. But we can already see
    from the structure that this is not right as the 16 cores are actually spread over 3 L3 cache
    domains or CCDs. 
    The two `PU` lines after each core are also continuously numbered and correspond to the 
    hardware threads. However, the regular hardware thread number is also shown as `P#` and we 
    see that we actually got 2 hardware threads on each of the physical cores 65 till 79 and then
    another one on core 88. So the cores assigned to the job are not only not on the minimal 
    number of CCDs needed for 16 cores (which would be 2) but are not even consecutive cores.
    Neither are guaranteed in a "Allocatable by resources" partition.
    This is also reflected in the taskset, that covers both the first and second hardware thread
    of each core (or as we could say, the physical core and its virtual counterpart).
    
    Next look at the output printed by lines 29 and 31:
    
    ```
    Task 0
    Output of lstopo:
    Machine (251GB total)
      Package L#0
        Group0 L#0
          NUMANode L#0 (P#0 31GB)
        Group0 L#1
          NUMANode L#1 (P#1 31GB)
          HostBridge
            PCIBridge
              PCI 41:00.0 (Ethernet)
                Net "nmn0"
        Group0 L#2
          NUMANode L#2 (P#2 31GB)
          HostBridge
            PCIBridge
              PCI 21:00.0 (Ethernet)
                Net "hsn0"
        Group0 L#3
          NUMANode L#3 (P#3 31GB)
      Package L#1
        Group0 L#4
          NUMANode L#4 (P#4 31GB)
          L3 L#0 (32MB)
            L2 L#0 (512KB) + L1d L#0 (32KB) + L1i L#0 (32KB) + Core L#0
              PU L#0 (P#65)
              PU L#1 (P#193)
            L2 L#1 (512KB) + L1d L#1 (32KB) + L1i L#1 (32KB) + Core L#1
              PU L#2 (P#66)
              PU L#3 (P#194)
            L2 L#2 (512KB) + L1d L#2 (32KB) + L1i L#2 (32KB) + Core L#2
              PU L#4 (P#67)
              PU L#5 (P#195)
            L2 L#3 (512KB) + L1d L#3 (32KB) + L1i L#3 (32KB) + Core L#3
              PU L#6 (P#68)
              PU L#7 (P#196)
            L2 L#4 (512KB) + L1d L#4 (32KB) + L1i L#4 (32KB) + Core L#4
              PU L#8 (P#69)
              PU L#9 (P#197)
            L2 L#5 (512KB) + L1d L#5 (32KB) + L1i L#5 (32KB) + Core L#5
              PU L#10 (P#70)
              PU L#11 (P#198)
            L2 L#6 (512KB) + L1d L#6 (32KB) + L1i L#6 (32KB) + Core L#6
              PU L#12 (P#71)
              PU L#13 (P#199)
          L3 L#1 (32MB) + L2 L#7 (512KB) + L1d L#7 (32KB) + L1i L#7 (32KB) + Core L#7
            PU L#14 (P#72)
            PU L#15 (P#200)
        Group0 L#5
          NUMANode L#5 (P#5 31GB)
        Group0 L#6
          NUMANode L#6 (P#6 31GB)
        Group0 L#7
          NUMANode L#7 (P#7 31GB)
    Taskset of current shell: pid 40147's current affinity mask: 1e0000000000000000
    
    Task 1
    Output of lstopo:
    Machine (251GB total)
      Package L#0
        Group0 L#0
          NUMANode L#0 (P#0 31GB)
        Group0 L#1
          NUMANode L#1 (P#1 31GB)
          HostBridge
            PCIBridge
              PCI 41:00.0 (Ethernet)
                Net "nmn0"
        Group0 L#2
          NUMANode L#2 (P#2 31GB)
          HostBridge
            PCIBridge
              PCI 21:00.0 (Ethernet)
                Net "hsn0"
        Group0 L#3
          NUMANode L#3 (P#3 31GB)
      Package L#1
        Group0 L#4
          NUMANode L#4 (P#4 31GB)
          L3 L#0 (32MB)
            L2 L#0 (512KB) + L1d L#0 (32KB) + L1i L#0 (32KB) + Core L#0
              PU L#0 (P#65)
              PU L#1 (P#193)
            L2 L#1 (512KB) + L1d L#1 (32KB) + L1i L#1 (32KB) + Core L#1
              PU L#2 (P#66)
              PU L#3 (P#194)
            L2 L#2 (512KB) + L1d L#2 (32KB) + L1i L#2 (32KB) + Core L#2
              PU L#4 (P#67)
              PU L#5 (P#195)
            L2 L#3 (512KB) + L1d L#3 (32KB) + L1i L#3 (32KB) + Core L#3
              PU L#6 (P#68)
              PU L#7 (P#196)
            L2 L#4 (512KB) + L1d L#4 (32KB) + L1i L#4 (32KB) + Core L#4
              PU L#8 (P#69)
              PU L#9 (P#197)
            L2 L#5 (512KB) + L1d L#5 (32KB) + L1i L#5 (32KB) + Core L#5
              PU L#10 (P#70)
              PU L#11 (P#198)
            L2 L#6 (512KB) + L1d L#6 (32KB) + L1i L#6 (32KB) + Core L#6
              PU L#12 (P#71)
              PU L#13 (P#199)
          L3 L#1 (32MB) + L2 L#7 (512KB) + L1d L#7 (32KB) + L1i L#7 (32KB) + Core L#7
            PU L#14 (P#72)
            PU L#15 (P#200)
        Group0 L#5
          NUMANode L#5 (P#5 31GB)
        Group0 L#6
          NUMANode L#6 (P#6 31GB)
        Group0 L#7
          NUMANode L#7 (P#7 31GB)
    Taskset of current shell: pid 40148's current affinity mask: 1e00000000000000000
    ```
    
    The output of `lstopo` is the same for both: we get the same 8 cores. This is because
    all cores for all tasks on a node are gathered in a single control group. Instead, 
    affinity masks are used to ensure that both tasks of 4 threads are scheduled on different
    cores. If we have a look at booth taskset lines:
    
    ```
    Taskset of current shell: pid 40147's current affinity mask: 01e0000000000000000
    Taskset of current shell: pid 40148's current affinity mask: 1e00000000000000000
    ```
    
    we see that they are indeed different (a zero was added to the front of the first to
    make the difference clearer). The first task got cores 65 till 68 and the second
    task got cores 69 till 72. This also shows an important property: Tasksets are
    defined based on the bare OS numbering of the cores, not based on the numbers used
    on the `L2` lines that are assigned by `lstopo` based on the visible cores in the 
    control group.
    
    The output of the `srun` command on line 34 confirms this:
    
    ```
    Running 2 MPI ranks with 4 threads each (total number of threads: 8).
    
    ++ hybrid_check: MPI rank   0/2   OpenMP thread   0/4   on cpu  65/256 of nid002053 mask 65-68
    ++ hybrid_check: MPI rank   0/2   OpenMP thread   1/4   on cpu  66/256 of nid002053 mask 65-68
    ++ hybrid_check: MPI rank   0/2   OpenMP thread   2/4   on cpu  67/256 of nid002053 mask 65-68
    ++ hybrid_check: MPI rank   0/2   OpenMP thread   3/4   on cpu  68/256 of nid002053 mask 65-68
    ++ hybrid_check: MPI rank   1/2   OpenMP thread   0/4   on cpu  72/256 of nid002053 mask 69-72
    ++ hybrid_check: MPI rank   1/2   OpenMP thread   1/4   on cpu  69/256 of nid002053 mask 69-72
    ++ hybrid_check: MPI rank   1/2   OpenMP thread   2/4   on cpu  72/256 of nid002053 mask 69-72
    ++ hybrid_check: MPI rank   1/2   OpenMP thread   3/4   on cpu  72/256 of nid002053 mask 69-72
    ```
    
    Note however that this output will depend on the compiler used to compile `hybrid_check`. The Cray
    compiler will produce different output as it has a different default strategy for OpenMP threads 
    and will by default pin each thread to a different hardware thread if possible.
     


## GPU numbering

The numbering of the GPUs is a very tricky thing on LUMI.

The only way to identify the physical GPU is through the PCIe bus ID. This does not change over time 
or in an allocation where access to some resources is limited through cgroups. It is the same on all nodes.

Based on these PICe bus IDs, the OS will assign numbers to the GPU. It are those numbers that are shown
in the figure in the
[ Architecture chapter - "Building LUMI: What a LUMI-G node really looks like"](01_Architecture.md#building-lumi-what-a-lumi-g-node-really-looks-like).
However, that numbering depends on the GPUs that are visible at that time.

Slurm manages GPUs for a task through the control group mechanism. Now if a job requesting 4 GPUs would
get the GPUs that are numbered 4 to 7 in the scheme and on the bare OS (outside the control groups created
by Slurm), it would still see them as GPUs 0 to 3, and this is the numbering that one would have to use
for the `ROCR_VISIBLE_DEVICES` environment variable that is used to further limit the GPUs that the ROCm runtime
will use in an application.

Inside a process the GPUs that the application can actually use are then again numbered starting from 0, 
independent of the actual GPUs that the process is using. 

Note also that Slurm does take care of setting the `ROCR_VISIBLE_DEVICES` environment variable. It will be set
at the start of a batch job step giving access to all GPUs that are available in the allocation, and will also
be set by `srun` for each task. 

<!-- ``` {.bash linenos=true linenostart=1 .copy}  -->
??? technical "A more technical example demonstrating what Slurm does (click to expand)"
    We will use the Linux `lstopo`command and the `ROCR_VISIBLE_DEVICES` environment variable
    to study how a job step sees the system
    and how task affinity is used to manage the CPUs for a task. 
    Consider the job script:

    ``` bash linenums="1"
    #!/bin/bash
    #SBATCH --job-name=gpu-numbering-demo1
    #SBATCH --partition=standard-g
    #SBATCH --account=project_46YXXXXXX
    #SBATCH --nodes=1
    #SBATCH --hint=nomultithread
    #SBATCH --time=15:00
    #SBATCH --output %x-%j.txt
    
    module load LUMI/22.12 partition/G lumi-CPEtools/1.1-cpeCray-22.12
    
    cat << EOF > task_lstopo_$SLURM_JOB_ID
    #!/bin/bash
    echo "Task \$SLURM_LOCALID"                                                > output-\$SLURM_JOB_ID-\$SLURM_LOCALID
    echo "Relevant lines of lstopo:"                                          >> output-\$SLURM_JOB_ID-\$SLURM_LOCALID
    lstopo | awk '/ PCI.*Display/ || /GPU/ || / Core / || /PU L/ {print \$0}' >> output-\$SLURM_JOB_ID-\$SLURM_LOCALID
    echo "ROCR_VISIBLE_DEVICES: \$ROCR_VISIBLE_DEVICES"                       >> output-\$SLURM_JOB_ID-\$SLURM_LOCALID
    EOF
    
    chmod +x ./task_lstopo_$SLURM_JOB_ID
    
    echo -e "\nFull lstopo output in the job:\n$(lstopo)\n\n"
    echo -e "Extract GPU info:\n$(lstopo | awk '/ PCI.*Display/ || /GPU/ {print $0}')\n" 
    echo "ROCR_VISIBLE_DEVICES at the start of the job script: $ROCR_VISIBLE_DEVICES"
    
    echo "Running two tasks, extracting parts from lstopo output in each:"
    srun -n 2 -c 1 --gpus-per-task=4 ./task_lstopo_$SLURM_JOB_ID
    echo
    cat output-$SLURM_JOB_ID-0
    echo
    cat output-$SLURM_JOB_ID-1
    
    echo -e "\nRunning gpu_check in the same configuration::"
    srun -n 2 -c 1 --gpus-per-task=4 gpu_check -l
    
    /bin/rm task_lstopo_$SLURM_JOB_ID output-$SLURM_JOB_ID-0 output-$SLURM_JOB_ID-1
    ```
    
    It creates a small test program that is run on two tasks and records some information on the system.
    The output is not sent to the screen directly as it could end up mixed between the tasks which is far 
    from ideal. 
    
    Let's first have a look at the first lines of the `lstopo` output:
    
    
    ```
    Machine (503GB total) + Package L#0
      Group0 L#0
        NUMANode L#0 (P#0 125GB)
        L3 L#0 (32MB)
          L2 L#0 (512KB) + L1d L#0 (32KB) + L1i L#0 (32KB) + Core L#0
            PU L#0 (P#1)
            PU L#1 (P#65)
          L2 L#1 (512KB) + L1d L#1 (32KB) + L1i L#1 (32KB) + Core L#1
            PU L#2 (P#2)
            PU L#3 (P#66)
          L2 L#2 (512KB) + L1d L#2 (32KB) + L1i L#2 (32KB) + Core L#2
            PU L#4 (P#3)
            PU L#5 (P#67)
          L2 L#3 (512KB) + L1d L#3 (32KB) + L1i L#3 (32KB) + Core L#3
            PU L#6 (P#4)
            PU L#7 (P#68)
          L2 L#4 (512KB) + L1d L#4 (32KB) + L1i L#4 (32KB) + Core L#4
            PU L#8 (P#5)
            PU L#9 (P#69)
          L2 L#5 (512KB) + L1d L#5 (32KB) + L1i L#5 (32KB) + Core L#5
            PU L#10 (P#6)
            PU L#11 (P#70)
          L2 L#6 (512KB) + L1d L#6 (32KB) + L1i L#6 (32KB) + Core L#6
            PU L#12 (P#7)
            PU L#13 (P#71)
          HostBridge
            PCIBridge
              PCI d1:00.0 (Display)
                GPU(RSMI) "rsmi4"
        L3 L#1 (32MB)
          L2 L#7 (512KB) + L1d L#7 (32KB) + L1i L#7 (32KB) + Core L#7
            PU L#14 (P#8)
            PU L#15 (P#72)
          L2 L#8 (512KB) + L1d L#8 (32KB) + L1i L#8 (32KB) + Core L#8
            PU L#16 (P#9)
            PU L#17 (P#73)
          L2 L#9 (512KB) + L1d L#9 (32KB) + L1i L#9 (32KB) + Core L#9
            PU L#18 (P#10)
            PU L#19 (P#74)
          L2 L#10 (512KB) + L1d L#10 (32KB) + L1i L#10 (32KB) + Core L#10
            PU L#20 (P#11)
            PU L#21 (P#75)
          L2 L#11 (512KB) + L1d L#11 (32KB) + L1i L#11 (32KB) + Core L#11
            PU L#22 (P#12)
            PU L#23 (P#76)
          L2 L#12 (512KB) + L1d L#12 (32KB) + L1i L#12 (32KB) + Core L#12
            PU L#24 (P#13)
            PU L#25 (P#77)
          L2 L#13 (512KB) + L1d L#13 (32KB) + L1i L#13 (32KB) + Core L#13
            PU L#26 (P#14)
            PU L#27 (P#78)
          L2 L#14 (512KB) + L1d L#14 (32KB) + L1i L#14 (32KB) + Core L#14
            PU L#28 (P#15)
            PU L#29 (P#79)
          HostBridge
            PCIBridge
              PCI d5:00.0 (Ethernet)
                Net "hsn2"
            PCIBridge
              PCI d6:00.0 (Display)
                GPU(RSMI) "rsmi5"
        HostBridge
          PCIBridge
            PCI 91:00.0 (Ethernet)
              Net "nmn0"
    ```
    
    
    We see only 7 cores in the first block (the lines `L2 ... + L1d ... + L1i ... + Core ...`)
    because the first physical core is reserved for the OS. And we see the same numbering as
    in the example in the previous "CPU numbering" section.
    
    The `lsotopo` output also clearly suggests that each GCD has a special link to a particular CCD
    
    Next check the output generated by lines 22 and 23 where we select the lines that show information
    about the GPUs and print some more information:
    
    ```
    Extract GPU info:
              PCI d1:00.0 (Display)
                GPU(RSMI) "rsmi4"
              PCI d6:00.0 (Display)
                GPU(RSMI) "rsmi5"
              PCI c9:00.0 (Display)
                GPU(RSMI) "rsmi2"
              PCI ce:00.0 (Display)
                GPU(RSMI) "rsmi3"
              PCI d9:00.0 (Display)
                GPU(RSMI) "rsmi6"
              PCI de:00.0 (Display)
                GPU(RSMI) "rsmi7"
              PCI c1:00.0 (Display)
                GPU(RSMI) "rsmi0"
              PCI c6:00.0 (Display)
                GPU(RSMI) "rsmi1"
    
    ROCR_VISIBLE_DEVICES at the start of the job script: 0,1,2,3,4,5,6,7
    
    ```
    
    All 8 GPUs are visible and note the numbering on each line below the line with the PCIe bus ID. 
    We also notice that `ROCR_VISIBLE_DEVICSES` was set by Slurm and includes all 8 GPUs.
    
    Next we run two tasks requesting 4 GPUs and a single core without hardware threading each. 
    The output of those two tasks is gathered in files that are then sent to the standard 
    output in lines 28 and 30:
    
    ```
    Task 0
    Relevant lines of lstopo:
          L2 L#0 (512KB) + L1d L#0 (32KB) + L1i L#0 (32KB) + Core L#0
            PU L#0 (P#1)
            PU L#1 (P#65)
          L2 L#1 (512KB) + L1d L#1 (32KB) + L1i L#1 (32KB) + Core L#1
            PU L#2 (P#2)
            PU L#3 (P#66)
              PCI d1:00.0 (Display)
              PCI d6:00.0 (Display)
              PCI c9:00.0 (Display)
                GPU(RSMI) "rsmi2"
              PCI ce:00.0 (Display)
                GPU(RSMI) "rsmi3"
              PCI d9:00.0 (Display)
              PCI de:00.0 (Display)
              PCI c1:00.0 (Display)
                GPU(RSMI) "rsmi0"
              PCI c6:00.0 (Display)
                GPU(RSMI) "rsmi1"
    ROCR_VISIBLE_DEVICES: 0,1,2,3
    
    Task 1
    Relevant lines of lstopo:
          L2 L#0 (512KB) + L1d L#0 (32KB) + L1i L#0 (32KB) + Core L#0
            PU L#0 (P#1)
            PU L#1 (P#65)
          L2 L#1 (512KB) + L1d L#1 (32KB) + L1i L#1 (32KB) + Core L#1
            PU L#2 (P#2)
            PU L#3 (P#66)
              PCI d1:00.0 (Display)
                GPU(RSMI) "rsmi0"
              PCI d6:00.0 (Display)
                GPU(RSMI) "rsmi1"
              PCI c9:00.0 (Display)
              PCI ce:00.0 (Display)
              PCI d9:00.0 (Display)
                GPU(RSMI) "rsmi2"
              PCI de:00.0 (Display)
                GPU(RSMI) "rsmi3"
              PCI c1:00.0 (Display)
              PCI c6:00.0 (Display)
    ROCR_VISIBLE_DEVICES: 0,1,2,3
    ```
    
    Each task sees GPUs named 'rsmi0' till 'rsmi3', but look better and you see that these are
    not the same. If you compare with the first output of `lstopo` which we ran in the batch job step,
    we notice that task 0 gets the first 4 GPUs in the node while task 1 gets the next 4, that
    were named `rsmi4` till `rsmi7` before. 
    The other 4 GPUs are invisible in each of the tasks. Note also that in both tasks 
    `ROCR_VISIBLE_DEVICES` has the same value `0,1,2,3` as the numbers detected by `lstopo` in that
    task are used. 
    
    Finally we have the output of the `gpu_check` command run in the same configuration. The `-l` option
    that was used prints some extra information that makes it easier to check the mapping: For the hardware
    threads it shows the CCD and for each GPU it shows the GCD number based on the physical order of the GPUs
    and the corresponding CCD that should be used for best performance:
    
    ```
    MPI 000 - OMP 000 - HWT 001 (CCD0) - Node nid005047 - RT_GPU_ID 0,1,2,3 - GPU_ID 0,1,2,3 - Bus_ID c1(GCD0/CCD6),c6(GCD1/CCD7),c9(GCD2/CCD2),cc(GCD3/CCD3)
    MPI 001 - OMP 000 - HWT 002 (CCD0) - Node nid005047 - RT_GPU_ID 0,1,2,3 - GPU_ID 0,1,2,3 - Bus_ID d1(GCD4/CCD0),d6(GCD5/CCD1),d9(GCD6/CCD4),dc(GCD7/CCD5)
    ```
    
    `RT_GPU_ID` is the numbering of devices used in the program itself, `GPU_ID` is essentially the value of `ROCR_VISIBLE_DEVICES`
    and `Bus_ID` shows the relevant part of the PCIe bus ID.


The above example is very technical and not suited for every reader. One important conclusion though
that is of use when running on LUMI is that **Slurm works differently with CPUs and GPUs on LUMI**. 
Cores and GPUs are treated differently. Cores access is controlled by control groups at the
job step level on each node and at the task level by affinity masks. 
The equivalent for GPUs would be to also use control groups at the job step level and then
`ROCR_VISIBLE_DEVICES` to further set access to GPUs for each task, but this is not what 
is currently happening in Slurm on LUMI. Instead it is using control groups at the 
task level. 

??? technical "Playing with control group and `ROCR_VISIBLE_DEVICES`"
    Consider the following (tricky and maybe not very realistic) job script.

    ``` bash linenums="1"
    #!/bin/bash
    #SBATCH --job-name=gpu-numbering-demo2
    #SBATCH --account=project_46YXXXXXX
    #SBATCH --partition=standard-g
    #SBATCH --nodes=1
    #SBATCH --hint=nomultithread
    #SBATCH --time=5:00
    #SBATCH --output %x-%j.txt
    
    module load LUMI/22.12 partition/G lumi-CPEtools/1.1-cpeCray-22.12
    
    cat << EOF > select_1gpu_$SLURM_JOB_ID
    #!/bin/bash
    export ROCR_VISIBLE_DEVICES=\$SLURM_LOCALID
    exec \$*
    EOF
    
    chmod +x ./select_1gpu_$SLURM_JOB_ID
    
    cat << EOF > task_lstopo_$SLURM_JOB_ID
    #!/bin/bash
    echo "Task \$SLURM_LOCALID"                                                > output-\$SLURM_JOB_ID-\$SLURM_LOCALID
    echo "Relevant lines of lstopo:"                                          >> output-\$SLURM_JOB_ID-\$SLURM_LOCALID
    lstopo | awk '/ PCI.*Display/ || /GPU/ || / Core / || /PU L/ {print \$0}' >> output-\$SLURM_JOB_ID-\$SLURM_LOCALID
    echo "ROCR_VISIBLE_DEVICES: \$ROCR_VISIBLE_DEVICES"                       >> output-\$SLURM_JOB_ID-\$SLURM_LOCALID
    EOF
    
    chmod +x ./task_lstopo_$SLURM_JOB_ID
    
    srun -n 1 -c 1 --gpus=2 sleep 30 &
    
    set -x
    srun -n 4 -c 1 --gpus=4 ./task_lstopo_$SLURM_JOB_ID
    set +x
    
    cat output-$SLURM_JOB_ID-0
    
    set -x
    srun -n 4 -c 1 --gpus=4 ./select_1gpu_$SLURM_JOB_ID gpu_check -l
    set +x
    
    wait
    
    /bin/rm select_1gpu_$SLURM_JOB_ID task_lstopo_$SLURM_JOB_ID output-$SLURM_JOB_ID-*
    ```
    
    We create two small programs that we will use in here. The first one is used to set
    `ROCR_VISIBLE_DEVICES` to the value of `SLURM_LOCALID` which is the local task number
    within a node of a Slurm task (so always numbered starting from 0 per node). We will use
    this to tell the `gpu_check` program that we will run which GPU should be used by which task.
    The second program is one we have seen before already and just shows some relevant output
    of `lstopo` to see which GPUs are in principle available to the task and then also prints
    the value of `ROCR_VISIBLE_DEVICES`.
    
    The tricky bit is line 30. Here we start an `srun` command on the background that steals
    two GPUs. In this way, we ensure that the next `srun` command will not be able to get the
    GCDs 0 and 1 from the regular full-node numbering.
    
    On line 33 we run our command that extracts info from `lstopo`.
    As we already know from the more technical example above the output will be the same for each
    task so in line 36 we only look at the output of the first task:
    
    ```
    Task 0
    Relevant lines of lstopo:
          L2 L#0 (512KB) + L1d L#0 (32KB) + L1i L#0 (32KB) + Core L#0
            PU L#0 (P#2)
            PU L#1 (P#66)
          L2 L#1 (512KB) + L1d L#1 (32KB) + L1i L#1 (32KB) + Core L#1
            PU L#2 (P#3)
            PU L#3 (P#67)
          L2 L#2 (512KB) + L1d L#2 (32KB) + L1i L#2 (32KB) + Core L#2
            PU L#4 (P#4)
            PU L#5 (P#68)
          L2 L#3 (512KB) + L1d L#3 (32KB) + L1i L#3 (32KB) + Core L#3
            PU L#6 (P#5)
            PU L#7 (P#69)
              PCI d1:00.0 (Display)
                GPU(RSMI) "rsmi2"
              PCI d6:00.0 (Display)
                GPU(RSMI) "rsmi3"
              PCI c9:00.0 (Display)
                GPU(RSMI) "rsmi0"
              PCI ce:00.0 (Display)
                GPU(RSMI) "rsmi1"
              PCI d9:00.0 (Display)
              PCI de:00.0 (Display)
              PCI c1:00.0 (Display)
              PCI c6:00.0 (Display)
    ROCR_VISIBLE_DEVICES: 0,1,2,3
    ```
    
    If you'd compare with output from a full-node `lstopo` shown in the previous example, you'd see that
    we actually got the GPUs with regular full node numbering 2 till 5, but they have been renumbered from 
    0 to 3. And notice that `ROCR_VISIBLE_DEVICES` now also refers to this numbering and not the 
    regular full node numbering when setting which GPUs can be used. 
    
    The `srun` command on line 39 will now run `gpu_check` through the `seledct_1gpu_$SLURM_JOB_ID`
    wrapper that gives task 0 access to GPU 0 in the "local" numbering, which should be GPU2/CCD2
    in the regular full node numbering, etc. Its output is
    
    ```
    MPI 000 - OMP 000 - HWT 002 (CCD0) - Node nid005942 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID c9(GCD2/CCD2)
    MPI 001 - OMP 000 - HWT 003 (CCD0) - Node nid005942 - RT_GPU_ID 0 - GPU_ID 1 - Bus_ID cc(GCD3/CCD3)
    MPI 002 - OMP 000 - HWT 004 (CCD0) - Node nid005942 - RT_GPU_ID 0 - GPU_ID 2 - Bus_ID d1(GCD4/CCD0)
    MPI 003 - OMP 000 - HWT 005 (CCD0) - Node nid005942 - RT_GPU_ID 0 - GPU_ID 3 - Bus_ID d6(GCD5/CCD1)
    ```
    
    which confirms that out strategy worked. So in this example we have 4 tasks running in a control group
    that in principle gives each task access to all 4 GPUs, but with actual access further restricted to
    a different GPU per task via `ROCR_VISIBLE_DEVICES`.

This again rather technical example demonstrates another difference between the way one works with 
CPUs and with GPUs. Affinity masks for CPUs refer to the "bare OS" numbering of hardware threads,
while the numbering used for `ROCR_VISIBLE_DEVICES` which determines which GPUs the ROCm runtime can use,
uses the numbering within the current control group.

**Running GPUs in a different control group per task may have consequences for the way inter-GPU
communication within a node can be organised so the above examples are important.**
