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

5.  There is also a management server which is not mentioned on the slides, but that component
    is not essential to understand the behaviour of Lustre for the purpose of this lecture.

!!! Note "Links"

    See also the ["Lustre Components" in "Understanding Lustre Internals" on the Lustre Wiki](https://wiki.lustre.org/Understanding_Lustre_Internals#Lustre_Components)


## Striping: Large files are spread across OSTs

<figure markdown style="border: 1px solid #000">
  ![Large files are spread across OSTs](https://465000095.lumidata.eu/training-materials-web/intro-202310xx/img/LUMI-BE-Intro-202310XX-10-lustre/LustreFileStriping.png){ loading=lazy }
</figure>

<!--
<figure markdown>
  ![Figure striping](../img/10_Lustre_chunks_of_File.svg)
   <caption>Striping a file across 4 (non-consecutive) OSTs</caption>
</figure>
-->

On Lustre, large files are typically broken into chunks that are then cyclically spread across
a number of OSTs. In the figure above, the file is spread across the OSTs 0, 2, 4 and 6.

This process is completely transparent to the user with respect to correctness. The Lustre client
takes care of the process and presents a traditional file to the application program.
It is however not transparent with respect to performance. The performance of reading and
writing a file depends a lot on how the file is spread across the OSTs of a file system.

Basically, there are two parameters that have to be chosen: The size of the chunks (all chunks have
the same size in this example, except for the last one which may be smaller) and the number of OSTs 
that should be used for a file. Lustre itself takes care of choosing the OSTs in general.

There are variants of Lustre where one has multiple layouts per file which can come in handy if one 
doesn't know the size of the file in advance. The first part of the file will then typically be written
with fewer OSTs and/or smaller chunks, but this is outside the scope of this course.
The feature is known as Progressive File Layout.

The chunk size and number of OSTs used can be chosen on a file-by-file basis. The default on LUMI
is to use only one OST for a file. This is done because that is the most reasonable choice for the many
small files that many unsuspecting users have, and as we shall see, it is sometimes even the best choice
for users working with large files. But it is not always the best choice.
And unfortunately there is no single set of parameters that is good for all users.


## Accessing a file

<figure markdown style="border: 1px solid #000">
  ![Accessing a file](https://465000095.lumidata.eu/training-materials-web/intro-202310xx/img/LUMI-BE-Intro-202310XX-10-lustre/LustreFileAccess.png){ loading=lazy }
</figure>

Let's now study how Lustre will access a file for reading or writing. Let's assume that the
second client in the above picture wants to write something to the file.

-   The first step is opening the file. 
  
    For that, the Lustre client has to talk to the metadata server (MDS) and query some information
    about the file.

    The MDS in turn will return information about the file, including the layout of the file: chunksize
    and the OSSes/OSTs that keep the chunks of the file.

-   From that point on, the client doesn't need to talk to the MDS anymore and can talk directly to 
    the OSSes to write data to the OSTs or read data from the OSTs.


## Parallelism is key!

<figure markdown style="border: 1px solid #000">
  ![Parallelism is key!](https://465000095.lumidata.eu/training-materials-web/intro-202310xx/img/LUMI-BE-Intro-202310XX-10-lustre/LustreParallelismKey.png){ loading=lazy }
</figure>

The metadata servers can be the bottleneck in a Lustre setup. 
It is not easy to spread metadata across multiple MDSes efficiently.
Moreover, the amount of metadata for any given file is small, so any metadata
operation will translate into small disk accesses on the MDTs and hence not 
fully exploit the speed that some RAID setups can give you.

However, when reading and writing data, there are up to four levels of parallelism:

1.  The read and write operations can engage multiple OSSes.

2.  Since a single modern OSS can handle more bandwidth than a some OSTs can
    deliver, OSSes may have multiple OSTs.

    *How many OSTs are engaged is something that a user has control over.*

3.  An OST will contain many disks or SSDs, typically with some kind of RAID, but hence
    each read or write operation to an OST can engage multiple disks.

    *An OST will only be used optimally when doing large enough file accesses. But the 
    file system client may help you here with caching.*

4.  Internally, SSDs are also parallel devices. The high bandwidth of modern high-end SSDs
    is the result of engaging multiple channels to the actual storage "chips" internally.

So to fully benefit from a Lustre file system, it is best to work with relatively few
files (to not overload the MDS) but very large disk accesses.
Very small I/O operations wouldn't even benefit from the RAID acceleration, and this is
especially true for very small files as they cannot even benefit from caching provided
by the file system client (otherwise a file system client may read in more data than requested,
as file access is often sequential anyway so it would be prepared for the next access).
To make efficient use of the OSTs it is important to have a relatively large chunk size
and relatively large I/O operations, even more so for hard disk based file systems as
if the OST file system manages to organise the data well on disk, it is a good way to
reduce the impact on effective bandwidth of the inherent latency of disk access.
And to engage multiple OSTs simultaneously (and thus reach a bandwidth which is much 
higher than a single OST can provide), even larger disk accesses will be needed so that
multiple chunks are read or written simultaneously. Usually you will have to do the I/O
in a distributed memory application from multiple nodes simultaneously as otherwise the
bandwidth to the interconnect and processing capacity of the client software 
of a single node might become the limiting factor.

Not all codes are using Lustre optimally though, even with the best care of their users.

-   Some codes use files in scientific data formats like HDF5 and netCDF, and when written
    properly they can have very scalable performance.

    A good code will write data to large files, from multiple nodes simultaneously, but 
    will avoid doing I/O from too many ranks simultaneously to avoid bombarding the OSSes/OSTs
    with I/O requests. But that is a topic for a more advanced course...

    One user has reported reading data from the hard disk based parallel file systems at
    about 25% of the maximal bandwidth, which is very good given that other users where also
    using that file system at the same time and not always in an optimal way.

    Surprisingly many of these codes may be rather old. But their authors grew up with
    noisy floppy drives (do you still know what that is) and slow hard drives so learned
    how to program efficiently.

-   But some code open one or more files per MPI rank. Those codes may have difficulties
    scaling to a large number of ranks, as they will put a heavy burden on the MDS when those
    files are created, but also may bombard each OSS/OST with too many I/O requests.

    Some of these codes are rather old also, but were never designed to scale to thousands
    of MPI ranks. However, nowadays some users are trying to solve such big problems that 
    the computations do scale reasonably well. But the I/O of those codes becomes a problem...

-   But some users simply abuse the file system as an unstructured database and simply drop
    their data as tens of thousands or even millions of small files with each one data element,
    rather than structuring that data in suitable file formats. This is especially common in
    science fields that became popular relatively recently - bio-informatics and AI - as those
    users typically started their work on modern PCs with fast SSDs. 

    The problem there is that metadata access and small I/O operations don't scale well to large
    systems. Even copying such a data set to a local SSD would be a problem should a compute node
    have a local SSD, but local SSDs suitable for supercomputers are also very expensive as they 
    have to deal with lots of write operations. Your gene data or training data set may be relatively
    static, but on a supercomputer you cannot keep the same node for weeks so you'd need to rewrite 
    your data to local disks very often. And there are shared file systems with better small file
    performance than Lustre, but those that scale to the size of even a fraction of Lustre, are
    also very expensive. And remember that supercomputing works exactly the opposite way: Try to
    reduce costs by using relatively cheap hardware but cleverly written software at all levels
    (system and application) as at a very large scale, this is ultimately cheaper than investing
    more in hardware and less in software. 

Lustre was originally designed to achieve very high bandwidth to/from a small number of files,
and that is in fact a good match for well organised scientific data sets and/or checkpoint data,
but was not designed to handle large numbers of small files. Nowadays of course optimisations to 
deal better with small files are being made, but they may come at a high hardware cost.


## How to determine the striping values?

<figure markdown style="border: 1px solid #000">
  ![How to determine the striping values?](https://465000095.lumidata.eu/training-materials-web/intro-202310xx/img/LUMI-BE-Intro-202310XX-10-lustre/LustreDetermineParameters.png){ loading=lazy }
</figure>

If you only access relatively small files (up to a few hundreds of kilobytes) and access them 
sequentially, then you are out of luck. There is not much you can do. Engaging multiple OSTs 
for a single file is not very useful in this case, and you will also have no parallelism from
accessing multiple files that may be stored on different OSTs.

As a rule of thumb, if you access a lot of data with a data access pattern that can exploit
parallelism, try to use all OSTs of the Lustre file system:

-   If the number of files that will be accessed simultaneously is larger than the number of
    OSTs, it is best to not spread a single file across OSTs and hence use a *stripe count* of 1.

    It will also reduce Lustre contention and OST file locking and as such gain performance
    for everybody.

-   At the opposite end, if you access only one very large file and use large or parallel disk
    accesses, set the stripe count to the number of OSTs (or a smaller number if you notice in
    benchmarking that the I/O performance plateaus). On a system the size of LUMI with storage
    as powerful as on LUMI, this will only work if you have more than on I/O client. 

-   When using multiple similar sized files simultaneously but less files than there are OSTs,
    you should probably chose the stripe count such that the product of the number of files
    and the stripe count is approximately the number of OSTs. E.g., with 32 OSTs and 8 files,
    set the stripe count to 4.

It is better not to force the system to use specific OSTs but to let it chose OSTs at random.

The typical *stripe size*  (size of the chunks) to use can be a bit harder to determine.
Typically this will be 1MB or more, and it can be up to 4 GB, but that only makes sense
for very large files. The ideal stripe size will also depend on the characteristics of
the I/O in the file. If the application never writes more than 1 GB of data in a single 
sequential or parallel I/O operation before continuing with more computations, obviously
with a stripe size of 1 GB you'd be engaging only a single OST for each write operation.


## Managing the striping parameters

<figure markdown style="border: 1px solid #000">
  ![Managing the striping parameters (1)](https://465000095.lumidata.eu/training-materials-web/intro-202310xx/img/LUMI-BE-Intro-202310XX-10-lustre/LustreManageStriping1.png){ loading=lazy }
</figure>








## Links

-   [Understanding Lustre Internals](https://wiki.lustre.org/Understanding_Lustre_Internals)
    on the [Lustre Wiki](https://wiki.lustre.org/).

-   [Lustre Basics](https://www.nas.nasa.gov/hecc/support/kb/lustre-basics_224.html) and
    [Lustre Best Practices](https://www.nas.nasa.gov/hecc/support/kb/lustre-best-practices_226.html)
    in the [knowledge base of the NASA supercomputers](https://www.nas.nasa.gov/hecc/support/kb/).

