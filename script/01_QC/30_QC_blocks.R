#20_QC_blocks.R
rm(list=ls());gc()
options(stringsAsFactors = F)

library(readr)
library(rtracklayer)
library(pheatmap)
library(SummarizedExperiment)
library(edgeR)
library(WGCNA)

load("working_data/summarizedExperiment/fc_2pass/se_blocks.RData")


##### (1) Visualization on raw data  #####
boxplot(assays(se_blocks)$counts, range=0, main="Raw Counts")
boxplot(log2(1+assays(se_blocks)$counts), range=0, main = "log2 counts + 1")


i=1;  plot(density(log2(.001+assays(se_blocks)$counts[,i])),col = as.factor(se_blocks$Diagnosis)[i], main = "Counts from tximport, countsFromAbundance = 'lengthScaledTPM'", xlab="log2(raw_counts + 1)", xlim=c(-15,30), ylim=c(0,0.45))
for(i in 2:ncol(se_blocks)) {
  lines(density(log2(.001+assays(se_blocks)$counts[,i])),col = as.factor(se_blocks$Diagnosis)[i])
}
legend("topright", legend = unique(se_blocks$Diagnosis), fill = 1:3)


##### (2) Remove low expressed genes and outlier samples ####
genes_to_keep = filterByExpr(DGEList(assays(se_blocks)$counts))
table(genes_to_keep)
se_blocks = se_blocks[genes_to_keep,]


##### (3) Remove outlier samples ####
normadj <- 0.5 + 0.5*bicor(cpm(calcNormFactors(DGEList(assays(se_blocks)$counts), method = 'TMM'), log = TRUE))
netsummary <- fundamentalNetworkConcepts(normadj)
C <- netsummary$Connectivity
Z.C <- (C-mean(C))/sqrt(var(C))


# plot the connectivity z-score for the normalized data and set a cut-off at 3 STD
plot(1:length(Z.C),
     Z.C,
     main="Outlier Plot of Block Data)",
     xlab = "Samples",ylab="Connectivity Z Score", 
     #col=factor(se_blocks$Diagnosis)
     )
text(1:length(Z.C),Z.C - .2, labels = names(Z.C))
abline(h= -2, col="red")

# determine which samples fail the 'outlier threshold' via connectivity z-score
km=kmeans(Z.C,2)
table(names(km$cluster) == colnames(se_blocks))
#to_remove = (km$cluster == as.numeric(rownames(km$centers)[km$centers[,1]<0]))
to_remove = Z.C < -2
to_remove = to_remove | se_blocks$Diagnosis==""
table(to_remove)

se_blocks = se_blocks[, !to_remove]


##### (3) Calculate normalized gene expression on outlier removed dataset
assays(se_blocks)$log2CPM = cpm(calcNormFactors(DGEList(assays(se_blocks)$counts), method = 'TMM'), log = TRUE)

boxplot(assays(se_blocks)$log2CPM,range=0, col=numbers2colors(se_blocks$TOTAL_READS))

i=1;  plot(density(assays(se_blocks)$log2CPM[,i]),col = as.factor(se_blocks$Diagnosis)[i], main = "Counts from tximport, countsFromAbundance = 'lengthScaledTPM'", xlab="log2(raw_counts + 1)", ylim=c(0,.5))
for(i in 2:ncol(assays(se_blocks)$log2CPM)){
  lines(density(assays(se_blocks)$log2CPM[,i]),col = as.factor(se_blocks$Diagnosis)[i])
}
legend("topright", legend = unique(se_blocks$Diagnosis), fill = 1:2)

#calculate top 10 principle components
mds = cmdscale(dist(t(assays(se_blocks)$log2CPM)),k = 10)
colnames(mds) = paste0("PC",1:ncol(mds))

pairs(mds, col=factor(se_blocks$Diagnosis), main="Group", pch=19)
par(xpd = TRUE,oma=c(1,1,1,1)); legend('bottomright', levels(factor(se_blocks$Group)),fill=1:2,cex=.5)

pairs(mds, col=numbers2colors(se_blocks$Age), main="Age", pch=19)
pairs(mds, col=numbers2colors(se_blocks$PMI), main="PMI", pch=19)
pairs(mds, col=numbers2colors(se_blocks$seqPC1), main="seqPC1", pch=19)

pairs(mds, col=factor(se_blocks$Sex), main="Sex", pch=19)
pairs(mds, col=factor(se_blocks$RNAseqPool), main="RNAseqPool", pch=19)


save(file="working_data/summarizedExperiment/fc_2pass/se_blocks_CPM_outlierRemoved.RData", se_blocks)









