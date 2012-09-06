prefix=/usr/local

all:
	mkdir -p $(prefix)/lib/pgtop
	rm -rf $(prefix)/lib/pgtop/*
	cp lib/* $(prefix)/lib/pgtop/
	cp bin/* $(prefix)/bin/

archive:
	$(eval GITPREF := pgtop-$(shell git describe HEAD --abbrev))
	git archive HEAD --prefix=$(GITPREF)/ | gzip > $(GITPREF).tar.gz
