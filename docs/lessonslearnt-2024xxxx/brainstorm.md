# Brainstorm

1.  Architecture of LUMI
    1.  Stress the differences with "traditional" clusters.
    2.  Explain idea of the Deep projects
    3.  Future: opposite of what CXL is preaching
    4.  Slingshot with Dragonfly architecture. Dynamic re-routing is very important!
    5.  Pay some attention to the storage also
2.  HPC is not cloud. Many users would be better off with a compute cloud architecture
    1.  A supercomputer is built for low latency
    2.  Supercomputers try to minimise the hardware cost by using clever software.
    3.  A commercial cloud has a very different exploitation model than a "free" supercomputer
    4.  Containers are no wonder solution and solve different problems than users think they solve
    5.  TCO is a difficult concept in the academic world...
3.  Scalability is not evident
    1.  Predictable performance is important and this is no longer the case with modern hardware
    2.  OS jitter is a real problem
    3.  Not all parameters in a system scale in the same way
    4.  As a result an HPC cluster is not a miracle machine to scale up workstation workloads
    5.  There is a real need for a hierarchy of machines. Bigger is not always better.
        1.  Single part failures have more consequences than you would expect...
4.  Special case of scalability: I/O tuning
    1.  I/O configuration on LUMI and the ideas behind it
    2.  Flash memory in a parallel file system solves fewer problems than people think.
    3.  A parallel file system needs help: Striping parameters
        1.  Proper setup of workflows will help
5.  Slurm is not a good scheduler but there is no better one
    1.  Slurm on LUMI
    2.  Importance of proper mapping of application on the compute resources
    3.  Multi-user multi-job tenancy of a node is problematic.
    4.  Lacks proper support for heterogeneous jobs
6.  We are in a software development crisis
    1.  We are back in a time where too many users depend on proprietary technologies limiting portability
        1.  What choices can we make for GPU computing?
    2.  Researchers use increasingly true research codes without having the competences to deal with such codes
    3.  Some packages that everybody relies on are badly written, badly tested and badly documented. Think of NumPy and SciPy.
    4.  Other element of the software crisis: Exploiting hierarchical architectures.
    5.  The way researchers use software is changing and European compute centres are not ready to deal with it.
        1.  And software installation tools are also not always ready to deal with the specifics of HPC installations.
    6.  There is no best way to install software. It is always a compromise.
        1.  LD_LIBRARY_PATH versus rpath versus static linking?
        2.  Most important is a rapid and flexible re-installation.
7.  Training is a problem
    1.  Users don't feel the need for training and reading documentation
    2.  Tier-2 compute centres try too much to protect users from the complexity of the machine but don't prepare those users to scale up
    3.  As many users stick to their first programming language it is important that that programming language is actually one suitable to extract performance out of a system. This has been a disaster in the past quarter century or more. We've had a Java age in part of scientific computing and now a Python age.
    4.  A very bad example is our Flemish Tier-1 system which doesn't prepare for Tier-0 computing at all.
        1.  Any course about the proper use of Lustre?
        2.  Recommended way of working is wrappers that hide even more of the mapping
        3.  Slurm partition model favours lots of small jobs over true HPC computing and uses a policy that does not take the hierarchy of resources into account.
8.  Other threats
    1.  Cost of transistors is no longer going down
    2.  Breakdown of Dennard scaling: Power crisis
    3.  Both previous points together: Next cluster may not be faster after all...
    4.  Very specialised architectures good for efficiency but how do we size the machine?
        1.  Not all users capable to figure out what they need. They follow the hype instead.
        2.  Working remotely also comes with problems
    5.  The problem of reproducibility
        1.  On LUMI we simply cannot guarantee that a binary that runs today will still run after the next system update. It is more likely that this will not be the case than that this will be the case.
        2.  Researchers need to start thinking about reproducibility of compute experiments in the same way as experimentalists.


## References

-   [AMD EPYC 7003 Series Microarchitecture Overview](https://www.amd.com/system/files/documents/overview-amd-epyc7003-series-processors-microarchitecture.pdf)
    gives some ideas how the I/O die is structured
-   [HPC Tuning Guide for AMD EPYC 7003 Series Processors](https://www.amd.com/system/files/documents/high-performance-computing-tuning-guide-amd-epyc7003-series-processors.pdf)
-   [Hot Chips 31 (2019) presentation "The Path to Zen2"](https://old.hotchips.org/hc31/HC31_1.1_AMD_ZEN2.pdf) gives a very little bit of insight in the I/O die.
    -   [YouTube vido of the presentation](https://youtu.be/QU3PHKdj8wQ?t=673)

-   MI200 articles
    -   [AMD CDNA2 Architecture Whitepaper](https://www.amd.com/system/files/documents/amd-cdna2-white-paper.pdf)
    -   ["AMD Instinct MI200" Instruction Set Architecture: Reference Guide](https://www.amd.com/system/files/TechDocs/instinct-mi200-cdna2-instruction-set-architecture.pdf)
    -   [Hot Chips 34 (2022) - AMD Instnt MI200 Series Accelerator and Node Architectures](https://hc34.hotchips.org/assets/program/conference/day1/GPU%20HPC/HC2022.AMD.AlanSmith.v14.Final.20220820.pdf)
        -   [YouTube video including the AMD MI200 presentation](https://www.youtube.com/watch?v=hxcAA32Htt0&t=2356s)
        -   [Hot Chips 34 – AMD’s Instinct MI200 Architecture on Chips and Cheese](https://chipsandcheese.com/2022/09/18/hot-chips-34-amds-instinct-mi200-architecture/)


