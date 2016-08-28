# This image adds all the pieces geocat should need
# TODO: look into how to include scripts for grabbing and setting up the static ancillary data

# for a step-by-step on installing geocat, see:
# getting libs: 
# https://groups.ssec.wisc.edu/groups/goes-r/algorithm-working-group/geocat-and-framework/geocat-user-documentationbuilding-geocat-cots-libraries
# trunk install:
# https://groups.ssec.wisc.edu/groups/goes-r/algorithm-working-group/geocat-and-framework/geocat-user-documentation/installing-geocat/?searchterm=geocat
# dev_lib_sat install:
# https://groups.ssec.wisc.edu/groups/goes-r/algorithm-working-group/geocat-and-framework/geocat-user-documentation/installing-and-testing-the-experimental-lib_sat-version-of-geocat

# docker-science-stack handles all the lib dependencies for us
FROM nbearson/docker-science-stack

# apparently we don't inherit ${BUILD} and ${OPT} from docker-science-stack
# how should we do this? .bashrc?
ENV BUILD /build
ENV OPT /opt

ENV WGRIB_VERSION 1.8.1.2c
ENV WGRIB2_VERSION 2.0.5
ENV PPVL_VERSION 1.2.6
ENV CRTM_VERSION 2.0.6
ENV PYHDF_VERSION 0.9.0
ENV NETCDFPY_VERSION 1.2.4rel

# unzip needed to unzip packages inside wgrib
# cvs needed to grab grib2hdf
# svn for checkout when running regression tests
RUN apt-get update && apt-get install -y unzip cvs subversion

## adds wgrib1 support for the grib2hdf
RUN mkdir -p ${BUILD}/wgrib && cd ${BUILD}/wgrib && \
    curl -O ftp://ftp.cpc.ncep.noaa.gov/wd51we/wgrib/wgrib.tar.v${WGRIB_VERSION} && \
    tar xf wgrib.tar.v${WGRIB_VERSION} && \
    cd ${BUILD}/wgrib && make && \
    mkdir ${OPT}/wgrib && cp wgrib ${OPT}/wgrib/wgrib && \
    rm -rf ${BUILD}

## adds wgrib2 support for the grib2hdf
RUN mkdir -p ${BUILD} && cd ${BUILD} && \
    curl -O ftp://ftp.cpc.ncep.noaa.gov/wd51we/wgrib2/wgrib2.tgz.v${WGRIB2_VERSION} && \
    tar xzf wgrib2.tgz.v${WGRIB2_VERSION} && \
    cd grib2 && export USE_AEC=0 && make && \
    mkdir ${OPT}/wgrib2 && cp wgrib2/wgrib2 ${OPT}/wgrib2/wgrib2 && \
    rm -rf ${BUILD}

## TODO: adds grib2hdf
# FIXME: can we get grib2hdf from cvs without having to log in? doesn't seem like it
#RUN cd ${BUILD} && cvs co -d cvs.ssec.wisc.edu:/cvsroot https://cvs.ssec.wisc.edu/cgi-bin/cvsweb.cgi/grib2hdf

## adds PPVL for MODIS:
# https://groups.ssec.wisc.edu/groups/goes-r/algorithm-working-group/geocat-and-framework/geocat-user-documentation/running-geocat-on-modis-data
RUN apt-get install -y csh
RUN mkdir -p ${BUILD} && cd ${BUILD} && \
    wget ftp://pirlftp.lpl.arizona.edu/pub/PPVL/PPVL-${PPVL_VERSION}.tar.gz && \
    tar xzf PPVL-${PPVL_VERSION}.tar.gz && \
    cd ${BUILD}/PPVL-${PPVL_VERSION} && mkdir -p ${OPT}/ppvl/lib ${OPT}/ppvl/include && INSTALL_DIR=${OPT}/ppvl make install && \
    rm -rf ${BUILD}

## adds Profile_Utility
RUN mkdir -p ${BUILD} && cd ${BUILD} && \
    curl -O ftp://ftp.emc.ncep.noaa.gov/jcsda/CRTM/utility/Profile_Utility.tar.gz && \
    tar xzf Profile_Utility.tar.gz && \
    cd ${BUILD}/Profile_Utility && make && make install && \
    mkdir ${OPT}/profile_utility && cp -r lib ${OPT}/profile_utility/lib && cp -r include ${OPT}/profile_utility/include && \
    rm -rf ${BUILD}

