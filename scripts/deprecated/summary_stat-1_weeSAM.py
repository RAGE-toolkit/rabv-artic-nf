import pandas as pd
import os
from argparse import ArgumentParser
from os.path import join as join

def process(args):
	appended_data = []
	file_lst = []
	for each_file in os.listdir(args.input_dir):
		file_name = each_file.split('.')[0]
		if 'summary.txt' in each_file:
			if file_name not in file_lst:
				data = pd.read_csv(join(args.input_dir, each_file), delimiter='\t')
				data.iloc[:, 0] = each_file.replace('.summary.txt', '')
				appended_data.append(data)
				file_lst.append(file_name)
	final_data = pd.concat(appended_data, ignore_index=True)
	final_data.columns.values[0] = 'sample_name'
	final_data.to_csv(args.output_file, sep='\t', index=False)

if __name__ == "__main__":
	print ("Merging summary files ..................\n")
	parser = ArgumentParser(description='Merges summary files')
	parser.add_argument('-i', '--input_dir', help='input directory', required=True)
	parser.add_argument('-o', '--output_file', help='output file name', required=True)
	args = parser.parse_args()
	process(args)
