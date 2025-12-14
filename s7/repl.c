/* gcc -o repl repl.c s7.o -Wl,-export-dynamic -lm -I. -ldl */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifndef _MSC_VER
  #include <errno.h>
  #include <unistd.h>
#endif

#include "s7.h"

#ifndef _MSC_VER
static char *realdir(s7_scheme *sc, const char *filename)
{
  char *path;
  char *p;

  if (!strchr(filename, '/'))
    {
      if (access("libc_s7.so", F_OK) != 0)
	{
	  if ((access("libc.scm", F_OK) == 0) &&
	      (access("cload.scm", F_OK) == 0))
	    {
	      s7_load(sc, "cload.scm");
	      s7_load(sc, "libc.scm");
	      return(NULL);
	    }
	  fprintf(stderr, "%s needs libc_s7.so (give the explicit repl pathname or build it by running: repl libc.scm)\n", filename); /* env PATH=/home/bil/cl repl */
	  exit(2);
	}
      return(NULL);  /* we're in the libc_s7.so directory, I hope (user could start a version of s7 that does not match the local libc_s7.so...) */
    }
  if (!(path = realpath(filename, NULL)))
    {
      fprintf(stderr, "%s: %s\n", strerror(errno), filename);
      exit(2);
    }
  if (!(p = strrchr(path, '/')))
    {
      free(path);
      fprintf(stderr, "please provide the full pathname for %s\n", filename);
      exit(2);
    }
  if (p > path) *p = '\0'; else p[1] = 0;
  return(path);
}
#endif

int main(int argc, char **argv)
{
  s7_scheme *sc;
  
  sc = s7_init();
  if (argc >= 2)
    for (int32_t i = 1; i < argc; i++)
      {
	if (strcmp(argv[i], "-e") == 0)         /* repl -e '(+ 1 2)' */
	  {
	    s7_pointer x;
	    char *s1;
	    x = s7_eval_c_string(sc, argv[++i]);
	    fprintf(stdout, "%s\n", s1 = s7_object_to_c_string(sc, x));
	    free(s1);
	  }
	else
	  if (strcmp(argv[i], "--version") == 0)
	    fprintf(stdout, "s7: %s, %s\n", S7_VERSION, S7_DATE);
	  else
	    {
	      fprintf(stderr, "load %s\n", argv[i]);  /* repl test.scm */
	      errno = 0;
	      if (!s7_load(sc, argv[i]))
		{
		  fprintf(stderr, "%s: %s\n", strerror(errno), argv[i]);
		  return(2);
		}}}
  else
    {
#ifdef _MSC_VER
  while (true)
    {
      char buffer[512];
      fprintf(stdout, "\n> ");
      if (!fgets(buffer, 512, stdin)) break;  /* error or ctrl-D */
      if (((buffer[0] != '\n') || (strlen(buffer) > 1)))
	{
	  char response[1024];
	  snprintf(response, 1024, "(write %s)", buffer);
	  s7_eval_c_string(sc, response);
	}
    }
  fprintf(stdout, "\n");
  if (ferror(stdin))
    fprintf(stderr, "read error on stdin\n");
#else
#ifdef S7_LOAD_PATH
      s7_add_to_load_path(sc, S7_LOAD_PATH);
#else
      char *dir; 
      dir = realdir(sc, argv[0]);
      if (dir)
	{
	  s7_add_to_load_path(sc, dir);
	  free(dir);
	}
#endif
      s7_repl(sc);
#endif
    }
  return(0);
}
