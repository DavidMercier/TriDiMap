# All inclusive code to perform crossmethod validation - Nanoindentation/EBSD phase maps/IPF - version 2.1 works perfectly
# Based on IPF_v0.9.R: IPF, EBSD maps image files processing, and mining of information,
# pixelwise_IPFNIcodebined_2.0.R: NI maps image files processing,
# CRF_CSM_v0.8.R: processing the Femtotools exported data

################################################################################################################
# Load libraries and path
################################################################################################################

# Load libraries
library (plyr); library(dplyr); library(tibble); library(future); plan(multisession); library(sfsmisc); library(pracma) 
library(caret); library(ggplot2); library(magick); library(plotly); library(gapminder); library(mosaic); library(COUNT)
library(stats4); library(bbmle); library(tidyr); library(doSNOW); library(readr); library(readxl); library(data.table); library(fields)
library("factoextra"); library(dbscan); library(fpc); library("cluster"); library(tidyverse); library(tibble); library(Rtsne)
library("PerformanceAnalytics"); library(stringr); library(reshape2); library(RColorBrewer) # https://plotly.com/r/contour-plots/
library(parallel);library(e1071); library(doParallel); library(mclust); library(plotGMM); library(segmented); library(imager); library(geometry)
library(dplyr); library(ggplot2); library(tidyr); library(imputeTS); library(class); library(ggvoronoi); library(jpeg); library(zoo) #library(magick) library(tidyverse) library(magrittr)

# Parallel computing 
unregister_dopar <- function() {
  env <- foreach:::.foreachGlobals
  rm(list=ls(name=env), pos=env)
}
# Get and Set the number of available cores, Create a cluster object using the specified number of cores, Register the cluster as the parallel backend
num_cores <- detectCores(); print(num_cores); num_cores <- 20
cl <- makeCluster(num_cores)
registerDoParallel(cl)

# Path
mypath = r"C:\Users\dmercier\OneDrive - ANSYS, Inc\pythonRepo\nanoMECommons\nanoindentation-and-EBSD-data-correlation-main_python"

setwd(mypath)

################################################################################################################
# Functions to be used
################################################################################################################

# fix plot theme for ggplot to ensure uniformity
plotTheme <- function() {
  theme(
    panel.background = element_rect(size = 0.1, colour = "black", fill = "white"),
    panel.grid.major = element_line(colour = "gray80", linetype = "dotted"),
    panel.grid.minor = element_line(colour = "gray90", linetype = "dashed"),
    axis.title.x = element_text(size = 16, face = "bold"),
    axis.title.y = element_text(size = 16, face = "bold"),
    axis.text = element_text(size = 16),  # Adjust this size according to your preference
    plot.title = element_text(size = 16, face = "bold", vjust = 1.5),
    axis.ticks = element_line(size = 0.5)
  )
}

# do distance based correlation for allocating colorshades to specific colors
# Function to compare RGB values with specific colors - more generic colors (maybe pale colors will be used)
# I play with it - choose colors for kColours as centers
get_color_category <- function(R, G, B) { # the kmeans colors are pale: this introduces a complication that favors pink pred
  # Define standard RGB values for each color category
  colors_data <- data.frame(
    color = c("green", "blue", "red", "yellow", "pink", "cyan", "white","black"),
    R = c(0.4666667, 0.3529412, 0.6705882, 0.7921569, 0.8470588, 0.4901961, 1, 0), # R = c(0.9, 0.9, 1, 1, 1, 0.9, 1, 0),
    G = c(0.8313725, 0.3490196, 0.2784314, 0.8196078, 0.4313725, 0.8313725, 1, 0), # G = c(1, 0.9, 0.9, 1, 0.7529, 1, 1, 0),
    B = c(0.4392157, 0.7843137, 0.2470588, 0.4000000, 0.6352941, 0.8156863, 1, 0) # B = c(0.9, 0.9, 0.9, 0, 0.7961, 1, 1, 0)
    #R = c(0.85, 0.85, 1, 1, 1, 0.85, 1, 0), # R = c(0.85, 0.85, 1, 1, 1, 0.85, 1, 0),
    #G = c(1, 0.85, 0.85, 1, 0.85, 1, 1, 0), # G = c(1, 0.85, 0.85, 1, 0.85, 1, 1, 0),
    #B = c(0.85, 0.85, 0.85, 0, 0.85, 1, 1, 0) # B = c(0.85, 0.85, 0.85, 0, 0.85, 1, 1, 0)
  )
  # Function to find the closest color category for each row
  find_closest_color <- function(r, g, b) {
    abs_diff <- abs(colors_data$R - r) + abs(colors_data$G - g) + abs(colors_data$B - b)
    closest_color <- colors_data$color[which.min(abs_diff)]
    return(closest_color)
  }
  
  # Apply the function to each row of R, G, and B
  color_categories <- mapply(find_closest_color, R, G, B)
  return(color_categories)
}

#col2rgb("#77D470")/255 col2rgb("#5A59C8")/255 col2rgb("#AB473F")/255 col2rgb("#CAD166")/255 col2rgb("#D86EA2")/255 col2rgb("#7DD4D0")/255

# for data imputation with knn method
impute_knn <- function(train_data, test_data, k = 8) {
  # Separate predictors and response variables in the training set
  X_train <- train_data[, c("x", "y")]
  y_train <- train_data[, c("R", "G", "B")]
  
  # Separate predictors in the test set
  X_test <- test_data[, c("x", "y")]
  
  # Use k-NN model to predict R, G, and B values for the test set
  imputed_data <- data.frame(x = X_test$x, y = X_test$y)
  
  for (col in c("R", "G", "B")) {
    imputed_data[[col]] <- knn(train = X_train, test = X_test, cl = y_train[[col]], k = k)
  }
  
  return(imputed_data)
}

################################################################################################################
# Start: IPF map - read image to extract knowledge (anisotropy, grain locations, grains coordinates)
################################################################################################################

################################################################################################################ 
# *************** Data Preparation - Phase #1 ***************** #
################################################################################################################
# Read IPF image
img <- readJPEG("IPF.jpg") # IPF
imgDm <- dim(img)

# Assign RGB channels to data frame
img_wide <- data.frame(
  x = rep(1:imgDm[2], each = imgDm[1]),
  y = rep(imgDm[1]:1, imgDm[2]),
  R = as.vector(img[,,1]),
  G = as.vector(img[,,2]),
  B = as.vector(img[,,3])
)

# do the rescalling
# Coordinates fix: IPF 59.5 x 45.0 um & round digits to facilitate merging
img_wide$x <- img_wide$x - 1 # make coordinates to start from zero
img_wide$y <- img_wide$y - 1

img_wide$x <- img_wide$x*59.5/max(img_wide$x)
img_wide$y <- img_wide$y*45.0/max(img_wide$y)

img_IPF <- img_wide

# identify the exact same coordinate locations to combine multi-modal outputs

# correct coordinates - if needed
#img_wide <- filter(img_wide, x > 2.499)
#img_wide <- filter(img_wide, between(y, 12.529, (max(img_wide$y) - 10.099)))

# fix to start from (0,0) - if needed
#summary(img_wide)
#img_wide$x <- img_wide$x - min(img_wide$x)
#img_wide$y <- img_wide$y - min(img_wide$y)
#summary(img_wide)

# Round digits
img_wide$x <- round(img_wide$x, digits = 1)
img_wide$y <- round(img_wide$y, digits = 1)

img_wide <- img_wide %>%
  mutate(color = rgb(R, G, B))

head(img_wide)

################################################################################################################ 
# *************** IPF map clustering to obtain each grain's coordinates ***************** #
################################################################################################################
# cluster separately: colours -> crystallographic planes

# see if we need to initialise to reproduce the same colours every time we cluster
# Combined map
set.seed(1000)
kClusters <- 50 # kalo: 8
kMeans <- kmeans(img_wide[, c("R", "G", "B")], centers = kClusters)
kColours <- rgb(kMeans$centers[kMeans$cluster,])
img_wide <- cbind(img_wide, kColours) # img_wide <- img_wide[,1:6]
unique(kColours) # length(unique(img_wide$color)) # img_wide_save <- img_wide

