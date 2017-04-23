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
ENV CRTM_VERSION 2.2.3

# unzip needed to unzip packages inside wgrib
# cvs needed to grab grib2hdf
# svn for checkout when running regression tests
# gdb & valgrind for the usual profiling / debugging things
RUN apt-get update && apt-get install -y unzip cvs subversion gdb valgrind

## adds wgrib1 support for the grib2hdf
RUN mkdir -p ${BUILD}/wgrib && cd ${BUILD}/wgrib && \
    wget -q ftp://ftp.cpc.ncep.noaa.gov/wd51we/wgrib/wgrib.tar.v${WGRIB_VERSION} && \
    tar xf wgrib.tar.v${WGRIB_VERSION} && \
    cd ${BUILD}/wgrib && make && \
    mkdir ${OPT}/wgrib && cp wgrib ${OPT}/wgrib/wgrib && \
    rm -rf ${BUILD}

## adds wgrib2 support for the grib2hdf
RUN mkdir -p ${BUILD} && cd ${BUILD} && \
    wget -q ftp://ftp.cpc.ncep.noaa.gov/wd51we/wgrib2/wgrib2.tgz.v${WGRIB2_VERSION} && \
    tar xzf wgrib2.tgz.v${WGRIB2_VERSION} && \
    cd grib2 && export USE_AEC=0 && make && \
    mkdir ${OPT}/wgrib2 && cp wgrib2/wgrib2 ${OPT}/wgrib2/wgrib2 && \
    rm -rf ${BUILD}

## TODO: adds grib2hdf
# FIXME: can we get grib2hdf from cvs without having to log in? doesn't seem like it
#RUN cd ${BUILD} && cvs co -d cvs.ssec.wisc.edu:/cvsroot https://cvs.ssec.wisc.edu/cgi-bin/cvsweb.cgi/grib2hdf

## adds W3lib for mesoscale NWP data (RAP-13 and RUC-13)
RUN mkdir -p ${BUILD} && cd ${BUILD} && \
    wget -q ftp://ftp.ssec.wisc.edu/pub/geocat/w3/w3lib.tar && \
    tar xf w3lib.tar && \
    for f in w3fb??.f; do gfortran -c $f; done && \
    ar rc libW3.a w3fb??.o && \
    mkdir ${OPT}/w3lib && cp libW3.a ${OPT}/w3lib/libW3.a && \
    rm -rf ${BUILD}

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
    wget -q ftp://ftp.emc.ncep.noaa.gov/jcsda/CRTM/utility/Profile_Utility.tar.gz && \
    tar xzf Profile_Utility.tar.gz && \
    cd ${BUILD}/Profile_Utility && make && make install && \
    mkdir ${OPT}/profile_utility && cp -r lib ${OPT}/profile_utility/lib && cp -r include ${OPT}/profile_utility/include && \
    rm -rf ${BUILD}

