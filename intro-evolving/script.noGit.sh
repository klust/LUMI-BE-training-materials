#! /usr/bin/env bash
sed \
                                             -e 's|00_Introduction|00-Introduction|g' \
    -e 's|01-architecture|01-Architecture|g' -e 's|01_Architecture|01-Architecture|g' \
                                             -e 's|02_CPE|02-CPE|g' \
    -e 's|03-access|03-Access|g'             -e 's|03_LUMI_access|03-Access|g' \
    -e 's|04-modules|04-Modules|g'           -e 's|04_Modules|04-Modules|g' \
    -e 's|05-software|05-SoftwareStacks|g'   -e 's|05_Software_stacks|05-SoftwareStacks|g' \
    -e 's|06-slurm|06-Slurm|g'               -e 's|06_Slurm|06-Slurm|g' \
    -e 's|07-binding|07-Binding|g'           -e 's|07_Binding|07-Binding|g' \
    -e 's|08-lustre|08-Lustre|g'             -e 's|08_Lustre|08-Lustre|g' \
    -e 's|09-containers|09-Containers|g'     -e 's|09_Containers|09-Containers|g' \
    -e 's|10-support|10-Support|g'           -e 's|10_Support|10-Support|g' \
    -e 's|A01_Slurm_issues|A01-SlurmIssues|g' \
    -e 's|A02_Documentation|A02-Documentation|g' \
    -e 's|E03_Exercises_1|E03-Access|g' \
    -e 's|E04_Exercises_2|E04-Modules|g' \
    -e 's|E05_Exercises_3|E05-SoftwareStacks|g' \
    -e 's|E07_Exercises_4|E07-Binding|g' \
    -i '.orig' $1