## adds CRTM
RUN mkdir -p ${BUILD} && cd ${BUILD} && \
    curl -O ftp://ftp.ssec.wisc.edu/pub/geocat/crtm/REL-${CRTM_VERSION}.CRTM.tar.gz && \
    tar xzf REL-${CRTM_VERSION}.CRTM.tar.gz && \
    cd ${BUILD}/REL-${CRTM_VERSION} && . configure/gfortran.setup && make && make test && make install && \
    mkdir ${OPT}/crtm && cp -r lib ${OPT}/crtm/lib && cp -r include ${OPT}/crtm/include && \
    mkdir ${OPT}/crtm/coeffs && \
    cp fix/AerosolCoeff/Little_Endian/AerosolCoeff.bin ${OPT}/crtm/coeffs/AerosolCoeff.bin && \
    cp fix/CloudCoeff/Little_Endian/CloudCoeff.bin ${OPT}/crtm/coeffs/CloudCoeff.bin && \
    cp fix/EmisCoeff/Little_Endian/Wu-Smith.CM-PDF.HQS_HQS-RefInd.EmisCoeff.bin ${OPT}/crtm/coeffs/EmisCoeff.bin && \
    cp fix/SpcCoeff/Little_Endian/seviri_m09.SpcCoeff.bin ${OPT}/crtm/coeffs/seviri_m09.SpcCoeff.bin && \
    cp fix/TauCoeff/ODAS/Little_Endian/seviri_m09.TauCoeff.bin ${OPT}/crtm/coeffs/seviri_m09.TauCoeff.bin && \
    cp fix/SpcCoeff/Little_Endian/sndr_g14.SpcCoeff.bin ${OPT}/crtm/coeffs/sndr_g14.SpcCoeff.bin && \
    cp fix/TauCoeff/ODAS/Little_Endian/sndr_g14.TauCoeff.bin ${OPT}/crtm/coeffs/sndr_g14.TauCoeff.bin && \
    rm -rf ${BUILD}

# add libHimawari
# not large, not sure what's important, build it outside of ${BUILD} for now
RUN cd ${OPT} && git clone https://gitlab.ssec.wisc.edu/rayg/himawari.git himawari && \
    cd himawari/src && (unset CXX CC LD F9X; make) && \
    rm -rf ${BUILD}

## add uwglance for regression testing
RUN apt-get install -y python-setuptools python-numpy python-scipy python-matplotlib python-mpltoolkits.basemap
RUN easy_install -f http://larch.ssec.wisc.edu/cgi-bin/repos.cgi uwglance

## add pyhdf for glance to read hdf4 files
RUN mkdir -p ${BUILD} && cd ${BUILD} && \
    wget http://hdfeos.org/software/pyhdf/pyhdf-${PYHDF_VERSION}.tar.gz && \
    tar xzf pyhdf-${PYHDF_VERSION}.tar.gz && \
    cd pyhdf-${PYHDF_VERSION} && \
    INCLUDE_DIRS="${OPT}/hdf4/include/" \
    LIBRARY_DIRS="${OPT}/hdf4/lib/" \
    python setup.py install && \
    rm -r ${BUILD}

## add netcdf4-python for glance to read netcdf4 files
RUN mkdir -p ${BUILD} && cd ${BUILD} && \
    wget https://github.com/Unidata/netcdf4-python/archive/v${NETCDFPY_VERSION}.tar.gz && \
    tar xzf v${NETCDFPY_VERSION}.tar.gz && \
    cd netcdf4-python-${NETCDFPY_VERSION} && \
    PATH="${OPT}/netcdf4/bin:$PATH" \
    python setup.py install && \
    rm -r ${BUILD}

## safe default that also makes SVN stop complaining when we run regression tests
RUN mkdir -p /root/.subversion && \
    echo "[global]" >> /root/.subversion/ser0.9.0vers && \
    echo "store-plaintext-passwords = no" >> /root/.subversion/servers


# set all the required env variables for the user
RUN echo "export GEOCAT_INCLUDES=${HDF4}/include" >> ~/.bashrc && \
    echo "export GEOCAT_LIBRARIES=${HDF4}/lib" >> ~/.bashrc && \
    echo "export PPVL=${OPT}/ppvl" >> ~/.bashrc && \
    echo "export CRTM=${OPT}/crtm" >> ~/.bashrc && \
    echo "export PROFILE_UTILITY=${OPT}/profile_utility" >> ~/.bashrc && \
    echo "export HIMAWARI_UTILS=${OPT}/himawari" >> ~/.bashrc && \
    echo "" >> ~/.bashrc


