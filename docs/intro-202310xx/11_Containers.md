# Containers on LUMI

## What are we talking about in this chapter?

<figure markdown style="border: 1px solid #000">
  ![Containers on LUMI](https://465000095.lumidata.eu/training-materials-web/intro-202310xx/img/LUMI-BE-Intro-202310XX-11-containers/ContainersIntro.png){ loading=lazy }
</figure>

Let's now switch to using containers on LUMI. 
This section is about using containers on the login nodes and compute nodes. 
Some of you may have heard that there were plans to also have an OpenShift Kubernetes container cloud
platform for running microservices but at this point it is not clear if and when this will materialize
due to a lack of personpower to get this running and then to support this.

In this section, we will 

-   discuss what to expect from containers on LUMI: what can they do and what can't they do,

-   discuss how to get a container on LUMI,

-   discuss how to run a container on LUMI,

-   and discuss some enhancements we made to the LUMI environment that are based on containers or help
    you use containers.

Remember though that the compute nodes of LUMI are an HPC infrastructure and not a container cloud!


## What do containers not provide

<figure markdown style="border: 1px solid #000">
  ![What do containers not provide](https://465000095.lumidata.eu/training-materials-web/intro-202310xx/img/LUMI-BE-Intro-202310XX-11-containers/ContainersNotProvide.png){ loading=lazy }
</figure>

What is being discussed in this subsection may be a bit surprising.
Containers are often marketed as a way to provide reproducible science and as an easy way to transfer
software from one machine to another machine. However, containers are neither of those and this becomes 
very clear when using containers built on your typical Mellanox/NVIDIA InfiniBand based clusters with
Intel processors and NVIDIA GPUs on LUMI.

First, computational results are almost never 100% reproducible because of the very nature of how computers
work. You can only expect reproducibility of sequential codes between equal hardware. As soon as you change the
CPU type, some floating point computations may produce slightly different results, and as soon as you go parallel
this may even be the case between two runs on exactly the same hardware and software. Containers may offer more
reproducibility than recompiling software for a different platform, but all you're trying to do is reproducing 
the same wrong result as in particular floating point operations are only an approximation for real numbers. 
When talking about reproducibility, you should think like way experimentalists do: You have a result and an 
error margin, and it is important to have an idea of that error margin too.

But full portability is a much greater myth. Containers are really only guaranteed to be portable between similar systems.
They may be a little bit more portable than just a binary as you may be able to deal with missing or different libraries
in the container, but that is where it stops. Containers are usually built for a particular CPU architecture and GPU
architecture, two elements where everybody can easily see that if you change this, the container will not run. But 
there is in fact more: containers talk to other hardware too, and on an HPC system the first piece of hardware that comes
to mind is the interconnect. And they use the kernel of the host and the kernel modules and drivers provided by that
kernel. Those can be a problem. A container that is not build to support the SlingShot interconnect, may fail 
(or if you're lucky just fall back to
TCP sockets in MPI, completely killing scalability, but technically speaking still working so portable). 
Containers that expect a certain version range of a particular driver on the system may fail if a different, out-of-range
version of that driver is on the system instead (think the ROCm driver).

Even if a container is portable to LUMI, it may not yet be performance-portable. E.g., without proper support for the
interconnect it may still run but in a much slower mode. 
Containers that expect the knem kernel extension for good 
intra-node MPI performance may not run as efficiently as LUMI uses xpmem instead.
But one should also realise that speed gains in the x86
family over the years come to a large extent from adding new instructions to the CPU set, and that two processors
with the same instructions set extensions may still benefit from different optimisations by the compilers. 
Not using the proper instruction set extensions can have a lot of influence. At UAntwerpen we've seen GROMACS 
doubling its speed by choosing proper options, and the difference can even be bigger.

Many HPC sites try to build software as much as possible from sources to exploit the available hardware as much as 
possible. You may not care much about 10% or 20% performance difference on your PC, but 20% on a 160 million EURO
investment represents 32 million EURO and a lot of science can be done for that money...


## But what can they then do on LUMI?

<figure markdown style="border: 1px solid #000">
  ![But what can they then do on LUMI?](https://465000095.lumidata.eu/training-materials-web/intro-202310xx/img/LUMI-BE-Intro-202310XX-11-containers/ContainersCanDoOnLUMI.png){ loading=lazy }
</figure>


*   A very important reason to use containers on LUMI is reducing the pressure on the file system by software
    that accesses many thousands of small files (Python and R users, you know who we are talking about).
    That software kills the metadata servers of almost any parallel file system when used at scale.

    As a container on LUMI is a single file, the metadata servers of the parallel file system have far less 
    work to do, and all the file caching mechanisms can also work much better.

*   Software installations that would otherwise be impossible. 
    E.g., some software may not even be suited for installation in
    a multi-user HPC system as it uses fixed paths that are not compatible with installation in 
    module-controlled software stacks.
    HPC systems want a lightweight `/usr` etc. structure as that part of the system
    software is often stored in a RAM disk, and to reduce boot times. Moreover, different users may need
    different versions of a software library so it cannot be installed in its default location in the system
    software region. However, some software is ill-behaved and cannot be relocated to a different directory,
    and in these cases containers help you to build a private installation that does not interfere with other
    software on the system.

*   As an example, Conda installations are not appreciated on the main Lustre file system.

    On one hand, Conda installations tend to generate lots of small files (and then even more due to a linking
    strategy that does not work on Lustre). So they need to be containerised just for storage manageability.

    They also re-install lots of libraries that may already be on the system in a different version. 
    The isolation offered by a container environment may be a good idea to ensure that all software picks up the
    right versions.

*   Another example where containers have proven to be useful on LUMI is to experiment with newer versions
    of ROCm than we can offer on the system. 

    This often comes with limitations though, as (a) that ROCm version is still limited by the drivers on the 
    system and (b) we've seen incompatibilities between newer ROCm versions and the Cray MPICH libraries.

*   And a combination of both: LUST with the help of AMD have prepared some containers with popular AI applications.
    These containers use some software from Conda, a newer ROCm version installed through RPMs, and some 
    performance-critical code that is compiled specifically for LUMI.

Remember though that whenever you use containers, you are the system administrator and not LUST. We can impossibly
support all different software that users want to run in containers, and all possible Linux distributions they may
want to run in those containers. We provide some advice on how to build a proper container, but if you chose to
neglect it it is up to you to solve the problems that occur.


## Managing containers

<figure markdown style="border: 1px solid #000">
  ![Managing containers](https://465000095.lumidata.eu/training-materials-web/intro-202310xx/img/LUMI-BE-Intro-202310XX-11-containers/ContainersManaging_1.png){ loading=lazy }
</figure>

On LUMI, we currently support only one container runtime.

Docker is not available, and will never be on the regular compute nodes as it requires elevated privileges
to run the container which cannot be given safely to regular users of the system.

Singularity is currently the only supported container runtime and is available on the login nodes and
the compute nodes. It is a system command that is installed with the OS, so no module has to be loaded
to enable it. We can also offer only a single version of singularity or its close cousin AppTainer 
as singularity/AppTainer simply don't really like running multiple versions next to one another, 
and currently the version that
we offer is determined by what is offered by the OS.

To work with containers on LUMI you will either need to pull the container from a container registry,
e.g., [DockerHub](https://hub.docker.com/), or bring in the container by copying the singularity `.sif` file.

Singularity does offer a command to pull in a Docker container and to convert it to singularity format.
E.g., to pull a container for the Julia language from DockerHub, you'd use

```bash
singularity pull docker://julia
```

Singularity uses a single flat sif file for storing containers. The `singularity pull` command does the 
conversion from Docker format to the singularity format.

Singularity caches files during pull operations and that may leave a mess of files in
the `.singularity` cache directory. This can lead to **exhaustion of your disk quota for your
home directory**. So you may want to use the environment variable `SINGULARITY_CACHEDIR`
to put the cache in, e.g,, your scratch space (but even then you want to clean up after the
pull operation so save on your storage billing units).

???+demo "Demo singularity pull"

    Let's try the `singularity pull docker://julia` command:

    <!-- Used a 105x23 window size -->
    <figure markdown style="border: 1px solid #000">
      ![Demo singularity pull slide 1](https://465000095.lumidata.eu/training-materials-web/intro-202310xx/img/LUMI-BE-Intro-202310XX-11-containers/ContainersExamplePull_1.png){ loading=lazy }
    </figure>

    We do get a lot of warnings but usually this is perfectly normal and usually they can be safely ignored.

    <figure markdown style="border: 1px solid #000">
      ![Demo singularity pull slide 2](https://465000095.lumidata.eu/training-materials-web/intro-202310xx/img/LUMI-BE-Intro-202310XX-11-containers/ContainersExamplePull_2.png){ loading=lazy }
    </figure>

    The process ends with the creation of the file `jula_latest.sif`. 

    Note however that the process has left a considerable number of files in `~/.singularity ` also:

    <figure markdown style="border: 1px solid #000">
      ![Demo singularity pull slide 3](https://465000095.lumidata.eu/training-materials-web/intro-202310xx/img/LUMI-BE-Intro-202310XX-11-containers/ContainersExamplePull_3.png){ loading=lazy }
    </figure>


<figure markdown style="border: 1px solid #000">
  ![Managing containers (2)](https://465000095.lumidata.eu/training-materials-web/intro-202310xx/img/LUMI-BE-Intro-202310XX-11-containers/ContainersManaging_2.png){ loading=lazy }
</figure>

There is currently limited support for building containers on LUMI and I do not expect that to change quickly.
Container build strategies that require elevated privileges, and even those that require fakeroot or user namespaces, cannot
be supported for security reasons (with user namespaces in particular a huge security concern as the Linux implementation
is riddled with security issues). 
Enabling features that are known to have had several serious security vulnerabilities in the recent past, or that
themselves are unsecure by design and could allow users to do more on the system than a regular user should
be able to do, will never be supported.

So you should pull containers from a container repository, or build the container on your own workstation
and then transfer it to LUMI.

There is some support for building on top of an existing singularity container.
We are also working on a number of base images to build upon, where the base images are tested with the
OS kernel on LUMI.

## Interacting with containers

<figure markdown style="border: 1px solid #000">
  ![Interacting with containers](https://465000095.lumidata.eu/training-materials-web/intro-202310xx/img/LUMI-BE-Intro-202310XX-11-containers/ContainersInteracting.png){ loading=lazy }
</figure>

There are basically three ways to interact with containers.

If you have the sif file already on the system you can enter the container with an interactive shell:

```
singularity shell container.sif
```

???+demo "Demo singularity shell"

    <figure markdown style="border: 1px solid #000">
      ![Demo singularity shell](https://465000095.lumidata.eu/training-materials-web/intro-202310xx/img/LUMI-BE-Intro-202310XX-11-containers/ContainersExampleShell.png){ loading=lazy }
    </figure>

    In this screenshot we checked the contents of the `/opt` directory before and after the
    `singularity shell julia_latest.sif` command. This shows that we are clearly in a different
    environment. Checking the `/etc/os-release` file only confirms this as LUMI runs SUSE Linux
    on the login nodes, not a version of Debian.


The second way is to execute a command in the container with `singularity exec`. E.g., assuming the 
container has the `uname` executable installed in it,

```
singularity exec container.sif uname -a
```

???+demo "Demo singularity exec"

    <figure markdown style="border: 1px solid #000">
      ![Demo singularity exec](https://465000095.lumidata.eu/training-materials-web/intro-202310xx/img/LUMI-BE-Intro-202310XX-11-containers/ContainersExampleExec.png){ loading=lazy }
    </figure>

    In this screenshot we execute the `uname -a` command before and with the
    `singularity exec julia_latest.sif` command. There are some slight differences in the
    output though the same kernel version is reported as the container uses the host kernel.
    Executing

    ```
    singularity exec julia_latest.sif cat /etc/os-release
    ```

    confirms though that the commands are executed in the container.


The third option is often called running a container, which is done with singularity run:

```
singularity run container.sif
```

It does require the container to have a special script that tells singularity what 
running a container means. You can check if it is present and what it does with `singularity inspect`: 

```
singularity inspect --runscript container.sif
```

???+demo "Demo singularity run"

    <figure markdown style="border: 1px solid #000">
      ![Demo singularity run](https://465000095.lumidata.eu/training-materials-web/intro-202310xx/img/LUMI-BE-Intro-202310XX-11-containers/ContainersExampleRun.png){ loading=lazy }
    </figure>

    In this screenshot we start the julia interface in the container using
    `singularity run`. The second command shows that the container indeed
    includes a script to tell singularity what `singularity run` should do.



You want your container to be able to interact with the files in your account on the system.
Singularity will automatically mount `$HOME`, `/tmp`, `/proc`, `/sys` and `dev` in the container,
but this is not enough as your home directory on LUMI is small and only meant to be used for
storing program settings, etc., and not as your main work directory. (And it is also not billed
and therefore no extension is allowed.) Most of the time you want to be able to access files in
your project directories in `/project`, `/scratch` or `/flash`, or maybe even in `/appl`.
To do this you need to tell singularity to also mount these directories in the container,
either using the 
`--bind src1:dest1,src2:dest2` 
flag or via the `SINGULARITY_BIND` or `SINGULARITY_BINDPATH` environment variables.
E.g.,

``` bash
export SINGULARITY_BIND='/pfs,/scratch,/projappl,/project,/flash'
```

will ensure that you have access to the scratch, project and flash directories of your project.


## Running containers on LUMI

<figure markdown style="border: 1px solid #000">
  ![/running containers on LUMI](https://465000095.lumidata.eu/training-materials-web/intro-202310xx/img/LUMI-BE-Intro-202310XX-11-containers/ContainersRunning.png){ loading=lazy }
</figure>

Just as for other jobs, you need to use Slurm to run containers on the compute nodes.

For MPI containers one should use `srun` to run the `singularity exec` command, e.g,,

```
srun singularity exec --bind ${BIND_ARGS} \
${CONTAINER_PATH} mp_mpi_binary ${APP_PARAMS}
```

(and replace the environment variables above with the proper bind arguments for `--bind`, container file and
parameters for the command that you want to run in the container).

On LUMI, the software that you run in the container should be compatible with Cray MPICH, i.e., use the
MPICH ABI (currently Cray MPICH is based on MPICH 3.4). It is then possible to tell the container to use
Cray MPICH (from outside the container) rather than the MPICH variant installed in the container, so that
it can offer optimal performance on the LUMI SlingShot 11 interconnect.

Open MPI containers are currently not well supported on LUMI and we do not recommend using them.
We only have a partial solution for the CPU nodes that is not tested in all scenarios, 
and on the GPU nodes Open MPI is very problematic at the moment.
This is due to some design issues in the design of Open MPI, and also to some piece of software
that recent versions of Open MPI require but that HPE only started supporting recently on Cray EX systems
and that we haven't been able to fully test.
Open MPI has a slight preference for the UCX communication library over the OFI libraries, and 
currently full GPU support requires UCX. Moreover, binaries using Open MPI often use the so-called
rpath linking process so that it becomes a lot harder to inject an Open MPI library that is installed
elsewhere. The good news though is that the Open MPI developers of course also want Open MPI
to work on biggest systems in the USA, and all three currently operating or planned exascale systems
use the SlingShot 11 interconnect, so work is going on for better support for OFI and for full GPU
support on systems that rely on OFI and do not support UCX.


## Enhancements to the environment

<figure markdown style="border: 1px solid #000">
  ![Environment enhancements](https://465000095.lumidata.eu/training-materials-web/intro-202310xx/img/LUMI-BE-Intro-202310XX-11-containers/ContainersEnvironmentEnhancement_1.png){ loading=lazy }
</figure>

To make life easier, LUST with the support of CSC did implement some modules
that are either based on containers or help you run software with containers.


### Bindings for singularity

The **`singularity-bindings/system`** module which can be installed via EasyBuild
helps to set `SINGULARITY_BIND` and `SINGULARITY_LD_LIBRARY_PATH` to use 
Cray MPICH. Figuring out those settings is tricky, and sometimes changes to the
module are needed for a specific situation because of dependency conflicts
between Cray MPICH and other software in the container, which is why we don't
provide it in the standard software stacks but instead make it available as
an EasyBuild recipe that you can adapt to your situation and install.

As it needs to be installed through EasyBuild, it is really meant to be 
used in the context of a LUMI software stack (so not in `CrayEnv`).
To find the EasyConfig files, load the `EasyBuild-user` module and 
run

```
eb --search singularity-bindings
```

You can also check the 
[page for the `singularity-bindings` in the LUMI Software Library](https://lumi-supercomputer.github.io/LUMI-EasyBuild-docs/s/singularity-bindings/).

You may need to change the EasyConfig for your specific purpose though.
E.g., the singularity command line option `--rocm` to import the ROCm installation
from the system doesn't fully work (and in fact, as we have alternative ROCm versions
on the system cannot work in all cases) but that can also be fixed by extending
the `singularity-bindings` module 
(or by just manually setting the proper environment variables).


### VNC container

The second tool is a container that we provide with some bash functions
to start a VNC server as temporary way to be able to use some GUI programs
on LUMI until the final setup which will be based on Open OnDemand is ready (expected late 2023).
It can be used in `CrayEnv` or in the LUMI stacks through the
[**`lumi-vnc`** module](https://lumi-supercomputer.github.io/LUMI-EasyBuild-docs/l/lumi-vnc/). 
The container also
contains a poor men's window manager (and yes, we know that there are sometimes
some problems with fonts). It is possible to connect to the VNC server either
through a regular VNC client on your PC or a web browser, but in both cases you'll
have to create an ssh tunnel to access the server. Try

```
module help lumi-vnc
```

for more information on how to use `lumi-vnc`.


### cotainr: Build Conda containers on LUMI

<figure markdown style="border: 1px solid #000">
  ![Environment enhancements (2)](https://465000095.lumidata.eu/training-materials-web/intro-202310xx/img/LUMI-BE-Intro-202310XX-11-containers/ContainersEnvironmentEnhancement_2.png){ loading=lazy }
</figure>

The third tool is [**`cotainr`**](https://lumi-supercomputer.github.io/LUMI-EasyBuild-docs/c/cotainr/), 
a tool developed by DeIC, the Danish partner in the LUMI consortium.
It is a tool to pack a Conda installation into a container. It runs entirely in user space and doesn't need
any special rights. (For the container specialists: It is based on the container sandbox idea to build
containers in user space.)


### Container wrapper for Python packages and conda

The fourth tool is a container wrapper tool that users from Finland may also know
as Tykky. It is a tool to wrap Python and conda installations in a container and then
create wrapper scripts for the commands in the bin subdirectory so that for most
practical use cases the commands can be used without directly using singularity
commands. 
Whereas cotainr fully exposes the container to users and its software is accessed
through the regular singularity commands, Tykky tries to hide this complexity with
wrapper scripts that take care of all bindings and calling singularity.
On LUMI, it is provided by the **`lumi-container-wrapper`**
module which is available in the `CrayEnv` environment and in the LUMI software stacks.
It is also [documented in the LUMI documentation](https://docs.lumi-supercomputer.eu/software/installing/container-wrapper/).

The basic idea is that you run the tool to either do a conda installation or an installation
of Python packages from a file that defines the environment in either standard conda
format (a Yaml file) or in the `requirements.txt` format used by `pip`. 

The container wrapper will then perform the installation in a work directory, create some
wrapper commands in the `bin` subdirectory of the directory where you tell the container
wrapper tool to do the installation, and it will use SquashFS to create as single file
that contains the conda or Python installation.

We do strongly recommend to use the container wrapper tool for larger conda and Python installation.
We will not raise your file quota if it is to house such installation in your `/project` directory.

???+demo "Demo lumi-container-wrapper"

    Create a subdirectory to experiment. In that subdirectory, create a file named `env.yml` with
    the content:

    ```
    channels:
      - conda-forge
    dependencies:
      - python=3.8.8
      - scipy
      - nglview
    ```

    and create an empty subdirectory `conda-cont-1`.

    Now you can follow the commands on the slides below:

    <figure markdown style="border: 1px solid #000">
      ![demo lumi-container-wrapper slide 1](https://465000095.lumidata.eu/training-materials-web/intro-202310xx/img/LUMI-BE-Intro-202310XX-11-containers/ContainersExampleWrapper_1.png){ loading=lazy }
    </figure>

    On the slide above we prepared the environment.

    Now lets run the command 

    ```
    conda-containerize new --prefix ./conda-cont-1 env.yml
    ```

    and look at the output that scrolls over the screen.
    The screenshots don't show the full output as some parts of the screen get overwritten during
    the process:

    <figure markdown style="border: 1px solid #000">
      ![demo lumi-container-wrapper slide 2](https://465000095.lumidata.eu/training-materials-web/intro-202310xx/img/LUMI-BE-Intro-202310XX-11-containers/ContainersExampleWrapper_2.png){ loading=lazy }
    </figure>

    The tool will first build the conda installation in a tempororary work directory
    and also uses a base container for that purpose.

    <figure markdown style="border: 1px solid #000">
      ![demo lumi-container-wrapper slide 3](https://465000095.lumidata.eu/training-materials-web/intro-202310xx/img/LUMI-BE-Intro-202310XX-11-containers/ContainersExampleWrapper_3.png){ loading=lazy }
    </figure>

    The conda installation itself though is stored in a SquashFS file that is then
    used by the container.

    <figure markdown style="border: 1px solid #000">
      ![demo lumi-container-wrapper slide 4](https://465000095.lumidata.eu/training-materials-web/intro-202310xx/img/LUMI-BE-Intro-202310XX-11-containers/ContainersExampleWrapper_4.png){ loading=lazy }
    </figure>

    <figure markdown style="border: 1px solid #000">
      ![demo lumi-container-wrapper slide 65](https://465000095.lumidata.eu/training-materials-web/intro-202310xx/img/LUMI-BE-Intro-202310XX-11-containers/ContainersExampleWrapper_5.png){ loading=lazy }
    </figure>

    In the slide above we see the installation contains both a singularity container
    and a SquashFS file. They work together to get a working conda installation.

    The `bin` directory seems to contain the commands, but these are in fact scripts 
    that run those commands in the container with the SquashFS file system mounted in it.

    <figure markdown style="border: 1px solid #000">
      ![demo lumi-container-wrapper slide 6](https://465000095.lumidata.eu/training-materials-web/intro-202310xx/img/LUMI-BE-Intro-202310XX-11-containers/ContainersExampleWrapper_6.png){ loading=lazy }
    </figure>

    So as you can see above, we can simply use the `python3` command without realising
    what goes on behind the screen...

The wrapper module also offers a pip-based command to build upon the Cray Python modules already present on the system


### Pre-build AI containers

**This is work in progress and not yet available when this text was written. 
The information below is preliminary. More information will follow.**

<figure markdown style="border: 1px solid #000">
  ![Environment enhancements (3): Prebuilt AI containers](https://465000095.lumidata.eu/training-materials-web/intro-202310xx/img/LUMI-BE-Intro-202310XX-11-containers/ContainersPrebuiltAI.png){ loading=lazy }
</figure>

LUST with the help of AMD is also building some containers with popular AI software.
These containers contain a ROCm version that is appropriate for the software,
use Conda for some components, but have several of the performance critical components
built specifically for LUMI for near-optimal performance. Depending on the software they
also contain a RCCL library with the appropriate plugin to work well on the Slingshot 11
interconnect, or a horovod compiled to use Cray MPICH. 

The containers are provided through a module which sets the `SINGULARITY_BIND` environment variable
to ensure proper bindings (as they need, e.g., the libfabric library from the system and the proper
"CXI provider" for libfabric to connect to the Slingshot interconnect). The module will also provide
an environment variable to refer to the container (name with full path) to make it easy to refer to
the container in job scripts.

These containers can be found through the
[LUMI Software Library](https://lumi-supercomputer.github.io/LUMI-EasyBuild-docs/) and are marked
with a container label.


## Conclusion: Container limitations on LUMI

<figure markdown style="border: 1px solid #000">
  ![Container limitations on LUMI](https://465000095.lumidata.eu/training-materials-web/intro-202310xx/img/LUMI-BE-Intro-202310XX-11-containers/ContainersLimitations.png){ loading=lazy }
</figure>

To conclude the information on using singularity containers on LUMI,
we want to repeat the limitations:

*   Containers use the host's operating system kernel which is likely different and
    may have different drivers and kernel extensions than your regular system.
    This may cause the container to fail or run with poor performance.
    Also, containers do not abstract the hardware unlike some virtual machine solutions.

*   The LUMI hardware is almost certainly different from that of the systems on which
    you may have used the container before and that may also cause problems.

    In particular a generic container may not offer sufficiently good support for the 
    SlingShot 11 interconnect on LUMI which requires OFI (libfabric) with the right 
    network provider (the so-called Cassini provider) for optimal performance.
    The software in the container may fall back to TCP sockets resulting in poor 
    performance and scalability for communication-heavy programs.

    For containers with an MPI implementation that follows the MPICH ABI the solution
    is often to tell it to use the Cray MPICH libraries from the system instead.

    Likewise, for containers for distributed AI, one may need to inject an appropriate
    RCCL plugin to fully use the SlingShot 11 interconnect.

*   As containers rely on drivers in the kernel of the host OS, the AMD driver may also
    cause problems. AMD only guarantees compatibility of the driver with two minor versions
    before and after the ROCm release for which the driver was meant. Hence containers 
    using a very old version of ROCm or a very new version compared to what is available
    on LUMI, may not always work as expected.

*   The support for building containers on LUMI is currently very limited due to security
    concerns. Any build process that requires elevated privileges, fakeroot or user namespaces
    will not work.