## adds CRTM
RUN mkdir -p ${BUILD} && cd ${BUILD} && \
    wget -q ftp://ftp.emc.ncep.noaa.gov/jcsda/CRTM/REL-${CRTM_VERSION}/crtm_v${CRTM_VERSION}.tar.gz && \
    tar xzf crtm_v${CRTM_VERSION}.tar.gz && \
    cd ${BUILD}/REL-${CRTM_VERSION} && . config-setup/gfortran.setup && ./configure --prefix=${OPT} && make && make install && \
    mkdir ${OPT}/crtm_v${CRTM_VERSION}/coeffs && \
    cp fix/AerosolCoeff/Little_Endian/AerosolCoeff.bin                                ${OPT}/crtm_v${CRTM_VERSION}/coeffs/AerosolCoeff.bin && \
    cp fix/CloudCoeff/Little_Endian/CloudCoeff.bin                                    ${OPT}/crtm_v${CRTM_VERSION}/coeffs/CloudCoeff.bin && \
    cp fix/EmisCoeff/MW_Water/Little_Endian/FASTEM4.MWwater.EmisCoeff.bin             ${OPT}/crtm_v${CRTM_VERSION}/coeffs/FASTEM4.MWwater.EmisCoeff.bin && \
    cp fix/EmisCoeff/MW_Water/Little_Endian/FASTEM5.MWwater.EmisCoeff.bin             ${OPT}/crtm_v${CRTM_VERSION}/coeffs/FASTEM5.MWwater.EmisCoeff.bin && \
    cp fix/EmisCoeff/IR_Land/SEcategory/Little_Endian/IGBP.IRland.EmisCoeff.bin       ${OPT}/crtm_v${CRTM_VERSION}/coeffs/IGBP.IRland.EmisCoeff.bin && \
    cp fix/EmisCoeff/VIS_Land/SEcategory/Little_Endian/IGBP.VISland.EmisCoeff.bin     ${OPT}/crtm_v${CRTM_VERSION}/coeffs/IGBP.VISland.EmisCoeff.bin && \
    cp fix/EmisCoeff/IR_Water/Little_Endian/Nalli.IRwater.EmisCoeff.bin               ${OPT}/crtm_v${CRTM_VERSION}/coeffs/Nalli.IRwater.EmisCoeff.bin && \
    cp fix/EmisCoeff/IR_Ice/SEcategory/Little_Endian/NPOESS.IRice.EmisCoeff.bin       ${OPT}/crtm_v${CRTM_VERSION}/coeffs/NPOESS.IRice.EmisCoeff.bin && \
    cp fix/EmisCoeff/IR_Land/SEcategory/Little_Endian/NPOESS.IRland.EmisCoeff.bin     ${OPT}/crtm_v${CRTM_VERSION}/coeffs/NPOESS.IRland.EmisCoeff.bin && \
    cp fix/EmisCoeff/IR_Snow/SEcategory/Little_Endian/NPOESS.IRsnow.EmisCoeff.bin     ${OPT}/crtm_v${CRTM_VERSION}/coeffs/NPOESS.IRsnow.EmisCoeff.bin && \
    cp fix/EmisCoeff/VIS_Ice/SEcategory/Little_Endian/NPOESS.VISice.EmisCoeff.bin     ${OPT}/crtm_v${CRTM_VERSION}/coeffs/NPOESS.VISice.EmisCoeff.bin && \
    cp fix/EmisCoeff/VIS_Land/SEcategory/Little_Endian/NPOESS.VISland.EmisCoeff.bin   ${OPT}/crtm_v${CRTM_VERSION}/coeffs/NPOESS.VISland.EmisCoeff.bin && \
    cp fix/EmisCoeff/VIS_Snow/SEcategory/Little_Endian/NPOESS.VISsnow.EmisCoeff.bin   ${OPT}/crtm_v${CRTM_VERSION}/coeffs/NPOESS.VISsnow.EmisCoeff.bin && \
    cp fix/EmisCoeff/VIS_Water/SEcategory/Little_Endian/NPOESS.VISwater.EmisCoeff.bin ${OPT}/crtm_v${CRTM_VERSION}/coeffs/NPOESS.VISwater.EmisCoeff.bin && \
    cp fix/EmisCoeff/IR_Land/SEcategory/Little_Endian/USGS.IRland.EmisCoeff.bin       ${OPT}/crtm_v${CRTM_VERSION}/coeffs/USGS.IRland.EmisCoeff.bin && \
    cp fix/EmisCoeff/VIS_Land/SEcategory/Little_Endian/USGS.VISland.EmisCoeff.bin     ${OPT}/crtm_v${CRTM_VERSION}/coeffs/USGS.VISland.EmisCoeff.bin && \
    cp fix/EmisCoeff/IR_Water/Little_Endian/WuSmith.IRwater.EmisCoeff.bin             ${OPT}/crtm_v${CRTM_VERSION}/coeffs/WuSmith.IRwater.EmisCoeff.bin && \
    cp fix/SpcCoeff/Little_Endian/*.bin                                               ${OPT}/crtm_v${CRTM_VERSION}/coeffs/. && \
    cp fix/TauCoeff/ODAS/Little_Endian/*.bin                                          ${OPT}/crtm_v${CRTM_VERSION}/coeffs/. && \
    rm -rf ${BUILD}

#    cp fix/SpcCoeff/Little_Endian/seviri_m09.SpcCoeff.bin ${OPT}/crtm/coeffs/seviri_m09.SpcCoeff.bin && \
#    cp fix/TauCoeff/ODAS/Little_Endian/seviri_m09.TauCoeff.bin ${OPT}/crtm/coeffs/seviri_m09.TauCoeff.bin && \
#    cp fix/SpcCoeff/Little_Endian/sndr_g14.SpcCoeff.bin ${OPT}/crtm/coeffs/sndr_g14.SpcCoeff.bin && \
#    cp fix/TauCoeff/ODAS/Little_Endian/sndr_g14.TauCoeff.bin ${OPT}/crtm/coeffs/sndr_g14.TauCoeff.bin && \

# add libHimawari
# not large, not sure what's important, build it outside of ${BUILD} for now
RUN apt-get install -y libboost-dev
RUN cd ${OPT} && git clone https://gitlab.ssec.wisc.edu/rayg/himawari.git himawari && \
    (cd himawari/src; unset CXX CC LD F9X; make) && \
		(cd himawari/; python setup.py install)

## safe default that also makes SVN stop complaining when we run regression tests
RUN mkdir -p /root/.subversion && \
    echo "[global]" >> /root/.subversion/ser0.9.0vers && \
    echo "store-plaintext-passwords = no" >> /root/.subversion/servers


# set all the required env variables for the user
ENV GEOCAT_INCLUDES ${HDF4}/include
ENV GEOCAT_LIBRARIES ${HDF4}/lib
ENV PPVL ${OPT}/ppvl
ENV CRTM ${OPT}/crtm_v${CRTM_VERSION}
ENV PROFILE_UTILITY ${OPT}/profile_utility
ENV HIMAWARI_UTILS ${OPT}/himawari
ENV W3_LIBRARIES ${OPT}/w3lib

# add utility scripts to /usr/bin/ (already in path)
ADD setup_geocat_ancil /usr/bin/
RUN chmod +x /usr/bin/setup_geocat_ancil
