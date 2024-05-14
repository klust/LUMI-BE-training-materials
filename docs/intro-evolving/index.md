# LUMI introductory training evolving version

*This document includes the base materials for the introductory training that we
provide to Belgian LUMI users. We try to evolve it as soon as possible when
it becomes outdated due to changes on LUMI, and it is certainly more up-to-date
than any other version you may find on this site in the future.*

*Short URL: [https://klust.github.io/intro-evolving](https://klust.github.io/intro-evolving).*

<!--
## Organisation

-   [Schedule](schedule.md)
-->

<!-- Exercises actual training session. 
## Setting up for the exercises

-   Create a directory in the scratch of the training project, or if you want to
    keep the exercises around for a while after the session and have already
    another project on LUMI, in a subdirectory or your project directory 
    or in your home directory (though we don't recommend the latter).
    Then go into that directory.

    E.g., in the scratch directory of the project:

    ```
    mkdir -p /scratch/project_465000523/$USER/exercises
    cd /scratch/project_465000523/$USER/exercises
    ```

-   Now download the exercises and un-tar:

    ```
    wget https://465000095.lumidata.eu/training-materials-web/intro-evolving/files/exercises-202310xx.tar.gz
    tar -xf exercises-20230509.tar.gz
    ```

    [Link to the tar-file with the exercises](https://465000095.lumidata.eu/training-materials-web/intro-evolving/files/exercises-20230509.tar.gz)

-   You're all set to go!
-->

## Setting up for the exercises

If you have an active project on LUMI, you should be able to make the exercises in that project.
You will only need an very minimum of CPU and GPU billing units for this.

-   Create a directory in the scratch of your project, or if you want to
    keep the exercises around for a while, in a subdirectory of your project directory 
    or in your home directory (though we don't recommend the latter).
    Then go into that directory.

    E.g., in the scratch directory of your project:

    ```
    mkdir -p /scratch/project_465XXXXXX/$USER/exercises
    cd /scratch/project_465XXXXXX/$USER/exercises
    ```

    where you have to replace `project_465XXXXXX` using the number of your own project.

-   Now download the exercises and un-tar:

    ```
    wget https://465000095.lumidata.eu/training-materials-web/intro-evolving/files/exercises-evolving.tar.gz
    tar -xf exercises-evolving.tar.gz
    ```

    [Link to the tar-file with the exercises](https://465000095.lumidata.eu/training-materials-web/intro-evolving/files/exercises-evolving.tar.gz)

-   You're all set to go!


## Downloads

| Presentation | Slides | Notes | Exercises |
|:-------------|:-------|:------|:----------|
| Notes Introduction | / | [notes](00-Introduction.md) | / |
| LUMI Architecture | [slides](https://465000095.lumidata.eu/training-materials-web/intro-evolving/files/LUMI-BE-Intro-evolving-01-Architecture.pdf) | [notes](01-Architecture.md) | / |
| HPE Cray Programming Environment | [slides](https://465000095.lumidata.eu/training-materials-web/intro-evolving/files/LUMI-BE-Intro-evolving-02-CPE.pdf) | [notes](02-CPE.md) | [exercises](E02-CPE.md) |
| Getting access to LUMI | [slides](https://465000095.lumidata.eu/training-materials-web/intro-evolving/files/LUMI-BE-Intro-evolving-03-Access.pdf) | [notes](03-Access.md) | [exercises](E03-Access.md) |
| Modules on LUMI | [slides](https://465000095.lumidata.eu/training-materials-web/intro-evolving/files/LUMI-BE-Intro-evolving-04-Modules.pdf) | [notes](04-Modules.md) | [exercises](E04-Modules.md) |
| LUMI Software Stacks | [slides](https://465000095.lumidata.eu/training-materials-web/intro-evolving/files/LUMI-BE-Intro-evolving-05-SoftwareStacks.pdf) | [notes](05-SoftwareStacks.md) | [exercises](E05-SoftwareStacks.md) |
| Slurm on LUMI | [slides](https://465000095.lumidata.eu/training-materials-web/intro-evolving/files/LUMI-BE-Intro-evolving-06-Slurm.pdf) | [notes](06-Slurm.md) | [exercises](E06-Slurm.md) |
| Binding resources | [slides](https://465000095.lumidata.eu/training-materials-web/intro-evolving/files/LUMI-BE-Intro-evolving-07-Binding.pdf) | [notes](07-Binding.md) | [exercises](E07-Binding.md) | 
| Using Lustre | [slides](https://465000095.lumidata.eu/training-materials-web/intro-evolving/files/LUMI-BE-Intro-evolving-08-Lustre.pdf) | [notes](08-Lustre.md) | / |
| Containers on LUMI | [slides](https://465000095.lumidata.eu/training-materials-web/intro-evolving/files/LUMI-BE-Intro-evolving-09-Containers.pdf) | [notes](09-Containers.md) | / |
| Container demo 1 | / | [notes](Demo1.md) | [video](Demo1.md#video-of-the-demo) |
| Container demo 2 | / | [notes](Demo2.md) | [video](Demo2.md#video-of-the-demo) |
| LUMI User Support | [slides](https://465000095.lumidata.eu/training-materials-web/intro-evolving/files/LUMI-BE-Intro-evolving-10-Support.pdf) | [notes](10-Support.md) | / |
| A1 Slurm issues | / | [notes](A01-SlurmIssues.md) | / | 
| A2 Additional documentation | / | [notes](A02-Documentation.md) | / | 


## Web links

-   [Links to additional HPE Cray documentation](A02-Documentation.md)

-   LUMI documentation

    -   [Main documentation](https://docs.lumi-supercomputer.eu/)

    -   [Shortcut to the LUMI Software Library](https://lumi-supercomputer.github.io/LUMI-EasyBuild-docs/)

-   Clusters in Belgium

    -   [VSC documentation](https://docs.vscentrum.be/en/latest/)

    -   [CÉCI documentation](https://support.ceci-hpc.be/doc/index.html)

    -   [Lucia@Cenaero documentation](https://doc.lucia.cenaero.be/)

-   LUMI training resources

    -   [LUMI training announcements](https://www.lumi-supercomputer.eu/events/)

    -   [LUMI training materials archive](https://lumi-supercomputer.github.io/LUMI-training-materials/)

-   Local (BE) trainings

    -   [VSC training page](https://www.vscentrum.be/vsctraining)

        -   [Local materials UAntwerpen](https://www.uantwerpen.be/en/research-facilities/calcua/training/)
  
        -   [Local materials VUB](https://hpc.vub.be/docs/training-material/)

        -   [Local materials UGent](https://www.ugent.be/hpc/en/training)

     -   [CÉCI HPC training page](https://www.ceci-hpc.be/training.html)

        Training materials of previous sessions are available via the 
        [CISM indico event management system](https://indico.cism.ucl.ac.be/category/1/). 
        For each training, go to the "Contribution List" and then to the presentation itself,
        and training materials are available at the bottom of the page.

        Recordings of several presentations are available on the 
        [CÉCI and CISM HPC YouTube Channel](https://www.youtube.com/@CECIandCISMHPC)

    -   [EuroCC Belgium training page](https://www.enccb.be/training)

-   Other course materials

    -   [Archive of PRACE training materials](https://training.prace-ri.eu/) (no https unfortunately)


