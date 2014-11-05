#include <Rmath.h>
#include <R.h>
#include <Rinternals.h>

/* #define LOG REprintf */
#define LOG if(0){}

SEXP get_cis_ranges (SEXP gex_chr, SEXP gex_start, SEXP gex_end, SEXP gt_chr, SEXP gt_pos, SEXP cis_window) {

  const R_xlen_t num_genes = length(gex_chr);
  const R_xlen_t num_snps = length(gt_chr);

  R_xlen_t geneIdx = 0;
  R_xlen_t snpStart = -1;
  R_xlen_t snpEnd = 0;
  const int cis = INTEGER(cis_window)[0];
  const int* start = INTEGER(gex_start);
  const int* end = INTEGER(gex_end);
  const int* pos = INTEGER(gt_pos);
  const char* chr_l;

  SEXP sxp_from = PROTECT(allocVector(INTSXP, num_genes));
  SEXP sxp_to = PROTECT(allocVector(INTSXP, num_genes));
  int* from = INTEGER(sxp_from);
  int* to = INTEGER(sxp_to);

  /* for each gene */
  do {

    LOG("geneIdx = %d\n", geneIdx);

    if((snpStart >= num_snps) || (snpEnd >= num_snps) || (geneIdx >= num_genes)) {
      break;
    }

    const char* chr_g = CHAR(STRING_ELT(gex_chr, geneIdx));
    const R_xlen_t start_g = start[geneIdx];
    const R_xlen_t end_g = end[geneIdx];

    R_xlen_t somethingMatchedCurrentGene = 0;

    LOG("snpStart = %d\n", snpStart);
    /* for each snp */
    do {

      if(snpEnd >= length(gt_pos)) {
	LOG("end of file.\n");
	break;
      }

      chr_l = CHAR(STRING_ELT(gt_chr, snpEnd));
      const R_xlen_t pos_l = pos[snpEnd];

      if(strcmp(chr_g, chr_l)) {
	LOG("different chromosome: gene has %s, SNP has %s\n", chr_g, chr_l);
	break;
      }

      if(pos_l < (start_g - cis)) {
	LOG("earlier\n");
	snpStart = snpEnd;
	snpEnd++;
	continue;
      }

      if(pos_l > (end_g + cis)) {
	LOG("later\n");
	break;
      }

      somethingMatchedCurrentGene = 1;
      snpEnd++;

    } while (1);

    if(somethingMatchedCurrentGene) {
      from[geneIdx] = snpStart + 2;
      to[geneIdx] = snpEnd;
      if(strcmp(chr_l, chr_g)) {
	snpStart = snpEnd - 1;
      }
    }

    snpEnd = snpStart + 1;
    geneIdx++;

  } while (1) ;

  SEXP ans = PROTECT(allocVector(VECSXP, 2));
  SET_VECTOR_ELT(ans, 0, sxp_from);
  SET_VECTOR_ELT(ans, 1, sxp_to);
  UNPROTECT(3);
  return ans;

}
