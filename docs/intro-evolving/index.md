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

::spantable::

| Country      | Address                                                  |
|:-------------| ---------------------------------------------------------|
| France @span | 8 Rue St Ferréol - 92190 City: Meudon (Île-de-France)    |
|              | 50 boulevard Amiral Courbet - 94310 Orly (Île-de-France) |
|              | ...                                                      |
|              | ...                                                      |
| Italy @span  | Str. S. Maurizio, 12, 10072 Caselle torinese TO          |
|              | S.S. Torino-Asti - 10026 Santena (TO)                    |
|              | ...                                                      |
| Poland @span | al. Jana Pawła II 22, 00-133 Warszawa                    |
|              | plac Trzech Krzyży 4/6, 00-535 Warszawa                  |
|              | ...                                                      |
|              | ...                                                      |
| Test @span   |                                                          |

::end-spantable::

::spantable:: caption="Life Expectancy By Current Age" class="foo"

| Italy @span   |       | 40 @span      |       | 20 @span      |       |
| ------------- | ----- | ------------- | ----- | ------------- | ----- |
|               |       | Men           | Women | Men           | Women |
|               |       | 78            | 82    | 77            | 81    |
| Poland @span  |       | 40 @span      |       | 20 @span      |       |
| ------------- | ----- | ------------- | ----- | ------------- | ----- |
|               |       | Men           | Women | Men           | Women |
|               |       | 78            | 82    | 77            | 81    |

::end-spantable::

Test 2:

::spantable::

| Presentation | Slides | Notes | Exercises |
|:-------------|:-------|:------|:----------|
| Notes Introduction | / | [notes](00-Introduction.md) | / |

::end-spantable::



| Presentation | Slides | Notes | Exercises |
|:-------------|:-------|:------|:----------|
| Notes Introduction | / | [notes](00-Introduction.md) | / |
| **Exploring LUMI from the login nodes** @span=4 |  |  |  |
| [LUMI Architecture](M01-Architecture.md) | [slides](https://465000095.lumidata.eu/training-materials-web/intro-evolving/files/LUMI-BE-Intro-evolving-01-Architecture.pdf) | [notes](01-Architecture.md) | / |
| [HPE Cray Programming Environment](M02-CPE.md) | [slides](https://465000095.lumidata.eu/training-materials-web/intro-evolving/files/LUMI-BE-Intro-evolving-02-CPE.pdf) | [notes](02-CPE.md) | [exercises](E02-CPE.md) |
| [Getting access to LUMI](M03-Access.md) | [slides](https://465000095.lumidata.eu/training-materials-web/intro-evolving/files/LUMI-BE-Intro-evolving-03-Access.pdf) | [notes](03-Access.md) | [exercises](E03-Access.md) |
| [Modules on LUMI](M04-Modules.md) | [slides](https://465000095.lumidata.eu/training-materials-web/intro-evolving/files/LUMI-BE-Intro-evolving-04-Modules.pdf) | [notes](04-Modules.md) | [exercises](E04-Modules.md) |
| [LUMI Software Stacks](M05-SoftwareStacks.md) | [slides](https://465000095.lumidata.eu/training-materials-web/intro-evolving/files/LUMI-BE-Intro-evolving-05-SoftwareStacks.pdf) | [notes](05-SoftwareStacks.md) | [exercises](E05-SoftwareStacks.md) |
| [LUMI User Support](M06-Support.md) | [slides](https://465000095.lumidata.eu/training-materials-web/intro-evolving/files/LUMI-BE-Intro-evolving-06-Support.pdf) | [notes](06-Support.md) | / |
| **Running jobs efficiently** @span |  |  |  |
| [Slurm on LUMI](M07-Slurm.md) | [slides](https://465000095.lumidata.eu/training-materials-web/intro-evolving/files/LUMI-BE-Intro-evolving-07-Slurm.pdf) | [notes](07-Slurm.md) | [exercises](E07-Slurm.md) |
| [Binding resources](M08-Binding.md) | [slides](https://465000095.lumidata.eu/training-materials-web/intro-evolving/files/LUMI-BE-Intro-evolving-08-Binding.pdf) | [notes](08-Binding.md) | [exercises](E08-Binding.md) | 
| **Data on LUMI** @span |  |  |  |
| [Using Lustre](M09-Lustre.md) | [slides](https://465000095.lumidata.eu/training-materials-web/intro-evolving/files/LUMI-BE-Intro-evolving-09-Lustre.pdf) | [notes](09-Lustre.md) | / |
| [LUMI-O object storage](M10-ObjectStorage.md) | [slides](https://465000095.lumidata.eu/training-materials-web/intro-evolving/files/LUMI-BE-Intro-evolving-10-ObjectStorage.pdf) | [notes](10-ObjectStorage.md) | / |
| **Containers on LUMI** @span |  |  |  |
| [Containers on LUMI](M11-Containers.md) | [slides](https://465000095.lumidata.eu/training-materials-web/intro-evolving/files/LUMI-BE-Intro-evolving-11-Containers.pdf) | [notes](11-Containers.md) | / |
| Container demo 1 | / | [notes and video](Demo1.md) | / |
| Container demo 2 | / | [notes and video](Demo2.md) | / |
| **Appendices** @span |  |  |  |
| A1 Slurm issues | / | [notes](A01-SlurmIssues.md) | / | 
| A2 Additional documentation | / | [notes](A02-Documentation.md) | / | 

<!--
| Container demo 1 | / | [notes and video](Demo1.md) | [video](Demo1.md#video-of-the-demo) |
| Container demo 2 | / | [notes and video](Demo2.md) | [video](Demo2.md#video-of-the-demo) |
-->

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


