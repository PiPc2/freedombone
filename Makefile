APP=freedombone
VERSION=1.00
RELEASE=1
PREFIX?=/usr/local

all:
debug:
source:
	tar -cvf ../${APP}_${VERSION}.orig.tar ../${APP}-${VERSION} --exclude-vcs
	gzip -f9n ../${APP}_${VERSION}.orig.tar
install:
	mkdir -p ${DESTDIR}${PREFIX}/bin
	install -m 755 src/${APP} ${DESTDIR}${PREFIX}/bin
	install -m 755 src/${APP}-prep ${DESTDIR}${PREFIX}/bin
	install -m 755 src/${APP}-tordongle ${DESTDIR}${PREFIX}/bin
	mkdir -m 755 -p ${DESTDIR}${PREFIX}/share/man/man1
	install -m 644 man/${APP}.1.gz ${DESTDIR}${PREFIX}/share/man/man1
	install -m 644 man/${APP}-prep.1.gz ${DESTDIR}${PREFIX}/share/man/man1
	install -m 644 man/${APP}-tordongle.1.gz ${DESTDIR}${PREFIX}/share/man/man1
uninstall:
	rm -f ${PREFIX}/share/man/man1/${APP}.1.gz
	rm -f ${PREFIX}/share/man/man1/${APP}-prep.1.gz
	rm -f ${PREFIX}/share/man/man1/${APP}-tordongle.1.gz
	rm -rf ${PREFIX}/share/${APP}
	rm -f ${PREFIX}/bin/${APP}
	rm -f ${PREFIX}/bin/${APP}-prep
	rm -f ${PREFIX}/bin/${APP}-tordongle
clean:
	rm -f \#* \.#* debian/*.substvars debian/*.log
	rm -fr deb.* debian/${APP}
	rm -f ../${APP}*.deb ../${APP}*.changes ../${APP}*.asc ../${APP}*.dsc
sourcedeb:
	tar -cvf ../${APP}_${VERSION}.orig.tar ../${APP}-${VERSION} --exclude-vcs --exclude 'debian'
	gzip -f9n ../${APP}_${VERSION}.orig.tar
