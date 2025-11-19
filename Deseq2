```{r}
# ===========================
# 1️⃣ Load featureCounts output
# ===========================
fc <- read.delim("C:/Users/00104058/OneDrive - UWA/Desktop/RSEM.gene.counts.matrix", 
                comment.char="#")

counts <- as.matrix(fc[, 7:ncol(fc)])
rownames(counts) <- fc$X

# ===========================
# 2️⃣ Load metadata
# ===========================
#coldata <- read.csv("coldata.csv", row.names=1)
#coldata<-sample_data[,2:3]

# remove that column from counts
counts <- counts[ , !(colnames(counts) %in% c("KW4.2")) ]

# also remove from metadata
coldata <- coldata[ !(rownames(coldata) %in% c("KW4.2")), ]
# remove that column from counts
counts <- counts[ , !(colnames(counts) %in% c("KW2.4")) ]

# also remove from metadata
coldata <- coldata[ !(rownames(coldata) %in% c("KW2.4")), ]

# Optional: sanity check that sample names match
if(!all(colnames(counts) %in% rownames(coldata))){
 stop("Sample names in counts and metadata do not match!")
}
Week<-as.numeric(sub("KW([0-9]+).*", "\\1", colnames(counts)))
coldata<-as.data.frame(cbind(colnames(counts),Week))
colnames(coldata)<-c("Sample","Week")
rownames(coldata)<-coldata$Sample

# Reorder metadata to match counts
coldata <- coldata[colnames(counts), , drop=FALSE]

# ===========================
# 3️⃣ Remove problematic samples
# ===========================
remove_samples <- c("KW4.7_merged.bam")  # add any other samples here

counts <- counts[, !(colnames(counts) %in% remove_samples)]
coldata <- coldata[!(rownames(coldata) %in% remove_samples), , drop=FALSE]

# ===========================
# 4️⃣ Create DESeq2 object
# ===========================
counts_rounded<-round(counts)
dds <- DESeqDataSetFromMatrix(countData = counts_rounded,
                             colData = coldata,
                             design = ~ Week)

# Ensure 'Week' is a factor
dds$Week <- factor(dds$Week)

# ===========================
# 5️⃣ Run DESeq2
# ===========================
dds <- DESeq(dds)

# ===========================
# 6️⃣ Generate all pairwise week comparisons
# ===========================
weeks <- levels(dds$Week)
pairs <- combn(weeks, 2)

dir.create("DE_results_weekwise_both_directions", showWarnings = FALSE)

for(i in 1:ncol(pairs)){
 a <- pairs[1, i]
 b <- pairs[2, i]
 
 # First direction: a vs b
 res_ab <- results(dds, contrast = c("Week", a, b))
 res_ab <- res_ab[order(res_ab$padj), ]
 outfile_ab <- paste0("DE_results_weekwise_both_directions/DE_Week", a, "_vs_Week", b, ".csv")
 write.csv(as.data.frame(res_ab),row.names = T, file = outfile_ab)
 
 # Second direction: b vs a
 res_ba <- results(dds, contrast = c("Week", b, a))
 res_ba <- res_ba[order(res_ba$padj), ]
 outfile_ba <- paste0("DE_results_weekwise_both_directions/DE_Week", b, "_vs_Week", a, ".csv")
 write.csv(as.data.frame(res_ba),row.names = T, file = outfile_ba)
 }
```


```{r}
library(pheatmap)
library(ggplot2)
library(RColorBrewer)
```

```{r}
# ===========================
# 7️⃣ Transform counts for visualization
# ===========================
vsd <- vst(dds, blind=TRUE)   # use rlog(dds, blind=TRUE) if few samples

# ===========================
# 8️⃣ PCA plot
# ===========================
pdf("PCA_Week.pdf", width=6, height=5)
plotPCA(vsd, intgroup="Week",) +
 ggtitle("PCA plot by Week")
dev.off()

# Create PCA data manually
pcaData <- plotPCA(vsd, intgroup = "Week", returnData = TRUE)
percentVar <- round(100 * attr(pcaData, "percentVar"))

pdf("PCA_Week_Annotated.pdf", width=6, height=5)
ggplot(pcaData, aes(PC1, PC2, color=Week, label=name)) +
 geom_point(size=1.2, alpha = 0.8) +
 geom_text_repel(size=3, max.overlaps=Inf) +
 xlab(paste0("PC1: ", percentVar[1], "% variance")) +
 ylab(paste0("PC2: ", percentVar[2], "% variance")) +
 theme_classic() +
 ggtitle("PCA by Week (labeled)")
dev.off()

# ===========================
# 9️⃣ Sample-to-sample distance heatmap
# ===========================
sampleDists <- dist(t(assay(vsd)))
sampleDistMatrix <- as.matrix(sampleDists)
rownames(sampleDistMatrix) <- colnames(vsd)
colnames(sampleDistMatrix) <- colnames(vsd)

annotation <- data.frame(Week = coldata$Week)
rownames(annotation) <- rownames(coldata)

pdf("sample_distance_heatmap.pdf", width=7, height=6)
pheatmap(sampleDistMatrix,
        clustering_distance_rows=sampleDists,
        clustering_distance_cols=sampleDists,
         annotation_col = annotation,
        fontsize_col = 6, fontsize_row = 6,
        legend=TRUE, annotation_legend=TRUE,
        main="Sample-to-sample distances")
dev.off()

# ===========================
# 🔟 Heatmap of top DE genes for each comparison
# ===========================
dir.create("heatmaps_top_DE", showWarnings=FALSE)

# loop over each pairwise result you already computed
weeks <- levels(dds$Week)
pairs <- combn(weeks, 2)

for(i in 1:ncol(pairs)){
 a <- pairs[1, i]
 b <- pairs[2, i]
 
 res <- results(dds, contrast=c("Week", a, b))
 res <- res[order(res$padj), ]
 res <- res[!is.na(res$padj), ]
 
 topgenes <- rownames(res)[1:50]  # top 50 DE genes
 mat <- assay(vsd)[topgenes, ]
 mat <- t(scale(t(mat)))          # z-score per gene
 
 annotation <- data.frame(Week = coldata$Week)
 rownames(annotation) <- rownames(coldata)
 
 #annotation_col=as.data.frame(coldata)
 outfile <- paste0("heatmaps_top_DE/heatmap_Week", a, "_vs_Week", b, ".pdf")
 pdf(outfile, width=10, height=8)
 pheatmap(mat, annotation_col=annotation,
          show_colnames = TRUE, fontsize_col = 7,
          show_rownames=TRUE, fontsize_row=5,
          annotation_legend = TRUE,
          main=paste("Top DE genes:", a, "vs", b))
 dev.off()
}
```
