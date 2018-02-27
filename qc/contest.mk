# This module runs ContEst on snp vcf files from gatk
# Author: inodb

##### MAKE INCLUDES #####
include usb-modules-v2/Makefile.inc

LOGDIR ?= log/contest.$(NOW)

.SECONDARY:
.DELETE_ON_ERROR:
.PHONY: contest

contest : contest/snp_vcf/all$(PROJECT_PREFIX)_contamination.txt $(foreach sample,$(SAMPLES),contest/snp_vcf/$(sample)_contamination.txt)

# ContEst on gatk snp_vcf folder
ifeq ($(findstring ILLUMINA,$(SEQ_PLATFORM)),ILLUMINA)
contest/snp_vcf/%_contamination.txt : bam/%.bam gatk/dbsnp/%.gatk_snps.vcf
	$(call RUN,1,$(RESOURCE_REQ_MEDIUM_MEM),$(RESOURCE_REQ_VSHORT),$(JAVA8_MODULE),"\
	$(MKDIR) contest/snp_vcf; \
	$(call GATK,ContEst,$(RESOURCE_REQ_MEDIUM_MEM_JAVA)) -I $(<) -B:genotypes$(,)vcf $(<<) -o $(@)")
endif
ifeq ($(findstring IONTORRENT,$(SEQ_PLATFORM)),IONTORRENT)
contest/snp_vcf/%_contamination.txt : bam/%.bam tvc/dbsnp/%/TSVC_variants.vcf
	$(call RUN,1,$(RESOURCE_REQ_MEDIUM_MEM),$(RESOURCE_REQ_VSHORT),$(JAVA8_MODULE),"\
	$(MKDIR) contest/snp_vcf; \
	$(call GATK,ContEst,$(RESOURCE_REQ_MEDIUM_MEM_JAVA)) -I $(<) -B:genotypes$(,)vcf $(<<) -o $(@)")
endif

contest/snp_vcf/all$(PROJECT_PREFIX)_contamination.txt : $(foreach sample,$(SAMPLES),contest/snp_vcf/$(sample)_contamination.txt)
	( \
		head -1 $< | sed "s/^/sample\t/"; \
		for s in $(^); do \
			grep -P "META\t" $$s | sed "s/^/`basename $$s _contamination.txt`/"; \
		done | sort -rnk5,5; \
	) > $@


include usb-modules-v2/vcf_tools/vcftools.mk
include usb-modules-v2/variant_callers/TVC.mk
include usb-modules-v2/variant_callers/gatk.mk
