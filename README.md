# docker-geocat
A docker image that provides the major geocat dependencies and some scripts to help you get up and running as a developer.

## Cheatsheet:
```bash
# Build the image from the Dockerfile
docker build -t geocat .

# Run the image, get a shell
docker run -t -i geocat /bin/bash

# Run the image, get a shell, and mount the current directory as /workspace
docker run -it --rm -v "$PWD":/workspace -w /workspace geocat /bin/bash
```

## Getting Started With Geocat
Using: https://groups.ssec.wisc.edu/groups/goes-r/algorithm-working-group/geocat-and-framework/geocat-user-documentation/installing-and-testing-the-experimental-lib_sat-version-of-geocat

```bash
docker run -it --rm -v "$PWD":/workspace -w /workspace geocat /bin/bash

# Then, inside the docker container...
mkdir /workspace/geocat; cd /workspace/geocat
svn checkout https://svn.ssec.wisc.edu/repos/geocat/branches

cd branches/dev_lib_sat
./install.sh -no_data
mkdir -p l1_output l2_output rtm_output nav_output active_output nwp_files area_files snow_archive

wget ftp://ftp.ssec.wisc.edu/pub/geocat/calibration/geocat_cal_v0_3.tar
wget ftp://ftp.ssec.wisc.edu/pub/geocat/navigation/geocat_nav_v0_1.tar.gz
wget ftp://ftp.ssec.wisc.edu/pub/geocat/pfaast/geocat_pfaast_luts_v0_1.tar
wget ftp://ftp.ssec.wisc.edu/pub/geocat/surface_data/geocat_sfc_data_v0_1.tar.gz
mkdir -p data/crtm data/instrument_data data/sfc_data data/plod/lit_end data/navigation
tar xf geocat_cal_v0_3.tar -C ./data/instrument_data 
tar xf geocat_nav_v0_1.tar.gz -C ./data/navigation
tar xf geocat_pfaast_luts_v0_1.tar -C ./data/plod/lit_end 
tar xf geocat_sfc_data_v0_1.tar.gz -C ./data/sfc_data

mv /crtm/coeffs data/crtm

./register_algorithms.sh
cd src
make gfortran_opt
cd ..

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
