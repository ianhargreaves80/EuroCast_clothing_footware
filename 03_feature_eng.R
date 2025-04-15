# ================================
# 📦 Step 1: Select Non-Predictor Variables
# ================================
# You might include these for structural behavior:
cluster_vars <- c(
  "household_income",  # long-term macro feature
  "unemployment_rate",
  "volume_index",      # historical demand level
  "sentiment",         # confidence proxy
  "price_index"        # structural inflation exposure
)

# ================================
# 🧮 Step 2: Aggregate at Country Level
# ================================
geo_summary <- combined_q_lags %>%
  group_by(geo) %>%
  summarise(across(all_of(cluster_vars), mean, na.rm = TRUE)) %>%
  column_to_rownames("geo") %>%
  scale()  # normalize across variables

# ================================
# 🔗 Step 3: Compute Distance Matrix
# ================================
dist_matrix <- dist(geo_summary, method = "euclidean")

# ================================
# 🌲 Step 4: Hierarchical Clustering
# ================================
hc <- hclust(dist_matrix, method = "ward.D2")

# Optional: Plot dendrogram
plot(hc, main = "Hierarchical Clustering of Countries", xlab = "", sub = "")

# ================================
# 🔢 Step 5: Cut Tree Into Clusters
# ================================
# Choose number of clusters (you can iterate to find best k)
k <- 4
cluster_assignments <- cutree(hc, k = k)

# Convert to data frame
geo_cluster_df <- data.frame(
  geo = rownames(geo_summary),
  cluster = as.factor(cluster_assignments)
)

# ================================
# 🔄 Step 6: Join Clusters Back to Main Data
# ================================
combined_q_lags <- combined_q_lags %>%
  left_join(geo_cluster_df, by = "geo")

# Heatmap
heatmap(as.matrix(geo_summary), Rowv = as.dendrogram(hc), scale = "none")

# ================================
# 📐 Step 1: Cut tree at height = 4
# ================================
# You can easily switch this value
cut_height <- 4.5  # try changing to 6, 8, etc. if needed

# Recut the dendrogram at chosen height
cluster_assignments <- cutree(hc, h = cut_height)

# Assign to tidy dataframe
geo_cluster_df <- data.frame(
  geo = rownames(geo_summary),
  cluster = as.factor(cluster_assignments)
)

# List countries by cluster
countries_by_cluster <- geo_cluster_df %>%
  group_by(cluster) %>%
  summarise(countries = list(sort(geo)), .groups = "drop")

# Print nicely
countries_by_cluster %>%
  rowwise() %>%
  mutate(print_line = paste(countries, collapse = ", ")) %>%
  select(cluster, print_line) %>%
  print(n = Inf)

# Merge cluster assignments back into full dataset
combined_q_lags <- combined_q_lags %>%
  left_join(geo_cluster_df, by = "geo")

# Step 1: Drop all existing cluster columns
combined_q_lags_cleaned <- combined_q_lags %>%
  select(-matches("^cluster(\\.|$)"))

# Step 2: Add fresh cluster assignment
combined_q_lags_cleaned <- combined_q_lags_cleaned %>%
  left_join(geo_cluster_df, by = "geo")
str(combined_q_lags_cleaned)
