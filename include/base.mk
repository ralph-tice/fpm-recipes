TOP := $(CURDIR)
BUILDDIR = $(TOP)/tmp/build
CACHEDIR = $(TOP)/tmp/cache
DESTDIR = $(TOP)/tmp/dest
PKGDIR = $(TOP)/pkg

# could be "java6-runtime" here
JAVA_PACKAGE = "jdk1.8.0_45"

.PHONY: all checkversion clean distclean default_build default_fetch \
	 default_package

ifndef ITERATION
ITERATION = 1
endif

NULL :=
SPACE := $(NULL) $(NULL)

DQUOTE = "
# Stupid highlighting, let's give it another double-quote "

# Makes '-d "$1"' if $1 is a non-empty string
add_d = $(if $(strip $1),-d "$(strip $1)")

# Replace spaces with +, explode on ", then call add_d after turning + back into spaces
# This is to support: DEPENDS = "package (>= 1.0)" other_pack "some_other_packge"
# GNU Make implictly thinks a space is a delimiter, so have to change it to read the above line
quoted_map = $(foreach i,$(subst $(DQUOTE),$(SPACE),$(subst $(SPACE),+,$2)),$(call $1,$(subst +,$(SPACE),$i)))

FPM_ARGS += $(call quoted_map,add_d,$(DEPENDS))

FPM_ARGS += --iteration $(ITERATION) -v $(VERSION)

ifdef LICENSE
FPM_ARGS += --license $(LICENSE)
endif

ifdef PACKAGE_DESCRIPTION
FPM_ARGS += --description "$(PACKAGE_DESCRIPTION)"
endif

ifdef PACKAGE_PROVIDES
FPM_ARGS += $(foreach pkg,$(PACKAGE_PROVIDES),--provides $(pkg))
endif

ifdef PACKAGE_URL
FPM_ARGS += --url $(PACKAGE_URL)
endif

ifdef POSTINSTALL
FPM_ARGS += --after-install $(POSTINSTALL)
endif

ifdef POSTUNINSTALL
FPM_ARGS += --after-remove $(POSTUNINSTALL)
endif

ifdef PREINSTALL
FPM_ARGS += --before-install $(PREINSTALL)
endif

ifdef PREUNINSTALL
FPM_ARGS += --before-remove $(PREUNINSTALL)
endif

ifeq ($(FPM_SOURCE),dir)
FPM_DEB_CMD := fpm -t deb -s $(FPM_SOURCE) $(FPM_ARGS) -n $(NAME) \
	-C $(DESTDIR) --deb-user root --deb-group root .
FPM_RPM_CMD := fpm -t rpm -s $(FPM_SOURCE) $(FPM_ARGS) -n $(NAME) \
	-C $(DESTDIR) --rpm-user root --rpm-group root --rpm-os linux .
else
FPM_DEB_CMD := fpm -t deb -s $(FPM_SOURCE) $(FPM_ARGS) $(NAME)
FPM_RPM_CMD := fpm -t rpm -s $(FPM_SOURCE) $(FPM_ARGS) $(NAME)
endif

all: build package

checkversion:
ifndef VERSION
$(error Did not specify package version)
endif

$(BUILDDIR):
	mkdir -p $(BUILDDIR)

$(CACHEDIR):
	mkdir -p $(CACHEDIR)

$(DESTDIR):
	mkdir -p $(DESTDIR)

$(PKGDIR):
	mkdir -p $(PKGDIR);

$(PKGDIR)/*.deb: $(PKGDIR)
	cd $(PKGDIR) && $(FPM_DEB_CMD);

$(PKGDIR)/*.rpm: $(PKGDIR)
	cd $(PKGDIR) && $(FPM_RPM_CMD);

clean:
	rm -rf tmp

distclean: clean
	rm -rf $(PKGDIR)

pkgclean:
	rm -rf $(PKGDIR)

default_fetch: $(CACHEDIR)
	if [ ! -f $(CACHEDIR)/$(SRC_TGZ) ]; \
	then cd $(CACHEDIR) && curl --retry 5 -# -L -k -o $(SRC_TGZ) $(SOURCE_URL); \
	else echo "Using previously downloaded file"; \
	fi;

default_build: $(BUILDDIR) $(DESTDIR)

default_package: $(PKGDIR) $(PKGDIR)/*.deb $(PKGDIR)/*.rpm

fetch: default_fetch
build: default_build
package: default_package
