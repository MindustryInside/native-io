CXX := g++

CXXSOURCES := src/main/cpp

CFLAGS := -O3 -Wall -Wextra -pedantic -g -std=c++17 -I$(CXXSOURCES)
LDFLAGS := -fPIC -shared -I"$(JAVA_HOME)/include" -I"$(JAVA_HOME)/include/linux"

SOURCES := src/main/java
RESOURCES := src/main/resources
BUILD := build
CLASSES := $(BUILD)/classes
CXXBUILD := $(BUILD)/shared
LIBS := libs

MINDUSTRY := $(HOME)/.local/share/Mindustry

JAVAC := javac
JAVACFLAGS := -g -Xlint:all
JAVACFLAGS += -classpath "$(LIBS)/*"
JAVACFLAGS += -sourcepath $(SOURCES)
JAVACFLAGS += --release 8
JAR := jar
JARFLAGS := -C $(CLASSES) .
JARFLAGS += -C $(RESOURCES) .
JARFLAGS += -C $(CXXBUILD) .

version := v126.1

cxxsources := $(shell find $(CXXSOURCES) -type f -name "*.h" -or -name "*.cpp")

sources := $(shell find $(SOURCES) -type f -name "*.java")
classes = $(patsubst $(SOURCES)/%.java, $(CLASSES)/%.class, $(sources))

shared := $(CXXBUILD)/libnativeio.so
jar := $(BUILD)/nativeio.jar

ifeq ($(OS), Windows_NT)
	rm = @cmd /C del /S /Q $(1)
	cp = xcopy "$(1)" "$(2)"

	MINDUSTRY := $(APPDATA)\Mindustry

	shared := $(CXXBUILD)/nativeio.dll
	LDFLAGS := -fPIC -shared -I"$(JAVA_HOME)/include" -I"$(JAVA_HOME)/include/win32"
else
	rm = @rm -rf $(1)
	cp = cp $(1) $(2)

	MINDUSTRY := $(HOME)/Library/Application Support/Mindustry

	ifeq ($(shell uname), Darwin) 
		shared :=  $(CXXBUILD)/libnativeio.dylib
		LDFLAGS := -dynamiclib -I"$(JAVA_HOME)/include" -I"$(JAVA_HOME)/include/darwin"
	endif
endif

all: jar

libs := arc-core mindustry-core
libs := $(libs:%=$(LIBS)/%.jar)

define lib
	@printf "LIB\t%s\n" $(LIBS)/$(1).jar
	@curl 'https://jitpack.io/com/github/$(2)/$(3)/$(4)/$(3)-$(4).jar' -o $(LIBS)/$(1).jar -s
endef

shared: $(shared)
jar: $(jar)

dependencies: libs
	$(call rm, $(LIBS))
	$(call lib,arc-core,Anuken/Arc,arc-core,$(version))
	$(call lib,mindustry-core,Anuken/Mindustry,core,$(version))

$(jar): $(shared) $(classes)
	@printf "JAR\t%s\n" $@
	@$(JAR) -cf $@ $(JARFLAGS)

$(CLASSES)/%.class: $(SOURCES)/%.java
	@printf "JAVAC\t%s\n" $@
	@$(JAVAC) $(JAVACFLAGS) -d $(CLASSES) $<

$(shared):
	@printf "CXX\t%s\n" $@
	@$(CXX) $(CFLAGS) $(LDFLAGS) -o $@ $(CXXSOURCES:%=%/*.cpp)

clean:
	$(call rm,$(BUILD))

install:
	$(call cp,.\$(subst /,\,$(jar)),$(USERPROFILE)\AppData\Roaming\Mindustry\mods)