ggplot(data = img_wide, aes(x = x, y = y)) + 
  geom_point(colour = img_wide$kColours) +
  labs(title = paste("k-Means Clustering of", kClusters, "Colours")) +
  xlab("x") + ylab("y") + plotTheme()

# try to convert kColours to RGB values
df_test <- col2rgb(img_wide$kColours)
df_test <- t(as.data.frame(df_test))
df_test <- as.data.frame(df_test)
df_test$red <- df_test$red/255
df_test$green <- df_test$green/255
df_test$blue <- df_test$blue/255
head(df_test)
img_wide <- cbind(img_wide, df_test) # img_wide <- img_wide[,1:7]
head(img_wide)

# check if colors are unique
col_df <- unique(img_wide$kColours)

merged_list <- lapply(col_df, function(col_val) filter(img_wide, kColours == col_val)) # check if colours are unique

# Use lapply to create a plot for each data frame in the merged_list
plot_list <- lapply(merged_list, function(df) {
  ggplot(data = df, aes(x = x, y = y)) + 
    geom_point(aes(colour = df$kColours)) + # aes(colour = kColours)
    xlab("x") + ylab("y") + plotTheme()
})

################################################################################################################
################      ISOLATE ALL GRAINS      #########
################################################################################################################
# Create an empty list to store the processed dataframes
processed_dataframes <- list()

# Loop through each dataframe in the plot_list and perform the operations
for (i in seq_along(plot_list)) {
  # Get the current dataframe from the list
  data <- as.data.frame(plot_list[[i]]$data)
  
  # Scaling
  scaled <- scale(data[, c(1, 2)])
  
  # k-means++ clustering implementation 
  
  # Choose an appropriate value of K (number of clusters)
  k_value <- 80
  
  # Use K-means++ initialization and run the algorithm in parallel with multiple starts (e.g., 100 starts)
  kmeans_model <- kmeans(scaled, centers = k_value, nstart = 100, algorithm = "Lloyd", trace = FALSE, iter.max = 300)
  
  # Get the cluster labels
  cluster_labels <- kmeans_model$cluster # unique(cluster_labels)
  
  data <- as_tibble(data)
  data$PDA <- 0; data$PDA <- cluster_labels; data$PDA <- as.numeric(data$PDA)
  data$PDA <- data$PDA + 80*(i-1)+1 # we have to change the annotation number in clusters: add a condition of $PDA <- $PDA + i*max(d$PDA) +1) or smthng like that!
  
  # Assuming you have the 'data' dataframe with columns 'R', 'G', 'B', and 'colors'
  # Perform the get_plane_annotation function and Apply the annotation and create a new column 'plane'
  data$plane <- with(data, get_color_category(red, green, blue)) # unique(data$plane) data$plane <- with(data, get_plane_annotation(R, G, B)) # unique(data$plane)
  
  # Filter out rows where the value appears less than 25 times
  value_counts <- table(data$PDA)
  threshold <- 5 # 25 lead to exclusion of ~ 80% of data
  data <- data[data$PDA %in% names(value_counts[value_counts >= threshold]), ]
  
  # Save the processed dataframe in the list
  processed_dataframes[[i]] <- data
}

# Combine the processed dataframes into a single dataframe
final_dataframe <- do.call(rbind, processed_dataframes) #final_dataframe <- lapply(final_dataframe, as.numeric); final_dataframe <- as.data.frame(final_dataframe)
#final_dataframe$plane <- with(final_dataframe, get_plane_annotation(R, G, B))
# this I used for quick eval: final_dataframe$plane <- with(final_dataframe, get_color_category(red, green, blue)) # Apply the function to your data
unique(final_dataframe$plane) # fix the problem! [1] "(001)U(101)"

final_dataframe$plane <- ifelse(final_dataframe$plane == 'red', '(001)', 
                                ifelse(final_dataframe$plane ==  'blue', '(111)',
                                       ifelse(final_dataframe$plane == 'green', '(101)', 
                                              ifelse(final_dataframe$plane == 'cyan', '(101)U(111)', 
                                                     ifelse(final_dataframe$plane == 'yellow', '(001)U(101)', 
                                                            ifelse(final_dataframe$plane == 'pink', '(001)U(111)', 
                                                                   ifelse(final_dataframe$plane == 'white', 'White', 
                                                                          ifelse(final_dataframe$plane == 'black', 'Black', 'NA'
                                                                          ))))))))

head(final_dataframe) # final_dataframe$PDA <- final_dataframe$PDA - 100
nrow(filter(final_dataframe, plane == "")); nrow(filter(final_dataframe, plane == "NA")) # count(filter(final_dataframe, plane == ""))
nrow(filter(final_dataframe, plane == "White")); nrow(filter(final_dataframe, plane == "Black"))
str(final_dataframe) # final_df_save <- final_dataframe

# check statistics
nrow(filter(final_dataframe, plane == "(001)U(111)")); nrow(filter(final_dataframe, plane == "(001)")); nrow(filter(final_dataframe, plane == "(111)"))
nrow(filter(final_dataframe, plane == "(001)U(101)")); nrow(filter(final_dataframe, plane == "(101)")); nrow(filter(final_dataframe, plane == "(101)U(111)"))

# Now 'final_dataframe' contains the results of applying the operations to each specific dataframe in the list
write.csv(x = final_dataframe, file = 'IPF_grains_n_planes_repeat.csv')

################################################################################################################
# test how it looks like a grain
################################################################################################################
test <- filter(final_dataframe, PDA == 755) 

ggplot(data = test, aes(x = x, y = y)) + 
  geom_point(aes(colour = kColours)) + # aes(colour = kColours)
  xlab("x") + ylab("y") + plotTheme()

# Need to count k number of grains and extract for each one its dimensions eq.diameter or length/width

################################################################################################################
# test how it looks like a unique anisotropic plane
################################################################################################################
test2 <- filter(final_dataframe, plane == "(001)")
test2 <- filter(final_dataframe, plane == "(101)")
test2 <- filter(final_dataframe, plane == "(111)")
test2 <- filter(final_dataframe, plane == "(101)U(111)")
test2 <- filter(final_dataframe, plane == "(001)U(101)")
test2 <- filter(final_dataframe, plane == "(001)U(111)")
head(test2)

ggplot(data = test2, aes(x = x, y = y)) + 
  geom_point(colour = test2$kColours, size=1.5) +
  labs(title = paste("EBSD pattern")) +
  xlab("x") +  ylab("y") +  plotTheme()

unique(test2$kColours)

################################################################################################################
# Apply necessary corrections to IPF classification
################################################################################################################
final_dataframe$plane <- ifelse(final_dataframe$kColours == "#C48B54", "(001)", 
                                ifelse(final_dataframe$kColours == "#D6A670", "(001)", 
                                       ifelse(final_dataframe$kColours == "#808DD8", "(111)",
                                              ifelse(final_dataframe$kColours == "#74A9DA", "(111)",
                                                     ifelse(final_dataframe$kColours == "#6CCEA8", "(101)",
                                                            ifelse(final_dataframe$kColours == "#A4CFB1", "(101)",
                                                                   ifelse(final_dataframe$kColours == "#D56F68", "(001)",
                                                                          ifelse(final_dataframe$kColours == "#D08480", "(001)", final_dataframe$plane
                                                                          ))))))))

################################################################################################################
# Correlate to EBSD phase map
################################################################################################################
# Then we should read also the EBSD dataset and add the labels for that and the labels of the planes by x,y

################################################################################################################ 
# *************** Data Preparation - Phase #1 ***************** #
################################################################################################################
# Read EBSD phase annotated image
img2 <- readJPEG("EBSD_phase.jpg") # IPF
imgDm2 <- dim(img2)

# Assign RGB channels to data frame
img_wide2 <- data.frame(
  x = rep(1:imgDm2[2], each = imgDm2[1]),
  y = rep(imgDm2[1]:1, imgDm2[2]),
  R = as.vector(img2[,,1]),
  G = as.vector(img2[,,2]),
  B = as.vector(img2[,,3])
)

# do the rescalling
# Coordinates fix: EBSD phase map (+8.7 to 59.5) x (+8.0 to 45.0) um & round digits to facilitate merging
img_wide2$x <- img_wide2$x - 1
img_wide2$y <- img_wide2$y - 1

