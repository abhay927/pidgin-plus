# Rules on how to make object files from various sources

%.o: %.c
	$(CC) $(CFLAGS) $(DEFINES) $(INCLUDE_PATHS) -o $@ -c $<

%.c: %.xs
	$(PERL) -MExtUtils::ParseXS -e 'ExtUtils::ParseXS::process_file(filename => "$<", output => "$@", typemap => "$(PURPLE_PERL_TOP)/common/typemap");'

%.o: %.rc
	$(WINDRES) $(PURPLE_INCLUDE_PATHS) $(INCLUDE_PATHS) -i $< -o $@

%.desktop: %.desktop.in $(wildcard $(PIDGIN_TREE_TOP)/po/*.po)
	LC_ALL=C $(PERL) $(INTLTOOL_MERGE) -d -u -c $(PIDGIN_TREE_TOP)/po/.intltool-merge-cache $(PIDGIN_TREE_TOP)/po $< $@
