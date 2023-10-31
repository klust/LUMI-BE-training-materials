# Getting Access to LUMI

## Who pays the bills?

<figure markdown style="border: 1px solid #000">
  ![Slide Who pays the bills](https://465000095.lumidata.eu/training-materials-web/intro-202310xx/img/LUMI-BE-Intro-202310XX-03-access/WhoPays.png){ loading=lazy }
</figure>

LUMI is one of the larger EuroHPC supercomuters. EuroHPC currently funds 
[supercomputers in three different clases](https://eurohpc-ju.europa.eu/supercomputers/our-supercomputers_en):

1.  There are a number of so-called petascale supercomputers. The first ones of those are
    Meluxina (in Luxembourg), VEGA (in Slovenia), Karolina (in the Czech Republic) and 
    Discoverr (ikn Bulgaria), with Deucalion (in Portugal) under construction.

2.  A number of pre-exascale supercomputers, LUMI being one of them. The other two are Leonardo (in Italy)
    and MareNostrum 5 (in Spain and still under construction)

3.  A decision has already been taken on two exascale supercomputers: Jupiter (in Germany) and
    Jules Verne (in France).

Depending on the machine, EuroHPC pays one third up to half of the bill, while the remainder of the budget
comes from the hosting country, usually with the help of a consortium of countries.

LUMI is hosted in Finland but operated by a consortium of 10 countries, with Belgium being the third largest
contributor to LUMI and the second largest in the consortium of countries. The Belgian contribution is
brought together by 4 entities:

1.  BELSPO, the science agency of the Federal government, invested 5M EURO in the project.
2.  The SPW Économie, Empoli, Recherche from Wallonia also invested 5M EURO in the project.
3.  The Depertment of Economy, Science and Innovation (EWI) of the Flemish government invested 3.5M EURO in the project.
4.  Innoviris (Brussels) invested 2M EURO.

The resources of LUMI are allocated proportional to the investments. As a result EuroHPC can allocate half
of the resources. The Belgian share is approximately 7.4%.

Each LUMI consortium country can set its own policies for a national access program, within the limits of
what the supercomputer can technically sustain. In Belgium, the 4 entities that invested in LUMI do so together.
The access conditions for projects in the Belgian share are advertised via the 
[EuroCC Belgium National Competence Centre](https://www.enccb.be/GettingAccess).

Web links:

-   [EuroHPC JU supercomputers](https://eurohpc-ju.europa.eu/supercomputers/our-supercomputers_en)
-   [EuroCC Belgium National Competence Centre](https://www.enccb.be/)
    with the [specifics of LUMI access via the Belgian share](https://www.enccb.be/GettingAccess).


## Users and projects

<figure markdown style="border: 1px solid #000">
  ![Slide Projects and users 1](https://465000095.lumidata.eu/training-materials-web/intro-202310xx/img/LUMI-BE-Intro-202310XX-03-access/ProjectsUsers_1.png){ loading=lazy }
</figure>

LUMI works like most European large supercomputers: Users are members of projects.

A project corresponds to a coherent amount of work that is being done by a single person or a collaboration
of a group of people. It typically corresponds to a research project, though there are other project types also,
e.g., to give people access in the context of a course, or for organisational issues, e.g., a project for VSC support.
Most projects are short-lived, with a typical duration of 4 to 6 months for benchmarking projects or one year for a 
regular project.

Projects are also the basis for most research allocations on LUMI. In LUMI there are three types of resource allocations,
and each project needs at least two of them:

1.  A compute budget for the CPU nodes of LUMI (LUMI-C), expressed in core-hours.
2.  A compute budget for the GPU nodes of LUMI (LUMI-G), expressed in GPU-hours. As the mechanism was
    already fixed before it became publically known that for all practical purposes one AMD MI250X GPU
    should really be treated as 2 GPUs, one GPU-hour is one hour on a full MI250X, so computing for one
    hour on a full LUMI-G GPU node costs 4 GPU-hours.
3.  A storage budget which is expressed in TB-hours. Only storage that is actually being used is charged
    on LUMI, to encourage users to clean up temporary storage. The rate at which storage is charged depends
    on the file system:

    1.  Storing one TB for one hour on the disk based Lustre file systems costs 1 TB-hour.
    2.  Storing one TB for one hour on the flash based Lustre file system costs 10 TB-hour, also reflecting
        the purchase cost difference of the systems.
    3.  Storing one TB for one hour on the object based file system costs 0.5 TB-hour.

These budgets are assigned and managed by the resource allocators, not by the LUMI User Support Team.
For Belgium the VSC and CÉCI both have the role of resource allocator, but both use a common help desk.

LUMI projects will typically have multiple project numbers which may be a bit confusing:

1.  Each RA may have its own numbering system, often based on the numbering used for the project
    requests. Note that the LUMI User Support Team is not aware of that numbering as it is purely
    internal to the RA.
2.  Each project on LUMI also gets a LUMI project ID which also corresponds to a Linux group to manage
    access to the project resources. These project IDs are of the form `project_465XXXXXX` for most
    projects but `project_462XXXXXX` for projects that are managed by the internal system of 
    CSC Finland. 
    
    **This is also the project number that you should mention when contacting the 
    central LUMI User Support.**


<figure markdown style="border: 1px solid #000">
  ![Slide Projects and users 2](https://465000095.lumidata.eu/training-materials-web/intro-202310xx/img/LUMI-BE-Intro-202310XX-03-access/ProjectsUsers_2.png){ loading=lazy }
</figure>

Besides projects there are also user accounts. 
Each user account on LUMI corresponds to a physical person, and user accounts should
not be shared. Some physical persons have more than one user account but this is an
unfortunate consequence of decisions made very early in the LUMI project about how projects on
LUMI would be managed. Users themselves cannot do a lot without a projects as all a user
has on LUMI is a small personal disk space which is simply a Linux requirement. 
To do anything useful on LUMI users need to be member of a project.
There is some discussion about special "robot accounts" for special purposes 
that would not correspond to a physical person but have a specific goal 
(like organising data ingestion from an external source) but those
do not yet exist.

There ia a many-to-may mapping between projects and user accounts.
Projects can of course have multiple users who collaborate in the project, but a user account
can also be part of multiple projects. The latter is more common than
you may think, as. e.g., you may become member of a training project when
you take a LUMI training.

Most resources are attached to projects. The one resource that is attached to a user account
is a small home directory to store user-specific configuration files. That home directory
is not billed but can also not be extended. For some purposes you may have to store things
that would usually be automatically be placed in the home directory in a separate directory,
e.g., in the project scratch space, and link to it. This may be the case when you try to convert
big docker containers into singularity containers as the singularity cache can eat a lot of
disk space.


## Project management

<figure markdown style="border: 1px solid #000">
  ![Slide Project Management](https://465000095.lumidata.eu/training-materials-web/intro-202310xx/img/LUMI-BE-Intro-202310XX-03-access/ProjectManagement.png){ loading=lazy }
</figure>

A large system like LUMI with many entities giving independent access to the system to users 
needs an automated system to manage those projects and users. There are two such systems
for LUMI. CSC, the hosting institution from Finland, uses its own internal system to manage
projects allocated on the Finnish national share. This system manages the "642"-projects.
The other system is called Puhuri and is developed in a collaboration between the Nordic countries
to manage more than just LUMI projects. It can be used to manage multiple supercomputers
but also to manage access to other resources such as experimental equipment. 
Puhuri projects can span multiple resources (e.g., multiple supercomputers so that you can
create a workflow involving Tier-2, Tier-1 and Tier-0 resources).

In Belgium two entities manage projects for the Belgian LUMI organisation: VSC and CÉCI.
These entities are called the resource allocators.

All projects allocated by Belgium ara managed through the Puhuri system, and VSC and CÉCI 
both have their own zone in that system. For Belgium it is only used to manage access to LUMI,
not to any of the VSC, CÉCI or Ceanero systems or other infrastructure.
Belgian users log in to the Puhuri portal via MyAccessID, which is a GÉANT service. GÉANT is 
the international organisation that manages the research network in Europe. 
MyAccessID then in turn connects to your institute identity provider and a number of alternatives.
It is important that you always use the same credentials to log in via MyAccessID, otherwise
you create another user in MyAccessID that is unknown to Puhuri and get all kinds of strange
error messages.

The URL to the Puhuri portal is: [puhuri-portal.neic.no](https://puhuri-portal.neic.no/).

Puhuri can be used to check your remaining project resources, but once your user account 
on LUMI is created it is very easy to do this on the command line with the
`lumi-workspaces` command.

Web links

-   [Puhuri documentation](https://puhuri.neic.no/), look for the "User Guides".
    Resource allocations done by VSC or CÉCI are managed via a
    [shared puhuri portal](https://puhuri.neic.no/user_guides/user_guide_shared/organization_and_project_management_shared/),
    though we recommend having a look at the 
    ["New interface" documentation](https://puhuri.neic.no/user_guides/new_interface/interface/).
-   The `lumi-workspaces` command is provided through the [`lumi-tools module]](https://lumi-supercomputer.github.io/LUMI-EasyBuild-docs/l/lumi-tools/#lumi-workspaces)
    which is loaded by default. The command will usually give the output you need when used
    without any argument.


## File spaces

<figure markdown style="border: 1px solid #000">
  ![Slide File spaces 1](https://465000095.lumidata.eu/training-materials-web/intro-202310xx/img/LUMI-BE-Intro-202310XX-03-access/FileSpaces_1.png){ loading=lazy }
</figure>

LUMI has file spaces that are linked to a user account and file spaces that are linked to projects.

The only permanent file space linked to a user account is the home directory which is of the form
`/users/<my_uid>`. It is limited in both size and number of files it can contain, and neither limit
can be expanded. It should only be used for things that are not project-related and first and
foremost for those things that Linux and software automatically stores in a home directory like
user-specific software configuration files. It is not billed as users can exist temporarily without
an active project but therefore is also very limited in size.

Each project also has 4 permanent or semi-permanent file spaces that are all billed against the
storage budget of the project.

1.  Permanent (for the duration of the project) storage on a hard disk based Lustre filesystem
    accessed via `/project/project_46yXXXXXX`. This is the place to perform the software installation
    for the project (as it is assumed that a project is a coherent amount of work it is only 
    natural to assume that everybody in the project needs the same software), or to store input data
    etc. that will be needed for the duration of the project.

2.  Semi-permanent scratch storage on a hard disk based Lustre filesystem accessed via
    `/scratch/project_46YXXXXXX`. Files in this storage space can in principle be erased 
    automatically after 90 days. This is not happening yet on LUMI, but will be activated if
    the storage space starts to fill up.

3.  Semi-permanent scratch storage on an SSD based Lustre filesystem accessed via
    `/flash/project_46YXXXXXX`. Files in this storage space can in principle be erased
    automatically after 30 days. This is not happening yet on LUMI, but will be activated if
    the scratch storage space starts to fill up.

4.  Permanent (for the duration of the project) storage on the hard disk based
    object filesystem.


<figure markdown style="border: 1px solid #000">
  ![Slide File spaces 1](https://465000095.lumidata.eu/training-materials-web/intro-202310xx/img/LUMI-BE-Intro-202310XX-03-access/FileSpaces_2.png){ loading=lazy }
</figure>

The use of space in each file space is limited by block and file quota. Block quota limit the
capacity you can use, while file quota limit the number of so-called inodes you can use. Each file,
each subdirectory and each link use an inode.
As we shall see later in this course or as you may have seen in other HPC courses already
(e.g., the VSC "Supercomputers for Starters" course organised by UAntwerpen),
parallel file systems are not build to deal with hundreds of thousands of small files and are
very inefficient at that. Therefore block quota on LUMI tend to be rather flexible (except for
the home directory) but file quota are rather strict and will not easily get extended.
Software installations that require tens of thousands of small files should be done in 
containers (e.g., conda installations or any big Python installation) while data should also
be organised in proper file formats rather than being dumped on the file system abusing the file
system as a database.
Quota extensions are currently handled by the central LUMI User Support Team.

**So storage billing units come from the RA, quota come from the LUMI User Support Team!**

LUMI has four disk based Lustre file systems that house `/users`, `/project` and `/scratch`.
The `/project` and `/scratch` directories of your project will always be on the same parallel
file system, but your home directory may be on a different one. Both are assigned automatically
suring project and account creation and these assignements cannot be changed by the LUMI User Support Team.
As htere is a many-to-may mapping between user accounts and projects it is not possible to
ensure that user accounts are on the same file system as their main project. In fact, many users
enter LUMI for the first time through a course project and not through one of their main compute
projects...

It is important to note that even though `/flash` is SSD based storage, it is still a parallel file 
system and will not behave the way an SSD in your PC does. The cost of opening and closing a file
is still very high due to it being both a networked and a parallel file system rather than a
local drive. In fact, the cost for metadata operations is similar as on the hard disk based
parallel file systems as both use SSDs to store the metadata. Once a file is opened and with
a proper data access pattern (big accesses, properly striped files which we will discuss later
in this course) the flash file system can give a lot more bandwidth than the disk based ones.

It is important to note that LUMI is not a data archiving service. "Permanent" in the
above discussion only means "for the duration of the project". There is no backup, not even
of the home directory. And three months after the end of the project all data from the
project is irrevocably deleted from the system. User accounts without project will also
be closed, as will user accounts that remain inactive for several months, even if an
active project is still attached to them.

If you run out of storage billing units, access to the job queues or even to the storage 
can be blocked and you should contact your resource allocator for extra billing units.
Our experience within Belgium is that projects tend to heavily under-request storage
billing units. It is important that you clean up after a run as LUMI is not meant for
long-term data archiving. But at the same time it is completely normal that you cannot do 
so right after a run, so data from a run has to stay on the system for a few days or weeks,
and you need to budget for that in your project request.

Web links:

-   [Overview of storage systems on LUMI](https://docs.lumi-supercomputer.eu/storage/)
-   [Billing policies (includes those for storage)](https://docs.lumi-supercomputer.eu/runjobs/lumi_env/billing/#storage-billing)

## Access

<figure markdown style="border: 1px solid #000">
  ![Slide Access](https://465000095.lumidata.eu/training-materials-web/intro-202310xx/img/LUMI-BE-Intro-202310XX-03-access/Access.png){ loading=lazy }
</figure>

LUMI currently has 4 login nodes through which users can enter the system via key-based ssh.
The generic name of those login nodes is `lumi.csc.fi`. Using the generic names will put you
onto one of the available nodes more or less at random and will avoid contacting a login node
that is down for maintenance. However, in some cases one needs to enter a specific login node. 
E.g., tools for remote editing or remote file synchronisation such as Visual Studio Code or Eclipse 
usually don't like it if they get a different node every time they try to connect, e.g., because 
they may start a remote server and try to create multiple connections to that server.
In that case you have to use a specific login node, which you can do through the names
`lumi-uan01.csc.fi` up to `lumi-uan04.csc.fi`. 
(UAN is the abbreviation for User Access Node, the term Cray uses for login nodes.)

Key management is for most users done via MyAccessID: [mms.myaccessid.org](https://mms.myaccessid.org/).
This is the case for all user accounts who got their first project on LUMI via Puhuri, which is the case for
almost all Belgian users. User accounts that were created via the My CSC service have to use
the [my.csc.fi](https://my.csc.fi/) portal to manage their keys. It recently became possible to link
your account in My CSC to MyAccessID so that you do not get a second account on LUMI ones you join a 
Puhuri-managed project, and in this case your keys are still managed through the My CSC service.
But this procedure is only important for those LUMI-BE users who may have gotten their first access 
to LUMI via a project managed by CSC.

There is currently not much support for GUI applications on LUMI. 
Running X11 over ssh (via `ssh -X`) is unbearibly slow for users located in Belgium. 
The alternative is some support offered for VNC, though the window manager and fonts used by
the server do look a little dated. Access is possible via a browser or VNC client. 
On the system, check for the 
[`lumi-vnc` module](https://lumi-supercomputer.github.io/LUMI-EasyBuild-docs/l/lumi-vnc/).

In the future we plan to provide a web interface via Open OnDemand, but there is no date set yet
for availability. The setup of Open OnDemand is not as easy as many would like you to believe as 
the product does suffer from a number of security issues and needs to be linked to multiple 
authentication services.

Web links:

-   [LUMI documentation on logging in to LUMI and creating suitable SSH keys](https://docs.lumi-supercomputer.eu/firststeps/)
-   [CSC documentation on linking My CSC to MyAccessID](https://docs.csc.fi/accounts/how-to-manage-user-information/)


## Data transfer

<figure markdown style="border: 1px solid #000">
  ![Slide Access](https://465000095.lumidata.eu/training-materials-web/intro-202310xx/img/LUMI-BE-Intro-202310XX-03-access/DataTransfer.png){ loading=lazy }
</figure>

There are currently two main options to transfer data to and from LUMI.

The first one is to use sftp to the login nodes, authenticating via your ssh key. 
There is a lot of software available for all major operating systems, both command line
based and GUI based. The sftp protocol can be very slow over high latency connections.
This is because it is a protocol that opens only a single stream for communication
with the remote host, and the bandwidth one can reach via a single stream in the 
TCP network protocol used for such connections, is limited not only by the bandwidth of
all links involved but also by the latency. After sending a certain amount of data, the
sender will wait for a confirmation that the data has arrived, and if the latency is
hight, that confirmation takes more time to reach the sender, limiting the effective
bandwidth that can be reached over the connection. LUMI is not to blame for that;
the whole path from the system from which you initiate the connection to LUMI
is responsible and every step adds to the latency. We've seen many cases where the
biggest contributor to the latency was actually the campus network of the user.

The second important option is to transfer data via the object storage system LUMI-O.
To transfer data to LUMI, you'd first push the data to LUMI-O and then on LUMI pull it 
from LUMI-O. When transferring data to your home institute, you'd first push it onto
LUMI-O from LUMI and then pull the data from LUMI-O to your work machine. 
LUMI offers some support for various tools, including 
[rclone](https://rclone.org/)
and [S3cmd](https://s3tools.org/s3cmd).
There also exist many GUI clients to access object storage. 
Even though in principle any tool that can connect via the S3 protocol can work,
the LUMI User Support Team nor the local support in Belgium can give you instructions
for every possible tool. 
Those tools for accessing object storage tend to set up multiple data streams and hence
will offer a much higher effective bandwidth, even on high latency connections.
These tools work with keys which are different from SSH keys and temporary in nature.
They can be obtained from [auth.lumidata.eu](https://auth.lumidata.eu) where you need
to log in either via MyAccessID (if your project is managed through Puhuri) or your
"My CSC" account (if your project is managed via that platform).

Alternatively, you can also chose to access external servers from LUMI if you have client
software that runs on LUMI (or if that software is already installed on LUMI, e.g., rclone
and S3cmd),

Unfortunately there is no support yet for Globus or other forms of gridFTP. 

Web links:

-   [Documentation for the LUMI-O object storage service](https://docs.lumi-supercomputer.eu/storage/)
-   Software for LUMI-O on LUMI is provided throug the
    [`lumio` module](https://lumi-supercomputer.github.io/LUMI-EasyBuild-docs/l/lumio/) which
    provides the configuration tool on top of the software and the
    [`lumio-ext-tools` module](https://lumi-supercomputer.github.io/LUMI-EasyBuild-docs/l/lumio-ext-tools/)
    providing rclone, S3cmd and restic and links to the documentation of those tools.

    -   [rclone documentation](https://rclone.org/docs/)
    -   [S3cmd tools usage](https://s3tools.org/usage)
    -   [restic documentation](https://restic.readthedocs.io/en/latest/)


## Local trainings

Any HPC introductory training in Belgium covers logging in via ssh and transferring files.
Such a course is a prerequisite for this section.