img_wide2$x <- img_wide2$x*(59.5 - 8.7)/max(img_wide2$x)
img_wide2$y <- img_wide2$y*(45.0 - 8.0)/max(img_wide2$y)

img_wide2$x <- img_wide2$x + 8.7
img_wide2$y <- img_wide2$y + 8.0

img_EBSD_phase <- img_wide2

# Round digits
img_wide2$x <- round(img_wide2$x, digits = 1)
img_wide2$y <- round(img_wide2$y, digits = 1)

img_wide2 <- img_wide2 %>%
  mutate(color = rgb(R, G, B))

head(img_wide2)
unique(img_wide2$color)

################################################################################################################ 
# *************** EBSD phase map: annotate phase names based on colors ***************** #
################################################################################################################
# cluster separately: colours -> phases
set.seed(1000)
kClusters <- 3 # kalo: 8
kMeans <- kmeans(img_wide2[, c("R", "G", "B")], centers = kClusters)
kColours <- rgb(kMeans$centers[kMeans$cluster,])
img_wide2 <- cbind(img_wide2, kColours) # img_wide <- img_wide[,1:6]
unique(kColours) # length(unique(img_wide$color)) # img_wide_save <- img_wide

ggplot(data = img_wide2, aes(x = x, y = y)) + 
  geom_point(colour = img_wide2$kColours) +
  labs(title = paste("k-Means Clustering of", kClusters, "Colours")) +
  xlab("x") + ylab("y") + plotTheme()

# In this specific case the steels consist of 3 phases according to EBSD characterisation
img_wide2$phase <- ifelse(img_wide2$kColours == "#251FCC", "Bainite", 
                          ifelse(img_wide2$kColours == "#1CC0F5", "Ferrite", 
                                 ifelse(img_wide2$kColours == "#B60D4A", "Martensite", "NA"
                                 )))
unique(img_wide2$phase)

################################################################################################################ 
# *************** Establish a consensus mechanism to revise the phase map ***************** #
################################################################################################################
# merge datasets of IPF and phase map
merged_dataset <- merge(final_dataframe, img_wide2, by = c("x", "y")) #write.csv(merged_dataset, "pixel_comparison_table.csv", row.names = FALSE)
head(merged_dataset)

# keep only distinct values
merged_dataset <- merged_dataset %>% distinct(x, y, .keep_all = TRUE)

a = d = 0

for (i in 1:max(merged_dataset$PDA)) {
  print(i)
  a <- filter(merged_dataset, PDA == i)
  if (nrow(a) < 4) {next}
  n_M <- sum(a$phase == 'Martensite')
  n_B <- sum(a$phase == 'Bainite')
  n_F <- sum(a$phase == 'Ferrite')
  
  if (n_M > n_B & n_M > n_F) {
    a$phase <- 'Martensite'; a$kColours.y <- "#B60D4A"
  } else if (n_B > n_M & n_B > n_F) {
    a$phase <- 'Bainite'; a$kColours.y <- "#251FCC"
  } else {
    a$phase <- 'Ferrite'; a$kColours.y <- "#1CC0F5"
  }
  
  d <- rbind(d, a)
}

head(d)
d <- d[-1,]

# And finally we should make the plot of the revised phase map 
ggplot(data = d, aes(x = x, y = y)) + 
  geom_point(colour = d$kColours.y) +
  #labs(title = paste("k-Means Clustering of", kClusters, "Colours")) +
  xlab("x") + ylab("y") + plotTheme()

EBSD_grain_phase_map <- d

################################################################################################################
# *** Data imputation *** kcolours.y to rgb & enhancement of datapoints with imputation & annotation with phases
################################################################################################################

################################################################################################################
# try to convert kColours to RGB values
################################################################################################################
df_test <- col2rgb(EBSD_grain_phase_map$kColours.y)
df_test <- t(as.data.frame(df_test))
df_test <- as.data.frame(df_test)
df_test <- df_test/255
head(df_test)
EBSD_grain_phase_map <- cbind(EBSD_grain_phase_map, df_test) # img_wide <- img_wide[,1:7]
head(EBSD_grain_phase_map)

EBSD_grain_phase_map <- EBSD_grain_phase_map[,c(1,2,11,12,17,18,19,20,21)]

# Data imputation
df <- EBSD_grain_phase_map[,c(1,2,7,8,9)]
colnames(df) <- c("x", "y", "R", "G", "B")
train_data <- df

# Create a grid of x and y coordinates with 0.1 intervals
grid_x <- seq(floor(min(df$x)), ceiling(max(df$x)), by = 0.1)
grid_y <- seq(floor(min(df$y)), ceiling(max(df$y)), by = 0.1)

# Create a data frame to store the imputed values
imputed_data_un <- expand.grid(x = grid_x, y = grid_y)
test_data <- imputed_data_un

imputed_data <- impute_knn(train_data, test_data) # k <- 8 # You can adjust this value as needed in functions section

# Combine the imputed_data with the original df dataframe
img_wide4 <- rbind(df, imputed_data)

head(img_wide4)

img_wide4 <- img_wide4 %>%
  mutate(color = rgb(R, G, B))

unique(img_wide4$color)

ggplot(data = img_wide4, aes(x = x, y = y)) + 
  geom_point(colour = img_wide4$color) +
  xlab("x") + ylab("y") + plotTheme()

################################################################################################################ 
# Annotate based on Color Distance # 
################################################################################################################
# EBSD map
img_wide4$R <- as.numeric(img_wide4$R); img_wide4$G <- as.numeric(img_wide4$G); img_wide4$B <- as.numeric(img_wide4$B)

img_wide4$kColours <- with(img_wide4, get_color_category(R, G, B)) # imputation introduces shades, which are reduced with this method

unique(img_wide4$kColours) # str(img_wide4)

#ggplot(data = img_wide4, aes(x = x, y = y)) + 
#  geom_point(colour = img_wide4$kColours) +
#  xlab("x") + ylab("y") + plotTheme()

# Check the amount of data that will be left out
count(img_wide4$kColours == "black"); count(img_wide4$kColours == "green"); count(img_wide4$kColours == "yellow")

imgRGB2 <- img_wide4 %>% filter(kColours %in% c("blue", "cyan", "red")) # select the colors resembling the initial map colours

ggplot(data = imgRGB2, aes(x = x, y = y)) + 
  geom_point(colour = imgRGB2$kColours) +
  xlab("x") + ylab("y") + plotTheme()

imgRGB2$phase <- ifelse(imgRGB2$kColours == "red", "Martensite",
                        ifelse(imgRGB2$kColours  == "cyan", "Ferrite",
                               ifelse(imgRGB2$kColours  == "blue", "Bainite", 'N/A')))
head(imgRGB2) 

################################################################################################################
# Correlate to grain boundaries (Edge detection is an easy alternative)
################################################################################################################

################################################################################################################ 
# *************** Data Preparation - Phase #1 ***************** #
################################################################################################################
# Read EBSD phase annotated image
img3 <- readJPEG("GBs.jpg") # GBs
imgDm3 <- dim(img3)

# Assign RGB channels to data frame
img_wide3 <- data.frame(
  x = rep(1:imgDm3[2], each = imgDm3[1]),
  y = rep(imgDm3[1]:1, imgDm3[2]),
  R = as.vector(img3[,,1]),
  G = as.vector(img3[,,2]),
  B = as.vector(img3[,,3])
)

# do the rescalling
# Coordinates fix: EBSD phase map 59.5 x 45.0 um & round digits to facilitate merging
img_wide3$x <- img_wide3$x - 1
img_wide3$y <- img_wide3$y - 1

img_wide3$x <- img_wide3$x*59.5/max(img_wide3$x)
img_wide3$y <- img_wide3$y*45.0/max(img_wide3$y)

img_GB <- img_wide3

# Round digits
img_wide3$x <- round(img_wide3$x, digits = 1)
img_wide3$y <- round(img_wide3$y, digits = 1)

img_wide3 <- img_wide3 %>%
  mutate(color = rgb(R, G, B))

head(img_wide3)
unique(img_wide3$color)

