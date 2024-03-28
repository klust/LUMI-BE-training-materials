# Exercises 2: Modules on LUMI

See [the instructions](index.md#setting-up-for-the-exercises)
to set up for the exercises.

## Exercises on the use of modules

1.  The `Bison` program installed in the OS image is pretty old (version 3.0.4) and
    we want to use a newer one. Is there one available on LUMI?

    ??? Solution "Click to see the solution."

        ```
        module spider Bison
        ```

        tells us that there are indeed newer versions available on the system. 

        The versions that have a compiler name (usually `gcc`) in their name followed
        by some seemingly random characters are installed with Spack and not in the
        CrayEnv or LUMI environments.

        To get more information about `Bison/3.8.2`: 

        ```
        module spider Bison/3.8.2
        ```

        tells us that Bison 3.8.2 is provided by a couple of `buildtools` modules and available
        in all partitions in several versions of the `LUMI` software stack and in `CrayEnv`.

        Alternatively, in this case

        ```
        module keyword Bison
        ```

        would also have shown that Bison is part of several versions of the `buildtools` module.

        The `module spider` command is often the better command if you use names that with a high 
        likelihood could be the name of a package, while `module keyword` is often the better choice
        for words that are more a keyword. But if one does not return the solution it is a good idea 
        to try the other one also.

2.  The `htop` command is a nice alternative for the `top` command with a more powerful user interface.
    However, typing `htop` on the command line produces an error message. Can you find and run `htop`?

    ??? Solution "Click to see the solution."

        We can use either `module spider htop` or `module keyword htop` to find out that `htop` is indeed
        available on the system. With `module keyword htop` we'll find out immediately that it is in the 
        `systools` modules and some of those seem to be numbered after editions of the LUMI stack suggesting
        that they may be linked to a stack, with `module spider` you'll first see that it is an extension of
        a module and see the versions. You may again see some versions installed with Spack.

        Let's check further for `htop/3.2.1` that should exist according to `module spider htop`:

        ```
        module spider htop/3.2.1
        ```

        tells us that this version of `htop` is available in all partitions of `LUMI/22.08` and `LUMI/22.06`,
        and in `CrayEnv`. Let us just run it in the `CrayEnv` environment:

        ```
        module load CrayEnv
        module load systools/22.08
        htop
        ```

        (You can quit `htop` by pressing `q` on the keyboard.)

3.  In the future LUMI will offer Open OnDemand as a browser-based interface to LUMI that will also enable
    running some graphical programs. At the moment the way to do this is through a so-called VNC server.
    Do we have such a tool on LUMI, and if so, how can we use it?

    ??? Solution "Click to see the solution."

        `module spider VNC` and `module keyword VNC` can again both be used to check if there is software
        available to use VNC. Both will show that there is a module `lumi-vnc` in several versions. If you 
        try loading the older ones of these (the version number points at the date of some scripts) you will
        notice that some produce a warning as they are deprecated. However, when installing a new version we 
        cannot remove older ones in one sweep, and users may have hardcoded full module names in scripts they
        use to set their environment, so we chose to not immediate delete these older versions.

        One thing you can always try to get more information about how to run a program, is to ask for the help
        information of the module. For this to work the module must first be available, or you have to use 
        `module spider` with the full name of the module. We see that version `20230110` is the newest version
        of the module, so let's try that one:

        ```
        module spider lumi-vnc/20230110
        ```

        The output may look a little strange as it mentions `init-lumi` as one of the modules that you can load.
        That is because this tool is available even outside `CrayEnv` or the LUMI stacks. But this command also
        shows a long help test telling you how to use this module (though it does assume some familiarity with how
        X11 graphics work on Linux).

        Note that if there is only a single version on the system, as is the case for the course in May 2023,
        the `module spider VNC` command without specific version or correct module name will already display the
        help information.

4.  Search for the `bzip2` tool (and not just the `bunzip2` command as we also need the `bzip2` command) and make 
    sure that you can use software compiled with the Cray compilers in the LUMI stacks in the same session.

    ??? Solution "Click to see the solution."

        ```
        module spider bzip2
        ```

        shows that there are versions of `bzip2` for several of the `cpe*` toolchains and in several versions
        of the LUMI software stack.

        Of course we prefer to use a recent software stack, the `22.08` or `22.12` (but as of early May 2023, 
        there is a lot more software ready-to-install for `22.08`). 
        And since we want to use other software
        compiled with the Cray compilers also, we really want a `cpeCray` version to avoid conflicts between 
        different toolchains. So the module we want to load is `bzip2/1.0.8-cpeCray-22.08`.

        To figure out how to load it, use

        ```
        module spider bzip2/1.0.8-cpeCray-22.08
        ```

        and see that (as expected from the name) we need to load `LUMI/22.08` and can then use it in any of the
        partitions.


