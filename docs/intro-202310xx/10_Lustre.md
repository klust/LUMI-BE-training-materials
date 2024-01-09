# I/O and file systems on LUMI

Notes are still incomplete.

## File systems on LUMI

<figure markdown style="border: 1px solid #000">
  ![File systems on LUMI](https://465000095.lumidata.eu/training-materials-web/intro-202310xx/img/LUMI-BE-Intro-202310XX-10-lustre/FileSystemLumi.png){ loading=lazy }
</figure>

Supercomputing since the second half of the 1980s has almost always been about 
trying to build a very fast system from relatively cheap volume components
or technologies (as low as you
can go without loosing too much reliability) and very cleverly written software
both at the system level (to make the system look like a true single system as
much as possible) and at the application level (to deal with the restrictions that
inevitably come with such a setup).

The Lustre parallel file system that we use on LUMI (and is its main file system serving
user files) fits in that way of thinking.
A large file system is built by linking many fairly regular file servers
through a fast network to the compute resources to build a single system
with a lot of storage capacity and a lot of bandwidth.
It has its restrictions also though: IOPs (number of I/O operations per second)
doesn't scale as well or as easily as bandwidth and capacity so this comes with
usage restrictions on large clusters that may a lot more severe than you are used
to from small systems. And yes, it is completely normal that some file operations are
slower than on the SSD of a good PC.

HPE Cray EX systems go even one step further. 
Lustre is the only network file system directly served to the compute nodes.
Other network file system come via a piece of software called Data
Virtualisation Service (abbreviated DVS) that basically forward I/O requests
to servers in the management section of the cluster where the actual file
system runs. 
This is part of the measures that Cray takes in Cray Operating System to
minimise OS jitter on the compute nodes to improve scalability of applications.


## Lustre building blocks

<figure markdown style="border: 1px solid #000">
  ![Lustre building blocks](https://465000095.lumidata.eu/training-materials-web/intro-202310xx/img/LUMI-BE-Intro-202310XX-10-lustre/LustreBuildingBlocks1.png){ loading=lazy }
</figure>

<figure markdown style="border: 1px solid #000">
  ![Lustre building blocks (2)](https://465000095.lumidata.eu/training-materials-web/intro-202310xx/img/LUMI-BE-Intro-202310XX-10-lustre/LustreBuildingBlocks2.png){ loading=lazy }
</figure>

A key element of Lustre - but also of other parallel file systems for large parallel
computers such as BeeGFS, Spectrum Scale (formerly GPFS) or PanFS - is the separation of
metadata and the actual file data, as the way both are accessed and used is very different.

A Lustre system consists of the following blocks:

1.  Metadata servers (MDSes) with one or more metadata targets (MDTs) each store
    namespace metadata such as filenames, directories and access permissions, and the
    file layout.

    Each MDT is a filesystem, usually with some level of RAID or similar technologies
    for increased reliability. Usually there is also more than one MDS and they are put
    in a high availability setup for increased availability (and this is the case in 
    LUMI).

    Metadata is accessed in small bits and it does not need much capacity. However, 
    metadata accesses are hard to parallelise so it makes sense to go for the fastest
    storage possible even if that storage is very expensive per terabyte. On LUMI all
    metadata servers use SSDs.

2.  Object storage servers (OSSes) with one or more object storage targets (OSTs) each
    store the actual data. Data from a single file can be distributed across multiple
    OSTs and even multiple OSSes. As we shall see, this is also the key to getting very
    high bandwidth access to the data.

    Each MDT is a filesystem, again usually with some level of RAID or similar technologies
    to survive disk failures. One OSS typically has between 1 and 8 OSTs, and in a big setup
    a high availability setup will be used again (as is the case in LUMI).

    The total capacity of a Lustre file system is the sum of the capacity of all OSTs in the 
    Lustre file system. Lustre file systems are often many petabytes large.

    Now you may think different from prices that you see in the PC market for hard drives
    and SSDs, but SSDs of data centre quality are still up to 10 times as expensive as 
    hard drives of data centre quality. Building a file system of several tens of petabytes
    out of SSDs is still extremely expensive and rarely done, certainly in an environment 
    with a high write pressure on the file system as that requires the highest quality SSDs.
    Hence it is not uncommon that supercomputers will use mostly hard drives for their large
    storage systems.

    On LUMI there is roughly 80 PB spread across 4 large hard disk based Lustre file systems, and
    8.5 PB in an SSD-based Lustre file system. However, all MDSes use SSD storage.

3.  Lustre clients access and use the data. They make the whole Lustre file system look like
    a single file system.

    Now Lustre is transparent in functionality. You can use a Lustre file system just as any 
    other regular file system, with all your regular applications. However, it is not at really
    transparent when it comes to performance: How you use Lustre can have a huge impact on 
    performance. Lustre is optimised very much for high bandwidth access to large chunks of
    data at a time from multiple nodes in the application simultaneously, and is not very good 
    at handling access to a large pool of small files instead. 

    So you have to store your data (but also your applications as the are a kind of data also)
    in an appropriate way, in fewer but larger files instead of more smaller files. 
    Some centres with large supercomputers will advise you to containerise software for optimal
    performance. On LUMI we do advise Python users or users who install software through Conda
    to do so. 

4.  All these components are linked together through a high performance interconnect. On HPE Cray EX
    systems - but on more an more other systems also - there is no separate network anymore for 
    storage access and the same high performance interconnect that is also used for internode
    communication by applications (through, e.g., MPI) is used for that purpose.