################################################################################################################ 
# *************** EBSD phase map: annotate GBs coordinates  ***************** #
################################################################################################################
# cluster separately: colours -> phases
set.seed(1000)
kClusters <- 2 
kMeans <- kmeans(img_wide3[, c("R", "G", "B")], centers = kClusters)
kColours <- rgb(kMeans$centers[kMeans$cluster,])
img_wide3 <- cbind(img_wide3, kColours) # img_wide <- img_wide[,1:6]
unique(kColours) # length(unique(img_wide$color)) # img_wide_save <- img_wide

ggplot(data = img_wide3, aes(x = x, y = y)) + 
  geom_point(colour = img_wide3$kColours) +
  labs(title = paste("k-Means Clustering of", kClusters, "Colours")) +
  xlab("x") + ylab("y") + plotTheme()

img_wide3$phase <- ifelse(img_wide3$kColours == "#0F0F0F", "Matrix", 
                          ifelse(img_wide3$kColours == "#C0C0C0", "GBs","NA"
                          ))
unique(img_wide3$phase)

# merge datasets of IPF and phase map (without data imputation)
merged_dataset2 <- merge(merged_dataset, img_wide3, by = c("x", "y")) #write.csv(merged_dataset, "pixel_comparison_table.csv", row.names = FALSE)
head(merged_dataset2)

# keep only distinct values
merged_dataset2 <- merged_dataset2 %>% distinct(x, y, .keep_all = TRUE)

merged_dataset2$phase.x <- ifelse(merged_dataset2$phase.y == "GBs", "GBs", merged_dataset2$phase.x)
unique(merged_dataset2$phase.x)

merged_dataset2$kColours.y <- ifelse(merged_dataset2$phase.y == "GBs", "black", merged_dataset2$kColours.y)
unique(merged_dataset2$kColours.y)

# And finally we should make the plot of the revised phase map with GBs
ggplot(data = merged_dataset2, aes(x = x, y = y)) + 
  geom_point(colour = merged_dataset2$kColours.y) +
  xlab("x") + ylab("y") + plotTheme()

# This is really optional in case someone needs to avoid data imputation for any reason
# use anti_join to collect also other coordinates and bind it
rest <- anti_join(merged_dataset, img_wide3, by = c("x", "y")) #write.csv(merged_dataset, "pixel_comparison_table.csv", row.names = FALSE)

head(rest)
head(merged_dataset2)

rest <- rest %>%
  rename(phase.x = phase) 

new_merged <- rbind(merged_dataset2[,c(1,2,11,12,17,18)], rest[,c(1,2,11,12,17,18)])

# And finally we should make the plot of the revised and enriched phase map with GBs
ggplot(data = new_merged, aes(x = x, y = y)) + 
  geom_point(colour = new_merged$kColours.y) +
  xlab("x") + ylab("y") + plotTheme()

# Now 'new_merged' contains the results of grains, crystallographic planes, corrected phases, and boundaries
write.csv(x = new_merged, file = 'grains_planes_phases_boundaries_rerun_Oct23.csv')

################################################################################################################
# Nanoindentation (NI) data turn - start processing
################################################################################################################

################################################################################################################ 
# *************** Data Preparation - Phase #1 ***************** #
################################################################################################################
# NTUA NI: Analysis of tests and classification
#df_save <- df

df = 0 #df <- read.csv(file = "data.csv", header = T)

# Set the expected column length
#expected_length <- 16

# Read the text file, skipping rows with incorrect column length
lines <- readLines("data.txt")
lines <- readLines("Data_2023-07-20,18h29m05s.txt")

#skip_rows <- which(nchar(lines) != expected_length)
#if (length(skip_rows) > 0) {lines <- lines[-c(skip_rows, length(lines))]}
df <- read.table(text = lines, header = TRUE, sep = "\t", fill = TRUE)
df <- df[-c(1,3),]
colnames(df) <- df[1,]
df <- df[-1,]
head(df)
lines = 0

df <- df[, c("Index", "Phase", "Pos X", "Pos Y", "Force A", "Stiffness", "HMax", "Contact Depth", "Area", "Hardness", "Reduced Mod.")]
df <- lapply(df, as.numeric); df <- as.data.frame(df)
df <- na.omit(df) # df <- df[, c(1,2,5:8,11:16)] # Nital: df <- df[, c(1,2,4:6,8:14)] 
df <- filter(df, Hardness > 0) #df <- filter(df, Force.A > 0) 
max(df$Index)
head(df)

df$Depth..nm. <- df$HMax*1000
df$Load..mN. <- df$Force.A/1000
df$E.GPa <- df$Reduced.Mod./1000
df$H.GPa <- df$Hardness/1000
df$hc.nm <- df$Contact.Depth*1000
df$Ac.nm2 <- df$Area*1000000

min(df$Pos.X); max(df$Pos.X); min(df$Pos.Y); max(df$Pos.Y)

df$Pos.X <- df$Pos.X - min(df$Pos.X)
df$Pos.Y <- df$Pos.Y - min(df$Pos.Y)

df$X <- df$Pos.X 
df$Y <- df$Pos.Y

head(df)

df <- df[, c("Index", "Phase", "Stiffness", "Depth..nm.", "Load..mN.", "E.GPa", "H.GPa", "hc.nm", "Ac.nm2", "X", "Y")] # df <- df[,c(1,2, 6, 12:20)] 

min(df$X); max(df$X); min(df$Y); max(df$Y)

df <- filter(df, X < 100)

df$X <- -df$X + max(df$X)
df$Y <- -df$Y + max(df$Y)

min(df$X); max(df$X); min(df$Y); max(df$Y)

df <- filter(df, between(Depth..nm., 12, 35)) # df <- filter(df, between(Depth..nm., 12, 43))
df <- filter(df, between(H.GPa, 0, 20))
df <- filter(df, between(E.GPa, 0, 400))
df <- filter(df, between(Load..mN., 0, 20))
df <- filter(df, between(X, 0, 100))
df <- filter(df, between(Y, 0, 100))

min(df$Depth..nm.); max(df$Depth..nm.); mean(df$Depth..nm.)

summary(df)

################################################################################################################ 
# *************** Plot 2D ***************** # *** CHOOSE REFERENCE DEPTH ***
################################################################################################################
# Select depth - here: 35 nm
#df2 <- filter(df, between(Depth..nm., 34.0, 36.0)) # df2 <- filter(data, between(Depth..nm., 34.0, 36.0))
#df2 <- subset(df2, Index %in% unique(df2$Index))

# Select depth - here: 30 nm
df2 <- filter(df, between(Depth..nm., 29.0, 31.0)) # df2 <- filter(data, between(Depth..nm., 34.0, 36.0))

# Distinct values extraction!
df2 <- distinct(df2, Index, .keep_all = TRUE)
length(unique(df2$Index))

# Create the ggplot with specified color scale limits
ggplot(data = df2, aes(x = X, y = Y)) + # Hardness
  geom_point(aes(colour = H.GPa)) +
  scale_colour_gradientn(colours = c("blue", "cyan", "green", "yellow", "red", "brown"),
                         limits = c(0, 12), breaks = seq(0, 12, by = 2)) +
  xlab("x (um)") + ylab("y (um)") + plotTheme() 

ggplot(data = df2, aes(x = X, y = Y)) + # Modulus
  geom_point(aes(colour = E.GPa)) +
  scale_colour_gradientn(colours = c("blue", "cyan", "green", "yellow", "red", "brown"),
                         limits = c(120, 280), breaks = seq(120, 280, by = 30)) +
  xlab("x (um)") + ylab("y (um)") + plotTheme()

############################################################################################ ###########################
### GMM clustering - PDF - EXPECTATION MAXIMIZATION OPTIMIZATION ALGORITHM ### DO THIS WITH MULTIPLE PARAMETERS 
########################################################################################################################
# tinyheero Github - mixture with THREE (3) components
data <- df2 #data <- read.csv('Pristine.csv') wait <- d
summary(data)
data <- filter(data, between(Load..mN., 0.01, 0.45)) # data <- filter(data, between(Load..mN., 0.1, 0.45))
head(data)
scaled <- scale(data[,c("E.GPa","H.GPa","Load..mN.")])
head(scaled)

gmm <- Mclust(scaled, G = 3, modelNames = NULL, prior = NULL, 
              control = emControl(), 
              initialization = NULL, 
              warn = mclust.options("warn"))

