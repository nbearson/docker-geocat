# docker-geocat
A docker image that provides the major geocat dependencies and some scripts to help you get up and running as a developer.

## Developer cheatsheet:
```bash
# Build the image from the Dockerfile
docker build -t geocat .

# Run the image, get a shell
docker run -t -i geocat /bin/bash

# Run the image, get a shell, and mount the current directory as /workspace
docker run -it --rm -v "$PWD":/workspace -w /workspace geocat /bin/bash
```

## Getting Started With Geocat
Based on: https://groups.ssec.wisc.edu/groups/goes-r/algorithm-working-group/geocat-and-framework/geocat-user-documentation/installing-and-testing-the-experimental-lib_sat-version-of-geocat


### Start up the container
```bash
docker run -it --rm -v "$PWD":/workspace -w /workspace geocat /bin/bash
```

You should now be at a bash prompt as root inside the docker container...

### Checkout the code
```bash
git clone https://gitlab.ssec.wisc.edu/geocat/geocat.git

cd geocat
./install.sh -no_data
mkdir -p l1_output l2_output rtm_output nav_output active_output nwp_files area_files snow_archive
```

### Get ancillary
This is a script put in the container's $PATH when it's created; it
downloads the large ancillary datasets and extracts them to the right locations
under a data/ directory. This can take a long time to run, and requires ~30 GB of
free space.
```bash
setup_geocat_ancil
```

### Build geocat
```bash
./register_algorithms.sh
cd src
make gfortran_opt
cd ..
```

### Run regression tests
```bash
cd test/dev_lib_sat_regression_test
wget ftp.ssec.wisc.edu:/pub/geocat/test_data/geocat_lib_sat_regression_test_data_20160728.tar.gz
tar xf geocat_lib_sat_regression_test_data_20160728.tar.gz 
rm geocat_lib_sat_regression_test_data_20160728.tar.gz 

make -f regression_test.mk

glance stats --doPassFail ./geocat_ref/nav_output/geocatNAV.GOES-12.2009306.174500.hdf \
./geocat_test/nav_output/geocatNAV.GOES-12.2009306.174500.hdf &> /dev/null && echo PASS || echo FAIL
# should PASS

glance stats --doPassFail ./geocat_ref/nav_output/geocatNAV.GOES-12.2009306.174500.hdf \
./geocat_test/nav_output/geocatNAV.GOES-12.2009306.174500.hdf &> /dev/null && echo PASS || echo FAIL
# should FAIL
```