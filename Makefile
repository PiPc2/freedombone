APP=freedombone
VERSION=1.01
RELEASE=1
PREFIX?=/usr/local

all:
	bash -c "./translate make"
debug:
	bash -c "./translate make"
translations:
	bash -c "./translate translations"
source:
	tar -cvf ../${APP}_${VERSION}.orig.tar ../${APP}-${VERSION} --exclude-vcs
	gzip -f9n ../${APP}_${VERSION}.orig.tar
install:
	mkdir -p ${DESTDIR}${PREFIX}/bin
	mkdir -p ${DESTDIR}/etc/freedombone
	cp -r image_build/* ${DESTDIR}/etc/freedombone
	install -m 755 src/* ${DESTDIR}${PREFIX}/bin
	install -m 755 src/${APP}-meshweb ${DESTDIR}${PREFIX}/bin/meshweb
	install -m 755 src/${APP}-controlpanel ${DESTDIR}${PREFIX}/bin/control
	install -m 755 src/${APP}-backup-local ${DESTDIR}${PREFIX}/bin/backup
	mkdir -m 755 -p ${DESTDIR}${PREFIX}/share/man/man1
	install -m 644 man/*.1.gz ${DESTDIR}${PREFIX}/share/man/man1
	bash -c "./translate install"
uninstall:
	rm -f ${PREFIX}/share/man/man1/${APP}*.1.gz
	rm -rf ${PREFIX}/share/${APP}
	rm -f ${PREFIX}/bin/${APP}*
	rm -f ${PREFIX}/bin/zeronetavahi
	rm -f ${PREFIX}/bin/mesh
	rm -f ${PREFIX}/bin/backup
	rm -f ${PREFIX}/bin/meshweb
	rm -rf /etc/freedombone
	bash -c "./translate uninstall"
clean:
	rm -f \#* \.#* debian/*.substvars debian/*.log
	rm -fr deb.* debian/${APP}
	rm -f ../${APP}*.deb ../${APP}*.changes ../${APP}*.asc ../${APP}*.dsc