# Get the cluster labels
cluster_labels <- gmm$classification
unique(cluster_labels)
#multi_clean$gmm <- cluster_labels

# Create the same plot with GMM clustering (EM optimised)
summary(gmm, parameters = TRUE)

################################################################################################################ 
# *************** INSERT THE PHASE LABELS IN DF & PLOT2D ***************** #
################################################################################################################
data <- as_tibble(data)
data$PDA <- 0
head(data)
data$PDA <- cluster_labels
summary(filter(data, PDA == 1)); summary(filter(data, PDA == 2)); summary(filter(data, PDA == 3)); summary(filter(data, PDA == 4))

# the numeric allocation is not standard - should tune! 
data$labels <- ifelse(data$PDA == 3, 'Martensite', # select the pairs based on the summary of properties
                      ifelse(data$PDA == 1, 'Bainite',    
                             ifelse(data$PDA == 2, 'Ferrite', 'To be classified'
                             )))
data$PDA <- ifelse(data$labels == 'Martensite', 3, # revise the numbers to correspond to the colorscale as needed for visualisation
                   ifelse(data$labels == 'Bainite', 2,   
                          ifelse(data$labels == 'Ferrite', 1, 'To be classified'
                          )))
data$PDA <- as.numeric(data$PDA)

# Plot 2D phase map, load map, and morphology map

min(data$X); max(data$X); min(data$Y); max(data$Y)

unique(data$PDA)

# Phase map
ggplot(data = data, aes(x = X, y = Y)) +
  geom_point(aes(colour = PDA)) +
  scale_colour_gradientn(colours = c("green", "yellow", "red"), # colours = c("blue", "green", "yellow", "red"),
                         limits = c(1, 3),  # Set the color scale limits
                         breaks = seq(1, 3, by = 1)) + # for more phases/microstructures increase the seq range
  xlab("x (um)") + ylab("y (um)") + plotTheme() # + theme_bw()

write.csv(x = data, file = 'NI_phases_at30nm_newrun_Oct23.csv')

################################################################################################################
# Combine with NI data - without imputation (a lot of data will be missing)
################################################################################################################
# data: the data from NI with the 3 parameters GMM clustering and phase annotation
#data_save <- data
head(data) # NI data
head(new_merged) # EBSD anisotropy/phase/grain number

# correct the NI coordinates: X: - 1.199 um (to left), Y: -0.399 um (down)
min(new_merged$x); max(new_merged$x) ; min(new_merged$y); max(new_merged$y)
#min(data$x); max(data$x) ; min(data$y); max(data$y)

data$X <- data$X - 1.199
data$Y <- data$Y - 0.399

data$x <- round(data$X, digits = 1)
data$y <- round(data$Y, digits = 1)

# merge datasets of IPF/grain/phase map with NI map
merged_NI <- merge(new_merged, data, by = c("x", "y")) #write.csv(merged_dataset, "pixel_comparison_table.csv", row.names = FALSE)
head(merged_NI)

# keep only distinct values
merged_NI <- merged_NI %>% distinct(x, y, .keep_all = TRUE)

merged_NI$labels <- ifelse(merged_NI$phase.x == "GBs", "GBs", merged_NI$labels)
unique(merged_NI$labels)

merged_NI$PDA.y <- ifelse(merged_NI$labels == "GBs", 0, merged_NI$PDA.y)
unique(merged_NI$PDA.y)

merged_NI$color <- ifelse(merged_NI$PDA.y == 0, "black", 
                          ifelse(merged_NI$PDA.y == 1, "green", 
                                 ifelse(merged_NI$PDA.y == 2, "yellow", 
                                        ifelse(merged_NI$PDA.y == 3, "red", 'N/A'))))


# And finally we should make the plot of the revised phase map with GBs (based on non-imputed data - a lot of missing data)
ggplot(data = merged_NI, aes(x = x, y = y)) + 
  geom_point(colour = merged_NI$color) +
  xlab("x") + ylab("y") + plotTheme()

################################################################################################################
# Revise NI phase map per grain consensus 
################################################################################################################
# this step is not necessary if the data imputation path will be followed (maintained for demostration reasons)
head(merged_NI)

a = d = 0

for (i in 1:max(merged_NI$PDA.x)) {
  print(i)
  a <- filter(merged_NI, PDA.x == i)
  if (nrow(a) < 4) {next}
  n_M <- sum(a$labels == 'Martensite')
  n_B <- sum(a$labels == 'Bainite')
  n_F <- sum(a$labels == 'Ferrite')
  
  if (n_M > n_B & n_M > n_F) {
    a$phase <- 'Martensite'; a$kColours.y <- "red"
  } else if (n_B > n_M & n_B > n_F) {
    a$phase <- 'Bainite'; a$kColours.y <- "yellow"
  } else {
    a$phase <- 'Ferrite'; a$kColours.y <- "green"
  }
  
  d <- rbind(d, a)
}

head(d)
d <- d[-1,] 

# And finally we should make the plot of the revised phase map 
ggplot(data = d, aes(x = x, y = y)) + 
  geom_point(colour = d$kColours.y) +
  xlab("x") + ylab("y") + plotTheme()

################################################################################################################ 
# ******** Nanoindentation Image of phase map - read and preparation *********** --- http://mfviz.com/r-image-art/
################################################################################################################
# Image comparison, especially for diffraction techniques and nanoindentation - having already the data of grains/phases/GBs
img <- readJPEG("NI.jpeg") # NI - PDA
imgDm <- dim(img)

# Assign RGB channels to data frame
img_wide <- data.frame(
  x = rep(1:imgDm[2], each = imgDm[1]),
  y = rep(imgDm[1]:1, imgDm[2]),
  R = as.vector(img[,,1]),
  G = as.vector(img[,,2]),
  B = as.vector(img[,,3])
)

# Coordinates fix: NI 59.60 x 69.60 um & round digits to facilitate merging
img_wide$x <- img_wide$x - 1
img_wide$y <- img_wide$y - 1

img_wide$x <- img_wide$x*59.60/max(img_wide$x)
img_wide$y <- img_wide$y*69.60/max(img_wide$y)

# Bring NI within EBSD ROI
img_wide$x <- img_wide$x - 1.199
img_wide$y <- img_wide$y - 0.399

img_NI <- img_wide

# identify the exact same coordinate locations to combine multi-modal outputs

# correct coordinates
#img_wide <- filter(img_wide, x > 2.499)
#img_wide <- filter(img_wide, between(y, 12.529, (max(img_wide$y) - 10.099)))

# fix to start from (0,0)
summary(img_wide)
#img_wide$x <- img_wide$x - min(img_wide$x)
#img_wide$y <- img_wide$y - min(img_wide$y)
#summary(img_wide)

# Round digits
img_wide$x <- round(img_wide$x, digits = 1)
img_wide$y <- round(img_wide$y, digits = 1)

# Data imputation
df <- img_wide # colnames(df) <- c("x", "y", "R", "G", "B")
train_data <- df

# Create a grid of x and y coordinates with 0.1 intervals
grid_x <- seq(floor(min(df$x)), ceiling(max(df$x)), by = 0.1)
grid_y <- seq(floor(min(df$y)), ceiling(max(df$y)), by = 0.1)

# Create a data frame to store the imputed values
imputed_data_un <- expand.grid(x = grid_x, y = grid_y)
test_data <- imputed_data_un

imputed_data <- impute_knn(train_data, test_data) # k <- 8 # You can adjust this value as needed in functions section

# Combine the imputed_data with the original df dataframe
img_wide <- rbind(df, imputed_data)

head(img_wide)

img_wide <- img_wide %>%
  mutate(color = rgb(R, G, B))

unique(img_wide$color)

ggplot(data = img_wide, aes(x = x, y = y)) + 
  geom_point(colour = img_wide$color) +
  xlab("x") + ylab("y") + plotTheme()

################################################################################################################ 
# *************** CLUSTERING ***************** #
################################################################################################################
# see if we need to initialise to reproduce the same colours every time we cluster
# Nanoindentation map
set.seed(1000)
kClusters <- 3 # kalo: 8
kMeans <- kmeans(img_wide[, c("R", "G", "B")], centers = kClusters)
kColours <- rgb(kMeans$centers[kMeans$cluster,])
imgRGB <- cbind(img_wide, kColours)
unique(kColours)

