#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <math.h>

#define __STDC_FORMAT_MACROS
#include <inttypes.h>

/* #define LOG(X) fprintf(stderr, X) */
#define LOG(X) {}

#define MAX(a,b) ((a)<(b)) ? (b) : (a)

#define MAX_LINE_LENGTH (1024 * 1024)
#define MAX_CHR_LENGTH 255
#define START_GT_SIZE 100000

static char* gex_filename;
static int64_t cis_window;
static FILE* GT;
static FILE* GEX;

static char line_buffer[MAX_LINE_LENGTH + 1];

static char gex_id[MAX_LINE_LENGTH], gex_chr[MAX_LINE_LENGTH];
static int64_t gex_start, gex_end;
static int64_t out_from, out_to, gt_line;

static size_t gt_len;
static char **gt_chr;
static int64_t *gt_pos;

void error(char* msg) {
  fprintf(stderr, "ERROR: %s\n", msg);
  exit(1);
}

int next_gene() {
  if(feof(GEX)) {
    return 0;
  }

  fgets(line_buffer, MAX_LINE_LENGTH, GEX);
  if(feof(GEX)) {
    return 0;
  }

  char* token;
  token = strtok(line_buffer, "\t");
  if(token == NULL) {
    error("malformed genes positions file");
  }
  strncpy(gex_id, token, MAX_LINE_LENGTH);

  token = strtok(NULL, "\t");
  if(token == NULL) {
    error("malformed genes positions file");
  }
  strncpy(gex_chr, token, MAX_LINE_LENGTH);

  token = strtok(NULL, "\t");
  if(token == NULL) {
    error("malformed genes positions file");
  }
  gex_start = atol(token);

  token = strtok(NULL, "\t");
  if(token == NULL) {
    error("malformed genes positions file");
  }
  gex_end = atol(token);

  out_from = 0;
  out_to = 0;

  return 1;
}

int slurp_gt() {
  static size_t buffer_size = START_GT_SIZE;
  gt_len = 0;

  gt_chr = (char**) malloc(buffer_size * sizeof(char*));
  for(size_t i = 0; i < buffer_size; i++) {
    gt_chr[i] = (char*) malloc((MAX_CHR_LENGTH + 1) * sizeof(char));
  }
  gt_pos = (int64_t*) malloc(buffer_size * sizeof(int64_t));

  while(!feof(GT)) {

    if(gt_len >= buffer_size) {
      const size_t new_buffer_size = 2 * buffer_size;
      /* fprintf(stderr, "expanding buffer: from %ld to %ld\n", buffer_size, new_buffer_size); */
      gt_chr = (char**) realloc(gt_chr, new_buffer_size * sizeof(char*));
      if(gt_chr == NULL) {
	error("can't alloc memory");
      }
      LOG("done\n");
      for(size_t i = buffer_size; i < new_buffer_size; i++) {
	gt_chr[i] = (char*) malloc((MAX_CHR_LENGTH + 1) * sizeof(char));
      }
      gt_pos = (int64_t*) realloc(gt_pos, new_buffer_size * sizeof(int64_t));
      buffer_size = new_buffer_size;
    }

    fgets(line_buffer, MAX_LINE_LENGTH, GT);
    if(feof(GT)) {
      break;
    }

    char* token;
    /* SNP ID: just discard it */
    token = strtok(line_buffer, "\t");
    if(token == NULL) {
      error("malformed genotype positions file");
    }

    token = strtok(NULL, "\t");
    if(token == NULL) {
      error("malformed genotype positions file");
    }
    strncpy(gt_chr[gt_len], token, MAX_CHR_LENGTH);

    token = strtok(NULL, "\t");
    if(token == NULL) {
      error("malformed genotype positions file");
    }
    gt_pos[gt_len] = atol(token);

    gt_len++;

  }

}

int poscmp(const char* chrA, const int64_t pA, const char* chrB, const int64_t pB) {
  int chrCmp = strcmp(chrA, chrB);
  if(chrCmp != 0) {
    return chrCmp;
  }
  return pA - pB;
}

void print_range() {
  fprintf(stdout,
	  "%s\t%" PRIu64 "\t%" PRIu64 "\n",
	  gex_id, out_from + 1, out_to);
}

int main(int argc, char** argv) {

  if(argc != 3) {
    fprintf(stderr, "wrong number of arguments: expected 2, got %d instead\n", argc - 1);
    fprintf(stderr, "Computes cis-ranges from sorted genotype and genes positions annotation tables\n"
	    "\nUsage:\n"
	    "data-cis-ranges gt-positions-file.tab cis-window-size < gex-position-file.tab\n"
	    "\ngenotype positions files should have 3 tab-delimited columns:\nSNPID (ignored), chromosome, position.\n"
	    "genes positions files should have 4 tab-delimited columns:\ngeneID, chromosome, start, end.\n"
	    "Genotypes and genes positions tables must be sorted\nby chromosome (alphabetically) and by start position (numerically).\n"
	    "I.e., call 'sort -k2,2 -k3,3g' on them both before passing them to this program.\n"
	    , argc - 1);
    exit(1);
  }

  GEX = stdin;
  GT = fopen(argv[1], "r");
  if(GT == NULL) {
    error("can't open SNPs positions file");
  }
  cis_window = atol(argv[2]);
  fprintf(stderr, "cis window: %ld\n", cis_window);

  LOG("init: reading full genotype position data in memory...\n");
  slurp_gt();

  int64_t prev_start = 0;
  int64_t prev_from = 0;
  char prev_chr[MAX_CHR_LENGTH + 1];
  strncpy(prev_chr, "", MAX_CHR_LENGTH);

  while(1) {

    LOG("next gene...\n");
    int status = next_gene();
    if(!status) {
      LOG("reached end of gex file\n");
      break;
    }

    /* check that we are sorted indeed*/
    if(prev_start > 0) {
      if(poscmp(gex_chr, gex_start, prev_chr, prev_start) < 0) {
	error("expression positions file is not sorted");
      }
    }
    prev_start = gex_start;
    strncpy(prev_chr, gex_chr, MAX_CHR_LENGTH);

    /* find start position */
    LOG("finding start\n");
    for(out_from = prev_from;
	out_from < gt_len &&
	  poscmp(gt_chr[out_from], gt_pos[out_from], gex_chr, MAX(0, gex_start - cis_window)) < 0;
	out_from++) {
    }
    prev_from = out_from;

    /* find end position */
    LOG("finding end\n");
    for(out_to = out_from;
	out_to < gt_len &&
	  poscmp(gt_chr[out_to], gt_pos[out_to], gex_chr, MAX(gex_end, gex_end + cis_window)) <= 0;
	out_to++) {
    }

    LOG("outputting if needed\n");
    if(out_to > out_from) {
      /* we actually do have some cis SNPs*/
      print_range();
      LOG("printed\n");
    }

  };

  return 0;
}
