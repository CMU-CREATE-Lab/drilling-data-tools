LIBS=../../libs
TMCA=$(LIBS)/tmca
CPP_UTILS=$(TMCA)/cpp_utils
TILESTACKTOOL=$(TMCA)/tilestacktool

all: event2vid

translate: translate.cpp
	g++ -O3 -Wall -I/opt/local/include -I$(LIBS)/include translate.cpp $(LIBS)/lib/libcsv.a /opt/local/lib/libboost_regex-mt.a -o translate && ./translate

event2vid: event2vid.cpp
	g++ -O3 -Wall -I$(TILESTACKTOOL) -I$(CPP_UTILS) event2vid.cpp $(TILESTACKTOOL)/FfmpegEncoder.cpp $(TILESTACKTOOL)/qt-faststart.cpp $(TILESTACKTOOL)/io.cpp $(TILESTACKTOOL)/io_streamfile.cpp $(CPP_UTILS)/cpp_utils.cpp -o event2vid && ./event2vid

