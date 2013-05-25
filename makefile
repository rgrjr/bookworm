# Installation and (some day) testing of Bookworm.
#
# $Id: makefile 283 2010-11-30 18:19:30Z rogers $

# install tools
modest-dir = /shared.local/mgi/modest
MODEST = perl -Mlib=${modest-dir} ${modest-dir}/
# Web file database
web-database = cgi/web-files.tbl
web-import-database = cgi/imported-web-files.tbl
# server-prefix is the server-root relative URL path, which is used to construct
# links, such as href="/${server-prefix}/projects/project.cgi"
server-prefix = bookworm
# bookworm-path is the filesystem path to server-prefix.
bookworm-path = /srv/www/htdocs/${server-prefix}

RELEASE = 0.1
# This is the number of the compatible MODEST release.
MODEST_RELEASE = 2.4

all:
	@echo Nobody here but us scripts.

install:	install-web

# Build options for maintain-cgi.pl
MAINTAIN-WEB-OPTS = --cgi-root=${bookworm-path} \
	--script-database=${web-database} --script-directory=cgi \
	--hacked-include=`cd ${modest-dir} && pwd`
IMPORT-WEB-OPTS = --cgi-root=${bookworm-path} \
	--script-database=${web-import-database} \
	--script-directory=${modest-dir}/public_html
check-web-dirs:	cgi/templates/web_map.tsv
	test -d "${bookworm-path}" && test -w "${bookworm-path}"
# Try to make this robust about whether we have an SVN client.
revision.text:		makefile .
	echo -n '${RELEASE}' > $@
	if [ -d .svn ]; then  \
	    echo ', revision ' `svnversion` >> $@; \
	fi
cgi/templates/web_map.tsv:	${web-database} revision.text
	cat ${web-database} ${web-import-database} > $@.tmp
	${MODEST}make-navmap.pl --site-layout $@.tmp \
		--modest-version "`cat revision.text`" \
		--base-url ${server-prefix} > $@
	rm -f $@.tmp
install-web:	check-web-dirs
	${MODEST}maintain-cgi.pl ${MAINTAIN-WEB-OPTS} --oper='install'
	${MODEST}maintain-cgi.pl ${IMPORT-WEB-OPTS} --oper='install'
# Maintenance tools, intended for development.
cmp-web:
	${MODEST}maintain-cgi.pl ${MAINTAIN-WEB-OPTS} --oper=cmp
diff-web:
	${MODEST}maintain-cgi.pl ${MAINTAIN-WEB-OPTS} --oper='diff -u'
reverse-install-web:
	${MODEST}maintain-cgi.pl ${MAINTAIN-WEB-OPTS} --oper=reverse-install

FIND-SOURCES = find . -type f | egrep '\.(p[lm]|cgi)$$' | grep -v old | sort
ETAGS = etags --no-globals
tags:
	${FIND-SOURCES} | ${ETAGS} --regex='/=item B<\(--.*\)>/\1/' -
wc:
	${FIND-SOURCES} | xargs wc

clean:
	rm -f revision.text cgi/templates/web_map.tsv
