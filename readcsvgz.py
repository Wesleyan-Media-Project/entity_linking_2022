import pandas as pd
import datetime
import argparse
import os

# This script may take a while (>10 min) to run depending on the size of the data.

# Set up argument parsing
def parse_arguments():
    parser = argparse.ArgumentParser(description="Filter large CSV files and save results to an Excel file.")
    parser.add_argument('--file', type=str, required=True, help='Path to the CSV file.')
    parser.add_argument('--skiprows', type=int, default=0, help='Number of rows to skip at the start of the file.')
    parser.add_argument('--nrows', type=int, default=1000, help='Number of rows to read from the file.')
    parser.add_argument('--filter_text', type=str, default='', help='Text to filter the rows.')
    return parser.parse_args()

def load_data(file_path, skiprows, nrows):
    # Load data from the CSV file 
    # with specified rows to skip and number of rows to read
    try:
        return pd.read_csv(file_path, skiprows=skiprows, nrows=nrows)
    except FileNotFoundError:
        print(f"File not found: {file_path}")
        exit(1)
    except Exception as e:
        print(f"Error loading data: {e}")
        exit(1)

def filter_data(df, text):
    # Filter the DataFrame based on the provided text
    return df[df.apply(lambda row: row.astype(str).str.contains(text, case=False, na=False).any(), axis=1)]

def save_to_excel(df, file_prefix='Readcsvgz_Output'):
    # Save the filtered DataFrame to an Excel file with a timestamp
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    excel_file_path = f'{file_prefix}_{timestamp}.xlsx'
    try:
        df.to_excel(excel_file_path, index=False)
        print(f"Filtered data saved to: {excel_file_path}")
    except Exception as e:
        print(f"Error saving to Excel: {e}")

def main():
    # Parse command-line arguments
    args = parse_arguments()
    df = load_data(args.file, args.skiprows, args.nrows)
    filtered_df = filter_data(df, args.filter_text)
    
    # Set display options to avoid truncation in columns
    pd.set_option('display.max_columns', None)
    pd.set_option('display.max_colwidth', None)
    pd.set_option('display.width', 1000)
    pd.set_option('display.max_rows', None)
    save_to_excel(filtered_df)

if __name__ == "__main__":
    main()
