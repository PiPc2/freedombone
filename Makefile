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
	install -m 755 src/${APP}-client ${DESTDIR}${PREFIX}/bin
	install -m 755 src/${APP}-remote ${DESTDIR}${PREFIX}/bin
	install -m 755 src/${APP}-config ${DESTDIR}${PREFIX}/bin
	install -m 755 src/${APP}-sec ${DESTDIR}${PREFIX}/bin
	install -m 755 src/${APP}-addcert ${DESTDIR}${PREFIX}/bin
	install -m 755 src/${APP}-addlist ${DESTDIR}${PREFIX}/bin
	install -m 755 src/${APP}-addemail ${DESTDIR}${PREFIX}/bin
	install -m 755 src/${APP}-renew-cert ${DESTDIR}${PREFIX}/bin
	mkdir -m 755 -p ${DESTDIR}${PREFIX}/share/man/man1
	install -m 644 man/${APP}.1.gz ${DESTDIR}${PREFIX}/share/man/man1
	install -m 644 man/${APP}-prep.1.gz ${DESTDIR}${PREFIX}/share/man/man1
	install -m 644 man/${APP}-client.1.gz ${DESTDIR}${PREFIX}/share/man/man1
	install -m 644 man/${APP}-remote.1.gz ${DESTDIR}${PREFIX}/share/man/man1
	install -m 644 man/${APP}-config.1.gz ${DESTDIR}${PREFIX}/share/man/man1
	install -m 644 man/${APP}-sec.1.gz ${DESTDIR}${PREFIX}/share/man/man1
	install -m 644 man/${APP}-addcert.1.gz ${DESTDIR}${PREFIX}/share/man/man1
	install -m 644 man/${APP}-addlist.1.gz ${DESTDIR}${PREFIX}/share/man/man1
	install -m 644 man/${APP}-addemail.1.gz ${DESTDIR}${PREFIX}/share/man/man1
	install -m 644 man/${APP}-renew-cert.1.gz ${DESTDIR}${PREFIX}/share/man/man1
uninstall:
	rm -f ${PREFIX}/share/man/man1/${APP}.1.gz
	rm -f ${PREFIX}/share/man/man1/${APP}-prep.1.gz
	rm -f ${PREFIX}/share/man/man1/${APP}-client.1.gz
	rm -f ${PREFIX}/share/man/man1/${APP}-remote.1.gz
	rm -f ${PREFIX}/share/man/man1/${APP}-config.1.gz
	rm -f ${PREFIX}/share/man/man1/${APP}-sec.1.gz
	rm -f ${PREFIX}/share/man/man1/${APP}-addcert.1.gz
	rm -f ${PREFIX}/share/man/man1/${APP}-addlist.1.gz
	rm -f ${PREFIX}/share/man/man1/${APP}-addemail.1.gz
	rm -f ${PREFIX}/share/man/man1/${APP}-renew-cert.1.gz
	rm -rf ${PREFIX}/share/${APP}
	rm -f ${PREFIX}/bin/${APP}
	rm -f ${PREFIX}/bin/${APP}-prep
	rm -f ${PREFIX}/bin/${APP}-client
	rm -f ${PREFIX}/bin/${APP}-remote
	rm -f ${PREFIX}/bin/${APP}-config
	rm -f ${PREFIX}/bin/${APP}-sec
	rm -f ${PREFIX}/bin/${APP}-addcert
	rm -f ${PREFIX}/bin/${APP}-addlist
	rm -f ${PREFIX}/bin/${APP}-addemail
	rm -f ${PREFIX}/bin/${APP}-renew-cert
clean:
	rm -f \#* \.#* debian/*.substvars debian/*.log
	rm -fr deb.* debian/${APP}
	rm -f ../${APP}*.deb ../${APP}*.changes ../${APP}*.asc ../${APP}*.dsc
sourcedeb:
	tar -cvf ../${APP}_${VERSION}.orig.tar ../${APP}-${VERSION} --exclude-vcs --exclude 'debian'
	gzip -f9n ../${APP}_${VERSION}.orig.tar
