library(scales)
library(viridis)
library(clusterProfiler)
library(org.Mm.eg.db)

load("dataAndFunctions_generateKeggPlots.RData", envir=.GlobalEnv)

scale01 <- function(x, low = min(x), high = max(x)) {
      x <- (x - low)/(high - low)
      x
  }


PushOL<- function (Data, qt1 = 0.05, qt2 = 0.95, PushHigh = T, PushLow = T) 
{
  Q5 = apply(Data, 1, function(i) quantile(i, qt1))
  Q95 = apply(Data, 1, function(i) quantile(i, qt2))
  DataSc2 = Data
  for (i in 1:nrow(Data)) {
    if (PushLow) 
      DataSc2[i, which(DataSc2[i, ] < Q5[i])] = Q5[i]
    if (PushHigh) 
      DataSc2[i, which(DataSc2[i, ] > Q95[i])] = Q95[i]
  }
  DataSc2
}

polyCurve <- function(x, y, from, to, n = 100, miny,
                      col = "red", border = col) {
  drawPoly <- function(fun, from, to, n = 100, miny, col, border) {
    Sq <- seq(from = from, to = to, length = n)
    polygon(x = c(Sq[1], Sq, Sq[n]),
            y = c(miny, fun(Sq), miny),
            col = col, border = border)
  }
  lf <- length(from)
  stopifnot(identical(lf, length(to)))
  if(length(col) != lf)
    col <- rep(col, length.out = lf)
  if(length(border) != lf)
    border <- rep(border, length.out = lf)
  if(missing(miny))
    miny <- min(y)
  interp <- approxfun(x = x, y = y)
  mapply(drawPoly, from = from, to = to, col = col, border = border,
         MoreArgs = list(fun = interp, n = n, miny = miny))
  invisible()
}


firstPlot <- function(MAIN, TOP) {
  dens1 <- density(na.omit(getCorr), from=-1, to=1, bw=.3)
  par(mar=c(5,5,2,1))
  plot(dens1$x, dens1$y, cex.axis=1.5, 
       cex.lab=1.5, bty = 'n', xlim=c(-1.1,1.1), lwd=2,
       cex=1, main=MAIN, ylim=c(0,(TOP*1.2)), col="black", type="l", 
       cex.main=1.3,
       xlab="Correlation", ylab="Density", xaxt='n', yaxt='n')
  axis(2, at=round(seq(0,TOP, length.out=4),1), lwd=2,cex.axis=2)
  axis(1, at=seq(-1,1, by=.5), cex.axis=1.5, lwd=2,cex.axis=2)
  polyCurve(dens1$x, dens1$y, from = -1, to = 1,miny=0,
            col = alpha("gray", .2), border = alpha("gray", .2))
  
}

quickScatter <- function(allGenes) {
  for(geneX in allGenes) {


    # Scale data
    getMeans.h <- layerMeans[geneX, ]
    rescaleY.halpern.means <- scale01(getMeans.h)
  
    getMeans.m <- layerMeans.morten[geneX,]
    rescaleY.morten.means <- scale01(getMeans.m)
  
    plot(0,0, col="white", pch=20, cex.axis=1.5, cex.lab=1.5,bty = 'n', xlim=c(1,9),
         cex=1, main=geneX, ylim=c(0,1), ylab="Scaled Expressed", xlab="Zonation Group", xaxt='n', yaxt='n')
    axis(2, at=seq(0,1, by=.5), label=seq(0,1, by=.5), lwd=2,cex.axis=1.5)
    axis(1, at=1:9, label=1:9, cex.axis=1.5, lwd=2)
  
    FIT = smooth.spline(1:9, rescaleY.morten.means,
                        control.spar=list(low=.2, high=.5))
    lines(FIT$x, FIT$y, lwd=3, col="#fc8d59")
  
    FIT = smooth.spline(1:9, rescaleY.halpern.means, 
                        control.spar=list(low=.2, high=.5))
    lines(FIT$x, FIT$y, lwd=3, col="#91bfdb")
  
    points(1:9, rescaleY.morten.means, col="#fc8d59", pch=95, cex=3)
    points(1:9, rescaleY.halpern.means, col="#91bfdb", pch=95, cex=3)
  
    # Decide where to put legenes
    if (rescaleY.morten.means[1] > rescaleY.morten.means[9]){
      legend('topright', c("Full-length", "UMI"), col=c("#fc8d59", "#91bfdb"), lty=1, lwd=3, cex=.5)
    } else {
      legend('bottomright', c("Full-length", "UMI"), col=c("#fc8d59", "#91bfdb"), lty=1, lwd=3, cex=.5)
    }

  }
}