ggplot(data = imgRGB, aes(x = x, y = y)) + 
  geom_point(colour = kColours) +
  labs(title = paste("k-Means Clustering of", kClusters, "Colours")) +
  xlab("x") + ylab("y") + plotTheme()

imgRGB$phase <- ifelse(imgRGB$kColours == "#C12B03", "Martensite",
                          ifelse(imgRGB$kColours  == "#22F407", "Ferrite",
                                 ifelse(imgRGB$kColours  == "#E1FC17", "Bainite", 'N/A')))
head(imgRGB)

################################################################################################################
# Revise NI phase map - Part1: Annotate phase by grain - v1.8
################################################################################################################
# merge datasets of IPF/grain/phase map with NI map
merged_NI2 <- merge(final_dataframe, imgRGB, by = c("x", "y")) #write.csv(merged_dataset, "pixel_comparison_table.csv", row.names = FALSE)
head(merged_NI2)
head(final_dataframe)

# keep only distinct values
merged_NI2 <- merged_NI2 %>% distinct(x, y, .keep_all = TRUE)

a = d = 0

for (i in 1:max(merged_NI2$PDA)) { # I can add here the equivalent diameter calculation: Feret diameter: d = 2*sqrt(A/pi), min, max
  print(i)
  a <- filter(merged_NI2, PDA == i)
  if (nrow(a) < 4) {next}
  n_M <- sum(a$phase == 'Martensite')
  n_B <- sum(a$phase == 'Bainite')
  n_F <- sum(a$phase == 'Ferrite')
  
  if (n_M > n_B & n_M > n_F) {
    a$phase <- 'Martensite'; a$kColours <- "red"
  } else if (n_B > n_M & n_B > n_F) {
    a$phase <- 'Bainite'; a$kColours <- "yellow"
  } else {
    a$phase <- 'Ferrite'; a$kColours <- "green"
  }
  
  # Calculate Convex Hull
  aa1 <- a[,c("x", "y")]
  chull_points <- chull(aa1)
  convex_hull <- aa1[chull_points, ]
  
  # Calculate Diameter
  diameter <- sqrt(max(rdist(convex_hull)))  #print(paste("Equivalent Diameter:", diameter)) # um
  
  a$diameter <- diameter
  a$length <- max(a$x) - min(a$x)
  a$width <- max(a$y) - min(a$y)
  
  d <- rbind(d, a)
}

head(d)
d <- d[-1,] 

# And finally we should make the plot of the revised phase map 
ggplot(data = d, aes(x = x, y = y)) + 
  geom_point(colour = d$kColours) +
  xlab("x") + ylab("y") + plotTheme()

# NI grain corrected dataset and with data imputation before binding with the grain map
NI_grain_corrected <- d
  
################################################################################################################
# Correlate to grain boundaries
################################################################################################################
img_GB <- img_wide3

# Data imputation
df <- img_wide3 # colnames(df) <- c("x", "y", "R", "G", "B")
train_data <- df

# Create a grid of x and y coordinates with 0.1 intervals
grid_x <- seq(floor(min(df$x)), ceiling(max(df$x)), by = 0.1)
grid_y <- seq(floor(min(df$y)), ceiling(max(df$y)), by = 0.1)

# Create a data frame to store the imputed values
imputed_data_un <- expand.grid(x = grid_x, y = grid_y)
test_data <- imputed_data_un

imputed_data <- impute_knn(train_data, test_data) # k <- 8 # You can adjust this value as needed in functions section

# Combine the imputed_data with the original df dataframe
img_wide3 <- rbind(df, imputed_data)

head(img_wide3)

# produce the color code for plotting
img_wide3 <- img_wide3 %>%
  mutate(color = rgb(R, G, B))

unique(img_wide3$color)

ggplot(data = img_wide3, aes(x = x, y = y)) + 
  geom_point(colour = img_wide3$color) +
  xlab("x") + ylab("y") + plotTheme()

head(img_wide3)

################################################################################################################ 
# *************** EBSD phase map: annotate GBs coordinates  ***************** #
################################################################################################################
# cluster separately: colours -> phases
set.seed(1000)
kClusters <- 2 
kMeans <- kmeans(img_wide3[, c("R", "G", "B")], centers = kClusters)
kColours <- rgb(kMeans$centers[kMeans$cluster,])
img_wide3 <- cbind(img_wide3, kColours) # img_wide <- img_wide[,1:6]
unique(kColours) # length(unique(img_wide$color)) # img_wide_save <- img_wide
img_wide3 <- img_wide3[,c(1:6,8:9)]

ggplot(data = img_wide3, aes(x = x, y = y)) + 
  geom_point(colour = img_wide3$kColours) +
  labs(title = paste("k-Means Clustering of", kClusters, "Colours")) +
  xlab("x") + ylab("y") + plotTheme()

img_wide3$phase <- ifelse(img_wide3$kColours == "#0F0F0F", "Matrix", 
                          ifelse(img_wide3$kColours == "#C0C0C0", "GBs","NA"
                          ))
unique(img_wide3$phase)

################################################################################################################
# Revise NI phase map - Part2
################################################################################################################
# merge datasets of grain map with NI map
head(d)
head(img_wide3)
merged_NI3 <- merge(d[,c(1,2,11,12,18:22)], img_wide3[,c(1,2,8)], by = c("x", "y")) #write.csv(merged_dataset, "pixel_comparison_table.csv", row.names = FALSE)
head(merged_NI3)

# keep only distinct values
merged_NI3 <- merged_NI3 %>% distinct(x, y, .keep_all = TRUE)

#merged_NI3$phase.x <- ifelse(merged_NI3$phase.y == "GBs", "GBs", merged_NI3$phase.x) # may check it
#merged_NI3$kColours <- ifelse(merged_NI3$phase.x == "GBs", "black", merged_NI3$kColours)

unique(merged_NI3$kColours.y)

merged_NI3$phase <- ifelse(merged_NI3$kColours.y == "#C0C0C0", "GBs", merged_NI3$phase) # may check it
merged_NI3$kColours <- ifelse(merged_NI3$phase == "GBs", "black", merged_NI3$kColours.x)

unique(merged_NI3$phase)
unique(merged_NI3$kColours)

ggplot(data = merged_NI3, aes(x = x, y = y)) + 
  geom_point(colour = merged_NI3$kColours) +
  xlab("x") + ylab("y") + plotTheme()

################################################################################################################
# Revise NI phase map - Part3: Consensus between NI and EBSD phase annotation
################################################################################################################
# merge datasets of grain map with NI map
head(imgRGB2)
head(merged_NI3)
new_merged3 <- merge(imgRGB2[,c(1,2,8)], merged_NI3[,1:9], by = c("x", "y")) #write.csv(merged_dataset, "pixel_comparison_table.csv", row.names = FALSE)
head(new_merged3)

# keep only distinct values
new_merged3 <- new_merged3 %>% distinct(x, y, .keep_all = TRUE)

################################################################################################################
# Consensus 
################################################################################################################
unique(new_merged3$phase.x)
unique(new_merged3$phase.y)
unique(new_merged3$kColours)

new_merged3$phase.y <- ifelse(new_merged3$phase.x == "Martensite", "Martensite", 
                            ifelse(new_merged3$phase.x == "Bainite", "Bainite", 
                                   ifelse(new_merged3$phase.x == "Ferrite", "Ferrite",new_merged3$phase.y)))

new_merged3$phase.y <- ifelse(new_merged3$kColours == "black", "GBs", new_merged3$phase.y)

new_merged3$kColours <- ifelse(new_merged3$phase.y == "Martensite", "red", 
                               ifelse(new_merged3$phase.y == "Bainite", "yellow", 
                                      ifelse(new_merged3$phase.y == "Ferrite", "green", 
                                             ifelse(new_merged3$phase.y == "GBs", "black", "white"))))

# And finally we should make the plot of the revised phase map 
ggplot(data = new_merged3, aes(x = x, y = y)) + 
  geom_point(colour = new_merged3$kColours) +
  xlab("x") + ylab("y") + plotTheme()

