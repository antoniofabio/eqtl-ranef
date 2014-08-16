#!/usr/bin/env Rscript

gt <- "data/genotype.bySample.thin"
gex <- "data/expression.thin"
ref <- "data/ranef.tab"
ief <- "data/intef.tab"

gt <- read.table(gt,
                 header = FALSE,
                 sep = "\t",
                 colClasses = c("character", "character", "numeric"),
                 col.names = c("SNPID", "sampleID", "alleleCopyNumber"))

gex <- read.table(gex,
                  header = FALSE,
                  sep = "\t",
                  colClasses = c("character", "character", "numeric"),
                  col.names = c("reporterID", "sampleID", "expression"))

ref <- read.table(ref,
                  header = FALSE,
                  sep = "\t",
                  as.is = TRUE)
names(ref)[1] <- "sampleID"
names(ref)[-1] <- paste0("R", seq_len(length(ref) - 1))

ief <- read.table(ief,
                  header = FALSE,
                  sep = "\t",
                  as.is = TRUE)
names(ief)[1] <- "sampleID"
names(ief)[-1] <- paste0("FI", seq_len(length(ief) - 1))

tables <- list(gt, gex, ref, ief)
dat <- Reduce(merge, tables)

suppressMessages({
  library(lme4)
  library(plyr)
})

fits.full <-
    dlply(dat, .(SNPID, reporterID),
          function(x) lmer(expression ~ alleleCopyNumber * FI1 + (1|R1), data = x))

fit2tab <- function(x) {
  ans <- coefficients(summary(x))
  ans <- data.frame(term = rownames(ans),
                    ans,
                    stringsAsFactors = FALSE,
                    check.names = FALSE)
  ans$term <- sub("alleleCopyNumber:", ":", ans$term)
  ans$beta <- ans$Estimate
  ans$t <- ans$`t value`
  return(subset(ans, select = c(term, beta, t)))
}

expected.main <- ldply(fits.full, fit2tab)

##
## try running main script
##
tdir <- tempdir()

stopifnot(system(sprintf("./test-011.sh > %s/stdout 2> %s/stderr",
                         tdir, tdir)) == 0)

observed <- read.table(sprintf("%s/stdout", tdir),
                       header = FALSE,
                       sep = "\t",
                       as.is = TRUE,
                       col.names = c("reporterID", "SNPID", "pvalue", "beta", "t", "nobs", "term", "cis"))

compare.main <- merge(observed, expected.main, by = c("reporterID", "SNPID", "term"),
                      suffixes = c(".observed", ".expected"))

with(compare.main, {
  stopifnot(max(abs(beta.observed - beta.expected)) < 1e-13)
  stopifnot(max(abs(t.observed - t.expected)) < 1e-13)
})

##
## check pooled interaction tests
##

expected.int <-
    ldply(fits.full, function(fit.full) {
    })
fits.base <-
    dlply(dat, .(SNPID, reporterID),
          function(x) lmer(expression ~ alleleCopyNumber + FI1 + (1|R1), data = x))

expected.int <- ldply(mapply(function(full, reduced) anova(full, reduced), fits.full, fits.base,
                             SIMPLIFY = FALSE))

expected.int <- within(expected.int, {
  SNPID <- sub("^(.*)\\..*$", "\\1", expected.int$.id)
  reporterID <- sub("^.*\\.(.*)$", "\\1", expected.int$.id)
  pvalue <- expected.int$`Pr(>Chisq)`
  t <- expected.int$`Chisq`
  term <- "anyInteraction"
})
expected.int <- subset(expected.int, !is.na(Chisq), select = c(reporterID, SNPID, term, pvalue, t))

compare.int <- merge(observed, expected.int, by = c("reporterID", "SNPID", "term"),
                     suffixes = c(".observed", ".expected"))

with(compare.int, {
  stopifnot(max(abs(t.observed - t.expected)) < 1e-14)
  stopifnot(max(abs(-log10(pvalue.observed) - -log10(pvalue.expected))) < 1e-14)
})
