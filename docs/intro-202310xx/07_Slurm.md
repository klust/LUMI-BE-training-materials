# Slurm on LUMI

!!! Audience "Who is this for?"
    We assume some familiarity with job scheduling in this section. The notes will cover
    some of the more basic aspects of Slurm also, though as this version of the notes is
    intended for Belgian users and since all but one HPC site in Belgium currently teaches
    Slurm to their users, some elements will be covered only briefly.

    Even if you have a lot of experience with Slurm, it may still be useful to have a quick
    look at this section as Slurm is not always configured in the same way.

## What is Slurm

<figure markdown style="border: 1px solid #000">
  ![Slide What is Slurm](https://465000095.lumidata.eu/intro-202310xx/img/LUMI-BE-Intro-202310XX-07-slurm/WhatIsSlurm.png){ loading=lazy }
</figure>

Slurm is both a resource manager and job scheduler for supercomputers in a single package.

A resource manager manages all user-exposed resources on a supercomputer: cores, GPUs or other
accelerators, nodes, ... It sets up the resources to run a job and cleans up after the job,
and may also give additional facilities to start applications in a job. Slurm does all this.

But Slurm is also a job scheduler. It will assign jobs to resources, following policies set
by sysadmins to ensure a good use of the machine and a fair distribution of resources among
projects.

Slurm is the most popular resource manager and job scheduler at the moment and is used on more
than 50% of all big supercomputers. It is an open source package with commercial support.
Slurm is a very flexible and configurable tool with the help of tens or even hundreds of
plugins. This also implies that Slurm installations on different machines can also differ
a lot and that not all features available on one computer are also available on another.
So do not expect that Slurm will behave the same on LUMI as on that other computer you're
familiar with, even if that other computer may have hardware that is very similar to LUMI.

Slurm is starting to show its age and has trouble dealing in an elegant and proper way with
the deep hierarcy of resources in modern supercomputers. So Slurm will not always be as
straightforward to use as we would like it, and some tricks will be needed on LUMI. Yet there
is no better option at this moment that is sufficiently mature.

!!! lumi-be "Other systems in Belgium"
    Previously at the VSC Torque was used as the resource manager and Moab as the scheduler.
    All VSC sites now use Slurm, though at UGent it is still hidden behind wrappers that
    mimic Torque/Moab. As we shall see in this and the next session, Slurm, which is a
    more modern resource manager and scheduler than the Torque-Moab combination, has 
    already trouble dealing well with the hierarchy of resources in a modern supercomputer.
    Yet it is still a lot better at it than Torque and Moab. So no, the wrappers used on
    the HPC systems managed by UGent will not be installed on LUMI.

!!! nice-to-know "Nice to know..."
    Lawrence Livermore National Laboratory, the USA national laboratory that 
    originally developed Slurm is now working on the 
    development of andother resource and job management framework called 
    [flux](https://computing.llnl.gov/projects/flux-building-framework-resource-management).
    It will be used on the third USA exascale supercomputer El Capitan which is currently
    being assembled. 


## Slurm concepts: Physical resources

<figure markdown style="border: 1px solid #000">
  ![Slide Slurm concepts 1](https://465000095.lumidata.eu/intro-202310xx/img/LUMI-BE-Intro-202310XX-07-slurm/SlurmConceptsPhys.png){ loading=lazy }
</figure>

The machine model of Slurm is bit more limited than what we would like for LUMI. 

On the CPU side it knows:

-   A **node**: The hardware that runs a single operating system image

-   A **socket**: On LUMI a Slurm socket corresponds to a physical socket, so there are two sockets on the 
    CPU nodes and a single socket on a GPU node.

    Alternatively a cluster could be configured to let a Slurm socket correspond to a NUMA domain or 
    L3 cache domain, but this is something that sysadmins need to do so even if this would be useful for
    your job, you cannot do so.

-   A **core** is a physical core in the system

-   A **thread** is a hardware thread in the system (virtual core)

-   A **CPU** is a "consumable resource" and the unit at which CPU processing capacity is allocated to a job.
    On LUMI a Slurm CPU corresponds to a physical core, but Slurm could also be configured to let it correspond
    to a hardware thread.

The first three bullets already show the problem we have with Slurm on LUMI: For three levels in the hierarchy
of CPU resources on a node: the socket, the NUMA domain and the L3 cache domain, there is only one concept in
Slurm, so we are not able to fully specify the hierarchy in resources that we want when sharing nodes with 
other jobs.

A **GPU** in Slurm is an accelerator and on LUMI corresponds to one GCD of an MI250X, so one half of an MI250X.

## Slurm concepts: Logical resources

<figure markdown style="border: 1px solid #000">
  ![Slide Slurm concepts 2](https://465000095.lumidata.eu/intro-202310xx/img/LUMI-BE-Intro-202310XX-07-slurm/SlurmConceptsLog.png){ loading=lazy }
</figure>

-   A **partition**: is a job queue with limits and access control. Limits include maximum
    wall time for a job, the maximum number of nodes a single job can use, or the maximum
    number of jobs a user can run simultaneously in the partition. The access control 
    mechanism determines who can run jobs in the partition.

    It is different from what we call LUMI-C and LUMI-G, or the `partition/C` and `partition/G`
    modules in the LUMI software stacks.

    Each partition covers a number of nodes, but partitions can overlap. This is not the case
    for the partitions that are visible to users on LUMI. Each partition covers a disjunct set
    of nodes. There are hidden partitions though that overlap with other partitions, but they
    are not accessible to regular users.

-   A **job** in Slurm is basically only a resource allocation request.

-   A **job step** is a set of (possibly parallel) tasks within a job

    -   Each batch job always has a special job step called the batch job step which runs
        the job script on the first node of a job allocation.

    -   An MPI application will typically run in its own job step.

    -   Serial or shared memory applications are often run in the batch job step but there
        can be good reasons to create a separate job step for those applications.

-   A **task** executes in a job step and corresponds to a Linux process (and possibly subprocesses)

    -   A shared memory program is a single task

    -   In an MPI application: Each rank (so each MPI process) is a task

        -   Pure MPI: Each task uses a single CPU (which is also a core for us)

        -   Hybrid MPI/OpenMP applications: Each task can use multiple CPUs

    Of course a task cannot use more CPUs than available in a single node as a process can only run
    within a single operating system image.


## Slurm is first and foremost a batch scheduler

<figure markdown style="border: 1px solid #000">
  ![Slide Slurm is first and foremost a batch scheduler](https://465000095.lumidata.eu/intro-202310xx/img/LUMI-BE-Intro-202310XX-07-slurm/BatchScheduler.png){ loading=lazy }
</figure>

And LUMI is in the first place a batch processing supercomputer.

A supercomputer like LuMI is a very large and very expensive machine. This implies that it also has to be
used as efficiently as possible which in turn implies that we don't want to wast time waiting for input
as is the case in an interactive program.

On top of that, very few programs can use the whole capacity of the supercomputer, so in practice a
supercomputer is a shared resource and each simultaneous user gets a fraction on the machine depending
on the requirements that they specify. Yet, as parallel applications work best when performance is predictable,
it is also important to isolate users enough from each other.

Research supercomputers are also typically very busy with lots of users so one often has to wait a little 
before resources are available. This may be different on some commercial supercomputers and is also different
on commercial cloud infrastructures, but the "price per unit of work done on the cluster" is also very 
different from an academic supercomputer and few or no funding agencies are willing to carry that cost.

Due to all this the preferred execution model on supercomputer is via batch jobs as they don't have to wait
for input from the user, specified via batch scripts with resource specification where the user asks 
precisely the amount of resources needed for the job, submitted to a queueing system with a scheduler
to select the next job in a fair way based on available resources and scheduling policies set by the 
compute centre.

LUMI does have some facilities for interactive jobs, and with the introduction of Open On Demand some more
may be available. But it is far from ideal, and you will also be billed for the idle time of the resources
you request. In fact, if you only need some interactive resources for a quick 10-minute experiment and don't 
need too many resources, the wait may be minimal thanks to a scheduler mechanism called backfill where the
scheduler looks for small and short jobs to fill up the gaps left while the scheduler is collecting resources
for a big job.


## A Slurm batch script

<figure markdown style="border: 1px solid #000">
  ![Slide A Slurm batch script](https://465000095.lumidata.eu/intro-202310xx/img/LUMI-BE-Intro-202310XX-07-slurm/BatchScript.png){ loading=lazy }
</figure>

Slurm batch scripts (also called job scripts) are conceptually not that different from batch scripts for other HPC schedulers.
A typical batch script will have 4 parts:

1.  The shebang line with the shell to use. We advise to use the bash shell (`/bin/bash` or `/usr/bin/bash`)
    If omitted, a very restricted shell will be used and some commands (e.g., related to modules)
    may fail. In principle any shell language that uses a hashtag to denote comments can be used, but
    we would advise against experimenting and the LUMI User Support Team and VSC support teams will only
    support bash.

2.  Specification of resources and some other instructions for the scheduler and resource manager. This part
    is also optional as one can also pass the instructions via the command line of `sbatch`, the command to
    submit a batch job. But again, we would advise against omitting this block as specifying all options on
    the command line can be very tedious.

3.  Building a suitable environment for the job. This part is also optional as on LUMI, Slurm will copy the
    environment from the node from which the job was submitted. This may not be the ideal envrionment for your job,
    and if you later resubmit the job you may do so accidentally from a different environment so it is a good practice
    to specify the environment.

4.  The commands you want to execute.

Blocks 3 and 4 can of course be mixed as you may want to execute a second command in a different environment.

On the following slides we will explore in particular the second block and to some extent how to start programs
(the fourth block).

!!! note "lumi-CPEtools module"
    The [`lumi-CPEtools` module](https://lumi-supercomputer.github.io/LUMI-EasyBuild-docs/l/lumi-CPEtools/)
    will be used a lot in this session of the course and in the next one on binding. It contains among
    other things a number of programs to quickly visualise how a serial, OpenMP, MPI or hybrid OpenMP/MPI
    application would run on LUMI and which cores and GPUs would be used. It is a very useful tool to 
    discover how Slurm options work without using a lot of billing units and we would advise you to 
    use it whenever you suspect Slurm isn't doing what you meant to do.

    It has its [documentation page in the LUMI Software Library](https://lumi-supercomputer.github.io/LUMI-EasyBuild-docs/l/lumi-CPEtools/).


## Partitions

<figure markdown style="border: 1px solid #000">
  ![Slide Partitions 1](https://465000095.lumidata.eu/intro-202310xx/img/LUMI-BE-Intro-202310XX-07-slurm/Partitions_1.png){ loading=lazy }
</figure>

!!! Remark
    Jobs run in partitions so the first thing we should wonder when setting up a job is which partition
    to use for a job (or sometimes partitions in case of a heterogeneous job which will be discussed
    later).

Slurm partitions are possibly overlapping groups of nodes with similar resources or associated limits. 
Each partition typically targets a particular job profile. E.g., LUMI has partitions for large multi-node jobs,
for smaller jobs that often cannot fill a node, for some quick debug work and for some special resources that 
are very limited (the nodes with 4TB of memory and the nodes with GPUs for visualisation). The number of jobs
a user can have running simultaneously in each partition or have in the queue, the maximum wall time for a job,
the number of nodes a job can use are all different for different partitions.

There are two types of partitions on LUMI:

-   **Exclusive node use by a single job.** This ensures that parallel jobs can have a clean environment
    with no jitter caused by other users running on the node and with full control of how tasks and threads
    are mapped onto the available resources. This may be essential for the performance of a lot of codes.

-   **Allocatable by resources (CPU and GPU).** In these partitions nodes are shared by multiple users and
    multiple jobs, though in principle it is possible to ask for exclusive use which will however increase
    your waiting time in the queue. The cores you get are not always continuously numbered, nor do you 
    always get the minimum number of nodes needed for the number of tasks requested. A proper mapping 
    of cores onto GPUs is also not ensured at all. The fragmentation of resources is a real problem on
    these nodes and this may be an issue for the performance of your code.

It is also important to realise that the default settings for certain Slurm parameters may differ
between partitions and hence a node in a partition allocatable by resource but for which exclusive 
access was requested may still react differently to a node in the exclusive partitions.

In general it is important to use some common sense when requesting resources and to have some understanding
of what each Slurm parameter really means. Overspecifying resources (using more parameters than needed for the
desired effect) may result in unexpected conflicts between parameters and error messages.

<figure markdown style="border: 1px solid #000">
  ![Slide Partitions 2](https://465000095.lumidata.eu/intro-202310xx/img/LUMI-BE-Intro-202310XX-07-slurm/Partitions_2.png){ loading=lazy }
</figure>

For the overview of Slurm partitions, see the [LUMI dpcumentation, "Slurm partitions" page](https://docs.lumi-supercomputer.eu/runjobs/scheduled-jobs/partitions/).
In the overview on the slide we did not mention partitions that are hidden to regular users.

The policies for partitions and the available partitions may change over time to fine tune the
operation of LUMI and depending on needs observed by the system administrators and LUMI
User Support Team.

<figure markdown style="border: 1px solid #000">
  ![Slide Partitions 3](https://465000095.lumidata.eu/intro-202310xx/img/LUMI-BE-Intro-202310XX-07-slurm/Partitions_3.png){ loading=lazy }
</figure>

Some useful commands with respect to Slurm partitions:

-   To request information about the available partitions, use `sinfo -s`: 

    ```
    $ sinfo -s
    PARTITION   AVAIL  TIMELIMIT   NODES(A/I/O/T) NODELIST
    standard       up 2-00:00:00  595/71/354/1020 nid[001002-001009,001012-002023]
    small          up 3-00:00:00   354/16/124/494 nid[002028-002060,002062-002152,002154-002523]
    interactive    up    8:00:00          0/3/1/4 nid[002524-002527]
    debug          up      30:00          0/5/3/8 nid[002528-002535]
    lumid          up 1-00:00:00          0/0/8/8 nid[000016-000023]
    largemem       up 1-00:00:00          0/0/8/8 nid[000101-000108]
    eap            up 1-00:00:00        2/26/4/32 nid[005000-005031]
    standard-g     up 2-00:00:00 1809/319/80/2208 nid[005032-007239]
    small-g        up 3-00:00:00    62/196/22/280 nid[007240-007519]
    dev-g          up    6:00:00        1/43/4/48 nid[007520-007531,007534-007545,007548-007559,007562-007573]
    q_nordiq       up      15:00          0/1/0/1 nid001001
    q_fiqci        up      15:00          0/1/0/1 nid002153
    ```

    The fourth column shows 4 numbers: The number of nodes that are currently fully or partially allocated
    to jobs, the number of idle nodes, the number of nodes in one of the other possible states (and not
    user-accessible) and the total number of nodes in the partition. When these nodes were written
    a large number of nodes were suffering from hardware problems with the Slingshot network cards and
    we were waiting for replacement parts which explains the thigh number of CPU nodes in the "other"
    field.

    Note that this overview may show partitions that are not hidden but also not accessible to everyone. E.g., 
    the `q_nordic` and `q_fiqci` partitions are used to access experimental quantum computers that are only
    available to some users of those countries that paid for those machines, which does not include Belgium.

    The `eap` partition will likely be phased out over time and is a remainder of a platform used for early 
    development before LUMI-G was attached to the machine. At the moment it allows users to experiment freely 
    with the GPU nodes.

    It is not clear to the LUMI Support Team what the `interactive` partition, that uses dome GPU nodes, is 
    meant for as it was introduced without informting the support. The resources in that partition are very
    limited so it is not meant for widespread use.

-   For technically-oriented people, some more details about a partition can be obtained with
    `scontrol show partition <partition-name>`.

??? example "Additional example with `sinfo`"
    Try

    ```
    $ sinfo --format "%4D %10P %25f %.4c %.8m %25G %N"
    NODE PARTITION  AVAIL_FEATURES            CPUS   MEMORY GRES                      NODELIST
    256  standard   AMD_EPYC_7763,x1001        256   229376 (null)                    nid[001256-001511]
    256  standard   AMD_EPYC_7763,x1002        256   229376 (null)                    nid[001512-001767]
    256  standard   AMD_EPYC_7763,x1003        256   229376 (null)                    nid[001768-002023]
    252  standard   AMD_EPYC_7763,x1000        256   229376 (null)                    nid[001002-001009,001012-001255]
    244  small      AMD_EPYC_7763,x1005        256  229376+ (null)                    nid[002280-002523]
    250  small      AMD_EPYC_7763,x1004        256   229376 (null)                    nid[002028-002060,002062-002152,002154-002279]
    4    interactiv AMD_EPYC_7763,x1005        256   229376 (null)                    nid[002524-002527]
    8    debug      AMD_EPYC_7763,x1005        256   229376 (null)                    nid[002528-002535]
    8    lumid      AMD_EPYC_7742              256  2048000 gpu:a40:8,nvme:40000      nid[000016-000023]
    8    largemem   AMD_EPYC_7742              256 4096000+ (null)                    nid[000101-000108]
    32   eap        AMD_EPYC_7A53,x1100        128   491520 gpu:mi250:8               nid[005000-005031]
    112  standard-g AMD_EPYC_7A53,x1401        128   491520 gpu:mi250:8               nid[007016-007127]
    112  standard-g AMD_EPYC_7A53,x1402        128   491520 gpu:mi250:8               nid[007128-007239]
    80   standard-g AMD_EPYC_7A53,x1100        128   491520 gpu:mi250:8               nid[005032-005111]
    112  standard-g AMD_EPYC_7A53,x1101        128   491520 gpu:mi250:8               nid[005112-005223]
    112  standard-g AMD_EPYC_7A53,x1102        128   491520 gpu:mi250:8               nid[005224-005335]
    112  standard-g AMD_EPYC_7A53,x1103        128   491520 gpu:mi250:8               nid[005336-005447]
    112  standard-g AMD_EPYC_7A53,x1104        128   491520 gpu:mi250:8               nid[005448-005559]
    112  standard-g AMD_EPYC_7A53,x1105        128   491520 gpu:mi250:8               nid[005560-005671]
    112  standard-g AMD_EPYC_7A53,x1200        128   491520 gpu:mi250:8               nid[005672-005783]
    112  standard-g AMD_EPYC_7A53,x1201        128   491520 gpu:mi250:8               nid[005784-005895]
    112  standard-g AMD_EPYC_7A53,x1202        128   491520 gpu:mi250:8               nid[005896-006007]
    112  standard-g AMD_EPYC_7A53,x1203        128   491520 gpu:mi250:8               nid[006008-006119]
    112  standard-g AMD_EPYC_7A53,x1204        128   491520 gpu:mi250:8               nid[006120-006231]
    112  standard-g AMD_EPYC_7A53,x1205        128   491520 gpu:mi250:8               nid[006232-006343]
    112  standard-g AMD_EPYC_7A53,x1300        128   491520 gpu:mi250:8               nid[006344-006455]
    112  standard-g AMD_EPYC_7A53,x1302        128   491520 gpu:mi250:8               nid[006568-006679]
    112  standard-g AMD_EPYC_7A53,x1303        128   491520 gpu:mi250:8               nid[006680-006791]
    112  standard-g AMD_EPYC_7A53,x1304        128   491520 gpu:mi250:8               nid[006792-006903]
    112  standard-g AMD_EPYC_7A53,x1305        128   491520 gpu:mi250:8               nid[006904-007015]
    112  standard-g AMD_EPYC_7A53,x1301        128   491520 gpu:mi250:8               nid[006456-006567]
    56   small-g    AMD_EPYC_7A53,x1405        128   491520 gpu:mi250:8               nid[007464-007519]
    112  small-g    AMD_EPYC_7A53,x1404        128   491520 gpu:mi250:8               nid[007352-007463]
    112  small-g    AMD_EPYC_7A53,x1403        128   491520 gpu:mi250:8               nid[007240-007351]
    48   dev-g      AMD_EPYC_7A53,x1405        128   491520 gpu:mi250:8               nid[007520-007531,007534-007545,007548-007559,007562-007573]
    1    q_nordiq   AMD_EPYC_7763,x1000        256   229376 (null)                    nid001001
    1    q_fiqci    AMD_EPYC_7763,x1004        256   229376 (null)                    nid002153
    ```
    (Output may vary over time)
    
    This shows more information about the system. The `xNNNN` feature corresponds to groups in 
    the Slingshot interconnect and may be useful if you want to try to get a job running in
    a single group (which is too advanced for this course).

    The memory size is given in megabyte (MiB, multiples of 1024). The "+" in the second group
    of the small partition is because that partition also contains the 512 GB and 1 TB regular 
    compute nodes. The memory reported is always 32 GB less than you would expect from the 
    node specifications. This is because 32 GB on each node is reserved for the OS and the 
    RAM disk it needs.


## Queueing and fairness

<figure markdown style="border: 1px solid #000">
  ![Slide Fairness of queueing](https://465000095.lumidata.eu/intro-202310xx/img/LUMI-BE-Intro-202310XX-07-slurm/Fairness.png){ loading=lazy }
</figure>

!!! Remark
    Jobs are queued until they can run so we should wonder how that system works.

LUMI is a pre-exascale machine meant to foster research into exascale applications. 
As a result the scheduler setup of LUMI favours large jobs (though some users with large
jobs will claim that it doesn't do so enough yet). Most nodes are reserved for larger 
jobs (in the `standard` and `standard-g` partitions), and the priority computation
also favours larger jobs (in terms of number of nodes).

When you submit a job, it will be queued until suitable resources are available for the
requested time window. Keep in mind that you may see a lot of free nodes on LUMI yet your 
small job may not yet start immediately as the scheduler may be gathering nodes for a
big job.

The command to check the status of the queue is `squeue`. Two command line flags are useful:

-   `--me` will restrict the output to your jobs only

-   `--start` will give an estimated start time for each job. Note that this really doesn't say 
    much as the scheduler cannot predict the future. On one hand, other jobs that are running
    already or scheduled to run before your job, may have overestimated the time they need and
    end early. But on the other hand, the scheduler does not use a "first come, first serve" policy
    so another user may submit a job that gets a higher priority than yours, pushing back the start
    time of your job. So it is basically a random number generator.

The `sprio` command will list the different elements that determine the priority of your job but
is basically a command for system administrators as users cannot influence those numbers nor do 
they say a lot unless you understand all intricacies of the job policies chosen by the site,
and those policies may be fine-tuned over time to optimise the operation of the cluster.
The fairshare parameter influences the priority of jobs depending on how much users or projects
(this is not clear to us at the moment) have been running jobs in the past few days and is a
very dangerous parameter on a supercomputer where the largest project is over 1000 times the size
of the smallest projects, as treating all projects equally for the fair share would make it impossible
for big projects to consume all their CPU time.

Another concept of the scheduler on LUMI is **backfill**. On a system supporting very large jobs as LUMI,
the scheduler will often be collecting nodes to run those large jobs, and this may take a while,
particularly since the maximal wall time for a job in the standard partitions is rather large
for such a system. If you need one quarter of the nodes for a big job on a partition on which most 
users would launch jobs that use the full two days of walltime, one can expect that it takes half
a day to gather those nodes. However, the LUMI scheduler will schedule short jobs even though they have a lower
priority on the nodes already collected if it expects that those jobs will be finisehd before it expects
to have all nodes for the big job. This mechanism is called backfill and is the reason why
short experiments of half an hour or so often start quickly on LUMI even though the queue is very long.


## Accounting of jobs

<figure markdown style="border: 1px solid #000">
  ![Slide Accounting of jobs](https://465000095.lumidata.eu/intro-202310xx/img/LUMI-BE-Intro-202310XX-07-slurm/Accounting.png){ loading=lazy }
</figure>

!!! Remark "Billing of jobs"
    Jobs are billed against your allocation, so how does this work?

The use of resources by a job is billed to projects, not users. All management is also
done at the project level, not at the "user-in-a-project" level.
As users can have multiple projects, the system cannot know to which project a job
should be billed, so it is mandatory to specify a project account (of the form
`project_46YXXXXXX`) with every command that creates an allocation.

Billing on LUMI is not based on which resources you effectively use, but on the
amount of resources that others cannot use well because of your allocation. 
This assumes that you make proportional use of CPU cores, CPU memory and GPUs (actually GCDs).
If you job makes a disproportionally high use of one of those resources, you will be billed
based on that use. For the CPU nodes, the billing is based on both the number of cores you
request in your allocation and the amount of memory compared to the amount of memory per core
in a regular node, and the highest of the two numbers is used. For the GPU nodes, the formula
looks at the number of cores compared to he number of cores per GPU, the amount of CPU memory compared 
to the amount of memory per GCD (so 64 GB), and the amount of GPUs and the highest amount
determines for how many GCDs you will be billed (with a cost of 0.5 GPU-hour per hour per GCD).
For jobs in job-exclusive partitions you are automatically billed for the full node as no other
job can use that node, so 128 core-hours per hour for the standard partition or
4 GPU-hours per hour for the standard-g partition.

E.g., if you would ask for only one core but 128 GB of memory, half of what a regular LUMI-C node has,
you'd be billed for the use of 64 cores. Or assume you want to use only one GCD but want to use 16 cores
and 256 GB of system RAM with it, then you would be billed for 4 GPUs/GCDs: 256 GB of memory makes it impossible
for other users to use 4 GPUs/GCDs in the system, and 16 cores make it impossible to use 2 GPUs/GCDs,
so the highest number of those is 4, which means that you will pay 2 GPU-hours per hour that you use the
allocation (as GPU-hours are based on a full MI250x and not on a GCD which is the GPU for Slurm).

!!! Remark "This billing policy is unreasonable!"
    Users who have no experience with performance optimisation may think this way of
    billing is unfair. After all, there may be users who need far less than 2 GB of memory
    per core so they could still use the other cores on a node where I am using only
    one core but 128 GB of memory, right? Well, no, and this has everything to do with
    the very hierarchical nature of a modern compute node, with on LUMI-C 2 sockets,
    4 NUMA domains per socket, and 2 L3 cache domains per NUMA domain. Assuming your
    job would get the first core on the first socket (called core 0 and socket 0 as
    computers tend to number from 0). Linux will then allocate the memory of the job
    as close as possible to that core, so it will fill up the 4 NUMA domains of that
    socket. It can migrate unused memory to the other socket, but let's assume your 
    code does not only need 128 GB but also accesses bits and pieces from it everywhere
    all the time. Another application running on socket 0 may then get part or all
    of its memory on socket 1, and the latency to access that memory is more than 
    3 times higher, so performance of that application will suffer. In other words,
    the other cores in socket 0 cannot be used with full efficiency.

    This is not a hypothetical scenario. The author of this text has seem benchmarks
    run on one of the largest systems in Flanders that didn't scale at all and for
    some core configuration ran at only 10% of the speed they should have been
    running at...

    Still, even with this billing policy Slurm oon LUMI is a far from perfect scheduler
    and core, GPU and memory allocation on the non-exclusive partitions are far from
    optimal. Which is why we spend a section of the course on binding applications
    to resources.

The billing is done in a postprocessing step in the system based on data from the Slurm 
job database, but the Slurm accounting features do not produce the correct numbers. 
E.g., Slurm counts the core hours based on the virtual cores so the numbers are double
of what they should be. There are two ways to check the state of an allocation, though
both work with some delay.

-   The `lumi-workspaces` and `lumi-allocations` commands show the total amount of 
    billing units consumed. In regular operation of the system these numbers are updated
    approximately once an hour.

    `lumi-workspaces` is the all-in command that intends to show all information that is 
    useful to a regular user, while `lumi-allocations` is a specialised tool that only
    shows billing units, but he numbers shown by both tools come from the same database
    and are identical.

-   For projects managed via Puhuri, Puhuri can show billing unit use per month, but the
    delay is larger than with the `lumi-workspaces` command.



!!! Remark "Billing unit use per user in a project"
    The current project management system in LUMI cannot show the use of billing units
    per person within a project.

    For storage quota this would be very expensive to organise as quota are managed
    by Lustre on a group basis. 

    For CPU and GPU billing units it would in principle be possible as the Slurm
    database contains the necessary information, but there are no plans to implement
    such a feature. It is assumed that every PI makes sure that members of their 
    projects use LUMI in a responsible way and ensures that they have sufficient 
    experience to realise what they are doing.


## Creating a Slurm job

<figure markdown style="border: 1px solid #000">
  ![Slide Creating a Slurm job](https://465000095.lumidata.eu/intro-202310xx/img/LUMI-BE-Intro-202310XX-07-slurm/CreateJob.png){ loading=lazy }
</figure>

Slurm has three main commands to create jobs and job steps. 
Remember that a job is just a request for an allocation. Your applications always have to
run inside a job step.

The `salloc` command only creates an allocation but does not create a job step.
**The behaviour of `salloc` differs between clusters!** 
On LUMI, `salloc` will put you in a new shell on the node from which you issued
the `salloc` command, typically the login node. Your allocation will exist until
you exit that shell with the `exit` command or with the CONTROL-D key combination.
Creating an allocation with `salloc` is good for interactive work.

!!! Remark "Differences in `salloc` behaviour."
    On some systems `salloc` does not only create a job allocation but will
    also create a job step, the so-called "interactive job step" on a node of
    the allocation, similar to the way that the `sbatch` command discussed later
    will create a so-called "batch job step".

The main purpose of the `srun` command is to create a job step in an allocation.
When run outside of a job (outside an allocation) it will also create a job allocation.
However, be careful when using this command to also create the job in which the job step
will run as some options work differently as for the commands meant to create an allocation.
When creating a job with `salloc` you will have to use `srun` to start anything on the
node(s) in the allocation as it is not possible to, e.g., reach the nodes with `ssh`.

The `sbatch` command both creates a job and then start a job step, teh so-called batch
job step, to run the job script on the first node of the job allocation.
In principle it is possible to start both sequential and shared memory processes
directly in the batch job step without creating a new job step with `srun`, 
but keep in mind that the resources may be different from what you expect to see
in some cases as some of the options given with the `sbatch` command will only be
enforced when starting another job step from the batch job step. To run any
multi-process job (e.g., MPI) you will have to use `srun` or a process starter that
internally calls `srun` to start the job.
**When using Cray MPICH as the MPI implementation (and it is the only one that is fully
supported on LUMI) you will have to use `srun` as the process starter.**


## Passing options to srun, salloc and sbatch

<figure markdown style="border: 1px solid #000">
  ![Slide Passing options to srun, salloc and sbatch](https://465000095.lumidata.eu/intro-202310xx/img/LUMI-BE-Intro-202310XX-07-slurm/PassingOptions.png){ loading=lazy }
</figure>

There are several ways to pass options and flags to the `srun`, `salloc` and `sbatch` command.

The lowest priority way and only for the `sbatch` command is specifying the options (mostly resource-related)
in the batch script itself on `#SBATCH` lines. These lines should not be interrupted by commands, and it is
not possible to use environment variables to specify values of options. 

Higher in priority is specifying options and flags through environment variables. 
For the `sbatch` command this are the `SBATCH_*` environment variables, for `salloc`
the `SALLOC_*` environment variables and for `srun` the `SLURM_*` and some `SRUN_*` environment variables.
For the `sbatch` command this will overwrite values on the `#SBATCH` lines. You can find
lists in the manual pages of the 
[`sbatch`](https://slurm.schedmd.com/sbatch.html),
[ `salloc`](https://slurm.schedmd.com/salloc.html) and
[`srun`](https://slurm.schedmd.com/srun.html) command.
Specifying command line options via environment variables that are hidden in your
`.profile` or `.bashrc` file or any script that you run before starting your work,
is not free of risks. Users often forget that they set those environment variables and
are then surprised that the Slurm commands act differently then expected. E.g., it
is very tempting to set the project account to use in environment variables but if you 
then get a second project you may be running inadvertently in the wrong project.

The highest priority is for flags and options given on the command line. The position of 
those options is important though. With the `sbatch` command they have to be specified before
the batch script as otherwise they will be passed to the batch script as command line options for 
that script. Likewise, with `srun` they have to be specified before the command you want to execute
as otherwise they would be passed to that command as flags and options.

Several options specified to `sbatch` or `salloc` are also forwarded to `srun` via `SLURM_*` environment
variables set in the job by these commands.


## Specifying options

<figure markdown style="border: 1px solid #000">
  ![Slide Specifying options](https://465000095.lumidata.eu/intro-202310xx/img/LUMI-BE-Intro-202310XX-07-slurm/SpecifyingOptions.png){ loading=lazy }
</figure>

Slurm commands have way more options and flags than we can discuss in this course or even the
4-day comprehensive course organised by the LUMI User Support Team. Moreover, if and how they work
may depend on the specific configuration of Slurm. Slurm has so many options that no two clusters
are the same. 

Slurm command can exist in two variants:

1.  The long variant, with a double dash, is of the form `--long-option=<value>` or 
    `--long-option <value>`

2.  But many popular commands also have a single letter variant, with a single dash:
    `-S <value>` or `-S<value>`

This is no different from many popular Linux commands.

Slurm commands for creating allocations and job steps have many different flags for specifying
the allocation and the organisation of tasks in that allocation. Not all combinations are valid,
and it is not possible to sum up all possible configurations for all possible scenarios. Use 
common sense and if something does not work, check the manual page and try something different.
Overspecifying options is not a good idea as you may very well create conflicts, and we will see
some examples in this section and the next section on binding. However, underspecifying is not
a good idea either as some defaults may be used you didn't think of. Some combinations also just 
don't make sense, and we will warn for some on the following slides and try to bring some 
structure in the wealth of options.
<!-- 
E.g., if you are running in "allocatable by resource" partitions you don't 
always know which cores on a node you will get so using options that specify specific cores for
specific tasks will result in error messages. If you want full nodes it may just be better to use
the standard and standard-g partitions unless you need one of the CPU nodes with more memory per 
node. Also, keep in mind that on "allocatable by resource" partitions Slurm already needs to
know the structure of the tasks (cores per task, GPUs per task) to be able to create a proper 
allocation as tasks and cores may be spread out within a node or across multiple nodes of LUMI.
Obviously a task in a job step needs all its resources (cores, memory and GPUs) in the same 
node, and if multiple tasks are sharing GPUs then obviously these tasks must also be on the
same node.
-->

## Some common options to all partitions

<figure markdown style="border: 1px solid #000">
  ![Slide Some common options to all partitions](https://465000095.lumidata.eu/intro-202310xx/img/LUMI-BE-Intro-202310XX-07-slurm/SpecifyingCommonOptions.png){ loading=lazy }
</figure>

For CPU and GPU requests, a different strategy should be used for "allocatable by node" and "allocatable by resource" partitions,
and this will be discussed later. A number of options however are common to both strategies and will be discussed first.
All are typically used on `#SBATCH` lines in job scripts, but can also be used on the command line and the first three are
certainly needed with `salloc` also.

-   Specify the account to which the job should be billed with `--account=project_46YXXXXXX` or `-A project_46YXXXXXX`.
    This is mandatory; without this your job will not run.

-   Specify the partition: `--partition=<partition>  or `-p <partition>`. This option is also necessary
    on LUMI as there is currently no default partition.

-   Specify the wall time for the job: `--time=<timespec>` or `-t <timespec>`. There are multiple formats for
    the time specifications, but the most common ones are minutes (one number), minutes:seconds (two numbers separated
    by a colon) and hours:minutes:seconds (three numbers separated by a column). If not specified, the partition-dependent
    default time is used.

    It does make sense to make a reasonable estimate for the wall time needed. It does protect you a bit in case
    your application hangs for some reason, and short jobs that also don't need too many nodes have a high chance of
    running quicker as they can be used as backfill while the scheduler is gathering nodes for a big job.

-   Completely optional: Specify a name for the job with `--job-name=<name>` or `-J <name>`. Short but clear
    job names help to make the output of `squeue` easier to interpret, and the name can be used to generate 
    a name for the output file that captures output to stdout and stderr also.

-   Slurm also has options to send mail to a given address when a job starts or ends or some other job-related
    events occur, but this is currently not configured on LUMI.


## Redirecting output 

<figure markdown style="border: 1px solid #000">
  ![Slide Redirecting output](https://465000095.lumidata.eu/intro-202310xx/img/LUMI-BE-Intro-202310XX-07-slurm/SpecifyingOutput.png){ loading=lazy }
</figure>

Slurm has two options to redirect stdout and stderr respectively: `--output=<template>` or `-o <template>` for stdout
and `--error=<template>` or `-e <template>` for stderr. They work together in the following way:

-   If neither `--output` not `--error` is specified, then stdout and stderr are merged and redirected to the file `slurm-<jobid>.out`.

-   If `--output` is specified but `--error` is not, then stdout and stderr are merged and redirected to the file given with `--output`.

-   If `--output` is not specified but `--error`, then stdout will still be redirected to `slurm-<jobid>.out`, but
    stderr will be redirected to the file indicated by the `--error` option.

-   If both `--output` and `--error` are specified, then stdout is redirected to the file given by `--output` and
    stderr is redirected to the file given by `--error`.

It is possible to insert codes in the filename that will be replaced at runtime with the corresponding Slurm 
information. Examples are `%x` which will be replaced with the name of the job (that you can then best set with
`--job-name`) and `%j`` which will be replaced with the job ID (job number). It is recommended to always include 
the latter in the template for the filename as this ensures unique names if the same job script would be run a 
few times with different input files. Discussing all patterns that can be used for the filename is outside the
scope of this tutorial, but you can find them all in the [sbatch manual page](https://slurm.schedmd.com/sbatch.html)
in the ["filename pattern" section](https://slurm.schedmd.com/sbatch.html#SECTION_%3CB%3Efilename-pattern%3C/B%3E).





## Requesting resources: CPUs and GPUs

<figure markdown style="border: 1px solid #000">
  ![Slide Requesting resources: CPUs and GPUs](https://465000095.lumidata.eu/intro-202310xx/img/LUMI-BE-Intro-202310XX-07-slurm/RequestingCPUsGPUs.png){ loading=lazy }
</figure>

Slurm is very flexible in the way resources can be requested. Covering every scenario and every possible
way to request CPUs and GPUs is impossible, so we will present a scheme that works for most users and jobs.

First, you have to distinguish between two strategies for requesting resources, each with their own
pros and cons. We'll call them "per-node allocations" and "per-core allocations":

1.  **"Per-node allocations":** Request suitable nodes (number of nodes and partition) with `sbatch` or `salloc`
    but postpone specifying the full structure of the job step (i.e., tasks, cpus per task, gpus per task, ...)
    until you actually start the job step with `srun`.

    This strategy relies on job-exclusive nodes, so works on the `standard` and `standard-g` partitions that 
    are "allocatable-by-node" partitions, but can
    be used on the "allocatable-by-resource" partitions also it the `--exclusive` flag is used 
    with `sbatch` or `salloc` (on the command line or
    with and `#SBATCH --exclusive` line for `sbatch`).

    This strategy gives you the ultimate flexibility in the job as you can run multiple job steps with a different 
    structure in the same job rather than having to submit multiple jobs with job dependencies to ensure that they
    are started in the proper order. E.g., you could first have an initialisation step that generates input files in
    a multi-threaded shared memory program and then run a pure MPI job with a single-threaded process per rank. 

    This strategy also gives you full control over how the application is mapped onto the available hardware:
    mapping of MPI ranks across nodes and within nodes, binding of threads to cores, and binding of GPUs to
    MPI ranks. This will be the topic of the next section of the course and is for some applications very important
    to get optimal performance on modern supercomputer nodes that have a strongly hierarchical architecture
    (which in fact is not only the case for AMD processors, but will likely be an issue on some Intel Sapphire
    Rapids processors also).

    The downside is that allocations and hence billing is always per full node, so if you need only half a node 
    you waste a lot of billing units. It shows that to exploit the full power of a supercomputer you really need
    to have problems and applications that can at least exploit a full node.

2.  **"Per-core allocations":** Specify the full job step structure when creating the job allocation and optionally
    limit the choice fo Slurm for the resource allocation by specifying a number of nodes
    that should be used. 

    The problem is that Slurm cannot create a correct allocation on an "allocatable by resource" partition if it would
    only know the total number of CPUs and total number of GPUs that you need. Slurm does not automatically allocate the
    resources on the minimal number of nodes (and even then there could be problems) and cannot know how you intend to use
    the resources to ensure that the resources are actually useful for you job. E.g., if you ask for 16 cores and Slurm would
    spread them over two or more nodes, then they would not be useful to run a shared memory program as such a program cannot 
    span nodes. Or if you really want to run an MPI application that needs 4 ranks and 4 cores per rank, then those cores
    must be assigned in groups of 4 within nodes as an MPI rank cannot span nodes. The same holds for GPUs. If you would 
    ask for 16 cores and 4 GPUs you may still be using them in different ways. Most users will probably intend to start an
    MPI program with 4 ranks that each use 4 cores and one GPU, and in that case the allocation should be done in groups 
    that each contain 4 cores and 1 GPU but can be spread over up to 4 nodes, but you may as well intend to run 
    a 16-thread shared memory application that also needs 4 GPUs. 

    The upside of this is that with this strategy you will only get what you really need when used in an
    "allocatable-by-resources" partition, so 
    if you don't need a full node, you won't be billed for a full node (assuming of course that you
    don't request that much memory that you basically need a full node's memory). 

    One downside is that you are now somewhat bound to the job structure. You can run job steps with a different structure,
    but they may produce a warning or may not run at all if the job step cannot be mapped on the resources allocated to 
    the job.

    More importantly, most options to do binding (See the next session) cannot be used or don't make sense anyway as there
    is no guarantee your cores will be allocated in a dense configuration.

    However, if you can live with those restrictions and if your job size falls within the limits of the "allocatable per 
    resource" partitions, and cannot fill up the minimal number of nodes that would be used, then this strategy ensures
    you're only billed for the minimal amount of resources that are made unavailable by your job.

This choice is something you need to think about in advance and there are no easy guidelines. Simply say "use the first 
strategy if your job fills whole nodes anyway and the second one otherwise unless you'd need more than 4 nodes" doesn't
make sense as your job may be so sensitive to its mapping to resources that it could perform very badly in the second case.
The real problem is that there is no good way in Slurm to ask for a number of L3 cache domains (CPU chiplets), a number
of NUMA domains or a number of sockets and also no easy way to always do the proper binding if you would get resources
that way (but that is something that can only be understood after the next session). If a single job needs only a half 
node and if all jobs take about the same time anyway, it might be better to bundle them by hand in jobs and do a proper
mapping of each subjob on the available resources (e.g., in case of two jobs on a CPU node, map each on a socket).


## Resources for per-node allocations

<figure markdown style="border: 1px solid #000">
  ![Slide Per-node allocations](https://465000095.lumidata.eu/intro-202310xx/img/LUMI-BE-Intro-202310XX-07-slurm/PerNode.png){ loading=lazy }
</figure>

In a per-node allocation, all you need to specify is the partition and the number of nodes needed, and in some cases,
the amount of memory. In this scenario, one should use those Slurm options that specify resources per node
also.

The partition is specified using `--partition=<partition` or `-p <partition>`.

The number of nodes is specified with `--nodes=<number_of_nodes>` or its short form 
`-N <number_of_nodes>`.

IF you want to use a per-node allocation on a partition which is allocatable-by-resources such as small
and small-g, you also need to specify the `--exclusive` flag. On LUMI this flag does not have the same
effect as running on a partition that is allocatable-by-node. The `--exclusive` flag does allocate
all cores and GPUs on the node to your job, but the memory use is still limited by other parameters in
the Slurm configuration. In fact, this can also be the case for allocatable-by-node partitions, but there 
the limit is set to allow the use of all available memory. Currently the interplay between various parameters
in the Slurm configuration results in a limit of 112 GB of memory on the `small` partition and 64 GB on the
`standard` partition when running in `--exclusive` mode. It is possible to change this with the `--mem` option.

<!-- 

!!! technical "Where do these memory limits come from?"
    Checking the limits:

    -   On `small` the amount of memory available is the result of the `DefMemPerCPU` parameter in the
        Slurm config file. (Check with `scontrol show config | grep DefMemPerCPU`).
        Multiplied with 128, the number of cores, this gives 112 GB.

        This takes precedence over the `DefMemPerNode=UNLIMITED` that you see in the settings of the
        partition (`scontrol show partition small`).

    -   On `small-g` the amount of memory is restricted by the `DefMemPerNode` parameter in the
        settings of the partition ()`scontrol show partition small-g`). The fact that a concrete value is
        given seems to overwrite the effect of `DefMemPerCPU` in the Slurm config.

    To check the amount of memory available on a node to the Slurm job, one can check the CPUset
    that Slurm creates for the job:

    ```
    cat /sys/fs/cgroup/system.slice/slurmstepd.scope/job_$SLURM_JOB_ID/memory.max
    ```

    gives the amount of memory in bytes. This was used to verify the numbers obtained above.
-->

You can request all memory on a node by using `--mem=0`. This is currently the default behaviour on nodes in
the `standard` and `standard-g` partition so not really needed there. It is needed on all of the partitions
that are allocatable-by-resource.

We've experienced that it may be a better option to actually specify the maximum amount of useable memory on
a node which is the memory capacity of the node you want minus 32 GB, so you can use
`--mem=224G` for a regular CPU node or `--mem=480G` for a GPU node. In the past we have had memory leaks on
compute nodes that were not detected by the node health checks, resulting in users getting nodes with less
available memory than expected, but specifying these amounts protected them against getting such nodes.
(And similarly you could use `--mem=480G` and `--mem=992G` for the 512 GB and 1 TB compute nodes in the small 
partition, but note that running on these nodes is expensive!)

??? Example "Example jobscript (click to expand)"
    The following job script runs a shared memory program in the batch job step, which shows that
    it has access to all hardware threads and all GPUs in a node at that moment:

    ``` bash
    #! /usr/bin/bash
    #SBATCH --job-name=slurm-perNode-minimal-small-g
    #SBATCH --partition=small-g
    #SBATCH --exclusive
    #SBATCH --nodes=1
    #SBATCH --mem=480G
    #SBATCH --time=2:00
    #SBATCH --output=%x-%j.txt
    #SBATCH --account=project_46YXXXXXX

    module load LUMI/22.12 partition/G lumi-CPEtools/1.1-cpeCray-22.12

    gpu_check

    echo -e "\nsacct for the job:\n$(sacct -j $SLURM_JOB_ID)\n"
    ```

    As we are using small-g here instead of standard-g, we added the `#SBATCH --exclusive` and `#SBATCH --mem=480G` lines.

    A similar job script for a CPU-node in LIUMI-C and now in the standard partition would look like:

    ``` bash
    #! /usr/bin/bash
    #SBATCH --job-name=slurm-perNode-minimal-standard
    #SBATCH --partition=standard
    #SBATCH --nodes=1
    #SBATCH --time=2:00
    #SBATCH --output=%x-%j.txt
    #SBATCH --account=project_46YXXXXXX

    module load LUMI/22.12 partition/C lumi-CPEtools/1.1-cpeCray-22.12

    omp_check

    echo -e "\nsacct for the job:\n$(sacct -j $SLURM_JOB_ID)\n"
    ```

    `gpu_check` and `omp_check` are two programs provided by the `lmi-CPEtools` modules to check
    the allocations. Try `man lumi-CPEtools` after loading the module. The programs will be used
    extensively in the next section on binding also, and are written to check how your program
    would behave in the allocation without burning through tons of billing units.

<figure markdown style="border: 1px solid #000">
  ![Slide Per-node allocations: CPUs](https://465000095.lumidata.eu/intro-202310xx/img/LUMI-BE-Intro-202310XX-07-slurm/PerNodeCPU.png){ loading=lazy }
</figure>

By default you will get all the CPUs in each node that is allocated in a per-node allocation.
The Slurm options to request CPUs on a per-node basis are not really useful on LUMI, but might be on clusters
with multiple node types in a single partition as they enable you to specify the minimum number of
sockets, cores and hardware threads a node should have.

**We advise against using the options to request CPUs on LUMI** 
because it is more likely to cause problems due to user
error than to solve problems. Some of these options also conflict with options that will be used
later in the course.

There is no direct way to specify the number of cores per node. Instead one has to specify the number
sockets and then the number of cores per socket and one can specify even the number of hardware threads
per core, though we will favour another mechanism later in these course notes.

The two options are:

1.  Specify `--sockets-per-node=<sockets` and `--cores-per-socket=<cores>` and maybe even `--threads-per-core=<threads>`.
    For LUMI-C the maximal specification is 

    ```
    --sockets-per-node=2 --cores-per-socket-64
    ```

    and for LUMI-G

    ```
    --sockets-per-node=1 --cores-per-socket=63
    ```

    Note that on LUMI-G, nodes have 64 cores but one core is reserved for the operating system and drivers to 
    reduce OS jitter that limits the scalability of large jobs. Requesting 64 cores will lead to error messages
    or jobs getting stuck.

2.  There is a shorthand for those parameters: `--extra-node-info=<sockets>[:cores]` or
    `-B --extra-node-info=<sockets>[:cores]` where the second and third number are optional.
    The full maximal specification for LUMI-C would be `--extra-node-info=2:64` and for LUMI-G
    `--extra-node-info=1:63`.

??? intermediate "What about `--threads-per-core`?"
    Slurm also has a `--threads-per-core` (or a third number with `--extra-node-info`)
    which is a somewhat misleading name. On LUMI, as hyperthreading
    is turned on, you would expect that you can use `--threads-per-core=2` but if you try, you will see
    that your job is not accepted. This because on LUMI, the smallest allocatable processor resource 
    (called the CPU in Slurm) is a core and not a hardware thread (or virtual core as they are also 
    called). There is another mechanism to enable or disable hyperthreading in regular job steps that we will
    discuss later.

<figure markdown style="border: 1px solid #000">
  ![Slide Per-node allocations: GPUs](https://465000095.lumidata.eu/intro-202310xx/img/LUMI-BE-Intro-202310XX-07-slurm/PerNodeGPU.png){ loading=lazy }
</figure>

By default you will get all the GPUs in each node that is allocated in a per-node allocation. The Slurm options
to request GPUs on a per-node basis are not really useful on LUMI, but might be on clusters with multiple
types of GPUs in a single partition as they enable you to specify which type of node you want.
If you insist, slurm has several options to specify the number of GPUs for this scenario:

1.  The most logical one to use for a per-node allocation is `--gpus-per-node=8` to request 8 GPUs per node.
    You can use a lower value, but this doesn't make much sense as you will be billed for the full node anyway.

    It also has an option to also specify the type of the GPU but that doesn't really make sense on LUMI. 
    On LUMI, you could in principle use `--gpus-per-node=mi250:8`.

2.  `--gpus=<number>` or `-G <number>` specifies the total number of GPUs needed for the job. In our opinion
    this is a dangerous option to use as when you change the number of nodes, you likely also want to change
    the number of GPUs for the job and you may overlook this. Here again it is possible to specify the type of
    the GPU also.

3.  A GPU belongs to the family of "generic consumable resources" (or GRES) in Slurm and there is an option to request
    any type of GRES that can also be used. Now you also need to specify the type of the GRES. The number you 
    have to specify if on a per-node basis, so on LUMI you can use  `--gres=gpu:8` or `--gres=gpu:mi250:8`.


## Per-node allocations: Starting a job step

<figure markdown style="border: 1px solid #000">
  ![Slide Per-node allocations: Starting a job step](https://465000095.lumidata.eu/intro-202310xx/img/LUMI-BE-Intro-202310XX-07-slurm/PerNodeJobStep_1.png){ loading=lazy }
</figure>

Serial or shared-memory multithreaded programs in a batch script can in principle be run in 
the batch job step. As we shall see though the effect may be different from what you expect. 
However, if you are working interactively via `salloc` you are in a shell on the node on which
you called `salloc`, typically a login node, and to run anything on the compute nodes you 
will have to start a job step.

The command to start a new job step is `srun`. But it needs a number of arguments in most
cases. After all, a job step consists of a number of equal-sized tasks (considering only
homogeneous job steps at the moment, the typical case for most users) that each need a number
of cores or hardware threads and, in case of GPU compute, access to a number of GPUs.

<figure markdown style="border: 1px solid #000">
  ![Slide Per-node allocations: Starting a job step (2)](https://465000095.lumidata.eu/intro-202310xx/img/LUMI-BE-Intro-202310XX-07-slurm/PerNodeJobStep_2.png){ loading=lazy }
</figure>

There are several ways telling Slurm how many tasks should be created and what the 
resources are for each individual task, but this scheme is an easy scheme:

1.  Specifying the number of tasks: You can specify per node or the total number:

    1.  Specifying on a per node basis: `--ntasks-per-node=<ntasks>` which is a logical
        thing to do in a per node allocation.

    2.  Specifying the total number of tasks: `--ntasks=<ntasks` or `-n ntasks`.
        There is a risk associated to this approach which is the same as when specifying the
        total number of GPUs for a job: IF you change the number of nodes, then you should
        change the total number of tasks also. However, it is also very useful in certain cases.
        Sometimes the number of tasks cannot be easily adapted and does not fit perfectly into
        your allocation (cannot be divided by the number of nodes). In that case, specifying the
        total number of nodes makes perfect sense.

2.  Specifying the number of CPUs (cores on LUMI) for each task. The easiest way to do this is by
    using `--cpus-per-task=<number_CPUs>` or `-c <number_CPUs>`.

3.  Specifying the number of GPUs per task. The easiest way here is:

    1.  Use `--gpus-per-task=>number_GPUs>` to bind one or more GPUs to each task.
        This is probably the most used option in this scheme.

    2.  If however you want multiple tasks to share a GPU, then you should use 
        `--ntasks-per-gpu=<number_of_tasks>`. There are use cases where this makes sense.

Note however that the allocation in this simple scheme is not always efficient. Slurm has various
strategies to assign tasks to nodes, and there is an option which we will discuss in the next session
of the course (binding) to change that. Moreover, not all clusters use the same default setting for this
strategy. Cores and CPUs are assigned in order and this is not always the best order.

It is particularly difficult to get a good distribution on the GPU nodes because of the single core
reserved for low noise mode, which leaves the system in a very asymmetric state: There is one L3 cache
domain with 7 available cores (the first one) and 7 with 8 available cores. Assume you want to use one
task per GPU then there is no easy way to get each task bound to its own L3 cache domain. Any
strategy trying this with 8 cores per task will fail as there are no 64 cores available, while using
7 cores per task will set the first task on the first cache domain, the second task on the second cache 
domain, but the third task will already start on the last core of the second cache domain.
There are solutions to this problem which we will discuss in the session on binding.

It is also possible to specify these options already on `#SBATCH` lines. Slurm will transform those
options into `SLURM_*` environment variables that will then be picked up by `srun`. However, this 
behaviour has changed in more recent versions of Slurm. E.g., `--cpus-per-task` is no longer 
automatically picked up by `srun` as there were side effects with some MPI implementations on some
clusters. CSC has modified the configuration to again forward that option (now via an `SRUN_*` 
environment variable) but certain use cases beyond the basic one described above are not covered.
And take into account that not all cluster operators will do that as there are also good reasons not
to do so. Otherwise the developers of Slurm wouldn't have changed that behaviour in the first place.


## Turning simultaneous multithreading on or off

<figure markdown style="border: 1px solid #000">
  ![Slide Turning hardware threading on or off](https://465000095.lumidata.eu/intro-202310xx/img/LUMI-BE-Intro-202310XX-07-slurm/PerNodeHardwareThreading.png){ loading=lazy }
</figure>

Hardware threads are enabled by default at the operating system level. In Slurm however, regular
job steps start by default with hardware threads disabled. This is not true though for the 
batch job step as the example below will show.

Hardware threading for a regular job step can be turned on explicitly with
`--hint=multhithread` and turned off explicitly with `--hint=nomultithread`, 
with the latter the default on LUMI. The hint should be given as an option to
`sbatch`(e.g., as a line `#SBATCH --hint=multithread`) and not as an option of
`srun`. 

The way it works is a bit confusing though.
We've always told, and that is also what the Slurm manual tells, that a CPU is the 
smallest allocatable unit and that on LUMI, Slurm is set to use the core as the smallest
allocatable unit. So you would expect that `srun --cpus-per-task=4` combined with `#SBATCH --hint=multithread`
would give you 4 cores with in total 8 threads, but instead you will get 2 cores with 4 hardware
threads. In other words, it looks like (at least with the settings on LUMI) `#SBATCH --hint=multithread`
changes the meaning of CPU in the context of an `srun` command to a hardware thread instead of a 
core. This is illustrated with the example below.

??? example "Use of `--hint=(no)multithread` (click to expand)"
    We consider the job script 

    ``` bash
    #! /usr/bin/bash
    #SBATCH --job-name=slurm-HWT-standard-multithread
    #SBATCH --partition=standard
    #SBATCH --nodes=1
    #SBATCH --hint=multithread
    #SBATCH --time=2:00
    #SBATCH --output=%x-%j.txt
    #SBATCH --account=project_46YXXXXXX

    module load LUMI/22.12 partition/C lumi-CPEtools/1.1-cpeGNU-22.12

    echo -e "Job script:\n$(cat $0)\n"

    set -x
    srun -n 1 -c 4 omp_check -r
    set +x
    echo -e "\nsacct for the job:\n$(sacct -j $SLURM_JOB_ID)\n"
    ```

    We consider three variants of this script:

    1.  Without the `#SBATCH --hint=multithread` line to see the default behaviour of Slurm on LUMI.
        The relevant lines of the output are:

        ```
        + srun -n 1 -c 4 omp_check -r

        Running 4 threads in a single process

        ++ omp_check: OpenMP thread   0/4   on cpu   0/256 of nid001847 mask 0-3
        ++ omp_check: OpenMP thread   1/4   on cpu   1/256 of nid001847 mask 0-3
        ++ omp_check: OpenMP thread   2/4   on cpu   2/256 of nid001847 mask 0-3
        ++ omp_check: OpenMP thread   3/4   on cpu   3/256 of nid001847 mask 0-3

        + set +x

        sacct for the job:
        JobID           JobName  Partition    Account  AllocCPUS      State ExitCode 
        ------------ ---------- ---------- ---------- ---------- ---------- -------- 
        4238727      slurm-HWT+   standard project_4+        256    RUNNING      0:0 
        4238727.bat+      batch            project_4+        256    RUNNING      0:0 
        4238727.0     omp_check            project_4+          8    RUNNING      0:0 
        ```

        The `omp_check` program detects that it should run 4 threads (we didn't even need to
        help by setting `OMP_NUM_THREADS`) and uses cores 0 till 3 which are the first 4
        physical cores on the processor.

        The output of the `sacct` command claims that the job (which is the first line of
        the table) got allocated 256 CPUs. This is a confusing feature of `sacct`: it shows 
        the number of hardware threads even though the Slurm CPU on LUMI is defined as a core.
        The next line shows the batch job step which actually does see all hardware threads of
        all cores (and in general, all hardware threads of all allocated cores of the first node
        of the job). The final line, with the '.0' job step, shows that that core was using 8
        hardware threads, even though `omp_check` only saw 4. This is because the default 
        behaviour (as the next test will confirm) is `--hint=nomultithread`.

        Note that `sacct` shows the last job step as running even though it has finished. This is
        because `sacct` gets the information not from the compute node but from a database, and it 
        looks like the full information has not yet derived in the database. A short sleep before the
        `sacct` call would cure this problem.

    2.  Now replace the `#SBATCH --hint=multithread`  with `#SBATCH --hint=nomultithread`.
        The relevant lines of the output are now

        ```
        + srun -n 1 -c 4 omp_check -r

        Running 4 threads in a single process

        ++ omp_check: OpenMP thread   0/4   on cpu   0/256 of nid001847 mask 0-3
        ++ omp_check: OpenMP thread   1/4   on cpu   1/256 of nid001847 mask 0-3
        ++ omp_check: OpenMP thread   2/4   on cpu   2/256 of nid001847 mask 0-3
        ++ omp_check: OpenMP thread   3/4   on cpu   3/256 of nid001847 mask 0-3

        + set +x

        sacct for the job:
        JobID           JobName  Partition    Account  AllocCPUS      State ExitCode 
        ------------ ---------- ---------- ---------- ---------- ---------- -------- 
        4238730      slurm-HWT+   standard project_4+        256    RUNNING      0:0 
        4238730.bat+      batch            project_4+        256    RUNNING      0:0 
        4238730.0     omp_check            project_4+          8    RUNNING      0:0 
        ```

        The output is no different from the previous case which confirms that this is the
        default behaviour.

    3.  Lastly, we run the above script unmodified, i.e., with `#SBATCH --hint=multithread` 
        Now the relevant lines of the output are:

        ```
        + srun -n 1 -c 4 omp_check -r

        Running 4 threads in a single process

        ++ omp_check: OpenMP thread   0/4   on cpu   0/256 of nid001847 mask 0-1, 128-129
        ++ omp_check: OpenMP thread   1/4   on cpu   1/256 of nid001847 mask 0-1, 128-129
        ++ omp_check: OpenMP thread   2/4   on cpu 128/256 of nid001847 mask 0-1, 128-129
        ++ omp_check: OpenMP thread   3/4   on cpu 129/256 of nid001847 mask 0-1, 128-129

        + set +x

        sacct for the job:
        JobID           JobName  Partition    Account  AllocCPUS      State ExitCode 
        ------------ ---------- ---------- ---------- ---------- ---------- -------- 
        4238728      slurm-HWT+   standard project_4+        256    RUNNING      0:0 
        4238728.bat+      batch            project_4+        256    RUNNING      0:0 
        4238728.0     omp_check            project_4+          4  COMPLETED      0:0 
        ```

        The `omp_check` program again detects only 4 threads but now runs them on the first two
        physical cores and the corresponding second hardware thread for these cores. 
        The output of `sacct` now shows 4 in the "AllocCPUS" command for the `.0` job step,
        which confirms that indeed only 2 cores with both hardware threads were allocated instead
        of 4 cores.

??? Warning "Buggy behaviour when used with `srun`"
    Consider the following job script:

    ``` bash
    #! /usr/bin/bash
    #SBATCH --job-name=slurm-HWT-standard-bug2
    #SBATCH --partition=standard
    #SBATCH --nodes=1
    #SBATCH --time=2:00
    #SBATCH --output=%x-%j.txt
    #SBATCH --hint=multithread
    #SBATCH --account=project_46YXXXXXX

    module load LUMI/22.12 partition/C lumi-CPEtools/1.1-cpeGNU-22.12

    set -x
    srun -n 1 -c 4 --hint=nomultithread omp_check -r

    srun -n 1 -c 4 --hint=multithread omp_check -r

    OMP_NUM_THREADS=8 srun -n 1 -c 4 --hint=multithread omp_check -r

    srun -n 1 -c 4 omp_check -r
    set +x
    echo -e "\nsacct for the job:\n$(sacct -j $SLURM_JOB_ID)\n"

    set -x
    srun -n 1 -c 256 --hint=multithread omp_check -r
    ```

    The relevant lines of the output are:

    ```
    + srun -n 1 -c 4 --hint=nomultithread omp_check -r

    Running 4 threads in a single process

    ++ omp_check: OpenMP thread   0/4   on cpu   0/256 of nid001246 mask 0-3
    ++ omp_check: OpenMP thread   1/4   on cpu   1/256 of nid001246 mask 0-3
    ++ omp_check: OpenMP thread   2/4   on cpu   2/256 of nid001246 mask 0-3
    ++ omp_check: OpenMP thread   3/4   on cpu   3/256 of nid001246 mask 0-3

    + srun -n 1 -c 4 --hint=multithread omp_check -r

    Running 4 threads in a single process

    ++ omp_check: OpenMP thread   0/4   on cpu   0/256 of nid001246 mask 0-1, 128-129
    ++ omp_check: OpenMP thread   1/4   on cpu 129/256 of nid001246 mask 0-1, 128-129
    ++ omp_check: OpenMP thread   2/4   on cpu 128/256 of nid001246 mask 0-1, 128-129
    ++ omp_check: OpenMP thread   3/4   on cpu   1/256 of nid001246 mask 0-1, 128-129

    + OMP_NUM_THREADS=8
    + srun -n 1 -c 4 --hint=multithread omp_check -r

    Running 8 threads in a single process

    ++ omp_check: OpenMP thread   0/8   on cpu   0/256 of nid001246 mask 0-1, 128-129
    ++ omp_check: OpenMP thread   1/8   on cpu 128/256 of nid001246 mask 0-1, 128-129
    ++ omp_check: OpenMP thread   2/8   on cpu   0/256 of nid001246 mask 0-1, 128-129
    ++ omp_check: OpenMP thread   3/8   on cpu   1/256 of nid001246 mask 0-1, 128-129
    ++ omp_check: OpenMP thread   4/8   on cpu 129/256 of nid001246 mask 0-1, 128-129
    ++ omp_check: OpenMP thread   5/8   on cpu 128/256 of nid001246 mask 0-1, 128-129
    ++ omp_check: OpenMP thread   6/8   on cpu 129/256 of nid001246 mask 0-1, 128-129
    ++ omp_check: OpenMP thread   7/8   on cpu   1/256 of nid001246 mask 0-1, 128-129

    + srun -n 1 -c 4 omp_check -r

    Running 4 threads in a single process

    ++ omp_check: OpenMP thread   0/4   on cpu   0/256 of nid001246 mask 0-3
    ++ omp_check: OpenMP thread   1/4   on cpu   1/256 of nid001246 mask 0-3
    ++ omp_check: OpenMP thread   2/4   on cpu   2/256 of nid001246 mask 0-3
    ++ omp_check: OpenMP thread   3/4   on cpu   3/256 of nid001246 mask 0-3

    + set +x

    sacct for the job:
    JobID           JobName  Partition    Account  AllocCPUS      State ExitCode 
    ------------ ---------- ---------- ---------- ---------- ---------- -------- 
    4238801      slurm-HWT+   standard project_4+        256    RUNNING      0:0 
    4238801.bat+      batch            project_4+        256    RUNNING      0:0 
    4238801.0     omp_check            project_4+          8  COMPLETED      0:0 
    4238801.1     omp_check            project_4+          8  COMPLETED      0:0 
    4238801.2     omp_check            project_4+          8  COMPLETED      0:0 
    4238801.3     omp_check            project_4+          8  COMPLETED      0:0 

    + srun -n 1 -c 256 --hint=multithread omp_check -r
    srun: error: Unable to create step for job 4238919: More processors requested than permitted
    ```

    The first `omp_check` runs as expected. The seocnd one uses only 2 cores but all
    4 hyperthreads on those cores. This is also not unexpected. In the third case
    we force the use of 8 threads, and they all land on the 4 hardware threads of
    2 cores. Again, this is not unexpected. And neither is the output of the last 
    run of `omp_cehck` which is again with multithreading disabled as requested in
    the `#SBATCH` lines. What is surprising though is the output of `sacct`: 
    It claims there were 8 hardware threads, so 4 cores, allocated to the second 
    (the `.1`) and third (the `.2`) job step while whatever we tried, `omp_check`
    could only see 2 cores and 4 hardware threads. Indeed, if we would try to run
    with `-c 256` then `srun` will fail.

    But now try the reverse: we turn multithreading on in the `#SBATCH` lines
    and try to turn it off again with `srun`:

    ``` bash
    #! /usr/bin/bash
    #SBATCH --job-name=slurm-HWT-standard-bug2
    #SBATCH --partition=standard
    #SBATCH --nodes=1
    #SBATCH --time=2:00
    #SBATCH --output=%x-%j.txt
    #SBATCH --hint=multithread
    #SBATCH --account=project_46YXXXXXX

    module load LUMI/22.12 partition/C lumi-CPEtools/1.1-cpeGNU-22.12

    set -x
    srun -n 1 -c 4 --hint=nomultithread omp_check -r

    srun -n 1 -c 4 --hint=multithread omp_check -r

    srun -n 1 -c 4 omp_check -r
    set +x
    echo -e "\nsacct for the job:\n$(sacct -j $SLURM_JOB_ID)\n"
    ```

    The relevant part of the output is now

    ```
    + srun -n 1 -c 4 --hint=nomultithread omp_check -r

    Running 4 threads in a single process

    ++ omp_check: OpenMP thread   0/4   on cpu   1/256 of nid001460 mask 0-3
    ++ omp_check: OpenMP thread   1/4   on cpu   2/256 of nid001460 mask 0-3
    ++ omp_check: OpenMP thread   2/4   on cpu   3/256 of nid001460 mask 0-3
    ++ omp_check: OpenMP thread   3/4   on cpu   0/256 of nid001460 mask 0-3

    + srun -n 1 -c 4 --hint=multithread omp_check -r

    Running 4 threads in a single process

    ++ omp_check: OpenMP thread   0/4   on cpu   0/256 of nid001460 mask 0-1, 128-129
    ++ omp_check: OpenMP thread   1/4   on cpu 129/256 of nid001460 mask 0-1, 128-129
    ++ omp_check: OpenMP thread   2/4   on cpu 128/256 of nid001460 mask 0-1, 128-129
    ++ omp_check: OpenMP thread   3/4   on cpu   1/256 of nid001460 mask 0-1, 128-129

    ++ srun -n 1 -c 4 omp_check -r

    Running 4 threads in a single process

    ++ omp_check: OpenMP thread   0/4   on cpu   0/256 of nid001460 mask 0-1, 128-129
    ++ omp_check: OpenMP thread   1/4   on cpu 129/256 of nid001460 mask 0-1, 128-129
    ++ omp_check: OpenMP thread   2/4   on cpu 128/256 of nid001460 mask 0-1, 128-129
    ++ omp_check: OpenMP thread   3/4   on cpu   1/256 of nid001460 mask 0-1, 128-129

    + set +x

    sacct for the job:
    JobID           JobName  Partition    Account  AllocCPUS      State ExitCode 
    ------------ ---------- ---------- ---------- ---------- ---------- -------- 
    4238802      slurm-HWT+   standard project_4+        256    RUNNING      0:0 
    4238802.bat+      batch            project_4+        256    RUNNING      0:0 
    4238802.0     omp_check            project_4+          8  COMPLETED      0:0 
    4238802.1     omp_check            project_4+          4  COMPLETED      0:0 
    4238802.2     omp_check            project_4+          4  COMPLETED      0:0 
    ```

    And this is fully as expected. The first `srun` does not use hardware threads
    as requested by `srun`, the second run does use hardware threads and only 2 cores
    which is also what we requested with the `srun` command, and the last one also uses
    hardware threads. The output of `sacct` (and in particular the `AllocCPUS` comumn)
    not fully confirms that indeed there were only 2 cores allocated to the second and
    third run.

    So turning hardware threads on in the `#SBATCH` lines and then off again with `srun`
    works as expected, but the opposite, explicitly turning it off in the `#SBATCH` lines
    (or relying on the default which is off) and then trying to turn it on again, does not
    work.


## Per-core allocations

### When to use?

<figure markdown style="border: 1px solid #000">
  ![Slide Per core allocations: When to use?](https://465000095.lumidata.eu/intro-202310xx/img/LUMI-BE-Intro-202310XX-07-slurm/PerCoreWhenUse.png){ loading=lazy }
</figure>

Not all jobs can use entire nodes efficiently, and therefore the LUMI setup does provide some
partitions that enable users to define jobs that use only a part of a node. This scheme enables
the user to only request the resources that are really needed for the job (and only get billed for
those at least if they are proportional to the resources that a node provides), but also comes
with the disadvantage that it is not possible to control how cores and GPUs are allocated
within a node. Codes that depend on proper mapping of threads and processes on L3 cache domains,
NUMA domains or sockets, or on shortest paths between cores in a task and the associated GPU(s) 
may see an unpredictable performance lossas (a) the mapping will rarely be optimal unless you are
very lucky (and always be suboptimal for GPUs in the current LUMI setup) and (b) will also depend
on other jobs already running on the set of nodes assigned to your job.

Unfortunately, 

1.  Slurm does not seem to fully understand the GPU topology on LUMI and cannot take that properly into
    account when assigning resources to a job or task in a job, and

2.   Slurm does not support the hierarchy in the compute nodes of LUMI. There is no way to specifically
     request all cores in a socket, NUMA domain or L3 cache domain. It is only possible on a per-node level
     which is the case that we already discussed.

Instead, you have to specify the task structure in the `#SBATCH` lines of a job script or as the command line
arguments of `sbatch` and `salloc` that you will need to run the job.


### Resource request

<figure markdown style="border: 1px solid #000">
  ![Slide Per core allocations: Resource request (1)](https://465000095.lumidata.eu/intro-202310xx/img/LUMI-BE-Intro-202310XX-07-slurm/PerCoreResources_1.png){ loading=lazy }
</figure>

<figure markdown style="border: 1px solid #000">
  ![Slide Per core allocations: Resource request (2)](https://465000095.lumidata.eu/intro-202310xx/img/LUMI-BE-Intro-202310XX-07-slurm/PerCoreResources_2.png){ loading=lazy }
</figure>

To request an allocation, you have to specify the task structure of the job step you want to run using
mostly the same options that we have discussed on the slides "Per-node allocations: Starting a job step": 

1.  Now you should specify just the total amount of tasks needed using
    `--ntasks=<number>` or `-n <number>`. As the number of nodes is not fixed
    in this allocation type, `--ntasks-per-node=<ntasks>` does not make much sense.

    It is possible to request a number of nodes using `--nodes`, and it can even take
    two arguments: `--nodes=<min>-<max>` to specify the minimum and maximum number of
    nodes that Slurm should use rather than the exact number (and there are even more options), 
    but really the only case where
    it makes sense to use `--nodes` with `--ntasks-per-node` in this case, is if all tasks
    would fit on a single node and you also want to force them on a single node so that all
    MPI communications are done through shared memory rather than via the Slingshot interconnect.

    Restricting the choice of resources for the scheduler may increase your waiting time
    in the queue though.

2.  Specifying the number of CPUs (cores on LUMI) for each task. The easiest way to do this is by
    using `--cpus-per-task=<number>` or `-c <number`.

    Note that as has been discussed before, the standard behaviour of recent versions of Slurm is to
    no longer forward `--cpus-per-task` from the `sbatch` or `salloc` level to the `srun` level
    though CSC has made a configuration change in Slurm that will still try to do this though with
    some limitations.

3.  Specifying the number of GPUs per task. The easiest way here is:

    1.  Use `--gpus-per-task=>number_GPUs>` to bind one or more GPUs to each task.
        This is probably the most used option in this scheme.

    2.  If however you want multiple tasks to share a GPU, then you should use 
        `--ntasks-per-gpu=<number_of_tasks>`. There are use cases where this makes sense.

4.  CPU memory. By default you get less than the memory per core on the node type. To change:

    1.  Against the logic there is **no** `--mem-per-task=<number>`, instead memory needs to be specified in
        function of the other allocated resources.

    2.  Use `--mem-per-cpu=<number>` to request memory per CPU (use k, m, g to specify kilobytes, megabytes or gigabytes)

    3.  Alternatively on a GPU allocation `--mem-per-gpu=<number>`.
        **This is still CPU memory and not GPU memory!**

    4.  Specifying memory per node with `--mem` doesn't make much sense unless the number of nodes is fixed.

<figure markdown style="border: 1px solid #000">
  ![Slide Per core allocations: Warning: Allocations per socket?](https://465000095.lumidata.eu/intro-202310xx/img/LUMI-BE-Intro-202310XX-07-slurm/PerCoreWarningSocket.png){ loading=lazy }
</figure>

!!! Warning "`--sockets-per-node` and `--ntasks-per-socket`"
    If you don't read the manual pages of Slurm carefully enough you may have the impression that
    you can use parameters like `--sockets-per-node` and `--ntasks-per-socket` to force all tasks
    on a single socket (and get a single socket), but these options will not work as you expect.

    The `--sockets-per-node` option is not used to request an exact resource, but to specify a 
    type of node by specifying the *minimal* number of sockets a node should have.It is an irrelevant
    option on LUMI as each partition does have only a single node type.

    If you read the manual carefully, you will also see that there is a subtle difference between
    `--ntasks-per-node` and `--ntasks-per-socket`: With `--ntasks-per-node` you specify the
    *exact* number of tasks for each node while with `--tasks-per-socket` you specify the 
    *maximum* number of tasks for each socket. So all hope that something like

    ```
    --ntasks=8 --ntasks-per-socket=8 --cpus-per-task=8
    ```

    would always ensure that you get a socket for yourself with each task nicely assigned to
    a single L3 cache domain, is futile.


### Different job steps in a single job

<figure markdown style="border: 1px solid #000">
  ![Slide Per core allocations: Different job steps (1)](https://465000095.lumidata.eu/intro-202310xx/img/LUMI-BE-Intro-202310XX-07-slurm/PerCoreJobstep_1.png){ loading=lazy }
</figure>

<figure markdown style="border: 1px solid #000">
  ![Slide Per core allocations: Different job steps (2)](https://465000095.lumidata.eu/intro-202310xx/img/LUMI-BE-Intro-202310XX-07-slurm/PerCoreJobstep_2.png){ loading=lazy }
</figure>

It is possible to have an `srun` command with a different task structure in your job script.
This will work if no task requires more CPUs or GPUs than in the original request, and if there are
either not more tasks either or if an entire number of tasks in the new structure fits in a task
in the structure from the allocation and the total number of tasks does not exceed the original number
multiplied with that entire number. Other cases may work randomly, depending on how Slurm did the
actual allocation. In fact, this may even be abused to ensure that all tasks are allocated to a single
node, though this is done more elegantly by just specifying `--nodes=1`.

??? Example "Some examples that work and don't work (click to expand)"
    Consider the job script:

    ``` bash
    #! /usr/bin/bash
    #SBATCH --job-name=slurm-small-multiple-srun
    #SBATCH --partition=small
    #SBATCH --ntasks=4
    #SBATCH --cpus-per-task=4
    #SBATCH --hint=nomultithread
    #SBATCH --time=5:00
    #SBATCH --output %x-%j.txt
    #SBATCH --acount=project_46YXXXXXX

    module load LUMI/22.12 partition/C lumi-CPEtools/1.1-cpeCray-22.12

    echo "Running on $SLURM_JOB_NODELIST"

    set -x

    omp_check

    srun --ntasks=1 --cpus-per-task=3 omp_check

    srun --ntasks=2 --cpus-per-task=4 hybrid_check

    srun --ntasks=4 --cpus-per-task=1 mpi_check

    srun --ntasks=16 --cpus-per-task=1 mpi_check

    srun --ntasks=1 --cpus-per-task=16 omp_check

    set +x
    echo -e "\nsacct for the job:\n$(sacct -j $SLURM_JOB_ID)\n"
    ```

    In the first output example (with lots of output deleted) we got the full
    allocation of 16 cores on a single node, and in fact, even 16 consecutive cores
    though spread across 3 L3 cache domains. We'll go over the output in steps:

    ```
    Running on nid002154

    + omp_check

    Running 32 threads in a single process

    ++ omp_check: OpenMP thread   0/32  on cpu  20/256 of nid002154
    ++ omp_check: OpenMP thread   1/32  on cpu 148/256 of nid002154
    ...
    ```

    The first `omp_check` command was started without using `srun` and hence ran on all
    hardware cores allocated to the job. This is why hardware threading is enabled and why
    the executable sees 32 cores.

    ```
    + srun --ntasks=1 --cpus-per-task=3 omp_check

    Running 3 threads in a single process

    ++ omp_check: OpenMP thread   0/3   on cpu  20/256 of nid002154
    ++ omp_check: OpenMP thread   1/3   on cpu  21/256 of nid002154
    ++ omp_check: OpenMP thread   2/3   on cpu  22/256 of nid002154
    ```

    Next `omp_check` was started via `srun --ntasks=1 --cpus-per-task=3 `. One task instead of 4,
    and the task is also smaller in terms of number of nodes as the tasks requested in `SBATCH`
    lines, and Slurm starts the executable without problems. It runs on three cores, correctly
    detects that number, and also correctly does not use hardware threading.

    ```
    + srun --ntasks=2 --cpus-per-task=4 hybrid_check

    Running 2 MPI ranks with 4 threads each (total number of threads: 8).

    ++ hybrid_check: MPI rank   0/2   OpenMP thread   0/4   on cpu  23/256 of nid002154
    ++ hybrid_check: MPI rank   0/2   OpenMP thread   1/4   on cpu  24/256 of nid002154
    ++ hybrid_check: MPI rank   0/2   OpenMP thread   2/4   on cpu  25/256 of nid002154
    ++ hybrid_check: MPI rank   0/2   OpenMP thread   3/4   on cpu  26/256 of nid002154
    ++ hybrid_check: MPI rank   1/2   OpenMP thread   0/4   on cpu  27/256 of nid002154
    ++ hybrid_check: MPI rank   1/2   OpenMP thread   1/4   on cpu  28/256 of nid002154
    ++ hybrid_check: MPI rank   1/2   OpenMP thread   2/4   on cpu  29/256 of nid002154
    ++ hybrid_check: MPI rank   1/2   OpenMP thread   3/4   on cpu  30/256 of nid002154
    ```

    Next we tried to start 2 instead of 4 MPI processes with 4 cores each which also works without
    problems. The allocation now starts on core 23 but that is because Slurm was still finishing
    the job step on cores 20 till 22 from the previous `srun` command. This may or may not happen
    and is also related to a remark we made before about using `sacct` at the end of the job where
    the last job step may still be shown as running instead of completed.

    ```
    + srun --ntasks=4 --cpus-per-task=1 mpi_check

    Running 4 single-threaded MPI ranks.

    ++ mpi_check: MPI rank   0/4   on cpu  20/256 of nid002154
    ++ mpi_check: MPI rank   1/4   on cpu  21/256 of nid002154
    ++ mpi_check: MPI rank   2/4   on cpu  22/256 of nid002154
    ++ mpi_check: MPI rank   3/4   on cpu  23/256 of nid002154
    ```

    Now we tried to start 4 tasks with 1 core each. This time we were lucky and the system 
    considered the previous `srun` completely finished and gave us the first 4 cores of the 
    allocation.

    ```
    + srun --ntasks=16 --cpus-per-task=1 mpi_check
    srun: Job 4268529 step creation temporarily disabled, retrying (Requested nodes are busy)
    srun: Step created for job 4268529

    Running 16 single-threaded MPI ranks.

    ++ mpi_check: MPI rank   0/16  on cpu  20/256 of nid002154
    ++ mpi_check: MPI rank   1/16  on cpu  21/256 of nid002154
    ++ mpi_check: MPI rank   2/16  on cpu  22/256 of nid002154
    ++ mpi_check: MPI rank   3/16  on cpu  23/256 of nid002154
    ++ mpi_check: MPI rank   4/16  on cpu  24/256 of nid002154
    ++ mpi_check: MPI rank   5/16  on cpu  25/256 of nid002154
    ...
    ```

    With the above `srun` command we try to start 16 single-threaded MPI processes. This fits 
    perfectly in the allocation as it simply needs to put 4 of these tasks in the space reserved 
    for one task in the `#SBATCH` request. The warning at the start may or may not happen. Basically
    Slurm was still freeing up the cores from the previous run and therefore the new `srun` dind't 
    have enough resources the first time it tried to, but it automatically tried a second time.

    ```
    + srun --ntasks=1 --cpus-per-task=16 omp_check
    srun: Job step's --cpus-per-task value exceeds that of job (16 > 4). Job step may never run.
    srun: Job 4268529 step creation temporarily disabled, retrying (Requested nodes are busy)
    srun: Step created for job 4268529

    Running 16 threads in a single process

    ++ omp_check: OpenMP thread   0/16  on cpu  20/256 of nid002154
    ++ omp_check: OpenMP thread   1/16  on cpu  21/256 of nid002154
    ++ omp_check: OpenMP thread   2/16  on cpu  22/256 of nid002154
    ...
    ```

    In the final `srun` command we try to run a single 16-core OpenMP run. This time Slurm produces
    a warning as it would be impossible to fit a 16-cpre shared memory run in the space of 4 4-core 
    tasks if the resources for those tasks would have been spread across multiple nodes. The next
    warning is again for the same reason as in the previous case, but ultimately the command does run
    on all 16 cores allocated and without using hardware threading.

    ```
    + set +x

    sacct for the job:
    JobID           JobName  Partition    Account  AllocCPUS      State ExitCode 
    ------------ ---------- ---------- ---------- ---------- ---------- -------- 
    4268529      slurm-sma+      small project_4+         32    RUNNING      0:0 
    4268529.bat+      batch            project_4+         32    RUNNING      0:0 
    4268529.0     omp_check            project_4+          6  COMPLETED      0:0 
    4268529.1    hybrid_ch+            project_4+         16  COMPLETED      0:0 
    4268529.2     mpi_check            project_4+          8  COMPLETED      0:0 
    4268529.3     mpi_check            project_4+         32  COMPLETED      0:0 
    4268529.4     omp_check            project_4+         32    RUNNING      0:0 
    ```

    The output of `sacct` confirms what we have been seeing. The first `omp_check`
    was run without srun and ran in the original batch step which had all hardware threads
    of all 16 allocated cores available. The next `omp_check` ran on 3 cores but 6 is
    shwon in this scheme which is normal as the "other" hardware thread on each core is
    implicitly also reserved. And the same holds for all other numbers in that column.

    At another time I was less lucky and got the tasks spread out across 4 nodes, each 
    running a single 4-core task. Let's go through the output again:

    ```
    Running on nid[002154,002195,002206,002476]

    + omp_check

    Running 8 threads in a single process

    ++ omp_check: OpenMP thread   0/8   on cpu  36/256 of nid002154
    ++ omp_check: OpenMP thread   1/8   on cpu 164/256 of nid002154
    ++ omp_check: OpenMP thread   2/8   on cpu  37/256 of nid002154
    ++ omp_check: OpenMP thread   3/8   on cpu 165/256 of nid002154
    ++ omp_check: OpenMP thread   4/8   on cpu  38/256 of nid002154
    ++ omp_check: OpenMP thread   5/8   on cpu 166/256 of nid002154
    ++ omp_check: OpenMP thread   6/8   on cpu  39/256 of nid002154
    ++ omp_check: OpenMP thread   7/8   on cpu 167/256 of nid002154
    ```

    The first `omp_check` now uses all hardware threads of the 4 cores allocated
    in the first node of the job (while using 16 cores/32 threads in the configuration
    where all cores were allocated on a single node).

    ```
    + srun --ntasks=1 --cpus-per-task=3 omp_check

    Running 3 threads in a single process

    ++ omp_check: OpenMP thread   0/3   on cpu  36/256 of nid002154
    ++ omp_check: OpenMP thread   1/3   on cpu  37/256 of nid002154
    ++ omp_check: OpenMP thread   2/3   on cpu  38/256 of nid002154
    ```

    Running a three core OpenMP job goes without problems as it nicely fits within the
    space of a single task of the `#SBATCH` allocation.

    ```
    + srun --ntasks=2 --cpus-per-task=4 hybrid_check

    Running 2 MPI ranks with 4 threads each (total number of threads: 8).

    ++ hybrid_check: MPI rank   0/2   OpenMP thread   0/4   on cpu  36/256 of nid002195
    ++ hybrid_check: MPI rank   0/2   OpenMP thread   1/4   on cpu  37/256 of nid002195
    ++ hybrid_check: MPI rank   0/2   OpenMP thread   2/4   on cpu  38/256 of nid002195
    ++ hybrid_check: MPI rank   0/2   OpenMP thread   3/4   on cpu  39/256 of nid002195
    ++ hybrid_check: MPI rank   1/2   OpenMP thread   0/4   on cpu  46/256 of nid002206
    ++ hybrid_check: MPI rank   1/2   OpenMP thread   1/4   on cpu  47/256 of nid002206
    ++ hybrid_check: MPI rank   1/2   OpenMP thread   2/4   on cpu  48/256 of nid002206
    ++ hybrid_check: MPI rank   1/2   OpenMP thread   3/4   on cpu  49/256 of nid002206
    ```

    Running 2 4-thread MPI processes also goes without problems. In this case we got the second and third
    task from the original allocation, likely because Slurm was still freeing up the first node
    after the previous `srun` command.

    ```
    + srun --ntasks=4 --cpus-per-task=1 mpi_check
    srun: Job 4268614 step creation temporarily disabled, retrying (Requested nodes are busy)
    srun: Step created for job 4268614

    Running 4 single-threaded MPI ranks.

    ++ mpi_check: MPI rank   0/4   on cpu  36/256 of nid002154
    ++ mpi_check: MPI rank   1/4   on cpu  36/256 of nid002195
    ++ mpi_check: MPI rank   2/4   on cpu  46/256 of nid002206
    ++ mpi_check: MPI rank   3/4   on cpu   0/256 of nid002476
    ```

    Running 4 single threaded processes also goes without problems (but the fact that they are
    scheduled on 4 different nodes here is likely an artifact of the way we had to force to get
    more than one node as the small partition on LUMI was not very busy at that time).

    ```
    + srun --ntasks=16 --cpus-per-task=1 mpi_check

    Running 16 single-threaded MPI ranks.

    ++ mpi_check: MPI rank   0/16  on cpu  36/256 of nid002154
    ++ mpi_check: MPI rank   1/16  on cpu  37/256 of nid002154
    ++ mpi_check: MPI rank   2/16  on cpu  38/256 of nid002154
    ++ mpi_check: MPI rank   3/16  on cpu  39/256 of nid002154
    ++ mpi_check: MPI rank   4/16  on cpu  36/256 of nid002195
    ++ mpi_check: MPI rank   5/16  on cpu  37/256 of nid002195
    ++ mpi_check: MPI rank   6/16  on cpu  38/256 of nid002195
    ++ mpi_check: MPI rank   7/16  on cpu  39/256 of nid002195
    ++ mpi_check: MPI rank   8/16  on cpu  46/256 of nid002206
    ++ mpi_check: MPI rank   9/16  on cpu  47/256 of nid002206
    ++ mpi_check: MPI rank  10/16  on cpu  48/256 of nid002206
    ++ mpi_check: MPI rank  11/16  on cpu  49/256 of nid002206
    ++ mpi_check: MPI rank  12/16  on cpu   0/256 of nid002476
    ++ mpi_check: MPI rank  13/16  on cpu   1/256 of nid002476
    ++ mpi_check: MPI rank  14/16  on cpu   2/256 of nid002476
    ++ mpi_check: MPI rank  15/16  on cpu   3/256 of nid002476
    ```

    16 single threaded MPI processes also works without problems.

    ```
    + srun --ntasks=1 --cpus-per-task=16 omp_check
    srun: Job step's --cpus-per-task value exceeds that of job (16 > 4). Job step may never run.
    srun: Warning: can't run 1 processes on 4 nodes, setting nnodes to 1
    srun: error: Unable to create step for job 4268614: More processors requested than permitted
    ...
    ```

    However, trying to run a single 16-thread process now fails. Slurm first warns us that it might fail,
    then tries and lets it fail.



## Local trainings and materials

-   Docs VSC: Slurm material for the general docs is still under development and will be published
    later in 2023.

    -   [Slurm in the UAntwerp-specific documentation](https://docs.vscentrum.be/en/latest/antwerp/uantwerp_software_specifics.html#slurm-workload-manager)

    -   [Slurm in the VUB-specific documentation](https://hpc.vub.be/docs/job-submission/)

-   Docs CÉCI: Extensive [documentation on the use of Slurm](https://support.ceci-hpc.be/doc/#submitting-jobs-to-the-cluster)

-   VSC training materials

    -   [Slurm Lunchbox training KU Leuven](https://github.com/hpcleuven/Slurm-lunchbox)

    -   [VSC@KULeuven HPC-intro training](https://hpcleuven.github.io/HPC-intro/)
        covers Slurm in the "Starting to Compute" section.

    -   [VSC@UAntwerpen covers Slurm in the "HPC@UAntwerp introduction" training](https://www.uantwerpen.be/en/research-facilities/calcua/training/)

-   CÉCI training materials: Slurm is covered in the "Learning how to use HPC infrastructure" training.

    -   [2022 session: Lecture "Preparing, submitting and managing jobs with Slurm"](https://indico.cism.ucl.ac.be/event/121/contributions/60/)

