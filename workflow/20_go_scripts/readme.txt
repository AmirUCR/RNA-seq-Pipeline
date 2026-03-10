python 2_find_enrichment.py ids_stu.txt ids_pop.txt ../../data/go/PlasmoDB-68_PbergheiANKA_GO.gaf --pval=1 --method=fdr_bh --outfile=results_gaf.xlsx

python 2_find_enrichment.py ids_stu_up.txt ids_pop.txt ../../data/go/PlasmoDB-68_PbergheiANKA_GO.gaf --pval=0.05 --method=fdr_bh --outfile=results_up.xlsx

python 2_find_enrichment.py ids_stu_down.txt ids_pop.txt ../../data/go/PlasmoDB-68_PbergheiANKA_GO.gaf --pval=0.05 --method=fdr_bh --outfile=results_down.xlsx