makeCorPlots <- function(inCat, pushLow=0, pushHigh=1, sigUse){

  inCat <- gsub("KEGG: ", "", inCat, fixed=TRUE)
  usekegg <- subset(allKK, Description == inCat)
  KEGG <- usekegg$ID  
  keggCat1 <- bitr_kegg(KEGG, "Path", "ncbi-geneid", "mmu")[,2]

  sub2 <- subset(all.genes.map, ENTREZID %in% keggCat1)[,1]
  
  sig.h <- names(which(layerStatsPvalue[,2] < sigUse))
  sig.m <- names(which(adjusted.pvals < sigUse))
  sig.genes <- intersect(subset(geneSet, MortenGene %in% sig.m)[,2], sig.h)
  sig.genes <- (subset(geneSet, HalpernGene %in% sig.genes)[,1])
  
  sig.genes.map <- subset(all.genes.map, SYMBOL %in% sig.genes)
  sub3 <- subset(sig.genes.map, ENTREZID %in% keggCat1)[,1]
  
  if (length(sub2 >= 3) & length(sub3 >= 3)){
  dens2 <- density(na.omit(getCorr[sub2]), from=-1, to=1, bw=.3)
  dens3 <- density(na.omit(getCorr[sub3]), from=-1, to=1, bw=.3)

  top.res.fitted.use <- top.res.fitted[intersect(rownames(top.res.fitted), sub3),]
  
  useY <- t(apply(top.res.fitted.use, 1, function(x) tapply(x, layerSplit, mean)))
  useOrder <- names(sort(apply(useY, 1, which.max)))
  
  dataForPlot <- t(base::scale(t((top.res.fitted.use))))
  dataForPlot <- PushOL(dataForPlot, qt1 = pushLow, qt2 = pushHigh)
  
  dataForPlot <- dataForPlot[useOrder,]
  MIN = min(dataForPlot)
  MAX = max(dataForPlot)
 
  heatcols2 <- cividis(100)
  breaks <- seq(MIN, MAX, length.out=length(heatcols2)+1)

            
  MAT = matrix(c(1,1,1, 2,2, 1,1,1, 3,3, 4,5,6,7,8, 9,10,11,12,13), nrow=4, ncol=5, byrow=T)
  layout(MAT, width=c(.5,.5,.5,.5,.5), height=c(.2,1,.5,.5))


  TOP <- round(max(dens2$y, dens3$y),1)
  par(mar=c(5,5,2,7))
  firstPlot(inCat, TOP)
  segments(0,0, 0,TOP, lty=2, lwd=1.5)
  lines(dens2$x, dens2$y,lwd=2)
  polyCurve(dens2$x, dens2$y, from = -1, to = 1,miny=0,
            col = alpha("maroon1", .4), border = "black")
  lines(dens3$x, dens3$y,lwd=2)
  polyCurve(dens3$x, dens3$y, from = -1, to = 1,miny=0,
            col = alpha("maroon3", .7), border = "black")
  legend('topleft', c("All Genes", "KEGG Genes", "Zonated Genes"), 
                fill=c(alpha("gray", .2),alpha("maroon1", .4),alpha("maroon3", .7)), 
                bty = "n")

  par(mar=c(1.5,2,1,5))
    image(z = matrix(breaks, ncol = 1), col = heatcols2, 
          breaks = breaks, ylim=c(0,1))
    h <- hist(dataForPlot[useOrder,], plot = FALSE, breaks = breaks)
    hx <- scale01(breaks, 0, 1)
    hy <- c(h$counts, h$counts[length(h$counts)])
    lines(hx, hy/max(hy) * 0.95, lwd = 1, type = "s", 
        col = 'black') 
  par(mar=c(4,2,1,5))     
    image(t(dataForPlot[useOrder,]), col = heatcols2, 
            breaks = breaks,
            xaxt='n', yaxt='n')   
        
    axis(4, at = round(seq(0, 1, length.out = length(useOrder)),2), labels = useOrder, 
           las=1, cex.axis=1)
    axis(1, at=c(0,1), label=c("PC", "PP"), cex.axis=2, tick = F)
  
  
  par(mar=c(5,5,2,1))
    MIN <- min(10, length(sub3))
    allGenesToPlot <- names(c(sort(getCorr[sub3], decreasing=T)[1:MIN]))
    quickScatter(allGenesToPlot)
  }

}