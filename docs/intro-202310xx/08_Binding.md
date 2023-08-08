# Process and thread distribution and binding

Binding to discuss:

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

**Distribution** is the process of distributing processes and threads across the available
resources of the job (nodes, sockets, NUMA domains, cores, ...), and **binding** is the process
of ensuring they stay there as naturally processes and threads are only bound to a node 
(OS image) but will migrate between cores. 

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

    It will also already employ control groups to restrict the access to those reaources on a
    per-node per-job basis.

-   When creating a job step, Slurm will distribute the tasks over the available resources,
    bind them to CPUs and depending on how the job step was started, bind them to a subset of the
    GPUs available to the task on the node it is running on.

-   With Cray MPICH, you can change the binding between MPI ranks and Slurm tasks. Normally MPI rank *i*
    would be assigned to task *i* in the job step, but sometimes there are reasons to change this.
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

<!-- Script cpu-numbering-demo1 -->
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
    lstopo -p                                             >> output-\$SLURM_JOB_ID-\$SLURM_LOCALID
    echo "Taskset of current shell: \$(taskset -p \$\$)"  >> output-\$SLURM_JOB_ID-\$SLURM_LOCALID
    EOF
    
    chmod +x ./task_lstopo_$SLURM_JOB_ID
    
    echo -e "\nFull lstopo output in the job:\n$(lstopo -p)\n\n"
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
      Package P#0
        Group0
          NUMANode P#0 (31GB)
        Group0
          NUMANode P#1 (31GB)
          HostBridge
            PCIBridge
              PCI 41:00.0 (Ethernet)
                Net "nmn0"
        Group0
          NUMANode P#2 (31GB)
          HostBridge
            PCIBridge
              PCI 21:00.0 (Ethernet)
                Net "hsn0"
        Group0
          NUMANode P#3 (31GB)
      Package P#1
        Group0
          NUMANode P#4 (31GB)
        Group0
          NUMANode P#5 (31GB)
        Group0
          NUMANode P#6 (31GB)
          L3 P#12 (32MB)
            L2 P#100 (512KB) + L1d P#100 (32KB) + L1i P#100 (32KB) + Core P#36
              PU P#100
              PU P#228
            L2 P#101 (512KB) + L1d P#101 (32KB) + L1i P#101 (32KB) + Core P#37
              PU P#101
              PU P#229
            L2 P#102 (512KB) + L1d P#102 (32KB) + L1i P#102 (32KB) + Core P#38
              PU P#102
              PU P#230
            L2 P#103 (512KB) + L1d P#103 (32KB) + L1i P#103 (32KB) + Core P#39
              PU P#103
              PU P#231
          L3 P#13 (32MB)
            L2 P#104 (512KB) + L1d P#104 (32KB) + L1i P#104 (32KB) + Core P#40
              PU P#104
              PU P#232
            L2 P#105 (512KB) + L1d P#105 (32KB) + L1i P#105 (32KB) + Core P#41
              PU P#105
              PU P#233
            L2 P#106 (512KB) + L1d P#106 (32KB) + L1i P#106 (32KB) + Core P#42
              PU P#106
              PU P#234
            L2 P#107 (512KB) + L1d P#107 (32KB) + L1i P#107 (32KB) + Core P#43
              PU P#107
              PU P#235
            L2 P#108 (512KB) + L1d P#108 (32KB) + L1i P#108 (32KB) + Core P#44
              PU P#108
              PU P#236
            L2 P#109 (512KB) + L1d P#109 (32KB) + L1i P#109 (32KB) + Core P#45
              PU P#109
              PU P#237
            L2 P#110 (512KB) + L1d P#110 (32KB) + L1i P#110 (32KB) + Core P#46
              PU P#110
              PU P#238
            L2 P#111 (512KB) + L1d P#111 (32KB) + L1i P#111 (32KB) + Core P#47
              PU P#111
              PU P#239
        Group0
          NUMANode P#7 (31GB)
          L3 P#14 (32MB)
            L2 P#112 (512KB) + L1d P#112 (32KB) + L1i P#112 (32KB) + Core P#48
              PU P#112
              PU P#240
            L2 P#113 (512KB) + L1d P#113 (32KB) + L1i P#113 (32KB) + Core P#49
              PU P#113
              PU P#241
            L2 P#114 (512KB) + L1d P#114 (32KB) + L1i P#114 (32KB) + Core P#50
              PU P#114
              PU P#242
            L2 P#115 (512KB) + L1d P#115 (32KB) + L1i P#115 (32KB) + Core P#51
              PU P#115
              PU P#243
    
    Taskset of the current shell: pid 81788's current affinity mask: ffff0000000000000000000000000000ffff0000000000000000000000000
    ```
    
    Note the way the cores are represented. 
    There are 16 lines the lines `L2 ... + L1d ... + L1i ... + Core ...` that represent the
    16 cores requested. We have used the `-p` option of `lstopo` to ensure that `lstopo`
    would show us the physical number as seen by the bare OS. The numbers indicated after
    each core are within the socket but the number indicated right after `L2` is the global
    core numbering within the node as seen by the bare OS.
    The two `PU` lines (Processing Unit) after each core are correspond to the 
    hardware threads and are also the numbers as seen by the bare OS.
    
    We see that in this allocation the cores are not spread over the minimal number
    of L3 cache domains that would be possible, but across three domains. In this particular
    allocation the cores are still consecutive cores, but even that is not guaranteed
    in an "Allocatable by resources" partition.
    Despite `--hint=nomultithread` being the default behaviour, at this level we still see
    both hardware threads for each pysical core in the taskset. 

    Next look at the output printed by lines 29 and 31:

    ```
    Task 0
    Output of lstopo:
    Machine (251GB total)
      Package P#0
        Group0
          NUMANode P#0 (31GB)
        Group0
          NUMANode P#1 (31GB)
          HostBridge
            PCIBridge
              PCI 41:00.0 (Ethernet)
                Net "nmn0"
        Group0
          NUMANode P#2 (31GB)
          HostBridge
            PCIBridge
              PCI 21:00.0 (Ethernet)
                Net "hsn0"
        Group0
          NUMANode P#3 (31GB)
      Package P#1
        Group0
          NUMANode P#4 (31GB)
        Group0
          NUMANode P#5 (31GB)
        Group0
          NUMANode P#6 (31GB)
          L3 P#12 (32MB)
            L2 P#100 (512KB) + L1d P#100 (32KB) + L1i P#100 (32KB) + Core P#36
              PU P#100
              PU P#228
            L2 P#101 (512KB) + L1d P#101 (32KB) + L1i P#101 (32KB) + Core P#37
              PU P#101
              PU P#229
            L2 P#102 (512KB) + L1d P#102 (32KB) + L1i P#102 (32KB) + Core P#38
              PU P#102
              PU P#230
            L2 P#103 (512KB) + L1d P#103 (32KB) + L1i P#103 (32KB) + Core P#39
              PU P#103
              PU P#231
          L3 P#13 (32MB)
            L2 P#104 (512KB) + L1d P#104 (32KB) + L1i P#104 (32KB) + Core P#40
              PU P#104
              PU P#232
            L2 P#105 (512KB) + L1d P#105 (32KB) + L1i P#105 (32KB) + Core P#41
              PU P#105
              PU P#233
            L2 P#106 (512KB) + L1d P#106 (32KB) + L1i P#106 (32KB) + Core P#42
              PU P#106
              PU P#234
            L2 P#107 (512KB) + L1d P#107 (32KB) + L1i P#107 (32KB) + Core P#43
              PU P#107
              PU P#235
        Group0
          NUMANode P#7 (31GB)
    Taskset of current shell: pid 82340's current affinity mask: f0000000000000000000000000
    
    Task 1
    Output of lstopo:
    Machine (251GB total)
      Package P#0
        Group0
          NUMANode P#0 (31GB)
        Group0
          NUMANode P#1 (31GB)
          HostBridge
            PCIBridge
              PCI 41:00.0 (Ethernet)
                Net "nmn0"
        Group0
          NUMANode P#2 (31GB)
          HostBridge
            PCIBridge
              PCI 21:00.0 (Ethernet)
                Net "hsn0"
        Group0
          NUMANode P#3 (31GB)
      Package P#1
        Group0
          NUMANode P#4 (31GB)
        Group0
          NUMANode P#5 (31GB)
        Group0
          NUMANode P#6 (31GB)
          L3 P#12 (32MB)
            L2 P#100 (512KB) + L1d P#100 (32KB) + L1i P#100 (32KB) + Core P#36
              PU P#100
              PU P#228
            L2 P#101 (512KB) + L1d P#101 (32KB) + L1i P#101 (32KB) + Core P#37
              PU P#101
              PU P#229
            L2 P#102 (512KB) + L1d P#102 (32KB) + L1i P#102 (32KB) + Core P#38
              PU P#102
              PU P#230
            L2 P#103 (512KB) + L1d P#103 (32KB) + L1i P#103 (32KB) + Core P#39
              PU P#103
              PU P#231
          L3 P#13 (32MB)
            L2 P#104 (512KB) + L1d P#104 (32KB) + L1i P#104 (32KB) + Core P#40
              PU P#104
              PU P#232
            L2 P#105 (512KB) + L1d P#105 (32KB) + L1i P#105 (32KB) + Core P#41
              PU P#105
              PU P#233
            L2 P#106 (512KB) + L1d P#106 (32KB) + L1i P#106 (32KB) + Core P#42
              PU P#106
              PU P#234
            L2 P#107 (512KB) + L1d P#107 (32KB) + L1i P#107 (32KB) + Core P#43
              PU P#107
              PU P#235
        Group0
          NUMANode P#7 (31GB)
    Taskset of current shell: pid 82341's current affinity mask: f00000000000000000000000000
    ```
    
    The output of `lstopo -p` is the same for both: we get the same 8 cores. This is because
    all cores for all tasks on a node are gathered in a single control group. Instead, 
    affinity masks are used to ensure that both tasks of 4 threads are scheduled on different
    cores. If we have a look at booth taskset lines:
    
    ```
    Taskset of current shell: pid 82340's current affinity mask: 0f0000000000000000000000000
    Taskset of current shell: pid 82341's current affinity mask: f00000000000000000000000000
    ```
    
    we see that they are indeed different (a zero was added to the front of the first to
    make the difference clearer). The first task got cores 100 till 103 and the second
    task got cores 104 till 107. This also shows an important property: Tasksets are
    defined based on the bare OS numbering of the cores, not based on a numbering relative
    to the control group, with cores numbered from 0 to 15 in this example. It also implies
    that it is not possible to set a taskset manually without knowing which physical cores
    can be used!
    
    The output of the `srun` command on line 34 confirms this:
    
    ```
    Running 2 MPI ranks with 4 threads each (total number of threads: 8).

    ++ hybrid_check: MPI rank   0/2   OpenMP thread   0/4   on cpu 101/256 of nid002040 mask 100-103
    ++ hybrid_check: MPI rank   0/2   OpenMP thread   1/4   on cpu 102/256 of nid002040 mask 100-103
    ++ hybrid_check: MPI rank   0/2   OpenMP thread   2/4   on cpu 103/256 of nid002040 mask 100-103
    ++ hybrid_check: MPI rank   0/2   OpenMP thread   3/4   on cpu 100/256 of nid002040 mask 100-103
    ++ hybrid_check: MPI rank   1/2   OpenMP thread   0/4   on cpu 106/256 of nid002040 mask 104-107
    ++ hybrid_check: MPI rank   1/2   OpenMP thread   1/4   on cpu 107/256 of nid002040 mask 104-107
    ++ hybrid_check: MPI rank   1/2   OpenMP thread   2/4   on cpu 104/256 of nid002040 mask 104-107
    ++ hybrid_check: MPI rank   1/2   OpenMP thread   3/4   on cpu 105/256 of nid002040 mask 104-107
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

