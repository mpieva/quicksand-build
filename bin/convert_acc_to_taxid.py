import sys

acc_tax_dict = {}
for line in [x for x in open(sys.argv[2])]:
    _,k,v,_ = line.split('\t', 3)
    acc_tax_dict[k] = v

handle = open('taxid_map.tsv', 'w')

for line in [x for x in open(sys.argv[1])]:
    acc, fam, sp = line.replace('\n','').split('\t', 2)
    print(acc_tax_dict[acc], fam, sp, sep='\t', file=handle)

handle.close()

