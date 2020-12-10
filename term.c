#include <termios.h>

static struct termios saved;

void term_setup() {
  struct termios tattr;
  // Save current terminal attributes
  tcgetattr(0, &saved);
  // Get a copy to modify
  tcgetattr(0, &tattr);
  // Clear CANON and ECHO & set needed noncanonical attrs
  tattr.c_lflag &= ~(ICANON | ECHO);
  tattr.c_cc[VMIN] = 1; // Minimum # of bytes per read
  tattr.c_cc[VTIME] = 0; // No read timeout
  tcsetattr(0, TCSAFLUSH, &tattr);
}

void reset_term() {
  tcsetattr (0, TCSANOW, &saved);
}
