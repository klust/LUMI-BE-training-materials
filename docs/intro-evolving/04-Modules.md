Last update of this page: {{ git_revision_date_localized }}

# Modules on LUMI

<!-- 
Examples still to redo:
* module spider
* module spider FFTW
* module spider gnuplot would be nicer without all the Spack junk
* module keyword https also shows too much spack junk.
-->

!!! Audience "Intended audience"
    As this course is designed for people already familiar with HPC systems and
    as virtually any cluster nowadays uses some form of module environment, this
    section assumes that the reader is already familiar with a module environment
    but not necessarily the one used on LUMI.

    However, even if you are very familiar with Lmod it makes sense to go through
    these notes as not every Lmod configuration is the same.


## Module environments

<figure markdown style="border: 1px solid #000">
  ![Module environments](https://465000095.lumidata.eu/training-materials-web/intro-evolving/img/LUMI-BE-Intro-evolving-04-Modules/ModuleEnvironments.png)
</figure>

An HPC cluster is a multi-user machine. Different users may need different 
versions of the same application, and each user has their own preferences for
the environment. Hence there is no "one size fits all" for HPC and mechanisms
are needed to support the diverse requirements of multiple users on a single machine.
This is where modules play an important role.
They are commonly used on HPC systems to enable users to create 
custom environments and select between multiple versions of applications.
Note that this also implies that applications on HPC systems are often not
installed in the regular directories one would expect from the documentation
of some packages, as that location may not even always support proper multi-version
installations and as system administrators prefer to have a software stack which is as isolated as
possible from the system installation to keep the image that has to be loaded
on the compute nodes small.

Another use of modules is to configure the programs
that are being activated. E.g., some packages expect certain additional environment
variables to be set and modules can often take care of that also.

There are 3 systems in use for module management.
The oldest is a C implementation of the commands using module files written in Tcl.
The development of that system stopped around 2012, with version 3.2.10. 
This system is supported by the HPE Cray Programming Environment.
A second system builds upon the C implementation but now uses Tcl also for the
module command and not only for the module files. It is developed in France at
the CÉA compute centre. The version numbering was continued from the C implementation,
starting with version 4.0.0. 
The third system and currently probably the most popular one is Lmod, a version
written in Lua with module files also written in Lua. Lmod also supports most
Tcl module files. It is also supported by HPE Cray. They used to be a bit
slow in following versions, but since 2024 they stay close to the current version. 
The original developer of Lmod, Robert McLay, retired 
at the end of August 2023, but TACC, the centre where he worked, is committed to at least
maintain Lmod though it may not see much new development anymore.

On LUMI we have chosen to use Lmod. As it is very popular, many users may already be
familiar with it, though it does make sense to revisit some of the commands that are
specific for Lmod and differ from those in the two other implementations.

It is important to realise that each module that you see in the overview corresponds to
a module file that contains the actual instructions that should be executed when loading 
or unloading a module, but also other information such as some properties of the module,
information for search and help information.

??? Note "Links"
    -   [Old-style environment modules on SourceForge](https://sourceforge.net/projects/modules/files/Modules/modules-3.2.10/)
    -   [TCL Environment Modules home page on SourceForge](http://modules.sourceforge.net/) and the
        [development on GitHub](https://github.com/cea-hpc/modules)
    -   [Lmod documentation](https://lmod.readthedocs.io/en/latest/) and 
        [Lmod development on GitHub](https://github.com/TACC/Lmod)

<!-- BELGIUM -->
!!! Audience "I know Lmod, should I continue?"
    Lmod is a very flexible tool. Not all sites using Lmod use all features, and
    Lmod can be configured in different ways to the extent that it may even look
    like a very different module system for people coming from another cluster.
    So yes, it makes sense to continue reading as Lmod on LUMI may have some tricks
    that are not available on your home cluster. E.g., several of the features that 
    we rely upon on LUMI are disabled on the UGhent clusters to make them more similar
    to clusters running the C/Tcl module implementation which was used in the early
    days of the VSC.

<!-- GENERAL More general version 
!!! Audience "I know Lmod, should I continue?"
    Lmod is a very flexible tool. Not all sites using Lmod use all features, and
    Lmod can be configured in different ways to the extent that it may even look
    like a very different module system for people coming from another cluster.
    So yes, it makes sense to continue reading as Lmod on LUMI may have some tricks
    that are not available on your home cluster. E.g., several of the features that 
    we rely upon on LUMI may be disabled on clusters where admins try to mimic the
    old behaviour of the C/Tcl module implementation after switching to Lmod.
-->

!!! Note "Standard OS software"
    Most large HPC systems use enterprise-level Linux distributions: derivatives
    of the stable Red Hat or SUSE distributions. Those distributions typically have
    a life span of 5 years or even more during which they receive security updates and
    ports of some newer features, but some of the core elements of such a distribution
    stay at the same version to break as little as possible between minor version
    updates. Python and the system compiler are typical examples of those. Red Hat 8
    and SUSE Enterprise Linux 15 both came with Python 3.6 in their first version, and 
    keep using this version as the base version of Python even though official support from the Python Software Foundation has long ended. Similarly, the default GNU
    compiler version offered on those system also remains the same. The compiler may not even fully support some of the newer CPUs the code is running on. E.g., the
    system compiler of SUSE Enterprise Linux 15, GCC 7.5, does not support the zen2 "Rome"
    or zen3 "Milan" CPUs on LUMI. 

    HPC systems will usually offer newer versions of those system packages through modules and users should always use those. The OS-included tools are really
    only for system management and system related tasks and serve a different purpose which actually requires a version that remains stable across a number of updates
    to not break things at the core of the OS. Users however will typically have a choice between several newer versions through modules, which also enables them
    to track the evolution and transition to a new version at the best suited moment.


## Exploring modules with Lmod

<figure markdown style="border: 1px solid #000">
  ![Exploring modules with Lmod](https://465000095.lumidata.eu/training-materials-web/intro-evolving/img/LUMI-BE-Intro-evolving-04-Modules/ExploringWithLmod.png)
</figure>

Contrary to some other module systems, or even some other Lmod installations, **not all modules are
immediately available for loading**. So don't be disappointed by the few modules you will see with
`module available` right after login. Lmod has a **so-called hierarchical setup** that tries to protect
you from being confronted with all modules at the same time, even those that may conflict with 
each other, and we use that to some extent on LUMI. Lmod **distinguishes between installed modules and
available modules**. Installed modules are all modules on the system that can be loaded one way or
another, sometimes through loading other modules first. Available modules are all those modules
that can be loaded at a given point in time without first loading other modules.

The HPE Cray Programming Environment also uses a hierarchy though it is not fully implemented in
the way the Lmod developer intended so that some features do not function as they should.

-   For example, **the `cray-mpich` module** can only be loaded if **both a network target module and a
    compiler module** are loaded (and that is already the example that is implemented differently from
    what the Lmod developer had in mind). 
-   Another example is the **performance monitoring tools.** Many of those
    tools only become available after loading the `perftools-base` module. 
-   Another example is the
    **`cray-fftw`** module which requires a **processor target module** to be loaded first.

Lmod has **several tools to search for modules**. 

-   The `module avail` command is one that is also
    present in the various Environment Modules implementations and is the command to search in the
    available modules. 
-   But Lmod also has other commands, `module spider` and `module keyword`, to 
    search in the list of installed modules.

    On LUMI, we had to restrict the search space of `module spider`. By default, `module spider`
    will only search in the Cray PE modules, the CrayEnv stack and the LUMI stacks. This is done 
    for performance reasons. However, as we shall discuss later, you can load a module or set an
    environment variable to enable searching all installed modules. The behaviour is also not
    fully consistent. Lmod uses a cache which it refreshes once every 24 hours, or after manually
    clearing the cache. If a rebuild happens while modules from another software stack are available,
    that stack will also be indexed and results for that stack shown in the results of 
    `module spider`. It is a price we had to pay though as due to the large number of modules
    and the many organisations managing modules, the user cache rebuild time became too long
    and system caches are hard to manage also.


## Benefits of a hierarchy

<figure markdown style="border: 1px solid #000">
  ![Benefits of a hierarchy](https://465000095.lumidata.eu/training-materials-web/intro-evolving/img/LUMI-BE-Intro-evolving-04-Modules/BenefitsHierarchy.png)
</figure>

When the hierarchy is well designed, you get **some protection from loading modules that do
not work together well**. E.g., in the HPE Cray PE it is not possible to load the MPI
library built for another compiler than your current main compiler. This is currently
not exploited as much as we could on LUMI, mainly because we realised at the start
that too many users are not familiar enough with hierarchies and would get confused
more than the hierarchy helps them.

Another benefit is that when "swapping" a module that makes other modules available with
a different one, **Lmod will try to look for equivalent modules** in the list of modules made
available by the newly loaded module.

An easy example (though a tricky one as there are other mechanisms at play also) it to load
a different programming environment in the default login environment right after login:

```
$ module load PrgEnv-gnu
```

which results in the next slide:

<!-- Used window size 23x95 -->
<!-- ![module load PrgEnv-gnu](https://465000095.lumidata.eu/training-materials-web/intro-evolving/img/LUMI-BE-Intro-evolving-04-Modules-img/img_BenefitsHierarchyDemo.png) -->
<figure markdown style="border: 1px solid #000">
  ![module load PrgEnv-gnu](https://465000095.lumidata.eu/training-materials-web/intro-evolving/img/LUMI-BE-Intro-evolving-04-Modules/BenefitsHierarchyDemo.png)
</figure>

The first two lines of output are due to to other mechanisms that are at work here, 
and the order of the lines may seem strange but that has to do with the way Lmod works
internally. Each of the PrgEnv modules hard loads a compiler module which is why Lmod tells
you that it is loading `gcc-native/13.2`. However, there is also another mechanism at work that
causes `cce/17.0.1` and `PrgEnv-cray/8.5.0` to be unloaded, but more about that in the next
subsection (next slide).

The important line for the hierarchy in the output are the lines starting with 
"`Due to MODULEPATH changes...`".
Remember that we said that each module has a corresponding **module file**. Just as binaries
on a system, these are **organised in a directory structure**, and there is a path, in this
case `MODULEPATH`, that determines where Lmod will look for module files. The hierarchy is
implemented with a directory structure and the environment variable `MODULEPATH`, and
when the `cce/17.0.1` module was unloaded and `gcc-native/13.2` module was loaded, that 
`MODULEPATH` was changed. As a result, the version of the cray-mpich module for the 
`cce/17.0.1` compiler became unavailable, but one with the same module name for the
`gcc-native/13.2` compiler became available and hence Lmod unloaded the version for the
`cce/17.0.1` compiler as it is no longer available but loaded the matching one for
the `gcc-native/13.2` compiler. 


## About module names and families

<figure markdown style="border: 1px solid #000">
  ![Module names and families](https://465000095.lumidata.eu/training-materials-web/intro-evolving/img/LUMI-BE-Intro-evolving-04-Modules/ModuleNamesFamilies.png)
</figure>

In Lmod you **cannot have two modules with the same name loaded at the same time**.
On LUMI, when you load a module with the same name as an already loaded module, that
other module will be unloaded automatically before loading the new one. There is 
even no need to use the `module swap` command for that (which in Lmod corresponds
to a `module unload` of the first module and a `module load` of the second).
This gives you an automatic protection against some conflicts if the names of the modules
are properly chosen. 

!!! Remark
    Some clusters do not allow the automatic unloading of a module with the same
    name as the one you're trying to load, but on LUMI we felt that this is a 
    necessary feature to fully exploit a hierarchy.

Lmod goes further also. It also has a **family concept**: A module can belong to a family
(and at most 1) and **no two modules of the same family can be loaded together**. 
The family property is something that is defined in the module file. It is commonly 
used on systems with multiple compilers and multiple MPI implementations to ensure 
that each compiler and each MPI implementation can have a logical name without 
encoding that name in the version string (like needing to have `compiler/gcc-13.2`
or `compiler/gcc/13.2`
rather than `gcc-native/13.2`), while still having an easy way to avoid having two 
compilers or MPI implementations loaded at the same time. 
On LUMI, the conflicting module of the same family will be unloaded automatically
when loading another module of that particular family.

This is shown in the example in the previous subsection (the `module load PrgEnv-gnu` in 
a fresh long shell) in two places. It is the mechanism that unloaded `PrgEnv-cray`
when loading `PrgEnv-gnu` and that then unloaded `cce/17.0.1` when the 
`PrgEnv-gnu` module loaded the `gcc-native/13.2` module.

!!! Remark
    Some clusters do not allow the automatic unloading of a module of the same
    family as the one you're trying to load and produce an error message instead.
    On LUMI, we felt that this is a necessary feature to fully exploit the 
    hierarchy and the HPE Cray Programming Environment also relies very much
    on this feature being enabled to make live easier for users.


## Extensions

<figure markdown style="border: 1px solid #000">
  ![Extensions](https://465000095.lumidata.eu/training-materials-web/intro-evolving/img/LUMI-BE-Intro-evolving-04-Modules/ModuleExtensions.png)
</figure>

It would not make sense to have a separate module for each of the hundreds of R
packages or tens of Python packages that a software stack may contain.
In fact, as the software for each module is installed in a separate directory
it would also create a performance problem due to excess directory accesses simply
to find out where a command is located, and very long search path environment
variables such as `PATH` or the various variables packages such as Python, R or Julia use
to find extension packages.
On LUMI related packages are often bundled in a single module. 

Now you may wonder: If a module cannot be simply named after the package it contains as
it contains several ones, how can I then find the appropriate module to load?
Lmod has a solution for that through the so-called **extension** mechanism. An Lmod module
can define extensions, and some of the search commands for modules will also search in the extensions
of a module. Unfortunately, the HPE Cray PE cray-python and cray-R modules do not provide that 
information at the moment as they too contain several packages that may benefit from linking
to optimised math libraries.


## Searching for modules: The module spider command

<figure markdown style="border: 1px solid #000">
  ![module spider](https://465000095.lumidata.eu/training-materials-web/intro-evolving/img/LUMI-BE-Intro-evolving-04-Modules/ModuleSpider.png)
</figure>

There are three ways to use `module spider`, discovering software in more and more detail.
All variants however will by default only check the Cray PE, the CrayEnv stack and the
LUMI stacks, unless another software stack is loaded through a module or `module use`
statement and the cache is regenerated during that period.

1.  `module spider` by itself will show a list of all installed software with a short description.
    Software is bundled by name of the module, and it shows the description taken from the default
    version. `module spider` will also look for "extensions" defined in a module and show those also
    and mark them with an "E". Extensions are a useful Lmod feature to make clear that a module offers
    features that one would not expect from its name. E.g., in a Python module the extensions could be
    a list of major Python packages installed in the module which would allow you to find `NumPy` if
    it were hidden in a module with a different name. This is also a very useful feature to make
    tools that are bundled in one module to reduce the module clutter findable.

2.  `module spider` with the name of a package will show all versions of that package installed on
    the system. This is also case-insensitive. 
    The spider command will not only search in module names for the package, but also in extensions
    of the modules and so will be able to tell you that a package is delivered by another module. See 
    Example 4 below where we will search for the CMake tools.

3.  The third use of `module spider` is with the full name of a module. 
    This shows two kinds of information. First it shows which combinations of other modules one
    might have to load to get access to the package. That works for both modules and extensions
    of modules. In the latter case it will show both the module, and other modules that you might
    have to load first to make the module available.
    Second it will also show help information for the module if the module file provides 
    such information. 


### Example 1: Running `module spider` on LUMI

Let's first run the `module spider` command. The output varies over time, but at the time of writing,
and leaving out a lot of the output, one would have gotten:

<figure markdown style="border: 1px solid #000">
  ![module spider 1](https://465000095.lumidata.eu/training-materials-web/intro-evolving/img/LUMI-BE-Intro-evolving-04-Modules/ModuleSpiderCommand_1.png)
</figure>

<figure markdown style="border: 1px solid #000">
  ![module spider 2](https://465000095.lumidata.eu/training-materials-web/intro-evolving/img/LUMI-BE-Intro-evolving-04-Modules/ModuleSpiderCommand_2.png)
</figure>

In the above display, the `ARMForge` module is currently available in only one version.
The `Autoconf` package is offered in two versions, but in both cases as an extension of another
module as the blue `(E)` in the output shows. The `Blosc` package is available in many versions,
but they are not all shown as the `...` suggests.

After a few more screens, we get the last one:

<figure markdown style="border: 1px solid #000">
  ![module spider 3](https://465000095.lumidata.eu/training-materials-web/intro-evolving/img/LUMI-BE-Intro-evolving-04-Modules/ModuleSpiderCommand_3.png)
</figure>

On the second screen we see, e.g., the ARMForge module which was available in just a single version
at that time, and then Autoconf where the version is in blue and followed by `(E)`. This denotes
that the Autoconf package is actually provided as an extension of another module, and one of the next
examples will tell us how to figure out which one.

The third screen shows the last few lines of the output, which actually also shows some help information
for the command.


### Example 2: Searching for the FFTW module which happens to be provided by the PE

Next let us search for the popular FFTW library on LUMI:

```bash
$ module spider FFTW
```

produces

<figure markdown style="border: 1px solid #000">
  ![module spider FFTW](https://465000095.lumidata.eu/training-materials-web/intro-evolving/img/LUMI-BE-Intro-evolving-04-Modules/ModuleSpiderFFTW.png)
</figure>

This shows that the FFTW library is actually provided by the `cray-fftw` module and was at the time
that this was tested available in 4 versions. 
Note that (a) it is not case sensitive as FFTW is not in capitals in the module name and (b) it
also finds modules where the argument of module spider is only part of the name.

The output also suggests us to dig a bit deeper and 
check for a specific version, so let's run

```bash
$ module spider cray-fftw/3.3.10.7
```

This produces:

<figure markdown style="border: 1px solid #000">
  ![module spider cray-fftw/3.3.10.7](https://465000095.lumidata.eu/training-materials-web/intro-evolving/img/LUMI-BE-Intro-evolving-04-Modules/ModuleSpiderFFTWVersion_1.png)
</figure>

<figure markdown style="border: 1px solid #000">
  ![module spider cray-fftw/3.3.10.7](https://465000095.lumidata.eu/training-materials-web/intro-evolving/img/LUMI-BE-Intro-evolving-04-Modules/ModuleSpiderFFTWVersion_2.png)
</figure>

We now get a long list of possible combinations of modules that would enable us to load this module.
What these modules are will be explained in the next session of this course. However, it does show
a weakness when module spider is used with the HPE Cray PE. In some cases, not all possible combinations
are shown (and this is the case here as the module is actually available directly after login and also
via some other combinations of modules that are not shown). This is because the HPE Cray Programming
Environment is system-installed and sits next to the application software stacks that are managed differently,
but in some cases also because the HPE Cray PE uses Lmod in a different way than intended by the Lmod developers,
causing the spider command to not find some combinations that would actually work.
The command does work well with the software managed by the LUMI User Support Team as the
next two examples will show.


### Example 3: Searching for GNUplot

<figure markdown style="border: 1px solid #000">
  ![module spider for a regular package](https://465000095.lumidata.eu/training-materials-web/intro-evolving/img/LUMI-BE-Intro-evolving-04-Modules/ModuleSpiderRegular.png)
</figure>

To see if GNUplot is available, we'd first search for the name of the package:

```bash
$ module spider gnuplot
```

This produces:

<figure markdown style="border: 1px solid #000">
  ![module spider gnuplot screen 1](https://465000095.lumidata.eu/training-materials-web/intro-evolving/img/LUMI-BE-Intro-evolving-04-Modules/ModuleSpiderGnuplot_1.png)
</figure>

<figure markdown style="border: 1px solid #000">
  ![module spider gnuplot screen 2](https://465000095.lumidata.eu/training-materials-web/intro-evolving/img/LUMI-BE-Intro-evolving-04-Modules/ModuleSpiderGnuplot_2.png)
</figure>

<!-- The output again shows that the search is not case sensitive which is fortunate as uppercase and lowercase
letters are not always used in the same way on different clusters. Some management tools for scientific software
stacks will only use lowercase letters, while the package we use for the LUMI software stacks often uses both. -->

We see that there are a lot of versions installed on the system and that the version actually contains more 
information (e.g., `-cpeGNU-24.03`) that we will explain in the next part of this course. But you might of
course guess that it has to do with the compilers that were used. It may look strange to you to have the same
software built with different compilers. However, mixing compilers is sometimes risky as a library compiled
with one compiler may not work in an executable compiled with another one, so to enable workflows that use
multiple tools we try  to offer many tools compiled with multiple compilers (as for most software we
don't use rpath linking which could help to solve that problem). So you want to chose the appropriate
line in terms of the other software that you will be using.

The output again suggests to dig a bit further for more information, so let's try

```bash
$ module spider gnuplot/5.4.10-cpeGNU-24.03
```

This produces:

<figure markdown style="border: 1px solid #000">
  ![module spider gnuplot/5.4.10-cpeGNU-24.03 screen 1](https://465000095.lumidata.eu/training-materials-web/intro-evolving/img/LUMI-BE-Intro-evolving-04-Modules/ModuleSpiderGnuplotVersion_1.png)
</figure>

<figure markdown style="border: 1px solid #000">
  ![module spider gnuplot/5.4.10-cpeGNU-24.03 screen 2](https://465000095.lumidata.eu/training-materials-web/intro-evolving/img/LUMI-BE-Intro-evolving-04-Modules/ModuleSpiderGnuplotVersion_2.png)
</figure>

In this case, this module is provided by 3 different combinations of modules that also will be explained
in the next part of this course. Furthermore, the output of the command now also shows some help information
about the module, with some links to further documentation available on the system or on the web.
The format of the output is generated automatically by the software installation tool that we use
and we sometimes have to do some effort to fit all information in there.

For some packages we also have additional information in our
[LUMI Software Library web site](https://lumi-supercomputer.github.io/LUMI-EasyBuild-docs/) so it is often
worth looking there also.


### Example 4: Searching for an extension of a module: CMake.

<figure markdown style="border: 1px solid #000">
  ![module spider for extensions](https://465000095.lumidata.eu/training-materials-web/intro-evolving/img/LUMI-BE-Intro-evolving-04-Modules/ModuleSpiderExtensions.png)
</figure>

The `cmake` command on LUMI is available in the operating system image, but as is often the case with
such tools distributed with the OS, it is a rather old version and you may want to use a newer one.

If you would just look through the list of available modules, even after loading some other modules to
activate a larger software stack, you will not find any module called `CMake` though. But let's use the
powers of `module spider` and try

```bash
$ module spider CMake
```

which produces

<figure markdown style="border: 1px solid #000">
  ![module spider CMake](https://465000095.lumidata.eu/training-materials-web/intro-evolving/img/LUMI-BE-Intro-evolving-04-Modules/ModuleSpiderCMake1.png)
</figure>

the output above shows us that there are actually 4 other versions of CMake on the system, but their
version is followed by `(E)` which says that they are extensions of other modules.

Most users would have gotten the same output from

```bash
$ module spider cmake
```

<figure markdown style="border: 1px solid #000">
  ![module spider cmake](https://465000095.lumidata.eu/training-materials-web/intro-evolving/img/LUMI-BE-Intro-evolving-04-Modules/ModuleSpiderCMake2.png)
</figure>

However, if you've recently used one of the `spack` modules and the Lmod cache was last created with one of those
modules loaded, 

```bash
$ module spider CMake
```

may show you something like

<figure markdown style="border: 1px solid #000">
  ![module spider CMake with Spack](https://465000095.lumidata.eu/training-materials-web/intro-evolving/img/LUMI-BE-Intro-evolving-04-Modules/ModuleSpiderCMake3.png)
</figure>

This shows a number of alternative modules also called `cmake`, but with sometimes strange looking strings at the end
of the version. These are modules that were installed on the system using Spack, a tool for HPC software management that
we provide as our secondary tool for users familiar with that tool. More about it also in the presentation on
[software stack](05-SoftwareStacks.md).

With a `spack` module loaded, 

```bash
$ module spider cmake
```

would give you something similar to 

<figure markdown style="border: 1px solid #000">
  ![module spider cmake with Spack](https://465000095.lumidata.eu/training-materials-web/intro-evolving/img/LUMI-BE-Intro-evolving-04-Modules/ModuleSpiderCMake4.png)
</figure>

and we no longer see the CMake versions provided as extensions (and our main CMake instances).

So there is no module called `CMake` on the system (well, there may be one for Spack users but then
with lowercase name).
But Lmod already tells us
how to find out which module actually provides the CMake tools. So let's try

```bash
$ module spider CMake/3.29.3
```

which produces

<figure markdown style="border: 1px solid #000">
  ![module spider CMake/3.29.3](https://465000095.lumidata.eu/training-materials-web/intro-evolving/img/LUMI-BE-Intro-evolving-04-Modules/ModuleSpiderCMakeVersion_1.png)
</figure>

This shows us that the version is provided by a number of `buildtools` modules, and for each of those
modules also shows us which other modules should be loaded to get access to the commands. E.g.,
the first line tells us that there is a module `buildtools/24.03` that provides that version of CMake, but
that we first need to load some other modules, with `LUMI/24.03` and `partition/L` (in that order) 
one such combination.

So in this case, after

```bash
$ module load LUMI/24.03 partition/L buildtools/24.03
```

the `cmake` command would be available.

And you could of course also use

```
$ module spider buildtools/24.03
```

to get even more information about the buildtools module, including any help included in the module.


## Alternative search: the module keyword command

<figure markdown style="border: 1px solid #000">
  ![module keyword](https://465000095.lumidata.eu/training-materials-web/intro-evolving/img/LUMI-BE-Intro-evolving-04-Modules/ModuleKeyword.png)
</figure>

Lmod has a second way of searching for modules: `module keyword`. It searches 
in some of the information included in module files for the
given keyword, and shows in which modules the keyword was found.
We do an effort to put enough information in the modules to make this a suitable additional way
to discover software that is installed on the system.

Let us look for packages that allow us to download software via the `https` protocol.
One could try

```bash
$ module keyword https
```

which produces the following output:

<!-- Use a window of 105x23 -->
<figure markdown style="border: 1px solid #000">
  ![module keyword https screen 1](https://465000095.lumidata.eu/training-materials-web/intro-evolving/img/LUMI-BE-Intro-evolving-04-Modules/ModuleKeywordHTTPS_1.png)
</figure>

<figure markdown style="border: 1px solid #000">
  ![module keyword https screen 2](https://465000095.lumidata.eu/training-materials-web/intro-evolving/img/LUMI-BE-Intro-evolving-04-Modules/ModuleKeywordHTTPS_2.png)
</figure>

The first option is misleading and is shown because it contains a URL in the module
information that is used by `module keyword`. 
But `cURL` and `wget` are indeed 
two tools that can be used to fetch files from the internet.

!!! Note "LUMI Software Library"
    The [LUMI Software Library](https://lumi-supercomputer.github.io/LUMI-EasyBuild-docs/)
    also has a search box in the upper right. We will see in the next section of this course
    that much of the software of LUMI is managed through a tool called EasyBuild, and each
    module file corresponds to an EasyBuild recipe which is a file with the `.eb` extension.
    Hence the keywords can also be found in the EasyBuild recipes which are included in this
    web site, and from a page with an EasyBuild recipe (which may not mean much for you) it is
    easy to go back to the software package page itself for more information. Hence you can use
    the search box to search for packages that may not be installed on the system.

    The example given above though, searching for `https`, would not work via that box as most
    EasyBuild recipes include https web links to refer to, e.g., documentation and would be 
    shown in the result.

    The LUMI Software Library site includes both software installed in our central software stack
    and software for which we make customisable build recipes available for user installation,
    but more about that in the tutorial section on LUMI software stacks.


## Sticky modules and the module purge command

<figure markdown style="border: 1px solid #000">
  ![Sticky modules and module purge](https://465000095.lumidata.eu/training-materials-web/intro-evolving/img/LUMI-BE-Intro-evolving-04-Modules/StickyModules.png)
</figure>

On some systems you will be taught to avoid `module purge` as many HPC systems do their default user
configuration also through modules. This advice is often given on Cray systems as it is a common
practice to preload a suitable set of target modules and a programming environment.
On LUMI both are used. A default programming environment and set of target modules suitable for the
login nodes is preloaded when you log in to the system, and next the `init-lumi` module is loaded
which in turn makes the LUMI software stacks available that we will discuss in the next session.

Lmod however has a trick that helps to avoid removing necessary modules and it is called sticky modules.
When issuing the `module purge` command these modules are automatically reloaded. It is very important to
realise that those modules will not just be kept "as is" but are in fact unloaded and loaded again as
we shall see later that this may have unexpected side effects. 
It is still possible to force unload all these modules
using `module --force purge` or selectively unload those using `module --force unload`.

The sticky property is something that is defined in the module file and not used by the module files
ot the HPE Cray Programming Environment, but we shall see that there is a partial workaround for this in
some of the LUMI software stacks. The `init-lumi` module mentioned above though is a sticky module, as are
the modules that activate a software stack so that you don't have to start from scratch if you have already
chosen a software stack but want to clean up your environment.

Let us look at the output of the `module avail` command, taken just after login on the system at the
time of writing of these notes (the exact list of modules shown is a bit fluid):

<!-- Use a window of 95x23 -->
<figure markdown style="border: 1px solid #000">
  ![module avail slide 1](https://465000095.lumidata.eu/training-materials-web/intro-evolving/img/LUMI-BE-Intro-evolving-04-Modules/ModuleAvail_1.png)
</figure>

<figure markdown style="border: 1px solid #000">
  ![module avail slide 2](https://465000095.lumidata.eu/training-materials-web/intro-evolving/img/LUMI-BE-Intro-evolving-04-Modules/ModuleAvail_2.png)
</figure>

<figure markdown style="border: 1px solid #000">
  ![module avail slide 3](https://465000095.lumidata.eu/training-materials-web/intro-evolving/img/LUMI-BE-Intro-evolving-04-Modules/ModuleAvail_3.png)
</figure>

<figure markdown style="border: 1px solid #000">
  ![module avail slide 4](https://465000095.lumidata.eu/training-materials-web/intro-evolving/img/LUMI-BE-Intro-evolving-04-Modules/ModuleAvail_4.png)
</figure>

<figure markdown style="border: 1px solid #000">
  ![module avail slide 5](https://465000095.lumidata.eu/training-materials-web/intro-evolving/img/LUMI-BE-Intro-evolving-04-Modules/ModuleAvail_5.png)
</figure>

<figure markdown style="border: 1px solid #000">
  ![module avail slide 6](https://465000095.lumidata.eu/training-materials-web/intro-evolving/img/LUMI-BE-Intro-evolving-04-Modules/ModuleAvail_6.png)
</figure>

<figure markdown style="border: 1px solid #000">
  ![module avail slide 7](https://465000095.lumidata.eu/training-materials-web/intro-evolving/img/LUMI-BE-Intro-evolving-04-Modules/ModuleAvail_7.png)
</figure>

<figure markdown style="border: 1px solid #000">
  ![module avail slide 8](https://465000095.lumidata.eu/training-materials-web/intro-evolving/img/LUMI-BE-Intro-evolving-04-Modules/ModuleAvail_8.png)
</figure>

<figure markdown style="border: 1px solid #000">
  ![module avail slide 9](https://465000095.lumidata.eu/training-materials-web/intro-evolving/img/LUMI-BE-Intro-evolving-04-Modules/ModuleAvail_9.png)
</figure>

<figure markdown style="border: 1px solid #000">
  ![module avail slide 10](https://465000095.lumidata.eu/training-materials-web/intro-evolving/img/LUMI-BE-Intro-evolving-04-Modules/ModuleAvail_10.png)
</figure>

<figure markdown style="border: 1px solid #000">
  ![module avail slide 11](https://465000095.lumidata.eu/training-materials-web/intro-evolving/img/LUMI-BE-Intro-evolving-04-Modules/ModuleAvail_11.png)
</figure>

<figure markdown style="border: 1px solid #000">
  ![module avail slide 12](https://465000095.lumidata.eu/training-materials-web/intro-evolving/img/LUMI-BE-Intro-evolving-04-Modules/ModuleAvail_12.png)
</figure>

Next to the names of modules you sometimes see one or more letters.
The `(D)` means that that is currently the default version of the module, the one that will be loaded
if you do not specify a version. Note that the default version may depend on other modules that are already
loaded as we have seen in the discussion of the programming environment.

The `(L)` means that a module is currently loaded.

The `(S)` means that the module is a sticky module.

Next to the `rocm` module (on the fourth screen) you see 
`(5.0.2:5.1.0:5.2.0:5.2.3:5.5.1:5.7.0:6.0.0)`.
This shows that the `rocm/6.0.3` module can also 
be loaded as `rocm/5.0.2` or any of the other versions in that list.
Some of them were old versions that have been removed from the system in later updates,
and others are versions that are hard-coded some of the Cray PE modules and other
files but have never been on the system as we had an already patched version.
(E.g., the 24.03 version of the Cray PE will sometimes try to load `rocm/6.0.0` 
while we have immediate had `rocm/6.0.3` on the system which corrects some bugs).

At the end of the overview the extensions are also shown. If this would be fully implemented on LUMI, the list
could become very long. However, as we shall see next, there is an easy way to hide those from view.
We haven't used extensions very intensely so far as there was a bug in older versions of Lmod so that turning off
the view didn't work and so that extensions that were not in available modules, were also shown. But that
is fixed in current versions.


## Changing how the module list is displayed

<figure markdown style="border: 1px solid #000">
  ![Changing how the module list is displayed](https://465000095.lumidata.eu/training-materials-web/intro-evolving/img/LUMI-BE-Intro-evolving-04-Modules/ChangingDisplayStyle.png)
</figure>

You may have noticed in the above example that we don't show directories of module files
in the overview (as is the case on most clusters) but descriptive texts about the module group.
This is just one view on the module tree though, and it can be changed easily by loading a 
version of the `ModuleLabel` module.

-   `ModuleLabel/label` produces the default view of the previous example. 
-   `ModuleLabel/PEhierarchy` still uses descriptive texts but will show the whole 
    module hierarchy of the HPE Cray Programming Environment.
-   `ModuleLabel/system` does not use the descriptive texts but shows module directories instead.

When using any kind of descriptive labels, Lmod can actually bundle module files from different 
directories in a single category and this is used heavily when `ModuleLabel/label` is loaded 
and to some extent also when `ModuleLabel/PEhierarchy` is loaded.

It is rather hard to provide multiple colour schemes in Lmod, and as we do not know how your 
terminal is configured it is also impossible to find a colour scheme that works for all
users. Hence we made it possible to turn on and off the use of colours by Lmod through
the `ModuleColour/on` and `ModuleColour/off` modules.

As the module extensions list in the output of `module avail` could potentially become very long
over time (certainly if there would be Python or R modules installed with EasyBuild that show
all included Python or R packages in that list) you may want to hide those. You can do this by
loading the `ModuleExtensions/hide` module and undo this again by loading
`ModuleExtensions/show`.

There are two ways to tell `module spider` to search in all installed modules. One is more meant as a 
temporary solution: Load

```bash
module load ModuleFullSpider/on
```

and this is turned off again by force-unloading this module or loading

```bash
module load ModuleFullSpider/off
```

The second and permanent way is to set add the line

```bash
export LUMI_FULL_SPIDER=1
```

to your `.profile` file and from then on, `module spider` will index all modules on the system.
Note that this can have a large impact on the performance of the `module spider` and
`module avail` commands that can easily "hang" for a minute or more if a cache rebuild is
needed, which is the case after installing software with EasyBuild or once every 24 hours.

We also hide some modules from regular users because we think they are not useful at all for regular
users or not useful in the context you're in at the moment. 
You can still load them if you know they exist and specify the full version but 
you cannot see them with `module available`. It is possible though to still show most if not all of 
them by loading `ModulePowerUser/LUMI`. Use this at your own risk however, we will not help you to make
things work if you use modules that are hidden in the context you're in
or if you try to use any module that was designed for us to maintain the system and is therefore hidden 
from regular users.

Another way to show hidden modules also, is to use the `--show_hidden` flag of the module command
with the `avail` subcommand: `module --show_hidden avail`. 

With `ModulePowerUser`, all modules will be displayed as if they are regular modules, while
`module --show_hidden avail` will still grey the hidden modules and add an `(H)` to them
so that they are easily recognised.

!!! Example
    An example that will only become clear in the next session: When working with the software stack
    called `LUMI/24.03`, which is built upon the HPE Cray Programming Environment version 24.03,
    all (well, most) of the modules corresponding to other versions of the Cray PE are hidden.

    Just try

    ```
    $ module load LUMI/24.03
    $ module avail
    ```

    and you'll see a lot of new packages that have become available, but will also see less Cray PE 
    modules.


## Getting help with the module help command

<figure markdown style="border: 1px solid #000">
  ![Getting help](https://465000095.lumidata.eu/training-materials-web/intro-evolving/img/LUMI-BE-Intro-evolving-04-Modules/GettingHelp.png)
</figure>

Lmod has the `module help` command to get help on modules

```
$ module help
```

without further arguments will show some help on the `module` command. 

With the name of a module specified, it will show the help information for the default version of that
module, and with a full name and version specified it will show this information specifically for that
version of the module. But note that `module help` can only show help for currently available modules.

Try, e.g., the following commands:

```
$ module help cray-mpich
$ module help cray-python/3.11.7
$ module help buildtools/24.03
```

Lmod also has another command that produces more limited information (and is currently not fully exploited
on LUMI): `module whatis`. It is more a way to tag a module with different kinds of information, some of 
which has a special meaning for Lmod and is used at some places, e.g., in the output of `module spider` without
arguments.

Try, e.g.,:

```
$ module whatis Subversion
$ module whatis Subversion/1.14.3
```

## A note on caching

<figure markdown style="border: 1px solid #000">
  ![A note on caching](https://465000095.lumidata.eu/training-materials-web/intro-evolving/img/LUMI-BE-Intro-evolving-04-Modules/NoteCaching.png)
</figure>

Modules are stored as (small) files in the file system. Having a large module system with
much software preinstalled for everybody means a lot of small files which will make
our Lustre file system very unhappy.
Fortunately Lmod does use caches by default. On LUMI we currently have no 
system cache and only a user cache. That cache can be found in `$HOME/.cache/lmod`
(and in some versions of LMOD in `$HOME/.lmod.d/.cache`). 

That cache is also refreshed automatically every 24 hours. You'll notice when this happens as,
e.g., the `module spider` and `module available` commands will be slow during the rebuild.
you may need to clean the cache after installing new software as on LUMI Lmod does not
always detect changes to the installed software,

Sometimes you may have to clear the cache also if you get very strange answers from 
`module spider`. It looks like the non-standard way in which the HPE Cray Programming
Environment does certain things in Lmod can cause inconsistencies in the cache.
This is also one of the reasons why we do not yet have a central cache for that 
software that is installed in the central stacks as we are not sure when that cache is
in good shape.


## A note on other commands

<figure markdown style="border: 1px solid #000">
  ![A note on other commands](https://465000095.lumidata.eu/training-materials-web/intro-evolving/img/LUMI-BE-Intro-evolving-04-Modules/NoteOtherCommands.png)
</figure>

As this tutorial assumes some experience with using modules on other clusters, we haven't paid
much attention to some of the basic commands that are mostly the same across all three
module environments implementations. 
The `module load`, `module unload` and `module list` commands work largely as you would expect,
though the output style of `module list` may be a little different from what you expect.
The latter may show some inactive modules. These are modules that were loaded at some point,
got unloaded when a module closer to the root of the hierarchy of the module system got unloaded,
and they will be reloaded automatically when that module or an equivalent (family or name) module
is loaded that makes this one or an equivalent module available again.

!!! Example 
    To demonstrate this, try in a fresh login shell (with the lines starting with a `$` the commands that you should
    enter at the command prompt):

    ```
    $ module unload craype-network-ofi

    Inactive Modules:
      1) cray-mpich

    $ module load craype-network-ofi

    Activating Modules:
      1) cray-mpich/8.1.29
    ```

    The `cray-mpich` module needs both a valid network architecture target module to be loaded
    (not `craype-network-none`) and a compiler module. Here we remove the network target module
    which inactivates the `cray-mpich` module, but the module gets reactivated again as soon
    as the network target module is reloaded.

The `module swap` command is basically equivalent to a `module unload` followed by a `module load`. 
With one argument it will look for a module with the same name that is loaded and unload that one 
before loading the given module. With two modules, it will unload the first one and then load the
second one. The `module swap` command is not really needed on LUMI as loading a conflicting module
(name or family) will automatically unload the previously loaded one. However, in case of replacing 
a module of the same family with a different name, `module swap` can be a little faster than just
a `module load` as that command will need additional operations as in the first step it will 
discover the family conflict and then try to resolve that in the following steps (but explaining
that in detail would take us too far in the internals of Lmod).


## Links

**These links were OK at the time of the course. This tutorial will age over time though
and is not maintained but may be replaced with evolved versions when the course is organised again,
so links may break over time.**

-   [Lmod documentation](https://lmod.readthedocs.io/en/latest/) and more specifically
    the [User Guide for Lmod](https://lmod.readthedocs.io/en/latest/010_user.html) which is the part specifically for regular users who do not
    want to design their own modules.
-   [Information on the module environment in the LUMI documentation](https://docs.lumi-supercomputer.eu/runjobs/lumi_env/Lmod_modules/)


## Local materials

-   VSC
   
    -   VSC@UAntwerpen: Modules are covered in the [HPC@UAntwerp introduction](https://www.uantwerpen.be/en/research-facilities/calcua/training/)

    -   VSC@VUB: Modules are covered in the [HPC Introduction course](https://hpc.vub.be/docs/slides/hpc-intro/),
  
        with local documentation in the ["Module System" section of the documentation](https://hpc.vub.be/docs/software/modules/)

    -   VSC@UGent: Modules are briefly coverd in the "Introduction to HPC-UGent" course. The Lmod setup on the
        clusters at UGent is more restrictive than on LUMI with several usefull features disabled.

        -   [Slides](https://www.ugent.be/hpc/en/training/2024/introduction-to-hpc-ugent-2024-09-20.pdf) and [YouTube recording](https://www.ugent.be/hpc/en/training/introhpcugent-recording)
            of the September 20, 2024 session.

    -   VSC@KULeuven: Modules are discussed in the [Linux for HPC course](https://hpcleuven.github.io/Linux-for-HPC/)

-   CÉCI: 

    -   [Choosing and activating software with system modules on CÉCI clusters](https://indico.cism.ucl.ac.be/event/121/contributions/58/)
        from the fall 2022 introductory courses.

    -   [YouTube video: Modules: How to find/use software on cluster](https://www.youtube.com/watch?v=4hq8jcy2k3Q)
        from the fall 2020 introductory courses.

