# Delete all objects in the work space
rm(list=ls(all=TRUE))
library(ggplot2)
library(plyr)
library(reshape2)


allinone <- function(PET = PET, SAB = SAB, soil = soil){

  PET$sp <- "PET"
  SAB$sp <- "SAB"
  data <- rbind(PET, SAB)

  ####################################################
  # Define mixture
  ####################################################
  data$plot <- 1
  data[data$prop_PET_BA < 0.75 & data$prop_SAB_BA < 0.75, "plot"] <- "MIX"
  data[data$prop_PET_BA >= 0.75, "plot"] <- "PET"
  data[data$prop_SAB_BA >= 0.75, "plot"] <- "SAB"

  ####################################################
  # wide to long
  ####################################################

  data <- melt(data, id.vars = c("ID_PET_MES", "ID_ARB", "ESSENCE", "yr", "rcp", "mod", "plot"), measure.vars = paste("V", seq(1,10), sep=""))

  # change names
  data[data$rcp == "rcp45", "rcp"] <- "RCP4.5"
  data[data$rcp == "rcp85", "rcp"] <- "RCP8.5"
  colnames(data)[colnames(data) == "variable"] <- "sim"
  colnames(data)[colnames(data) == "value"] <- "BAI"

  ####################################################
  # Plot chronology over the 1950-2100 period
  ####################################################

  # sum of BAI for each year/rcp/mod/sim/mix
  pred <- ddply(data, .(yr, rcp, mod, sim, plot), summarise, BAI = sum(BAI))
  predall <- ddply(data, .(yr, rcp, mod, sim), summarise, BAI = sum(BAI))
  predall$plot <- "all"
  predall <- predall[, c("yr", "rcp", "mod", "sim", "plot", "BAI")]
  pred <- rbind(pred, predall)

  ################
  # min, max, CI
  ################
  minmax <- function(data = pred, plot = c("all", "MIX", "PET", "SAB")){
    data <- data[data$plot == plot,]
    data_min <- ddply(data, .(yr, rcp), summarise, BAImin = min(BAI))
    data_max <- ddply(data, .(yr, rcp), summarise, BAImax = max(BAI))
    data_CImin <- ddply(data, .(yr, rcp), summarise, CImin = wilcox.test(BAI,conf.int=TRUE)$conf.int[1])
    data_CImax <- ddply(data, .(yr, rcp), summarise, CImax = wilcox.test(BAI,conf.int=TRUE)$conf.int[2])
    chrono <- cbind(data_min, data_max$BAImax, data_CImin$CImin, data_CImax$CImax)
    chrono$plot <- plot
    colnames(chrono) <- c("yr", "rcp", "BAImin", "BAImax", "CImin", "CImax", "plot")
    return(chrono)
  }

  all <- minmax(pred, "all")
  MIX <- minmax(pred, "MIX")
  PET <- minmax(pred, "PET")
  SAB <- minmax(pred, "SAB")

  chronoplot <- rbind(all, MIX, PET, SAB)

  ################
  # plot
  ################

  if (soil == "T0D0"){
    ggplot(data = chronoplot)+
    geom_ribbon(aes(x=yr, ymax=BAImax, ymin=BAImin, fill = rcp), alpha = 0.2)+
    geom_ribbon(aes(x=yr, ymax=CImax, ymin=CImin, fill = rcp), alpha = 0.5)+
    xlab("year")+
    ylab("total BAI")+
    facet_wrap(~ plot, nrow = 1, scales="free_y",  labeller = as_labeller(c("all" = "a) all stands", "MIX" = "b) mixed stands", "PET" = "c) pure aspen stands", "SAB" = "d) pure fir stands")))+
    theme_bw()+
    theme(strip.background = element_rect(colour = "white", fill = "white"), legend.position = "bottom", legend.title = element_blank())
    ggsave (paste("~/Desktop/chap3/plot/plot", soil, ".pdf", sep = ""), width = 8, height= 5)
  } else {
    save(chronoplot, file = paste("chornoplot", soil, ".rdata", sep = ""))
  }

  # ####################################################
  # # difference between Mixed and PET
  # ####################################################
  #
  # # difference between
  # diff <- dcast(pred[pred$plot %in% c("MIX", "PET"),], yr + rcp + mod + sim ~ plot)
  # diff$BAI <- diff$MIX - diff$PET
  # diff$plot <- "diff"
  #
  # ################
  # # min, max, CI
  # ################
  # diff <- minmax(diff, "diff")
  # diffplot <- diff
  #
  # ################
  # # plot
  # ################
  #
  # ggplot(data = diff)+
  # geom_ribbon(aes(x=yr, ymax=BAImax, ymin=BAImin, fill = rcp), alpha = 0.2)+
  # geom_ribbon(aes(x=yr, ymax=CImax, ymin=CImin, fill = rcp), alpha = 0.5)+
  # xlab("year")+
  # ylab("total BAI of mixed stands - total BAI of pure aspen stands")+
  # theme_bw()+
  # theme(strip.background = element_rect(colour = "white", fill = "white"), legend.position = "bottom", legend.title = element_blank())
  #
  # # ggsave (paste("~/Desktop/chap3/plot/diffplot", soil, ".pdf", sep = ""), width = 4, height= 5)

  ####################################################
  # Plot SP chronology over the 1950-2100 period
  ####################################################

  # sum of BAI for each year/rcp/mod/sim/mix
  predPET <- ddply(data[data$ESSENCE == "PET" & data$plot %in% c("MIX", "PET"), ], .(yr, rcp, mod, sim, plot), summarise, BAI = sum(BAI))
  predPET$ESSENCE <- "PET"
  predSAB <- ddply(data[data$ESSENCE == "SAB" & data$plot %in% c("MIX", "SAB"), ], .(yr, rcp, mod, sim, plot), summarise, BAI = sum(BAI))
  predSAB$ESSENCE <- "SAB"
  pred <- rbind(predPET, predSAB)

  ################
  # min, max, CI
  ################

  petp <- minmax(pred[pred$ESSENCE == "PET", ], "PET")
  petp$plot <- "PET"
  petp$ESSENCE <- "PET"
  petm <- minmax(pred[pred$ESSENCE == "PET", ], "MIX")
  petm$plot <- "MIX"
  petm$ESSENCE <- "PET"
  sabp <- minmax(pred[pred$ESSENCE == "SAB", ], "SAB")
  sabp$plot <- "SAB"
  sabp$ESSENCE <- "SAB"
  sabm <- minmax(pred[pred$ESSENCE == "SAB", ], "MIX")
  sabm$plot <- "MIX"
  sabm$ESSENCE <- "SAB"
  chronosp <- rbind(petp, petm, sabp, sabm)

  ################
  # plot
  ################

  chronosp$a <- "a"
  chronosp[chronosp$ESSENCE == "PET" & chronosp$plot == "MIX", "a"] <- "a) aspen in mixed stands"
  chronosp[chronosp$ESSENCE == "PET" & chronosp$plot == "PET", "a"] <- "b) aspen in pure stands"
  chronosp[chronosp$ESSENCE == "SAB" & chronosp$plot == "MIX", "a"] <- "c) fir in mixed stands"
  chronosp[chronosp$ESSENCE == "SAB" & chronosp$plot == "SAB", "a"] <- "d) fir in pure stands"

  ggplot(data = chronosp)+
  geom_ribbon(aes(x=yr, ymax=BAImax, ymin=BAImin, fill = rcp), alpha = 0.2)+
  geom_ribbon(aes(x=yr, ymax=CImax, ymin=CImin, fill = rcp), alpha = 0.5)+
  xlab("year")+
  ylab("total BAI")+
  # facet_wrap(sp ~ plot, scales="free_y", labeller = as_labeller(c("PET" = "a) aspen", "mix" = "in mixed stands", "mono" = "in pure stands", "SAB" = "b) fir")))+
  facet_wrap(~ a, nrow = 1, scales="free_y")+
  theme_bw()+
  theme(strip.background = element_rect(colour = "white", fill = "white"), legend.position = "bottom", legend.title = element_blank())

  ggsave (paste("~/Desktop/chap3/plot/sp", soil, ".pdf", sep = ""), width = 8, height= 5)

  ####################################################
  # difference between Mixed and pure
  ####################################################

  # difference between MIX and PET
  diffpet <- pred[pred$ESSENCE == "PET", ]
  diffpet <- diffpet[,-ncol(pred)]
  diffpet <- dcast(diffpet[diffpet$plot %in% c("MIX", "PET"), ], yr + rcp + mod + sim ~ plot)
  diffpet$BAI <- diffpet$MIX - diffpet$PET
  diffpet$sp <- "PET"
  diffpet <- diffpet[, c("yr", "rcp", "mod", "sim", "BAI", "sp")]

  # difference between MIX and SAB
  diffsab <- pred[pred$ESSENCE == "SAB", ]
  diffsab <- diffsab[,-ncol(pred)]
  diffsab <- dcast(diffsab[diffsab$plot %in% c("MIX", "SAB"), ], yr + rcp + mod + sim ~ plot)
  diffsab$BAI <- diffsab$MIX - diffsab$SAB
  diffsab$sp <- "SAB"
  diffsab <- diffsab[, c("yr", "rcp", "mod", "sim", "BAI", "sp")]

  ################
  # min, max, CI
  ################
  # MIX PET
  colnames(diffpet)[colnames(diffpet) == "sp"] <- "plot"
  diffpet <- minmax(diffpet, "PET")
  # MIX SAB
  colnames(diffsab)[colnames(diffsab) == "sp"] <- "plot"
  diffsab <- minmax(diffsab, "SAB")
  # gather
  diff <- rbind(diffpet, diffsab)
  diff$soil <- soil
  # save
  save(diff, file = paste("diffsp", soil, ".rdata", sep = ""))

}

