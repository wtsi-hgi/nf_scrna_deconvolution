#!/usr/bin/env Rscript

args = commandArgs(trailingOnly=TRUE)
sample_name = args[1] #'samplename'
path_donor_ids_tsv =args[2] # '../donor_ids.tsv'
path_clusters_tsv = args[3] #"../clusters.tsv"

#.libPaths(c("/usr/local/lib/R/library", 
#          "/usr/local/lib/R/site-library",
#          "/software/R-4.1.0/lib/R/library",
#          "/software/team166/gn5/R/x86_64-pc-linux-gnu/4.1"))
library(tidyverse)


# donors ids tsv from vireo
df_donors_ids = read_tsv(path_donor_ids_tsv) %>% 
  rename(barcode = cell) 
df_donors_ids$assign_vireo = paste0('Vireo ', df_donors_ids$donor_id)

# clusters tsv from souporcell 
df_clusters = read_tsv(path_clusters_tsv)
df_clusters$assign_souporcell = ifelse(df_clusters$status == 'doublet' | df_clusters$status == 'unassigned',
                              paste0('Souporcell ', df_clusters$status),
                              paste0('Souporcell donor', df_clusters$assignment))

df_clusters$assign_souporcell %>% table

print('df_donors_ids$donor_id %>% table'); df_donors_ids$donor_id %>% table
print('df_clusters$status'); df_clusters$status %>% table
print('df_clusters$assignment'); df_clusters$assignment %>% table

print(' df_donors_ids$assign_vireo'); df_donors_ids$assign_vireo %>% table
print('df_clusters$assign_souporcell'); df_clusters$assign_souporcell %>% table

df = df_donors_ids %>% select(barcode, assign_vireo) %>%
  left_join(df_clusters %>% select(barcode, assign_souporcell))

df %<>% group_by(assign_vireo, assign_souporcell) %>%
  summarise(nn = n()) %>% arrange(assign_vireo, desc(nn))
df %>% head

p = ggplot(data=df, aes(x=assign_souporcell, y=nn, fill=assign_souporcell)) +
  geom_bar(stat="identity", position=position_dodge()) +
  geom_text(aes(label=nn), vjust=1.6, color="black",
            position = position_dodge(0.9), size=3.5)+
  scale_fill_brewer(palette="Paired") +
  facet_wrap(~assign_vireo, ncol = 3, scales = 'fixed') +
  theme(axis.text.x = element_text(angle = 90)) + 
  labs(x = 'deconvolution cell assignements: Souporcell (x-axis) vs Vireo (facets)', y = "number of assigned cells (barcodes)",
       fill = "Souporcell\ncell assignements",
       title=" Souporcell vs Vireo cell cluster assignements")

# To save to file, here on A4 paper
ggsave(paste0(sample_name, "_souporcell_vs_vireo.pdf"),
       p, width = 21, height = 29.7, units = "cm")
