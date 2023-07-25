# Slurm on LUMI

!!! Remark "Who is this for?"
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

!!! remark "Nice to know..."
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
  ![Slide Slurm concepts 2](https://465000095.lumidata.eu/intro-202310xx/img/LUMI-BE-Intro-202310XX-07-slurm/BatchScheduler.png){ loading=lazy }
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


## Partitions

<figure markdown style="border: 1px solid #000">
  ![Slide Partitions 1](https://465000095.lumidata.eu/intro-202310xx/img/LUMI-BE-Intro-202310XX-07-slurm/Partitions_1.png){ loading=lazy }
</figure>

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

    Note that this overview may show partitions that are not hidden but also not accessible to everyone. E.g., 
    the `q_nordic` and `q_fiqci` partitions are used to access experimental quantum computers that are only
    available to some users of those countries that paid for those machines, which does not include Belgium.

    The `eap` partition will likely be phased out over time and is a remainder of a platform used for early 
    development before LUMI-G was attached to the machine. At the moment it allows users to experiment freely 
    with the GPU nodes.

    It is not clear to the LUMI Support Team what the `interactive` partition, that uses dome GPU nodes, is 
    meant for as it was introduced without informting the support. The resources in that partition are very
    limited so it is not meant for widespread use.

-   For technically-oriented people, some more details about a partion can be obtained with
    `scontrol show partition <partition-name>`.


## Fairness of queueing

<figure markdown style="border: 1px solid #000">
  ![Slide Fairness of queueing](https://465000095.lumidata.eu/intro-202310xx/img/LUMI-BE-Intro-202310XX-07-slurm/Fairness.png){ loading=lazy }
</figure>

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

