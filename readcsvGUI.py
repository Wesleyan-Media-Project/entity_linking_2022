from pandasgui import show
import pandas as pd

#This script may take a while (>10 min) to run depending on the size of the data.

# Read csv.gz file
df = pd.read_csv('facebook/data/entity_linking_results_fb22.csv.gz', compression='gzip')

# Launch GUI
show(df)
