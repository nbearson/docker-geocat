# This image creates a common scientific build environment that includes:
# gfortran, hdf4, hdf5, netcdf4

FROM nbearson/docker-science-stack

## adds wgrib1 support for the gfs converter

## adds wgrib2 support for the gfs converter
# unzip needed to unzip packages inside wgrib
RUN apt-get update && apt-get install -y unzip
RUN mkdir /build
RUN cd /build && curl -O ftp://ftp.cpc.ncep.noaa.gov/wd51we/wgrib2/wgrib2.tgz
RUN cd /build && tar xzf wgrib2.tgz && cd grib2 && export USE_AEC=0 && make && \
    mkdir /wgrib2 && mv wgrib2/wgrib2 /wgrib2/wgrib2

## adds Profile_Utility

## adds CRTM

# remove all the build cruft
RUN rm -rf /build
RUN rm -rf /usr/man

