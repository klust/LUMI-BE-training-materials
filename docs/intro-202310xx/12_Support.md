# How to get support and documentation

See [the slides (PDF)](https://465000095.lumidata.eu/intro-202310xx/files/LUMI-BE-Intro-202310XX-09-Lumi-support.pdf).

**Notes under development.**

## Distributed nature of LUMI support

<figure markdown style="border: 1px solid #000">
  ![Distributed nature of support (1)](https://465000095.lumidata.eu/training-materials-web/intro-202310xx/img/LUMI-BE-Intro-202310XX-12-support/DistributedNature1.png){ loading=lazy }
</figure>

<figure markdown style="border: 1px solid #000">
  ![Distributed nature of support (2)](https://465000095.lumidata.eu/training-materials-web/intro-202310xx/img/LUMI-BE-Intro-202310XX-12-support/DistributedNature2.png){ loading=lazy }
</figure>

User support for LUMI comes from several parties. Unfortunately, as every participating consortium countries
has some responsibilities also and solves things differently, there is no central point where you can go
with all questions.

Resource allocators work independently from each other and the central LUMI User Support Team. This also 
implies that they are the only ones who can help you with questions regarding your allocation: How to apply
for compute time on LUMI, add users to your project, running out of resources (billing units) for your project, failure
to even get access to the portal managing the allocations given by your resource allocator (e.g., because
you let expire an invite), ... 
For projects allocated in the Belgian allocation, help can be requested via the email address
lumi-be-support@enccb.be. However, we cannot help you with similar problems for compute time directly 
obtained via EuroHPC.
For granted EuroHPC projects, support is available via lumi-customer-accounts@csc.fi.
<!-- TODO: How to get help for EuroHPC? -->

The central LUMI User Support Team (LUST) offers L1 and basic L2 support. 
Given that the LUST team is very small compared to the number of project granted annually on LUMI 
(roughly 10 FTE for on the order of 700 projects per year, and support is not their only task),
it is clear that the amount of support they can give is limited. 
E.g., don't expect them to install all software you request for them. There is simply too much
software and too much software with badly written install code to do that with that number
of people. Nor should you expect domain expertise from them. Though several members of the LUST
have been scientist before, it does not mean that they can understand all scientific problems thrown
at them or all codes used by users. Also, the team cannot fix bugs for you in the codes that you use,
and usually not in the system code either. For fixing bugs in HPE or AMD-provided software, they are
backed by a team of experts from those companies. However, fixing bugs in compilers or libraries 
and implementing those changes on the system takes
time.
The system software on a big shared machine cannot be upgraded as easily as on a personal workstation.
Usually you will have to look for workarounds, or if they show up in a preparatory project,
postpone applying for an allocation until all problems are fixed.

In Flanders, the VSC has a Tier-0 support project to offer more advanced L2 and some L3 support.
The project unfortunately is not yet fully staffed.
VSC Tier-0 support can be contacted via the LUMI-BE help desk at lumi-be-support@enccb.be (the same
help desk that you need to contact for allocation problems).

In the Walloon region, there is some limited advanced support via Orian Louant. However, this is only a part of
all his tasks. Here also the lumi-be-support@enccb.be mail address can be used.

EuroHPC has also granted the EPICURE project that starts in February 2024 to set up a network for
advanced L2 and L3 support across EuroHPC centres. Belgium also participates in that project as a partner
in the LUMI consortium. However, this project is also so small that it will have to select the problems
they tackle.

In principle the EuroHPC Centres of Excellence should also play a role in porting some applications in their
field of expertise and offer some support and training, but so far especially the support and training are
not yet what one would like to have.

Basically given the growing complexity of scientific computing and diversity in the software field, what one
needs is the equivalent of the "lab technician" that many experimental groups have who can then work with 
various support instances, a so-called [Research Software Engineer](https://researchsoftware.org/)...


## Support level 0: Help yourself!

Support starts with taking responsibility yourself and use the available sources of information
before contacting support. Support is not meant to be a search assistant for already available 
information.

The LUMI User Support Team has prepared trainings and a lot of documentation about LUMI.
Good software packages also come with documentation, and usually it is possible to find trainings for 
major packages. And a support team is also not there to solve communication problems in the 
team in which you collaborate on a project!


### Take a training!

<figure markdown style="border: 1px solid #000">
  ![L0 support: Take a training!](https://465000095.lumidata.eu/training-materials-web/intro-202310xx/img/LUMI-BE-Intro-202310XX-12-support/L0Training.png){ loading=lazy }
</figure>

There exist system-specific and application-specific trainings. 
Ideally of course a user would want a one-step solution, having a specific training for a specific application on
a specific system (and preferably with the workflow tools they will be using, if any), but that is simply
not possible. The group that would be interested in such a training is for most packages too small, and
it is nearly impossible to find suitable teachers for such course given the amount of expertise that is needed
in both the specific application and the specific system. It would also be hard to repeat such a training
with a high enough frequency to deal with the continuous inflow of new users.

The LUMI User Support Team organises 2 system-specific trainings:

1.  There is a 1-day introductory course entirely given by members of the LUST.
    The training does assume familiarity with HPC systems, e.g., obtained from the introductory
    courses taught by [VSC](https://www.vscentrum.be/vsctraining) and
    [CÉCI](https://www.ceci-hpc.be/training.html).

2.  And there is a 4-day comprehensive training with more attention on how to run efficiently, and on the
    development and profiling tools. Even if you are not a developer, you may benefit from more knowledge
    about these tools as especially a profiler can give you insight in why your application does not run
    as expected.

This training builds upon the 1-day LUMI training offered by the LUST, but has been enriched with 
links to the situation specifically in Belgium.

Application-specific trainings should come from other instances though that have the necessary domain
knowledge: Groups that develop the applications, user groups, the EuroHPC Centres of Excellence, ...

Currently the training landscape in Europe is not too well organised. EuroHPC is starting some new
training initiatives to succeed the excellent PRACE trainings.
Moreover, the centre coordinating the National Competence Centres also 
[tries to maintain an overview of available trainings](https://www.eurocc-access.eu/services/training/)
(and several National Competence Centres organise trainings open to others also).


### Read/search the documentation

<figure markdown style="border: 1px solid #000">
  ![L0 support: Check the docs! (1)](https://465000095.lumidata.eu/training-materials-web/intro-202310xx/img/LUMI-BE-Intro-202310XX-12-support/L0ReadTheDocs1.png){ loading=lazy }
</figure>

<figure markdown style="border: 1px solid #000">
  ![L0 support: Check the docs! (2)](https://465000095.lumidata.eu/training-materials-web/intro-202310xx/img/LUMI-BE-Intro-202310XX-12-support/L0ReadTheDocs2.png){ loading=lazy }
</figure>

The LUST has developed extensive documentation for LUMI. That documentation is split in two parts:

1.  The [main documentation at docs.lumi-supercomputer.eu](https://docs.lumi-supercomputer.eu/)
    covers the LUMI system itself and includes topics such as how to get on the 
    system, where to place your files, how to start jobs, how to use the programming environment,
    how to install software, etc.

2.  The [LUMI Software Library](https://lumi-supercomputer.github.io/LUMI-EasyBuild-docs/) contains
    an overview of software pre-installed on LUMI or for which we have install recipes to start from.
    For some software packages, it also contains additional information on how to use the software
    on LUMI.

    That part of the documentation is generated automatically from information in the various repositories
    that are used to manage those installation recipes. It is kept deliberately separate, partly to have
    a more focused search in both documentation systems and partly because it is managed and updated
    very differently.

Both documentation systems contain a search box which may help you find pages if you cannot find them 
easily navigating the documentation structure. E.g., you may use the search box in the LUMI Software Library
to search for a specific package as it may be bundled with other packages in a single module with a 
different name. E.g., try searching for the `htop` command.


### Talk to your colleagues

<figure markdown style="border: 1px solid #000">
  ![L0 support: Talk to your colleagues](https://465000095.lumidata.eu/training-materials-web/intro-202310xx/img/LUMI-BE-Intro-202310XX-12-support/L0Colleagues.png){ loading=lazy }
</figure>

A LUMI project is meant to correspond to a coherent research project in which usually multiple
people collaborate. 

This implies that your colleagues may have run in the same problem and may already have a solution,
or they didn't even experience it as a problem and know how to do it. So talk to your colleagues first.

Support teams are not meant to deal with your team communication problems. There is nothing worse than
having the same question asked multiple times from different people in the same project.
As a project does not have a dedicated support engineer, the second time a question is asked it may
land at a different person in the support team so that it is not recognized that the question has been asked
already and the answer is readily available, resulting in a loss of time for the support team and other,
maybe more important questions, remaining unanswered. 
Similarly bad is contacting multiple help desks with the same question without telling them, as that will
also duplicate efforts to solve a question. We've seen it often that users contact both a local help desk
and the LUST help desk without telling.

Resources on LUMI are managed on a project basis, not on a user-in-project basis, so if you want to know what
other users in the same project are doing with the resources, you have to talk to them and not to the LUST.
We do not have systems in place to monitor use on a per-user, per-project basis, only on a per-project basis,
and also have no plans to develop such tools as a project is meant to be a close collaboration of all
involved users. 


## L1 and basic L2 support: LUST

<figure markdown style="border: 1px solid #000">
  ![L1 and basic L2: LUST (1)](https://465000095.lumidata.eu/training-materials-web/intro-202310xx/img/LUMI-BE-Intro-202310XX-12-support/LUST1.png){ loading=lazy }
</figure>

<figure markdown style="border: 1px solid #000">
  ![L1 and basic L2: LUST (2)](https://465000095.lumidata.eu/training-materials-web/intro-202310xx/img/LUMI-BE-Intro-202310XX-12-support/LUST2.png){ loading=lazy }
</figure>

<figure markdown style="border: 1px solid #000">
  ![L1 and basic L2: LUST (3)](https://465000095.lumidata.eu/training-materials-web/intro-202310xx/img/LUMI-BE-Intro-202310XX-12-support/LUST3.png){ loading=lazy }
</figure>

The LUMI User Support Team is responsible for providing L1 and basic L2 support to users of the system.
Their work starts from the moment that you have userid on LUMI (the local RA is responsible for ensuring
that you get a userid when a project has been assigned).

The LUST is a distributed team roughly 10 FTE strong, with people in all LUMI consortium countries,
but they work as a team, coordinated by CSC. The Belgian contribution currently consists of two people
both working half time for LUMI and half time for user support in their own organisation (VSC and CÉCI).
However, you will not necessarily be helped by one of the Belgian team members when you contact LUST, but
by the team member who is most familiar with your problem. 

There are some problems that we need to pass on to HPE or AMD, particularly if it may be caused by 
bugs in system software, but also because they have more experts with in-depth knowledge of very specific
tools. 

The LUMI help desk is staffed from Monday till Friday between 8am and 6pm Brussels time (except on public holidays
in Finland). You can expect a same day first response if your support query is well formulated and submitted long
enough before closing time, but a full solution of your problem may of course take longer, depending on how busy
the help desk is and the complexity of the problem.

Data security on LUMI is very important. Some LUMI projects may host confidential data, and especially industrial
LUMI users may have big concerns about who can access their data. 
Therefore only very, very few people on LUMI have the necessary rights to access user data on the system,
and those people even went through a background check. The LUST members do not have that level of access,
so we cannot see your data and you will have to pass all relevant information to the LUST through other means!

The LUST help desk should be contacted through 
[web forms in the "User Support - Contact Us" section of the main LUMI web site](https://lumi-supercomputer.eu/user-support/need-help/).
The page is also linked from the ["Help Desk" page in the LUMI documentation](https://docs.lumi-supercomputer.eu/helpdesk/).
These forms help you to provide more information that we need to deal with your support request.
Please do not email directly to the support web address (that you will know as soon as we answer at ticket as that
is done through e-mail).
Also, separate issues should go in separate tickets so that separate people in the LUST can deal with them,
and you should not reopen an old ticket for a new question, also because then only the person who dealt with
the previous ticket gets notified, and they may be on vacation or even not work for LUMI anymore, so your new
request may remain unnoticed for a long time.


## Links

-   LUMI web sites

    -   The [main LUMI web site](https://lumi-supercomputer.eu/) contains very general information about
        LUMI and also has a section in which the trainings organised by the LUST and some other trainings
        are announced. It is also the starting point to contact the LUST with your support questions via
        web forms. The web forms assure that we have the necessary information to start investigating your 
        issues.

        Note that when the support form asks for a project number, this is the project number on LUMI 
        (of the form 465XXXXXX for most projects) and not
        the project number used in LUMI-BE or EuroHPC, as the LUST does not know these numbers.

    -   The [LUMI documentation](https://docs.lumi-supercomputer.eu/)
        covers the LUMI system itself and includes topics such as how to get on the 
        system, where to place your files, how to start jobs, how to use the programming environment,
        how to install software, etc.

        This is your primary source of information when you are investigating if LUMI might be suitable
        for you, or once you have obtained a project on LUMI.

    -   The [LUMI Software Library](https://lumi-supercomputer.github.io/LUMI-EasyBuild-docs/) contains
        an overview of software pre-installed on LUMI or for which we have install recipes to start from.
        For some software packages, it also contains additional information on how to use the software
        on LUMI.

-   Web sites in Belgium:

    -   The [EuroCC Belgium web site](https://www.enccb.be/) announced most local and LUST LUMI trainings
        in [the "Trainings" section](https://www.enccb.be/training)
        and also contains information on 
        [how to apply for compute time on LUMI via the Belgian share](https://www.enccb.be/GettingAccess).

    -   The [VSC web site](https://www.vscentrum.be/).
        Several [VSC trainings](https://www.vscentrum.be/vsctraining) are also relevant for (future) LUMI users!

        The VSC [Supercomputers for Starters](https://www.uantwerpen.be/en/research-facilities/calcua/training/) course
        lectured at UAntwerpen also covers several topics that are even more relevant to LUMI than to the
        Tier-2 systems of VSC and CÉCI. 
        [Full course notes are available](https://klust.github.io/SupercomputersForStarters/),
        so you can have a look at the material if you have no time to join the lectures (twice a year).

    -   The [CÉCI web site](https://www.ceci-hpc.be/).
        Several [CÉCI trainings](https://www.ceci-hpc.be/training.html) are also relevant for (future) LUMI users!

-   These course notes also contain a
    [page with links into technical documentation](A02_Documentation.md)
    of the scheduler and the programming environments on LUMI, and links to the user documentation
    of some similar systems.
