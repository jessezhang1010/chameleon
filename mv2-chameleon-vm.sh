
yum install -y pciutils
# enable appropriate permission for ivshmem device
IVSHMEMID=`lspci -nn | grep "1af4:1110" | awk '{print $1}' | sed 's/:/\\:/g'`
chmod 766 /sys/bus/pci/devices/0000\:$IVSHMEMID/resource2

OFED_NAME=MLNX_OFED_LINUX-3.0-1.0.1-rhel7.1-x86_64
OFED_TAR_NAME=$OFED_NAME.tgz
OFED_URL=http://www.mellanox.com/downloads/ofed/MLNX_OFED-3.0-1.0.1/$OFED_TAR_NAME

MV2_INSTALL_PATH=/opt/mvapich2-virt
MV2_RPM_NAME=mvapich2-virt-2.2-0.1rc1.el7.centos.x86_64.rpm
MV2_RPM_URL=http://mvapich.cse.ohio-state.edu/download/mvapich/virt/mvapich2-virt-2.2-0.1rc1.el7.centos.x86_64.rpm
MV2_PROFILE=/etc/profile.d/mvapich2

if [ -d "$MV2_INSTALL_PATH" ]
then
   echo "MVAPICH2 has been installed in $MV2_INSTALL_PATH."
   #exit 0
fi

# Install required packages
yum -y install gtk2 atk cairo libxml2-python tcsh libnl tcl tk perl lsof gcc-gfortran bc

# Install ofed if nonexist
ofed_info
if [ $? -eq 0 ]; then
   echo "MLNX OFED installed"
else
   echo "Downloading MLNX OFED ..."
   curl -O $OFED_URL
   echo "Installing MLNX OFED ..."
   tar zxf $OFED_TAR_NAME
   $OFED_NAME/mlnxofedinstall --force
fi

# Install MVAPICH2
curl -O $MV2_RPM_URL

rpm --prefix $MV2_INSTALL_PATH -Uvh --force --nodeps $MV2_RPM_NAME 

MV2_BIN_PATH=$(dirname $(find $MV2_INSTALL_PATH -name mpicc))
MV2_LIB_PATH=$(dirname $(find $MV2_INSTALL_PATH -name libmpi.so))

cat << EOF > $MV2_PROFILE.sh
# MVAPICH2 initialization script (sh)
if ! echo ${PATH} | grep -q $MV2_BIN_PATH ; then
        PATH=${PATH}:$MV2_BIN_PATH
        LD_LIBRARY_PATH=$MV2_LIB_PATH:${LD_LIBRARY_PATH}
fi
EOF
echo export LD_LIBRARY_PATH=$MV2_LIB_PATH:${LD_LIBRARY_PATH} >> /etc/bashrc

cat << EOF > $MV2_PROFILE.csh
# MVAPICH2 initialization script (csh)
if ( "${path}" !~ *$MV2_BIN_PATH* ) then
        set path = ( $path $MV2_BIN_PATH )
        set ld_library_path = ( $MV2_LIB_PATH $ld_library_path )
endif
EOF
echo set ld_library_path = \( $MV2_LIB_PATH $ld_library_path \) >> /etc/csh.cshrc

echo "$($MV2_BIN_PATH/mpiname -n -v -r) is successfully installed."

rmmod ib_isert xprtrdma ib_srpt 
systemctl restart openibd
