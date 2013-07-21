#include "event.h"
#include <fstream>
#include <string>
#include <vector>
#include <math.h>
#include <algorithm>
#include "FfmpegEncoder.h"
#include "cpp_utils.h"

using namespace std;

// #define WIDTH 2560
// #define HEIGHT 1600

#define WIDTH 1920
#define HEIGHT 1200

class Stats {
public:
  double minimum, maximum;
  Stats() : minimum(numeric_limits<double>::infinity()),
            maximum(-numeric_limits<double>::infinity()) {}
  void add(double x) {
    minimum = min(minimum, x);
    maximum = max(maximum, x);
  }
  string to_string() {
    char buf[200];
    sprintf(buf, "[%g ... %g]", minimum, maximum);
    return buf;
  }
};
  
void write_ppm(const std::string &filename, int width, int height, unsigned char *pixels) {
  FILE *out = fopen(filename.c_str(), "wb");
  fprintf(out, "P6\n#\n%d %d\n255\n", width, height);
  fwrite((void*)pixels, width * height * 3, 1, out);
  fclose(out);
  fprintf(stderr, "Wrote %dx%d pixels to %s\n", width, height, filename.c_str());
}
  
void draw_circle(float framebuf[][WIDTH], int xc, int yc, double radius) {
  int ceil_radius = (int)ceil(radius)+1;
  for (int y = max(0, yc - ceil_radius); y < min(HEIGHT, yc + ceil_radius + 1); y++) {
    for (int x = max(0, xc - ceil_radius); x < min(WIDTH, xc + ceil_radius + 1); x++) {
      framebuf[y][x] += min(1.0, max(0.0, radius - sqrt((x-xc)*(x-xc) + (y-yc)*(y-yc))));
    }
  }
}

int main(int argc, char **argv) {
  ifstream in("out.events");
  string csv = string(istreambuf_iterator<char>(in),
                      istreambuf_iterator<char>());
  vector<Event> events(csv.size() / sizeof(Event));
  memcpy(&events[0], csv.c_str(), events.size() * sizeof(Event));
  fprintf(stderr, "Read %d events from out.events\n", (int) events.size());

  Stats lat, lon, time;
  for (unsigned i = 0; i < events.size(); i++) {
    Event e = events[i];
    lat.add(e.lat);
    lon.add(e.lon);
    time.add(e.time);
  }
  fprintf(stderr, "lat range: %s\n", lat.to_string().c_str());
  fprintf(stderr, "lon range: %s\n", lon.to_string().c_str());
  fprintf(stderr, "time range: %s\n", time.to_string().c_str());

  Stats xs, ys, fs;
  double scale = (WIDTH-1) / 4.22219;

  int nframes = 300;
  
  float framebuf[HEIGHT][WIDTH];

  FfmpegEncoder::ffmpeg_path_override = "../../libs/tmca/tilestacktool/ffmpeg/osx/ffmpeg";
  int fps = 60;
  int compression = 24;
  FfmpegEncoder out(string_printf("out-%dx%d.mp4", WIDTH, HEIGHT), WIDTH, HEIGHT, fps, compression);
  
  double start = 1956.5;
  double end = 2014;

  for (int frame = 0; frame < nframes; frame++) {
    memset(framebuf, 0, sizeof(framebuf));
    for (unsigned i = 0; i < events.size(); i++) {
      Event e = events[i];
      double x = (e.lon - (-80.5187)) * cos(41.0 * M_PI / 180.0);
      double y = (42.2674 - e.lat);
      double f = (e.time - start) * nframes / (end - start);

      x *= scale;
      y *= scale;
      xs.add(x);
      ys.add(y);
      fs.add(f);

      double age = frame - f;
      double radius = 0;
      if (age > 4) {
        radius = 1;
      } else if (age > 2) {
        radius = 1.5;
      } else if (age > 0) {
        radius = 2.0;
      }
      if (radius > 0) {
        draw_circle(framebuf, (int)x, (int)y, radius);
      }
    }
    unsigned char framebuf8[HEIGHT][WIDTH][3];
    for (unsigned y = 0; y < HEIGHT; y++) {
      for (unsigned x = 0; x < WIDTH; x++) {
        framebuf8[y][x][0] = min(255.0, framebuf[y][x] * 256.0);
        framebuf8[y][x][1] = min(255.0, framebuf[y][x] * 100.0);
        framebuf8[y][x][2] = min(255.0, framebuf[y][x] *  50.0);
      }
    }
    out.write_pixels((unsigned char*) framebuf8, sizeof(framebuf8));
    //std::string filename = string_printf("frame%03d.ppm", frame);
    //write_ppm(filename, WIDTH, HEIGHT, (unsigned char*) framebuf8);
  }
  out.close();

  fprintf(stderr, "x range: %s\n", xs.to_string().c_str());
  fprintf(stderr, "y range: %s\n", ys.to_string().c_str());
  fprintf(stderr, "frame range: %s\n", fs.to_string().c_str());
  return 0;
}