<!-- Script gpu-numbering-demo1 -->
<!-- ``` {.bash linenos=true linenostart=1 .copy}  -->
??? technical "A more technical example demonstrating what Slurm does (click to expand)"
    We will use the Linux `lstopo`command and the `ROCR_VISIBLE_DEVICES` environment variable
    to study how a job step sees the system
    and how task affinity is used to manage the CPUs for a task. 
    Consider the job script:

    ``` bash linenums="1"
    #!/bin/bash
    #SBATCH --job-name=gpu-numbering-demo1
    #SBATCH --output %x-%j.txt
    #SBATCH --account=project_46YXXXXXX
    #SBATCH --partition=standard-g
    #SBATCH --nodes=1
    #SBATCH --hint=nomultithread
    #SBATCH --time=15:00
    
    module load LUMI/22.12 partition/G lumi-CPEtools/1.1-cpeCray-22.12
    
    cat << EOF > task_lstopo_$SLURM_JOB_ID
    #!/bin/bash
    echo "Task \$SLURM_LOCALID"                                                   > output-\$SLURM_JOB_ID-\$SLURM_LOCALID
    echo "Relevant lines of lstopo:"                                             >> output-\$SLURM_JOB_ID-\$SLURM_LOCALID
    lstopo -p | awk '/ PCI.*Display/ || /GPU/ || / Core / || /PU L/ {print \$0}' >> output-\$SLURM_JOB_ID-\$SLURM_LOCALID
    echo "ROCR_VISIBLE_DEVICES: \$ROCR_VISIBLE_DEVICES"                          >> output-\$SLURM_JOB_ID-\$SLURM_LOCALID
    EOF
    
    chmod +x ./task_lstopo_$SLURM_JOB_ID
    
    echo -e "\nFull lstopo output in the job:\n$(lstopo -p)\n\n"
    echo -e "Extract GPU info:\n$(lstopo -p | awk '/ PCI.*Display/ || /GPU/ {print $0}')\n" 
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
    
    Let's first have a look at the first lines of the `lstopo -p` output:
    
    ```
    Full lstopo output in the job:
    Machine (503GB total) + Package P#0
      Group0
        NUMANode P#0 (125GB)
        L3 P#0 (32MB)
          L2 P#1 (512KB) + L1d P#1 (32KB) + L1i P#1 (32KB) + Core P#1
            PU P#1
            PU P#65
          L2 P#2 (512KB) + L1d P#2 (32KB) + L1i P#2 (32KB) + Core P#2
            PU P#2
            PU P#66
          L2 P#3 (512KB) + L1d P#3 (32KB) + L1i P#3 (32KB) + Core P#3
            PU P#3
            PU P#67
          L2 P#4 (512KB) + L1d P#4 (32KB) + L1i P#4 (32KB) + Core P#4
            PU P#4
            PU P#68
          L2 P#5 (512KB) + L1d P#5 (32KB) + L1i P#5 (32KB) + Core P#5
            PU P#5
            PU P#69
          L2 P#6 (512KB) + L1d P#6 (32KB) + L1i P#6 (32KB) + Core P#6
            PU P#6
            PU P#70
          L2 P#7 (512KB) + L1d P#7 (32KB) + L1i P#7 (32KB) + Core P#7
            PU P#7
            PU P#71
          HostBridge
            PCIBridge
              PCI d1:00.0 (Display)
                GPU(RSMI) "rsmi4"
        L3 P#1 (32MB)
          L2 P#8 (512KB) + L1d P#8 (32KB) + L1i P#8 (32KB) + Core P#8
            PU P#8
            PU P#72
          L2 P#9 (512KB) + L1d P#9 (32KB) + L1i P#9 (32KB) + Core P#9
            PU P#9
            PU P#73
          L2 P#10 (512KB) + L1d P#10 (32KB) + L1i P#10 (32KB) + Core P#10
            PU P#10
            PU P#74
          L2 P#11 (512KB) + L1d P#11 (32KB) + L1i P#11 (32KB) + Core P#11
            PU P#11
            PU P#75
          L2 P#12 (512KB) + L1d P#12 (32KB) + L1i P#12 (32KB) + Core P#12
            PU P#12
            PU P#76
          L2 P#13 (512KB) + L1d P#13 (32KB) + L1i P#13 (32KB) + Core P#13
            PU P#13
            PU P#77
          L2 P#14 (512KB) + L1d P#14 (32KB) + L1i P#14 (32KB) + Core P#14
            PU P#14
            PU P#78
          L2 P#15 (512KB) + L1d P#15 (32KB) + L1i P#15 (32KB) + Core P#15
            PU P#15
            PU P#79
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
    ...
    ```
        
    We see only 7 cores in the first block (the lines `L2 ... + L1d ... + L1i ... + Core ...`)
    because the first physical core is reserved for the OS. 
    
    The `lstopo -p` output also clearly suggests that each GCD has a special link to a particular CCD
    
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
          L2 P#1 (512KB) + L1d P#1 (32KB) + L1i P#1 (32KB) + Core P#1
          L2 P#2 (512KB) + L1d P#2 (32KB) + L1i P#2 (32KB) + Core P#2
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
          L2 P#1 (512KB) + L1d P#1 (32KB) + L1i P#1 (32KB) + Core P#1
          L2 P#2 (512KB) + L1d P#2 (32KB) + L1i P#2 (32KB) + Core P#2
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
    MPI 000 - OMP 000 - HWT 001 (CCD0) - Node nid005163 - RT_GPU_ID 0,1,2,3 - GPU_ID 0,1,2,3 - Bus_ID c1(GCD0/CCD6),c6(GCD1/CCD7),c9(GCD2/CCD2),cc(GCD3/CCD3)
    MPI 001 - OMP 000 - HWT 002 (CCD0) - Node nid005163 - RT_GPU_ID 0,1,2,3 - GPU_ID 0,1,2,3 - Bus_ID d1(GCD4/CCD0),d6(GCD5/CCD1),d9(GCD6/CCD4),dc(GCD7/CCD5)
    ```
    
    `RT_GPU_ID` is the numbering of devices used in the program itself, `GPU_ID` is essentially the value of `ROCR_VISIBLE_DEVICES`,
    the logical numbers of the GPUs in the control group
    and `Bus_ID` shows the relevant part of the PCIe bus ID.


The above example is very technical and not suited for every reader. One important conclusion though
that is of use when running on LUMI is that **Slurm works differently with CPUs and GPUs on LUMI**. 
Cores and GPUs are treated differently. Cores access is controlled by control groups at the
job step level on each node and at the task level by affinity masks. 
The equivalent for GPUs would be to also use control groups at the job step level and then
`ROCR_VISIBLE_DEVICES` to further set access to GPUs for each task, but this is not what 
is currently happening in Slurm on LUMI. Instead it is using control groups at the 
task level. 

<!-- Script gpu-numbering-demo2 -->
??? technical "Playing with control group and `ROCR_VISIBLE_DEVICES`"
    Consider the following (tricky and maybe not very realistic) job script.

    ``` bash linenums="1"
    #!/bin/bash
    #SBATCH --job-name=gpu-numbering-demo2
    #SBATCH --output %x-%j.txt
    #SBATCH --partition=standard-g
    #SBATCH --nodes=1
    #SBATCH --hint=nomultithread
    #SBATCH --time=5:00
    
    module load LUMI/22.12 partition/G lumi-CPEtools/1.1-cpeCray-22.12
    
    cat << EOF > select_1gpu_$SLURM_JOB_ID
    #!/bin/bash
    export ROCR_VISIBLE_DEVICES=\$SLURM_LOCALID
    exec \$*
    EOF
    
    chmod +x ./select_1gpu_$SLURM_JOB_ID
    
    cat << EOF > task_lstopo_$SLURM_JOB_ID
    #!/bin/bash
    sleep \$((SLURM_LOCALID * 5))
    echo "Task \$SLURM_LOCALID"                                                   > output-\$SLURM_JOB_ID-\$SLURM_LOCALID
    echo "Relevant lines of lstopo:"                                             >> output-\$SLURM_JOB_ID-\$SLURM_LOCALID
    lstopo -p | awk '/ PCI.*Display/ || /GPU/ || / Core / || /PU L/ {print \$0}' >> output-\$SLURM_JOB_ID-\$SLURM_LOCALID
    echo "ROCR_VISIBLE_DEVICES: \$ROCR_VISIBLE_DEVICES"                          >> output-\$SLURM_JOB_ID-\$SLURM_LOCALID
    EOF
    
    chmod +x ./task_lstopo_$SLURM_JOB_ID
    
    srun -n 1 -c 1 --gpus=2 sleep 60 &
    sleep 5
    
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
    the value of `ROCR_VISIBLE_DEVICES`. We did have to put in some task-dependent delay 
    as it turns out that running multiple `lstopo` commands on a node together can cause
    problems.
    
    The tricky bit is line 30. Here we start an `srun` command on the background that steals
    two GPUs. In this way, we ensure that the next `srun` command will not be able to get the
    GCDs 0 and 1 from the regular full-node numbering. The delay is again to ensure that the
    next `srun` works without conflicts as internally Slurm is still finishing steps from
    the first `srun`.
    
    On line 34 we run our command that extracts info from `lstopo`.
    As we already know from the more technical example above the output will be the same for each
    task so in line 36 we only look at the output of the first task:
    
    ```
    Relevant lines of lstopo:
          L2 P#2 (512KB) + L1d P#2 (32KB) + L1i P#2 (32KB) + Core P#2
          L2 P#3 (512KB) + L1d P#3 (32KB) + L1i P#3 (32KB) + Core P#3
          L2 P#4 (512KB) + L1d P#4 (32KB) + L1i P#4 (32KB) + Core P#4
          L2 P#5 (512KB) + L1d P#5 (32KB) + L1i P#5 (32KB) + Core P#5
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
  
    If you'd compare with output from a full-node `lstopo -p` shown in the previous example, you'd see that
    we actually got the GPUs with regular full node numbering 2 till 5, but they have been renumbered from 
    0 to 3. And notice that `ROCR_VISIBLE_DEVICES` now also refers to this numbering and not the 
    regular full node numbering when setting which GPUs can be used. 
    
    The `srun` command on line 40 will now run `gpu_check` through the `seledct_1gpu_$SLURM_JOB_ID`
    wrapper that gives task 0 access to GPU 0 in the "local" numbering, which should be GPU2/CCD2
    in the regular full node numbering, etc. Its output is
    
    ```
    MPI 000 - OMP 000 - HWT 002 (CCD0) - Node nid005350 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID c9(GCD2/CCD2)
    MPI 001 - OMP 000 - HWT 003 (CCD0) - Node nid005350 - RT_GPU_ID 0 - GPU_ID 1 - Bus_ID cc(GCD3/CCD3)
    MPI 002 - OMP 000 - HWT 004 (CCD0) - Node nid005350 - RT_GPU_ID 0 - GPU_ID 2 - Bus_ID d1(GCD4/CCD0)
    MPI 003 - OMP 000 - HWT 005 (CCD0) - Node nid005350 - RT_GPU_ID 0 - GPU_ID 3 - Bus_ID d6(GCD5/CCD1)
    ```
    
    which confirms that out strategy worked. So in this example we have 4 tasks running in a control group
    that in principle gives each task access to all 4 GPUs, but with actual access further restricted to
    a different GPU per task via `ROCR_VISIBLE_DEVICES`.

This again rather technical example demonstrates another difference between the way one works with 
CPUs and with GPUs. Affinity masks for CPUs refer to the "bare OS" numbering of hardware threads,
while the numbering used for `ROCR_VISIBLE_DEVICES` which determines which GPUs the ROCm runtime can use,
uses the numbering within the current control group.

**Running GPUs in a different control group per task has consequences for the way inter-GPU
communication within a node can be organised so the above examples are important. It is essential
to run MPI applications with optimal efficiency.**


## Task distribution with Slurm

The Slurm `srun` command offers the `--distribution` option to influence the distribution of 
tasks across nodes (level 1), sockets or NUMA domains (level 2 and sockets or NUMA) or 
even across cores in the socket or NUMA domain (third level). The first level is the most useful level,
the second level is sometimes used but the third level is very tricky and both the second and third level
are often better replaced with other mechanisms that will also be discussed in this chapter on distribution
and binding.

The [general form of the `--distribution` option](https://slurm.schedmd.com/archive/slurm-22.05.8/srun.html#OPT_distribution) is 

```
--distribution={*|block|cyclic|arbitrary|plane=<size>}[:{*|block|cyclic|fcyclic}[:{*|block|cyclic|fcyclic}]][,{Pack|NoPack}]
```

-   Level 1: Distribution across nodes. There are three useful options for LUMI:

    -   `block` which is the default: A number of consecutive tasks is allocated on the first
        node, then another number of consecutive tasks on the second node, and so on till the last
        node of the allocation. Not all nodes may have the same number of tasks and this is determined
        by the optional  `pack` or `nopack` parameter at the end.

        -   With `pack` the first node in the allocation is first filled up as much as possible, then the
            second node, etc.

        -   With `nopack` a more balanced approach is taken filling up all nodes as equally as possible.
            In fact, the number of tasks on each node will correspond to that of the `cyclic` distribution,
            but the task numbers will be different.

    -   `cyclic` assigns the tasks in a round-robin fashion to the nodes of the allocation. The first task
        is allocated to the first node, then the second one to the second node, and so on, and when all nodes
        of the allocation have received one task, the next one will be allocated again on the first node. 

    -   `plane=<size>` is a combination of both of the former methods: Blocks of `<size>` consecutive tasks
        are allocated in a cyclic way. 

-   Level 2: Here we are distributing and pinning the tasks assigned to a node at level 1 across the sockets
    and cores of that node.

    As this option already does a form of binding, it may conflict with other options that we will discuss later
    that also perform binding. In practice, this second level is less useful as often other mechanisms will be 
    preferred for doing a proper binding, or the default behaviour is OK for simple distribution problems.

    -   'block' will assign whole tasks to consecutive sets of cores on the node. On LIUMI-C, it will first fill up
        the first socket before moving on to the second socket.

    -   `cyclic` assigns the first task of a node to a set of consecutive cores on the first socket, then the second task to a set 
        of cores on the second socket, etc., in a round-robin way. It will do its best to not allocate tasks across sockets.

    -   `fcyclic` is a very strange distribution, where tasks requesting more than 1 CPU per task will see those 
        spread out across sockets. 

        We cannot see how this is useful on an AMD CPU except for cases where we have only one task per node which accesses
        a lot of memory (more than offered by a single socket) but does so in a very NUMA-aware way.

-    Level 3 is beyond the scope of an introductory course and rarely used.

The default behaviour of Slurm depends on LUMI seems to be `block:block,nopack` if `--distribution` is not specified,
though it is best to always verify as it can change over time and as the manual indicates that the
default differs according to the number of tasks compared to the number of nodes.
The defaults are also very tricky if a binding option at level 2 (or 3) is replaced with a `*` to mark
the default behaviour, e.g., `--distribution="block:*"` gives the result of `--distribution=block:cyclic`
while `--distribution=block` has the same effect as `--distribution=block:block`.

**This option only makes sense on job-exclusive nodes.**


## Task-to-CPU binding with Slurm

This option is used to define the strategy that Slurm uses to bind tasks to CPUs.
The mechanism is always through task affinity masks, using control groups only at the jobstep level
within a node but not at the task level. Hence in most practical cases task binding through affinity
masks is something you will want to use, and we will see another way to further refine the mask 
further in this chapter of the tutorial.

Task-to-CPU binding is controlled through the Slurm option 

```
--cpu-bind=[{quiet|verbose},]<type>
```

We'll describe a few of the possibilities for the `<typ>` parameter but for a more concrete overview
we refer to the [Slurm `srun` manual page](https://slurm.schedmd.com/archive/slurm-22.05.8/srun.html#OPT_cpu-bind)

-   `--cpu-bind=threads` is the default behaviour on LUMI.

-   `--cpu-bind=map_cpu:<cpu_id_for_task_0>,<cpu_id_for_task_1>, ...` is used when tasks are bound to single
    cores. The first number is the number of the hardware thread for the task with local task ID 0, etc. 
    In other words, this option at the same time also defines the slots that can be used by the 
    `--distribrution` option above and replaces level 2 and level 3 of that option. 

    E.g.,
    
    ```
    module load LUMI/22.12 partition/G lumi-CPEtools/1.1-cpeGNU-22.12
    srun --ntasks=8 --cpu-bind=map_cpu:49,57,17,25,1,9,33,41 mpi_check -r
    ```

    will run the first task on hardware threads 49, the second task on 57, third on 17, fourth on 
    25, fifth on 1, sixth on 9, seventh on 33 and eight on 41.

    This may look like a very strange numbering, but we will see an application for it further in
    this chapter.


-   `--cpu-bind=mask_cpu:<mask_for_task_0>,<mask_for_task_1>,...` is similar to `map_cpu`, but now multiple
    hardware threads can be specified per task through a mask. The mask is a hexadecimal number and leading 
    zeros can be omitted. The least significant bit in the mask corresponds to HWT 0, etc. 

    Masks can become very long, but we shall see that this option is very useful on the nodes of the 
    `standard-g` partition. Just as with `map_cpu`, this option replaces level 2 and 3 of the `--distribution`
    option. 

    E.g.,
    
    ```
    module load LUMI/22.12 partition/G lumi-CPEtools/1.1-cpeGNU-22.12
    srun --ntasks=8 --cpu-bind=mask_cpu:7e000000000000,7e00000000000000,7e0000,7e000000,7e,7e00,7e00000000,7e0000000000 hybrid_check -r
    ```

    will run the first task on hardware threads 49-54, the second task on 57-62, third on 17-22, fourth on 
    25-30, fifth on 1-6, sixth on 9-14, seventh on 33-38 and eight on 41-46.

The `--cpu-bind=map_cpu` and `--cpu-bind=mask_gpu` options also do not go together with `-c` / `--cpus-per-task`.
Both commands define a binding (the latter in combination with the defulat `--gpu-bind=threads`) 
and these will usually conflict.

There are more options, but these are currently most relevant ones on LUMI. That may change in the future as
LUMI User support is investigating whether it isn't better to change the concept of "socket" in Slurm given how important it
sometimes is to carefully map onto L3 cache domains for performance.


## Task GPU binding with Slurm

**Doing the task-to-GPU binding fully via Slurm is currently not recommended on LUMI. 
The problem is that Slurm uses control groups at the task level rather than just `ROCR_VISIBLE_DEVICES`
with the latter being more or less the equivalent of affinity masks. As sue to the control groups
the other GPUs in a job step on a node become completely invisible to a task, communication between
tasks through shared memory becomes impossible.**

We present the options for completeness, and as it may still help users if the control group setup
is not a problem for the application.

Task-to-GPU binding is done with

```
--gpu-bind=[verbose,]<type>
```

[(see the Slurm manual)](https://slurm.schedmd.com/archive/slurm-22.05.8/srun.html#OPT_gpu-bind)
which is somewhat similar to `--cpu-binding` (to the extent that that makes sense).

Some options for the `<type>` parameter that are worth considering:

-   `--gpu-bind=closest`: This currently does not work well on LUMI. The problem is being investigated
    so the situation may have changed by the time you read this.

-   `--gpu-ding=none`: Turns off the GPU binding of Slurm. This can actually be useful on shared node
    jobs where doing a proper allocation of GPUS is difficult. You can then first use Slurm options such 
    as `--gpus-per-task` to get a working allocation of GPUs and CPUs, then un-bind and rebind using a 
    different mechanism that we will discuss later.

-   `--gpu-bind=map_gpu:<list>` is the equivalent of `--cpu-gind=map_cpu:<list>`.
    This option only makes sense on a job-exclusive node and is for jobs that need a single 
    GPU per task. It defines the list of GPUs that should be used, with the task with local ID 0
    using the first one in the list, etc.
    The numbering and topology was already discussed in the "LUMI ARchitecture" chapter, section
    ["Building LUMI: What a LUMI-G really looks like](01_Architecture.md#building-lumi-what-a-lumi-g-node-really-looks-like).
   
-   `--gpu-bind=mask_gpu:>list>` is the equivalent of `--cpu-gind=mask_cpu:<list>`. 
    Now the bits in the mask correspond to individual GPUs, with GPU 0 the least significant bit. 
    This option again only makes sense on a job-exclusive node.

Though `map_gpu` and `mask_gpu` could be very useful to get a proper mapping taking the topology of the 
node into account, due to the current limitation of creating a control group per task it can not often
be used as it breaks some efficient communication mechanisms between tasks, including the GPU Peer2Peer 
IPC used by Cray MPICH for intro-node MPI transfers if GPU aware MPI support is enabled.

??? advanced "What do the HPE Cray manuals say about this? (Click to expand)"
    From the HPE Cray CoE: 
    *"Slurm may choose to use cgroups to implement the required
    affinity settings. Typically, the use of cgroups has the downside of preventing the use of 
    GPU Peer2Peer IPC mechanisms. By default Cray MPI uses IPC for
    implementing intra-node, inter-process MPI data movement operations that involve GPU-attached user buffers. 
    When Slurm’s cgroups settings are in effect, users are
    advised to set `MPICH_SMP_SINGLE_COPY_MODE=NONE` or `MPICH_GPU_IPC_ENABLED=0`
    to disable the use of IPC-based implementations. 
    Disabling IPC also has a noticeable impact on intra-node MPI performance when 
    GPU-attached memory regions are involved."*

    This is exactly what Slurm does on LUMI.
    

## MPI rank redistribution with Cray MPICH

By default MPI rank *i* will use Slurm task *i* in a parallel job step. 
With Cray MPICH this can be changed via the environment variable 
`MPICH_RANK_REORDER_METHOD`. It provides an even more powerful way
of reordering MPI ranks than the Slurm `--distribution` option as one
can define fully custom orderings.

Rank reordering is an advanced topic that is discussed in more detail in the
4-day LUMI comprehensive courses organised by the LUMI User Support Team.
The [material of the latest one can be found via the course archive web page](https://lumi-supercomputer.github.io/LUMI-training-materials/comprehensive-latest)
and is discussed in the  "MPI Topics on the HPE Cray EX Supercomputer"
which is often given on day 3.

Rank reordering can be used to reduce the number of inter-node messages or to spread those
ranks that do parallel I/O over more nodes to increase the I/O bandwidth that can be
obtained in the application.

Rank reordering makes most sense if the block distribution method is used in Slurm as 
otherwise it become very difficult to understand on which node which task will land.

Possible values for `MPICH_RANK_REORDER_METHOD` are:

-   `export MPICH_RANK_REORDER_METHOD=0`: Round-robin placement of the MPI ranks.
    This is the equivalent of the cyclic ordering in Slurm.

-   `export MPICH_RANK_REORDER_METHOD=1`: This is the default and it preserves the
    ordering of Slurm.

-   `export MPICH_RANK_REORDER_METHOD=2`: Folded rank placement. This is somewhat similar 
    to round-robin, but when the last node is reached, the node list is transferred in the 
    opposite direction.

-   `export MPICH_RANK_REORDER_METHOD=3`: Use a custom ordering, given by the 
    `MPICH_RANK_ORDER` environment variable which gives a comma-separated list of the MPI ranks
    in the order they should be assigned to slots on the nodes.

Rank reordering does not always work well if Slurm is not using the block ordering. 
As the `lumi-CPEtools` `mpi_check`, `hybrid_check` and `gpu_check` commands use Cray MPICH
they can be used to test the Cray MPICH rank reordering also. The MPI ranks that are 
displayed are the MPI ranks as seen through MPI calls and not the value of
`SLURM_PROCID` which is the Slurm task number.

The HPE Cray Programming Environment actually has profiling tools that help you determine
the optimal rank ordering for a particular run, which is useful if you do a lot of runs with
the same problem size (and hence same number of nodes and tasks).

??? Example "Try the following job script (click to expand)

    ```
    #!/bin/bash
    #SBATCH --account=project_46YXXXXXX
    #SBATCH --job-name=renumber-demo
    #SBATCH --output %x-%j.txt
    #SBATCH --partition=standard
    #SBATCH --nodes=2
    #SBATCH --hint=nomultithread
    #SBATCH --time=5:00
    
    module load LUMI/22.12 partition/C lumi-CPEtools/1.1-cpeGNU-22.12
    
    set -x
    echo -e "\nSMP distribution on top of block."
    export MPICH_RANK_REORDER_METHOD=1
    srun -n 8 -c 32 -m block mpi_check -r
    echo -e "\nSMP distribution on top of cyclic."
    export MPICH_RANK_REORDER_METHOD=1
    srun -n 8 -c 32 -m cyclic mpi_check -r
    echo -e "\nRound-robin distribution on top of block."
    export MPICH_RANK_REORDER_METHOD=0
    srun -n 8 -c 32 -m block mpi_check -r
    echo -e "\nFolded distribution on top of block."
    export MPICH_RANK_REORDER_METHOD=2
    srun -n 8 -c 32 -m block mpi_check -r
    echo -e "\nCustom distribution on top of block."
    export MPICH_RANK_REORDER_METHOD=3
    cat >MPICH_RANK_ORDER <<EOF
    0,1,4,5,2,3,6,7
    EOF
    srun -n 8 -c 32 -m block mpi_check -r
    /bin/rm MPICH_RANK_ORDER
    set +x
    ```
    
    Ths script starts 8 tasks that each take a quarter node. 
    
    1.  The first `srun` command is just the block distribution. The first 4 MPI ranks are
        on the first node, the next 4 on the second node.
    
        ```
        + export MPICH_RANK_REORDER_METHOD=1
        + MPICH_RANK_REORDER_METHOD=1
        + srun -n 8 -c 32 -m block mpi_check -r

        Running 8 single-threaded MPI ranks.

        ++ mpi_check: MPI rank   0/8   on cpu  17/256 of nid001804 mask 0-31
        ++ mpi_check: MPI rank   1/8   on cpu  32/256 of nid001804 mask 32-63
        ++ mpi_check: MPI rank   2/8   on cpu  65/256 of nid001804 mask 64-95
        ++ mpi_check: MPI rank   3/8   on cpu 111/256 of nid001804 mask 96-127
        ++ mpi_check: MPI rank   4/8   on cpu   0/256 of nid001805 mask 0-31
        ++ mpi_check: MPI rank   5/8   on cpu  32/256 of nid001805 mask 32-63
        ++ mpi_check: MPI rank   6/8   on cpu  64/256 of nid001805 mask 64-95
        ++ mpi_check: MPI rank   7/8   on cpu 120/256 of nid001805 mask 96-127
        ```
    
    2.  The second `srun` command uses Cray MPICH rank reordering to get a round-robin ordering
        rather than using the Slurm `--distribution=cyclic` option. MPI rank 0 now lands on the first
        32 cores of node 0 of the allocation, MPI rank 1 on the first 32 cores of node 1 of the allocation,
        then task 2 on the second 32 cores of node 0, and so on:
    
        ```
        + export MPICH_RANK_REORDER_METHOD=1
        + MPICH_RANK_REORDER_METHOD=1
        + srun -n 8 -c 32 -m cyclic mpi_check -r

        Running 8 single-threaded MPI ranks.

        ++ mpi_check: MPI rank   0/8   on cpu   0/256 of nid001804 mask 0-31
        ++ mpi_check: MPI rank   1/8   on cpu   1/256 of nid001805 mask 0-31
        ++ mpi_check: MPI rank   2/8   on cpu  32/256 of nid001804 mask 32-63
        ++ mpi_check: MPI rank   3/8   on cpu  33/256 of nid001805 mask 32-63
        ++ mpi_check: MPI rank   4/8   on cpu  79/256 of nid001804 mask 64-95
        ++ mpi_check: MPI rank   5/8   on cpu  64/256 of nid001805 mask 64-95
        ++ mpi_check: MPI rank   6/8   on cpu 112/256 of nid001804 mask 96-127
        ++ mpi_check: MPI rank   7/8   on cpu 112/256 of nid001805 mask 96-127
        ```
    
    3.  Now we use the Slurm cyclic ordering and the default of 1 for the Cray MPICH rank
        reordering (which is no reordering) and the result is the same as the preovious case: 
    
        ```
        + export MPICH_RANK_REORDER_METHOD=0
        + MPICH_RANK_REORDER_METHOD=0
        + srun -n 8 -c 32 -m block mpi_check -r

        Running 8 single-threaded MPI ranks.

        ++ mpi_check: MPI rank   0/8   on cpu   0/256 of nid001804 mask 0-31
        ++ mpi_check: MPI rank   1/8   on cpu   1/256 of nid001805 mask 0-31
        ++ mpi_check: MPI rank   2/8   on cpu  32/256 of nid001804 mask 32-63
        ++ mpi_check: MPI rank   3/8   on cpu  47/256 of nid001805 mask 32-63
        ++ mpi_check: MPI rank   4/8   on cpu  64/256 of nid001804 mask 64-95
        ++ mpi_check: MPI rank   5/8   on cpu  64/256 of nid001805 mask 64-95
        ++ mpi_check: MPI rank   6/8   on cpu 112/256 of nid001804 mask 96-127
        ++ mpi_check: MPI rank   7/8   on cpu 112/256 of nid001805 mask 96-127
        ```
    
    4.  The fourth `srun` command demonstrates the folded ordering: Rank 0 runs on the first 32 
        cores of node 0 of the allocation, rank 1 on the first 32 of node 1, then rank 2 runs on 
        the second set of 32 cores again on node 1, with rank 3 then running on the second 32 cores
        of node 0, rank 4 on the third group of 32 cores of node 0, rank 5 on the third group of
        32 cores on rank 1, and so on. So the nodes are filled in the order 0, 1, 1, 0, 0, 1, 1, 0.
    
        ```
        + export MPICH_RANK_REORDER_METHOD=2
        + MPICH_RANK_REORDER_METHOD=2
        + srun -n 8 -c 32 -m block mpi_check -r

        Running 8 single-threaded MPI ranks.

        ++ mpi_check: MPI rank   0/8   on cpu   0/256 of nid001804 mask 0-31
        ++ mpi_check: MPI rank   1/8   on cpu  17/256 of nid001805 mask 0-31
        ++ mpi_check: MPI rank   2/8   on cpu  32/256 of nid001805 mask 32-63
        ++ mpi_check: MPI rank   3/8   on cpu  32/256 of nid001804 mask 32-63
        ++ mpi_check: MPI rank   4/8   on cpu  64/256 of nid001804 mask 64-95
        ++ mpi_check: MPI rank   5/8   on cpu  64/256 of nid001805 mask 64-95
        ++ mpi_check: MPI rank   6/8   on cpu 112/256 of nid001805 mask 96-127
        ++ mpi_check: MPI rank   7/8   on cpu 112/256 of nid001804 mask 96-127
        ```
    
    5.  The fifth example demonstrate a custon reordering. Here we fance a 4x2-grid which we want
        to split in 2 2x2 groups. In this example rank 0, 1, 4 and 5 will run on node 0 with rank 2, 3, 6 and 7
        running on node 1.
    
        ```
        + export MPICH_RANK_REORDER_METHOD=3
        + MPICH_RANK_REORDER_METHOD=3
        + cat
        + srun -n 8 -c 32 -m block mpi_check -r

        Running 8 single-threaded MPI ranks.

        ++ mpi_check: MPI rank   0/8   on cpu   0/256 of nid001804 mask 0-31
        ++ mpi_check: MPI rank   1/8   on cpu  32/256 of nid001804 mask 32-63
        ++ mpi_check: MPI rank   2/8   on cpu   1/256 of nid001805 mask 0-31
        ++ mpi_check: MPI rank   3/8   on cpu  32/256 of nid001805 mask 32-63
        ++ mpi_check: MPI rank   4/8   on cpu  64/256 of nid001804 mask 64-95
        ++ mpi_check: MPI rank   5/8   on cpu 112/256 of nid001804 mask 96-127
        ++ mpi_check: MPI rank   6/8   on cpu  64/256 of nid001805 mask 64-95
        ++ mpi_check: MPI rank   7/8   on cpu 112/256 of nid001805 mask 96-127
        ```


## Refining core binding in OpenMP applications

In a Slurm batch job step, threads of a shared memory process will be contained to all 
hardware threads of all available cores on the first node of your allocation. To contain
a shared memory program to the hardware threads asked for in the allocation (i.e., to ensure
that `--hint=[no]multithread` has effect) you'd have to start the shared memory program with
`srun` in a regular job step.

Any multithreaded executable run as a shared memory job or ranks in a hybrid MPI/multithread job,
will - when started properly via `srun` - get access to a group of cores via an affinity mask.
In some cases you will want to manually refine the way individual threads of each process are
mapped onto the available hardware threads.

In OpenMP, this is usually done through environment variables (it can also be done partially in
the program through library calls).




## GPU binding with ROCR_VISIBLE_DEVICES

-   Non-optimal example on standard-g

-   Examples on small-g )non-optimal by definition)


## Combining Slurm task binding with ROCR_VISIBLE_DEVICES

Or: How to get an optimal mapping on the GPU nodes?


## Further material

-   Distribution and binding is discussed in more detail in our
    [4-day comprehensive LUMI courses](https://lumi-supercomputer.github.io/LUMI-training-materials/comprehensive-latest).
    Check for the lecture on "Advanced Placement" which is usually
    given on day 2 of the course.

    Material of this presentation is available to all LUMI users on the system. Check the course
    website for the names of the files.

-   Rank reordering in Cray MPICH is discussed is also discussed in more dteail in our
    [4-day comprehensive LUMI courses](https://lumi-supercomputer.github.io/LUMI-training-materials/comprehensive-latest),
    but in the lecture on "MPI Topics on the HPE Cray EX Supercomputer" (often on day 3 of the course)
    that discusses more advanced MPI on LUMI, including loads of environment variables that can be used to
    improve the performance.

