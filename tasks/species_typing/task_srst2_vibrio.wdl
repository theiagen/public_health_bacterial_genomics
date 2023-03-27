version 1.0

task srst2_vibrio {
  meta {
    description: "Computational method for finding spa types in Staphylococcus aureus"
  }
  input {
    File reads1
    File? reads2
    String samplename
    Int srst2_min_cov
    Int srst2_max_divergence
    Int srst2_min_depth
    Int srst2_min_edge_depth
    Int srst2_gene_max_mismatch
    String docker = "quay.io/kapsakcj/srst2:0.2.0-vcholerae" # TODO: Update with container including vibrio db
    Int disk_size = 100
    Int cpu = 4
  }
  command <<<
    if [ -z "~{reads2}" ] ; then
      INPUT_READS="--input_se ~{reads1}"
    else
      # This task expects/requires that input FASTQ files end in "_1.clean.fastq.gz" and "_2.clean.fastq.gz"
      # which is the syntax from TheiaProk read cleaning tasks
      INPUT_READS="--input_pe ~{reads1} ~{reads2} --forward _1.clean --reverse _2.clean"
    fi

    srst2 --version 2>&1 | tee VERSION
    srst2 \
      ${INPUT_READS} \
      --gene_db /vibrio-cholerae-db/vibrio_230224.fasta \
      --output ~{samplename} \
      --min_coverage ~{srst2_min_cov} \
      --max_divergence ~{srst2_max_divergence} \
      --min_depth ~{srst2_min_depth} \
      --min_edge_depth ~{srst2_min_edge_depth} \
      --gene_max_mismatch ~{srst2_gene_max_mismatch}
    
    # capture output TSV
    mv ~{samplename}__genes__*__results.txt ~{samplename}.tsv

    # capture detailed output TSV - not available if no results are outputed
    mv ~{samplename}__fullgenes__*__results.txt ~{samplename}.detailed.tsv || echo "No results" >  ~{samplename}.detailed.tsv

    # parsing block to account for when output columns do not exist
    python <<CODE
    import csv
    import re

    # Converting TSV file into list of dictionaries
    def csv_to_dict(filename):
      result_list=[]
      with open(filename) as file_obj:
          reader = csv.DictReader(file_obj, delimiter='\t')
          for row in reader:
              result_list.append(dict(row))
      # only one sample is run, so there's only one row, flattening list
      return result_list[0]

    # Converting None to empty string
    conv = lambda i : i or ''

    # Make characters human-readable 
    def translate_chars(string):
      translation = []
      if '*' in string:
        translation.append("mismatch")
      if '?' in string:
        translation.append("low depth/uncertain")
      if '-' in string:
        translation.append("not detected")
      
      string = re.sub("\*|\?|-", "", string)

      if len(translation) > 0:
        string = string + ' (' + ';'.join(translation) + ')'
      return string


    row = csv_to_dict('~{samplename}.tsv')
  
    with open("ctxA", "wb") as ctxA_fh:
      value = row.get("ctxA")
      ctxA_fh.write(translate_chars(conv(value)))
    
    with open("ompW", "wb") as ompW_fh:
      value = row.get("ompW")
      ompW_fh.write(translate_chars(conv(value)))
    
    with open("tcpA_ElTor", "wb") as tcpA_ElTor_fh:
      value = row.get("tcpA_ElTor")
      tcpA_ElTor_fh.write(translate_chars(conv(value)))
    
    with open("toxR", "wb") as toxR_fh:
      value = row.get("toxR")
      toxR_fh.write(translate_chars(conv(value)))
    
    with open("wbeN_O1", "wb") as wbeN_O1_fh:
      value = row.get("wbeN_O1")
      wbeN_O1_fh.write(translate_chars(conv(value)))

    CODE
  >>>
  output {
      File srst2_tsv = "~{samplename}.tsv"
      File srst2_detailed_tsv = "~{samplename}.detailed.tsv"
      String srst2_version = read_string("VERSION")
      String srst2_vibrio_ctxA = read_string("ctxA")
      String srst2_vibrio_ompW = read_string("ompW")
      String srst2_vibrio_tcpA_ElTor = read_string("tcpA_ElTor")
      String srst2_vibrio_toxR = read_string("toxR")
      String srst2_vibrio_wbeN_O1 = read_string("wbeN_O1")
  }
  runtime {
    docker: "~{docker}"
    memory: "8 GB"
    cpu: cpu
    disks: "local-disk " + disk_size + " SSD"
    disk: disk_size + " GB"
    maxRetries: 3
    preemptible: 0
  }
}