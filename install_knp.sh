echo '(0/3) run install KNP script'

INSTALL_PATH=/usr/local/
#INSTALL_PATH=$(cd $(dirname $0); pwd)/bin
echo "Install path: $INSTALL_PATH"

mkdir build
cd build

# Install juman
wget 'http://nlp.ist.i.kyoto-u.ac.jp/DLcounter/lime.cgi?down=http://nlp.ist.i.kyoto-u.ac.jp/nl-resource/juman/juman-7.01.tar.bz2&name=juman-7.01.tar.bz2' -O juman.tar.bz2
tar xf juman.tar.bz2
cd juman-7.01
./configure --prefix=$INSTALL_PATH
make -j4
make install
cd ..
echo '(1/3) juman installed'

# Install juman++
wget https://github.com/ku-nlp/jumanpp/releases/download/v2.0.0-rc2/jumanpp-2.0.0-rc2.tar.xz
tar xf jumanpp-2.0.0-rc2.tar.xz
cd jumanpp-2.0.0-rc2
mkdir build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH
make install
cd ../..
echo '(2/3) Juman installed'

# Install KNP
wget 'http://nlp.ist.i.kyoto-u.ac.jp/DLcounter/lime.cgi?down=http://nlp.ist.i.kyoto-u.ac.jp/nl-resource/knp/knp-4.19.tar.bz2&name=knp-4.19.tar.bz2' -O knp.tar.bz2
tar xf knp.tar.bz2
cd knp-4.19
./configure --prefix=$INSTALL_PATH --with-juman-prefix=$INSTALL_PATH
make -j4
make install
cd ..
echo '(3/3) KNP installed'