####################################################
# Data
####################################################

# File list
setwd("~/owncloud/Work_directory/Analysis/chapitre_3/03_mixed_model/output")
PETs <- Sys.glob("QC_BAI_PET*")
SABs <- Sys.glob("QC_BAI_SAB*")


for (i in 1:length(PETs)){
  # import and merge predictions
  load(PETs[i])
  PET <- predictions
  load(SABs[i])
  SAB <- predictions
  soil <- substr(PETs[i], 12, 15)
  allinone(PET = PET, SAB = SAB, soil = soil)
}


####################################################
# Differences between mixed and pure
####################################################

# File list
diffs <- Sys.glob("diff*")

load("diffT0D0.rdata")

# 1 on empile tout puis on plot en facet


ggplot(data = diff)+
geom_ribbon(aes(x=yr, ymax=BAImax, ymin=BAImin, fill = rcp), alpha = 0.2)+
geom_ribbon(aes(x=yr, ymax=CImax, ymin=CImin, fill = rcp), alpha = 0.5)+
facet_grid(soil ~ plot)
xlab("year")+
ylab("total BAI of aspen in mixed stands - in pure aspen stands")+
theme_bw()+
theme(strip.background = element_rect(colour = "white", fill = "white"), legend.position = "bottom", legend.title = element_blank())

# # ggsave (paste("~/Desktop/chap3/plot/diffsp", soil, ".pdf", sep = ""), width = 4, height= 5)
