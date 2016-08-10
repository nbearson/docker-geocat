# This image adds all the pieces geocat should need
# TODO: look into how to include scripts for grabbing and setting up the static ancillary data

# for a step-by-step on installing geocat, see:
# getting libs: 
# https://groups.ssec.wisc.edu/groups/goes-r/algorithm-working-group/geocat-and-framework/geocat-user-documentation/building-geocat-cots-libraries
# trunk install:
# https://groups.ssec.wisc.edu/groups/goes-r/algorithm-working-group/geocat-and-framework/geocat-user-documentation/installing-geocat/?searchterm=geocat
# dev_lib_sat install:
# https://groups.ssec.wisc.edu/groups/goes-r/algorithm-working-group/geocat-and-framework/geocat-user-documentation/installing-and-testing-the-experimental-lib_sat-version-of-geocat

# docker-science-stack handles all the lib dependencies for us
FROM nbearson/docker-science-stack

ENV WGRIB_VERSION 1.8.1.2c
ENV WGRIB2_VERSION 2.0.5
ENV PPVL_VERSION 1.2.6
ENV CRTM_VERSION 2.0.6

# unzip needed to unzip packages inside wgrib
# cvs needed to grab grib2hdf
# svn for checkout when running regression tests
RUN apt-get update && apt-get install -y unzip cvs subversion

RUN mkdir /build

# do all downloads up front so they get cached until something changes
RUN mkdir -p /build/wgrib && cd /build/wgrib && curl -O ftp://ftp.cpc.ncep.noaa.gov/wd51we/wgrib/wgrib.tar.v${WGRIB_VERSION} && tar xf wgrib.tar.v${WGRIB_VERSION}
RUN cd /build && curl -O ftp://ftp.cpc.ncep.noaa.gov/wd51we/wgrib2/wgrib2.tgz.v${WGRIB2_VERSION} && tar xzf wgrib2.tgz.v${WGRIB2_VERSION} && mv grib2 wgrib2
# FIXME: can we get grib2hdf from cvs without having to log in? doesn't seem like it
#RUN cd /build && cvs co -d cvs.ssec.wisc.edu:/cvsroot https://cvs.ssec.wisc.edu/cgi-bin/cvsweb.cgi/grib2hdf
RUN cd /build && curl -O ftp://ftp.emc.ncep.noaa.gov/jcsda/CRTM/utility/Profile_Utility.tar.gz && tar xzf Profile_Utility.tar.gz
RUN cd /build && curl -O ftp://ftp.ssec.wisc.edu/pub/geocat/crtm/REL-${CRTM_VERSION}.CRTM.tar.gz && tar xzf REL-${CRTM_VERSION}.CRTM.tar.gz
# FIXME: curl -O doesn't work for the below???
RUN cd /build && wget ftp://pirlftp.lpl.arizona.edu/pub/PPVL/PPVL-${PPVL_VERSION}.tar.gz && tar xzf PPVL-${PPVL_VERSION}.tar.gz

## adds wgrib1 support for the grib2hdf
RUN cd /build/wgrib && make && \
    mkdir /wgrib && cp wgrib /wgrib/wgrib

## adds wgrib2 support for the grib2hdf
RUN cd /build/wgrib2 && export USE_AEC=0 && make && \
    mkdir /wgrib2 && cp wgrib2/wgrib2 /wgrib2/wgrib2

## adds grib2hdf
## adds PPVL for MODIS:
# https://groups.ssec.wisc.edu/groups/goes-r/algorithm-working-group/geocat-and-framework/geocat-user-documentation/running-geocat-on-modis-data
RUN apt-get install -y csh
RUN cd /build/PPVL-${PPVL_VERSION} && mkdir -p /ppvl/lib /ppvl/include && INSTALL_DIR=/ppvl make install

## adds Profile_Utility
RUN cd /build/Profile_Utility && make && make install && \
	mkdir /profile_utility && cp -r lib /profile_utility/lib && cp -r include /profile_utility/include

## adds CRTM
RUN cd /build/REL-${CRTM_VERSION} && . configure/gfortran.setup && make && make test && make install && \
	mkdir /crtm && cp -r lib /crtm/lib && cp -r include /crtm/include && \
	mkdir /crtm/coeffs && \
	cp fix/AerosolCoeff/Little_Endian/AerosolCoeff.bin /crtm/coeffs/AerosolCoeff.bin && \
	cp fix/CloudCoeff/Little_Endian/CloudCoeff.bin /crtm/coeffs/CloudCoeff.bin && \
	cp fix/EmisCoeff/Little_Endian/Wu-Smith.CM-PDF.HQS_HQS-RefInd.EmisCoeff.bin /crtm/coeffs/EmisCoeff.bin && \
	cp fix/SpcCoeff/Little_Endian/seviri_m09.SpcCoeff.bin /crtm/coeffs/seviri_m09.SpcCoeff.bin && \
	cp fix/TauCoeff/ODAS/Little_Endian/seviri_m09.TauCoeff.bin /crtm/coeffs/seviri_m09.TauCoeff.bin && \
	cp fix/SpcCoeff/Little_Endian/sndr_g14.SpcCoeff.bin /crtm/coeffs/sndr_g14.SpcCoeff.bin && \
	cp fix/TauCoeff/ODAS/Little_Endian/sndr_g14.TauCoeff.bin /crtm/coeffs/sndr_g14.TauCoeff.bin

## add uwglance for regression testing
RUN apt-get install -y python-setuptools python-numpy python-scipy python-matplotlib python-mpltoolkits.basemap
RUN easy_install -f http://larch.ssec.wisc.edu/cgi-bin/repos.cgi uwglance


## safe default that also makes SVN stop complaining when we run regression tests
RUN mkdir -p /root/.subversion && echo "store-plaintext-passwords = no" >> /root/.subversion/servers

# set all the required env variables for the user
RUN echo "export GEOCAT_INCLUDES=/usr/include" >> ~/.bashrc && \
    echo "export GEOCAT_LIBRARIES=/usr/lib" >> ~/.bashrc && \
    echo "export HDF4=/usr" >> ~/.bashrc && \
    echo "export HDF5=/usr/lib/x86_64-linux-gnu" >> ~/.bashrc && \
    echo "export NETCDF=/usr" >> ~/.bashrc && \
    echo "export PPVL=/ppvl" >> ~/.bashrc && \
    echo "export CRTM=/crtm" >> ~/.bashrc && \
    echo "export PROFILE_UTILITY=/profile_utility" >> ~/.bashrc

# remove all the build cruft
RUN rm -rf /build
RUN rm -rf /usr/man