# EBSD with GBs
head(merged_NI3)
head(imgRGB2)
new_merged4 <- merge(imgRGB2[,c(1,2,7,8)], merged_NI3[,c(1,2,7:9,11)], by = c("x", "y")) #write.csv(merged_dataset, "pixel_comparison_table.csv", row.names = FALSE)
head(new_merged4)
unique(new_merged4$kColours.x)

# keep only distinct values
new_merged4 <- new_merged4 %>% distinct(x, y, .keep_all = TRUE)

new_merged4$kColours.x <- ifelse(new_merged4$kColours.y == "black", "black", new_merged4$kColours.x)
new_merged4$phase <- ifelse(new_merged4$kColours.y == "black", "GBs", new_merged4$phase)

new_merged4$kColours.y <- ifelse(new_merged4$phase == "Martensite", "red", 
                               ifelse(new_merged4$phase == "Bainite", "yellow", 
                                      ifelse(new_merged4$phase == "Ferrite", "green", 
                                             ifelse(new_merged4$phase == "GBs", "black", "white"))))

# And finally we should make the plot of the revised phase map 
ggplot(data = new_merged4, aes(x = x, y = y)) + 
  geom_point(colour = new_merged4$kColours.y) +
  xlab("x") + ylab("y") + plotTheme()

################################################################################################################ 
# ************ Statistics - Plot the datasets containing the required information (for validation) *********** #
################################################################################################################

# Nanoindentation data - the information about grain dimensions is not known in this dataset
head(data) # NI map with cluster annotation
data$phase <- data$labels
data$diameter = data$length = data$width = 0
data$kColours <- ifelse(data$phase == "Martensite", "red", 
                                 ifelse(data$phase == "Bainite", "yellow", 
                                        ifelse(data$phase == "Ferrite", "green", "white")))

ggplot(data = data, aes(x = x, y = y)) + 
  geom_point(colour = data$kColours) +
  xlab("x") + ylab("y") + plotTheme()

# Nanoindentation data with correction of phases - one grain = one phase
head(data) # NI map with cluster annotation
head(NI_grain_corrected) # NI image with grain consensus annotation
NI_concensus <- merge(data[, c(6,7,14,15)], NI_grain_corrected[, c(1,2,12, 18:22)], by = c("x", "y"))
head(NI_concensus)

ggplot(data = NI_concensus, aes(x = x, y = y)) + 
  geom_point(colour = NI_concensus$kColours) +
  xlab("x") + ylab("y") + plotTheme()

# Nanoindentation data with correction of phases and annotation of grain boundaries
head(merged_NI3) # NI image with GBs annotation
NI_GBs_annot <- merge(data[, c(6,7,14,15)], merged_NI3[, c(1,2,4,5,7:9,11)], by = c("x", "y"))
NI_GBs_annot$plane <- ifelse(NI_GBs_annot$phase == "GBs", "no plane", NI_GBs_annot$plane) # GBs have no plane
head(NI_GBs_annot) # NI data with GBs annotation

ggplot(data = NI_GBs_annot, aes(x = x, y = y)) + 
  geom_point(colour = NI_GBs_annot$kColours) +
  xlab("x") + ylab("y") + plotTheme()

# Nanoindentation data with correction of phases and annotation of grain boundaries and annotation of phases by EBSD
head(new_merged4) # NI map with EBSD phases annotation and GBs
NI_EBSD_gr2ph_annot <- merge(data[, c(6,7, 14,15)], new_merged4[, c(1,2,4:8)], by = c("x", "y"))
NI_EBSD_gr2ph_annot <- merge(NI_EBSD_gr2ph_annot, NI_GBs_annot[, c(1,2,5)], by = c("x", "y"))
NI_EBSD_gr2ph_annot$kColours <- NI_EBSD_gr2ph_annot$kColours.y
NI_EBSD_gr2ph_annot$plane <- ifelse(NI_EBSD_gr2ph_annot$phase == "GBs", "no plane", NI_EBSD_gr2ph_annot$plane) # GBs have no plane
head(NI_EBSD_gr2ph_annot) # NI data with EBSD phases annotation and GBs

ggplot(data = NI_EBSD_gr2ph_annot, aes(x = x, y = y)) + 
  geom_point(colour = NI_EBSD_gr2ph_annot$kColours) +
  xlab("x") + ylab("y") + plotTheme()

################################################################################################################
# Statistics - Group the data by unique values in the 'PDA' column and calculate the mean and standard deviation
################################################################################################################
stat_df <- data # only by phase
stat_df <- NI_concensus # only by phase
stat_df <- NI_GBs_annot 
stat_df <- NI_EBSD_gr2ph_annot

head(stat_df)

result <- stat_df %>%
  group_by(phase) %>%
  summarize(
    Mean_E = mean(E.GPa, na.rm = TRUE),
    SD_E = sd(E.GPa, na.rm = TRUE),
    Mean_H = mean(H.GPa, na.rm = TRUE),
    SD_H = sd(H.GPa, na.rm = TRUE),
    Mean_diameter = mean(diameter, na.rm = TRUE),
    SD_diameter = sd(diameter, na.rm = TRUE),
    Mean_length = mean(length, na.rm = TRUE),
    SD_length = sd(length, na.rm = TRUE),
    Mean_width = mean(width, na.rm = TRUE),
    SD_width = sd(width, na.rm = TRUE)
  )

print(result)

result <- stat_df %>%
  group_by(plane) %>%
  summarize(
    Mean_E = mean(E.GPa, na.rm = TRUE),
    SD_E = sd(E.GPa, na.rm = TRUE),
    Mean_H = mean(H.GPa, na.rm = TRUE),
    SD_H = sd(H.GPa, na.rm = TRUE),
    Mean_diameter = mean(diameter, na.rm = TRUE),
    SD_diameter = sd(diameter, na.rm = TRUE),
    Mean_length = mean(length, na.rm = TRUE),
    SD_length = sd(length, na.rm = TRUE),
    Mean_width = mean(width, na.rm = TRUE),
    SD_width = sd(width, na.rm = TRUE)
  )

# Print the result
print(result)

# by plane and phase together

result <- stat_df %>%
  group_by(phase, plane) %>%
  summarize(
    Mean_E = mean(E.GPa, na.rm = TRUE),
    SD_E = sd(E.GPa, na.rm = TRUE),
    Mean_H = mean(H.GPa, na.rm = TRUE),
    SD_H = sd(H.GPa, na.rm = TRUE),
    Mean_diameter = mean(diameter, na.rm = TRUE),
    SD_diameter = sd(diameter, na.rm = TRUE),
    Mean_length = mean(length, na.rm = TRUE),
    SD_length = sd(length, na.rm = TRUE),
    Mean_width = mean(width, na.rm = TRUE),
    SD_width = sd(width, na.rm = TRUE)
  )

# Print the result
print(result)

# Filter columns of interest
head(result)

################################################################################################################
# Final plots
################################################################################################################

result_filtered <- result[, c(1:8)]
result_filtered$Mean_E <- result_filtered$Mean_E/100 # scale
result_filtered$Mean_H <- result_filtered$Mean_H/10 # scale
result_filtered$SD_E <- result_filtered$SD_E/100 # scale
result_filtered$SD_H <- result_filtered$SD_H/10 # scale

# Plot of final revised and validated dataset
ggplot() +
  geom_bar(data = result_filtered, aes(x = interaction(phase, plane), y = Mean_E, color = "cyan"), stat = "identity") +
  geom_bar(data = result_filtered, aes(x = interaction(phase, plane), y = Mean_H, color = "pink"), stat = "identity") +
  geom_point(data = result_filtered, aes(x = interaction(phase, plane), y = Mean_diameter), color = "green", size = 6) +
  geom_errorbar(data = result_filtered, aes(x = interaction(phase, plane), ymin = Mean_E - SD_E, ymax = Mean_E + SD_E), color = "pink", width = 0.3, size = 1) +
  geom_errorbar(data = result_filtered, aes(x = interaction(phase, plane), ymin = Mean_H - SD_H, ymax = Mean_H + SD_H), color = "cyan", width = 0.3, size = 1) +
  geom_errorbar(data = result_filtered, aes(x = interaction(phase, plane), ymin = Mean_diameter - SD_diameter, ymax = Mean_diameter + SD_diameter), color = "green", width = 0.1) +
  labs(x = "Phase-Plane", y = "Value") + plotTheme() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))


