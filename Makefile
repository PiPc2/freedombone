APP=freedombone
VERSION=1.02
RELEASE=1
PREFIX?=/usr/local

all:
debug:
translations:
	bash -c "./translate make"
rmtranslations:
	bash -c "./translate remove"
alltranslations:
	bash -c "./translate translations"
tidy:
	./tidyup src/*
source:
	tar -cvf ../${APP}_${VERSION}.orig.tar ../${APP}-${VERSION} --exclude-vcs
	gzip -f9n ../${APP}_${VERSION}.orig.tar
install:
	mkdir -p ${DESTDIR}${PREFIX}/bin
	mkdir -p ${DESTDIR}/usr/share/${APP}/base
	mkdir -p ${DESTDIR}/usr/share/${APP}/apps
	mkdir -p ${DESTDIR}/usr/share/${APP}/utils
	mkdir -p ${DESTDIR}/usr/share/${APP}/avatars
	mkdir -p ${DESTDIR}/etc/${APP}
	cp -r image_build/* ${DESTDIR}/etc/${APP}
	cp img/backgrounds/${APP}_*.png ${DESTDIR}${PREFIX}/share
	cp img/avatars/* ${DESTDIR}/usr/share/${APP}/avatars
	cp src/* ${DESTDIR}${PREFIX}/bin
	cp src/${APP}-controlpanel ${DESTDIR}${PREFIX}/bin/control
	cp src/${APP}-mesh-batman ${DESTDIR}${PREFIX}/bin/batman
	cp src/${APP}-backup-local ${DESTDIR}${PREFIX}/bin/backup
	cp src/${APP}-backup-local ${DESTDIR}${PREFIX}/bin/backup2friends
	cp src/${APP}-restore-local ${DESTDIR}${PREFIX}/bin/restore
	cp src/${APP}-restore-remote ${DESTDIR}${PREFIX}/bin/restorefromfriend
	rm -f ${DESTDIR}/usr/share/${APP}/base/*
	rm -f ${DESTDIR}/usr/share/${APP}/apps/*
	rm -f ${DESTDIR}/usr/share/${APP}/utils/*
	mv ${DESTDIR}${PREFIX}/bin/${APP}-base-* ${DESTDIR}/usr/share/${APP}/base
	mv ${DESTDIR}${PREFIX}/bin/${APP}-app-* ${DESTDIR}/usr/share/${APP}/apps
	mv ${DESTDIR}${PREFIX}/bin/${APP}-utils-* ${DESTDIR}/usr/share/${APP}/utils
	mkdir -m 755 -p ${DESTDIR}${PREFIX}/share/man/man1
	cp man/*.1.gz ${DESTDIR}${PREFIX}/share/man/man1
	cp man/${APP}-backup-local.1.gz ${DESTDIR}${PREFIX}/share/man/man1/backup.1.gz
	cp man/${APP}-restore-local.1.gz ${DESTDIR}${PREFIX}/share/man/man1/restore.1.gz
#	bash -c "./translate install"
uninstall:
	rm -f ${PREFIX}/share/${APP}_*.png
	rm -f ${PREFIX}/share/man/man1/backup.1.gz
	rm -f ${PREFIX}/share/man/man1/restore.1.gz
	rm -f ${PREFIX}/share/man/man1/${APP}*.1.gz
	rm -rf ${PREFIX}/share/${APP}
	rm -rf /usr/share/${APP}
	rm -f ${PREFIX}/bin/${APP}*
	rm -f ${PREFIX}/bin/meshavahi
	rm -f ${PREFIX}/bin/backup
	rm -f ${PREFIX}/bin/backup2friends
	rm -f ${PREFIX}/bin/restore
	rm -f ${PREFIX}/bin/restorefromfriend
	rm -f ${PREFIX}/bin/batman
	rm -rf /etc/${APP}
	bash -c "./translate uninstall"
clean:
	rm -f \#* \.#* debian/*.substvars debian/*.log src/*~
	rm -fr deb.* debian/${APP}
	rm -f ../${APP}*.deb ../${APP}*.changes ../${APP}*.asc ../${APP}*.dsc
