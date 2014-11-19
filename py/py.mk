# where py object files go (they have a name prefix to prevent filename clashes)
PY_BUILD = $(BUILD)/py

# where autogenerated header files go
HEADER_BUILD = $(BUILD)/genhdr

# file containing qstr defs for the core Python bit
PY_QSTR_DEFS = $(PY_SRC)/qstrdefs.h

# some code is performance bottleneck and compiled with other optimization options
CSUPEROPT = -O3

# py object files
PY_O_BASENAME = \
	nlrx86.o \
	nlrx64.o \
	nlrthumb.o \
	nlrsetjmp.o \
	malloc.o \
	gc.o \
	qstr.o \
	vstr.o \
	unicode.o \
	mpz.o \
	lexer.o \
	lexerstr.o \
	lexerunix.o \
	parse.o \
	parsehelper.o \
	scope.o \
	compile.o \
	emitcommon.o \
	emitpass1.o \
	emitcpy.o \
	emitbc.o \
	asmx64.o \
	emitnx64.o \
	asmx86.o \
	emitnx86.o \
	asmthumb.o \
	emitnthumb.o \
	emitinlinethumb.o \
	asmarm.o \
	emitnarm.o \
	formatfloat.o \
	parsenumbase.o \
	parsenum.o \
	emitglue.o \
	runtime.o \
	nativeglue.o \
	stackctrl.o \
	argcheck.o \
	map.o \
	obj.o \
	objarray.o \
	objbool.o \
	objboundmeth.o \
	objcell.o \
	objclosure.o \
	objcomplex.o \
	objdict.o \
	objenumerate.o \
	objexcept.o \
	objfilter.o \
	objfloat.o \
	objfun.o \
	objgenerator.o \
	objgetitemiter.o \
	objint.o \
	objint_longlong.o \
	objint_mpz.o \
	objlist.o \
	objmap.o \
	objmodule.o \
	objobject.o \
	objproperty.o \
	objnone.o \
	objnamedtuple.o \
	objrange.o \
	objreversed.o \
	objset.o \
	objslice.o \
	objstr.o \
	objstrunicode.o \
	objstringio.o \
	objtuple.o \
	objtype.o \
	objzip.o \
	opmethods.o \
	sequence.o \
	stream.o \
	binary.o \
	builtin.o \
	builtinimport.o \
	builtinevex.o \
	builtintables.o \
	modarray.o \
	modcollections.o \
	modgc.o \
	modio.o \
	modmath.o \
	modcmath.o \
	modmicropython.o \
	modstruct.o \
	modsys.o \
	vm.o \
	bc.o \
	showbc.o \
	repl.o \
	smallint.o \
	pfenv.o \
	pfenv_printf.o \
	../extmod/moductypes.o \
	../extmod/modujson.o \
	../extmod/modure.o \
	../extmod/moduzlib.o \
	../extmod/moduheapq.o \

# prepend the build destination prefix to the py object files
PY_O = $(addprefix $(PY_BUILD)/, $(PY_O_BASENAME))

# Anything that depends on FORCE will be considered out-of-date
FORCE:
.PHONY: FORCE

$(HEADER_BUILD)/py-version.h: FORCE
	$(Q)$(PY_SRC)/py-version.sh > $@.tmp
	$(Q)if [ -f "$@" ] && cmp -s $@ $@.tmp; then rm $@.tmp; else echo "Generating $@"; mv $@.tmp $@; fi

# qstr data

# Adding an order only dependency on $(HEADER_BUILD) causes $(HEADER_BUILD) to get
# created before we run the script to generate the .h
$(HEADER_BUILD)/qstrdefs.generated.h: $(PY_QSTR_DEFS) $(QSTR_DEFS) $(PY_SRC)/makeqstrdata.py mpconfigport.h $(PY_SRC)/mpconfig.h | $(HEADER_BUILD)
	$(ECHO) "CPP $<"
	$(Q)$(CPP) $(CFLAGS) $(PY_QSTR_DEFS) -o $(HEADER_BUILD)/qstrdefs.preprocessed.h
	$(ECHO) "makeqstrdata $(PY_QSTR_DEFS) $(QSTR_DEFS)"
	$(Q)$(PYTHON) $(PY_SRC)/makeqstrdata.py $(HEADER_BUILD)/qstrdefs.preprocessed.h $(QSTR_DEFS) > $@

# We don't know which source files actually need the generated.h (since
# it is #included from str.h). The compiler generated dependencies will cause
# the right .o's to get recompiled if the generated.h file changes. Adding
# an order-only dependendency to all of the .o's will cause the generated .h
# to get built before we try to compile any of them.
$(PY_O): | $(HEADER_BUILD)/qstrdefs.generated.h $(HEADER_BUILD)/py-version.h

# emitters

$(PY_BUILD)/emitnx64.o: CFLAGS += -DN_X64
$(PY_BUILD)/emitnx64.o: py/emitnative.c
	$(call compile_c)

$(PY_BUILD)/emitnx86.o: CFLAGS += -DN_X86
$(PY_BUILD)/emitnx86.o: py/emitnative.c
	$(call compile_c)

$(PY_BUILD)/emitnthumb.o: CFLAGS += -DN_THUMB
$(PY_BUILD)/emitnthumb.o: py/emitnative.c
	$(call compile_c)

$(PY_BUILD)/emitnarm.o: CFLAGS += -DN_ARM
$(PY_BUILD)/emitnarm.o: py/emitnative.c
	$(call compile_c)

# optimising gc for speed; 5ms down to 4ms on pybv2
$(PY_BUILD)/gc.o: CFLAGS += $(CSUPEROPT)

# optimising vm for speed, adds only a small amount to code size but makes a huge difference to speed (20% faster)
$(PY_BUILD)/vm.o: CFLAGS += $(CSUPEROPT)
