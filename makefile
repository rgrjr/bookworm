# Installation and (some day) testing of Bookworm.
#
# [created ("Initial import from lost repo").  -- rgr, 25-May-13.]
#

# install tools
modest-dir = /scratch/rogers/modest
MODEST = perl -Mlib=${modest-dir} ${modest-dir}/
# Web file database
web-database = cgi/web-files.tbl
# server-prefix is the server-root relative URL path, which is used to construct
# links, such as href="/${server-prefix}/projects/project.cgi"
server-prefix = bookworm
# bookworm-path is the filesystem path to server-prefix.
bookworm-path = /srv/www/htdocs/${server-prefix}

RELEASE = 0.1
# This is the number of the compatible MODEST release.
MODEST_RELEASE = 2.29

all:
	@echo Nobody here but us scripts.

install:	install-web

# Build options for maintain-cgi.pl
MAINTAIN-WEB-OPTS = --cgi-root=${bookworm-path} \
	--script-database=${web-database} \
	--script-directory=cgi --script-directory=${modest-dir}/public_html \
	--production-include=`pwd` \
	--hacked-include=`cd ${modest-dir} && pwd`
check-web-dirs:	cgi/web_map.tsv
	test -d "${bookworm-path}" && test -w "${bookworm-path}"
# Create the Web map from web-files.tbl.
transform_navmap = \
	'chomp; \
	 my ($$script, $$status, $$type, $$page_name, $$menu) = split("\t"); \
	 print join("\t", "page", $$script, $$page_name, $$menu || ""), "\n";'
cgi/web_map.tsv:	${web-database}
	echo -n 'modest_version	${RELEASE}' > $@.tmp
	if [ -d .git ]; then  \
	    echo -n ', revision ' >> $@.tmp; \
	    git log -n 1 --pretty=format:%h >> $@.tmp; \
	    echo -n ' on ' >> $@.tmp; \
	    echo -n `git branch --contains | fgrep '*' | cut -c3-` >> $@.tmp; \
	fi
	echo >> $@.tmp
	echo "server_prefix	${server-prefix}" >> $@.tmp
	perl -ne ${transform_navmap} < ${web-database} >> $@.tmp
	mv $@.tmp $@
install-web:	check-web-dirs
	${MODEST}bin/maintain-cgi.pl ${MAINTAIN-WEB-OPTS} --oper='install'
# Maintenance tools, intended for development.
cmp-web:
	${MODEST}bin/maintain-cgi.pl ${MAINTAIN-WEB-OPTS} --oper=cmp
diff-web:
	${MODEST}bin/maintain-cgi.pl ${MAINTAIN-WEB-OPTS} --oper='diff -u'
reverse-install-web:
	${MODEST}bin/maintain-cgi.pl ${MAINTAIN-WEB-OPTS} --oper=reverse-install

FIND-SOURCES = find . -type f | egrep '\.(p[lm]|cgi)$$' | grep -v old | sort
ETAGS = etags --no-globals
tags:
	${FIND-SOURCES} | ${ETAGS} --regex='/=item B<\(--.*\)>/\1/' -
wc:
	${FIND-SOURCES} | xargs wc

clean:
	rm -f cgi/web_map.tsv *.tmp