# Filter columns of interest + make this plots per phase
head(stat_df)

stat_filtered <- stat_df[, c(3,4,5,6,10,11)]
head(stat_filtered)

stat_filtered <- stat_filtered[stat_filtered$phase != "GBs", ]

# Create a plot of H.GPa vs diameter for each phase
ggplot(stat_filtered, aes(x = diameter, y = H.GPa, color = interaction(phase, plane))) +
  geom_point(size = 2) +
  labs(x = "Diameter", y = "H.GPa", title = "H.GPa vs Diameter") + 
  plotTheme() +
  facet_wrap(~ phase)

# Create a plot of E.GPa vs diameter for each phase
ggplot(stat_filtered, aes(x = diameter, y = E.GPa, color = interaction(phase, plane))) +
  geom_point(size = 2) +
  labs(x = "Diameter", y = "E.GPa", title = "E.GPa vs Diameter") + 
  plotTheme() +
  facet_wrap(~ phase)

# Define a color palette for planes
plane_colors <- c("no plane" = "black", "(101)" = "green", "(001)U(101)" = "yellow", "(001)U(111)" = "pink",
                  "(001)" = "red", "(111)" = "blue", "(101)U(111)" = "cyan")  # Add more colors as needed

# Define a color palette for planes
plane_colors <- c("no plane" = "red", "(101)" = "blue", "(001)U(101)" = "green", "(001)U(111)" = "purple")  # Add more colors as needed

# Create a plot of H.GPa vs diameter for each phase, color based on "plane"
ggplot(stat_filtered, aes(x = diameter, y = H.GPa, color = plane, fill = plane)) +
  geom_point(size = 2) +
  labs(x = "Diameter", y = "H.GPa") + 
  plotTheme() +
  facet_wrap(~ phase) +
  scale_color_manual(values = plane_colors) +
  scale_fill_manual(values = plane_colors)

# Create a plot of E.GPa vs diameter for each phase, color based on "plane"
ggplot(stat_filtered, aes(x = diameter, y = E.GPa, color = plane, fill = plane)) +
  geom_point(size = 2) +
  labs(x = "Diameter", y = "E.GPa") + 
  plotTheme() +
  facet_wrap(~ phase) +
  scale_color_manual(values = plane_colors) +
  scale_fill_manual(values = plane_colors)

################################################################################################################ 
# *************** APPENDIX ***************** #
################################################################################################################

################################################################################################################ 
# *************** Optional: plot NI maps correlated with EBSD or GBs without data imputation ***************** #
################################################################################################################
# merge datasets of EBSD grain map with NI map
head(EBSD_grain_phase_map)
head(img_NI)

img_NI <- img_NI %>%
  mutate(color = rgb(R, G, B))

# Round digits
img_NI$x <- round(img_NI$x, digits = 1)
img_NI$y <- round(img_NI$y, digits = 1)

merged_NI3_orig <- merge(EBSD_grain_phase_map, img_NI, by = c("x", "y")) #write.csv(merged_dataset, "pixel_comparison_table.csv", row.names = FALSE)
head(merged_NI3_orig)

# keep only distinct values
merged_NI3_orig <- merged_NI3_orig %>% distinct(x, y, .keep_all = TRUE)

ggplot(data = merged_NI3_orig, aes(x = x, y = y)) + 
  geom_point(colour = merged_NI3_orig$color) +
  xlab("x") + ylab("y") + plotTheme()

# merge NI map with GBs - new_merged # EBSD + GBs
head(new_merged)

merged_NI3_orig2 <- merge(new_merged, merged_NI3_orig, by = c("x", "y")) #write.csv(merged_dataset, "pixel_comparison_table.csv", row.names = FALSE)
head(merged_NI3_orig2)

# keep only distinct values
merged_NI3_orig2 <- merged_NI3_orig2 %>% distinct(x, y, .keep_all = TRUE)

unique(merged_NI3_orig2$phase.x)

merged_NI3_orig2$color <- ifelse(merged_NI3_orig2$phase.x == "GBs", "black", merged_NI3_orig2$color)

ggplot(data = merged_NI3_orig2, aes(x = x, y = y)) + 
  geom_point(colour = merged_NI3_orig2$color) +
  xlab("x") + ylab("y") + plotTheme()

############################################################################################ 
##### PDF - EXPECTATION MAXIMIZATION OPTIMIZATION ALGORITHM ###### DO THIS WITH LOAD - NTUA
############################################################################################

# tinyheero Github - mixture with THREE (3) components
data <- df2 #data <- read.csv('Pristine.csv') wait <- d
summary(data)
data <- filter(data, between(Load..mN., 0.01, 0.45)) # data <- filter(data, between(Load..mN., 0.1, 0.45))

h <- mean(data$Depth..nm.); sdh <- sd(data$Depth..nm.)

P <- as.data.frame(data$Load..mN.) # P <- as_tibble(P)
P <- P[order(P$`data$Load..mN.`),]

################################################################################################################ 
# *************** CLUSTERING - INITIAL GUESS OF PDA values ***************** #
################################################################################################################

gmm <- Mclust(P, G = 3, modelNames = NULL, prior = NULL, 
              control = emControl(), 
              initialization = NULL, 
              warn = mclust.options("warn"))

# Get the cluster labels
cluster_labels <- gmm$classification
unique(cluster_labels)
#multi_clean$gmm <- cluster_labels

# Create the same plot with GMM clustering (EM optimised)
summary(gmm, parameters = TRUE)

################################################################################################################ 
# *************** INSERT THE PHASE LABELS IN DF & PLOT2D ***************** #
################################################################################################################
data <- as_tibble(data); data <- data[order(data$Load..mN.),] #m.step.df <- as_tibble(m.step)
data$PDA <- 0
head(data)
data$PDA <- cluster_labels
summary(filter(data, PDA == 1)); summary(filter(data, PDA == 2)); summary(filter(data, PDA == 3)); summary(filter(data, PDA == 4))

# Checkpoint: Should select based on summary of properties & number of clusters & check sequence of phases
data$labels <- ifelse(data$PDA == 4, 'Martensite',
                      ifelse(data$PDA == 3, 'Bainite',    
                             ifelse(data$PDA == 1, 'Ferrite',
                                    ifelse(data$PDA == 2, 'Austenite', 'To be classified'
                                    ))))
data$labels <- ifelse(data$PDA == 3, 'Martensite',
                      ifelse(data$PDA == 1, 'Bainite',    
                             ifelse(data$PDA == 2, 'Ferrite', 'To be classified'
                             )))

# revise the numeric sequence for creating nice plots with color indications
data$PDA <- ifelse(data$labels == 'Martensite', 3,
                   ifelse(data$labels == 'Bainite', 2,   
                          ifelse(data$labels == 'Ferrite', 1, 'To be classified'
                          )))
data$PDA <- as.numeric(data$PDA)

# Plot 2D phase map, load map, and morphology map

min(data$X); max(data$X); min(data$Y); max(data$Y)

unique(data$PDA)

# Phase map
ggplot(data = data, aes(x = X, y = Y)) +
  geom_point(aes(colour = PDA)) +
  scale_colour_gradientn(colours = c("green", "yellow", "red"), # colours = c("blue", "green", "yellow", "red"),
                         limits = c(1, 3),  # Set the color scale limits
                         breaks = seq(1, 3, by = 1)) +
  xlab("x (um)") + ylab("y (um)") + plotTheme() # + theme_bw()

#data <- lapply(data, as.numeric); data <- as.data.frame(data); plot_ly(data, x = ~X, y = ~Y, z = ~PDA, type = "contour") 

# Load map
ggplot(data = data, aes(x = X, y = Y)) +
  geom_point(aes(colour = Load..mN.)) +
  scale_colour_gradientn(colours = c("black", "blue", "cyan", "green", "yellow", "red", "brown"),
                         limits = c(0, 0.4),  # Set the color scale limits
                         breaks = seq(0, 0.4, by = 0.05)) +
  xlab("x (um)") + ylab("y (um)") + plotTheme() # +  theme_bw()
