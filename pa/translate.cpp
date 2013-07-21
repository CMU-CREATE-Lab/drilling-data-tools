#include <string>
#include <vector>
#include <map>
#include <iostream>
#include <fstream>
#include <boost/cregex.hpp>
#include <math.h>
#include <assert.h>

using namespace std;
using namespace boost;

#include "csv.h"

#include "event.h"

vector<string> header;
vector<string> recordvec;

vector<event> events;

void field(void *data, size_t len, void *foo) {
  recordvec.push_back(string((char*)data));
}

int lineno;
int records;
int no_location;

double parse_degrees(const std::string &deg) {
  static RegEx r("(-?\\d+)º (\\d+)' ([\\d\\.]+)''");
  if (r.Match(deg)) {
    double d = atof(r.What(1).c_str());
    double m = atof(r.What(2).c_str());
    double s = atof(r.What(3).c_str());
    return (d < 0 ? -1 : 1) * (fabs(d) + (m / 60) + (s / 3600));
  } else if (deg == "") {
    return std::numeric_limits<double>::quiet_NaN();
  } else {
    fprintf(stderr, "couldn't parse degrees >%s<\n", deg.c_str());
    exit(0);
  }
}

double parse_date(const std::string &date) {
  static RegEx r("(\\d+)/(\\d+)/(\\d+)");
  if (r.Match(date)) {
    int m = atof(r.What(1).c_str());
    //int d = atof(r.What(2).c_str());
    int y = atof(r.What(3).c_str());
    assert(y>1700);
    
    return y + (m / 12.0);
  } else {
    fprintf(stderr, "Can't parse date >%s<\n", date.c_str());
    exit(0);
  }
}

void record(int x, void *foo) {
  lineno++;
  if (header.size() == 0) {
    header = recordvec;
    fprintf(stderr, "Got header of %d fields\n", (int)header.size());
  } else if (header.size() != recordvec.size()) {
    fprintf(stderr, "Line %d has %d fields but header has %d fields.  Skipping.\n",
            lineno, (int) recordvec.size(), (int) header.size());
  } else {
    map<string, string> recordmap;
    for (unsigned i = 0; i < header.size(); i++) {
      recordmap[header[i]] = recordvec[i];
    }
    records++;

    event e;
    e.lat = parse_degrees(recordmap["LATITUDE_DEGREES"]);
    e.lon = parse_degrees(recordmap["LONGITUDE_DEGREES"]);
    e.time = parse_date(recordmap["PERMIT_ISSUED_DATE"]);
    
    if (!isnan(e.lat) && !isnan(e.lon)) {
      events.push_back(e);
    } else {
      no_location++;
    }
  }
  recordvec.clear();
}

int main(int argc, char **argv) {
  ifstream in("Permits_Issued_Detail.csv");
  string csv = string(istreambuf_iterator<char>(in),
                      istreambuf_iterator<char>());
  fprintf(stderr, "read %d bytes\n", (int) csv.length());

  struct csv_parser parser;
  csv_init(&parser, CSV_APPEND_NULL);
  csv_parse(&parser, csv.c_str(), csv.size(), field, record, NULL);
  csv_fini(&parser, field, record, NULL);
  fprintf(stderr, "Parsed %d of %d records successfully (%d had no location)\n", (int) events.size(), records, no_location);
  FILE *out = fopen("out.events", "wb");
  fwrite((void*) &events[0], events.size() * sizeof(events[0]), 1, out);
  fclose(out);
  fprintf(stderr, "Wrote %d events to out.events\n", (int) events.size());
  return 0;
}
