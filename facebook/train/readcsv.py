import pandas as pd


df = pd.read_csv('fb_2022_adid_text.csv.gz', skiprows=0, nrows=1000000)
filtered_df = df[['product_brand']]
new_filtered_df = filtered_df[filtered_df['product_brand'].notnull() & (df['product_brand'] != 0)]


pd.set_option('display.max_columns', None)  
pd.set_option('display.max_colwidth', None)  
pd.set_option('display.width', 1000) 
pd.set_option('display.max_rows', None)  


print(new_filtered_df)

