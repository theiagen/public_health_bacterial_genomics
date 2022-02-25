version 1.0

task gambit {
  input {
    File assembly
    String samplename
    String docker = "quay.io/staphb/gambit:0.4.0"
  }
  # If "File" type is used Cromwell attempts to localize it, which fails because it doesn't exist yet.
  String report_path = "~{samplename}_gambit.json"
  String closest_genomes_path = "~{samplename}_gambit_closest.csv"
  command <<<
    # capture date and version
    date | tee DATE
    gambit --version | tee GAMBIT_VERSION

    gambit query -f json -o "~{report_path}" "~{assembly}"

    python3 <<EOF
    import json
    import csv

    def fmt_dist(d): return format(d, '.4f')

    with open("~{report_path}") as f:
      data = json.load(f)

    (item,) = data['items']
    predicted = item['predicted_taxon']
    next_taxon = item['next_taxon']
    closest = item['closest_genomes'][0]

    with open('CLOSEST_DISTANCE', 'w') as f:
      f.write(fmt_dist(closest['distance']))

    # Predicted taxon
    with open('PREDICTED_TAXON', 'w') as f:
      f.write('' if predicted is None else predicted['name'])
    with open('PREDICTED_RANK', 'w') as f:
      f.write('' if predicted is None else predicted['rank'])
    with open('PREDICTED_THRESHOLD', 'w') as f:
      f.write(fmt_dist(0 if predicted is None else predicted['distance_threshold']))

    # Next taxon
    with open('NEXT_TAXON', 'w') as f:
      f.write('' if next_taxon is None else next_taxon['name'])
    with open('NEXT_RANK', 'w') as f:
      f.write('' if next_taxon is None else next_taxon['rank'])
    with open('NEXT_THRESHOLD', 'w') as f:
      f.write(fmt_dist(0 if next_taxon is None else next_taxon['distance_threshold']))

    # Table of closest genomes
    with open('~{closest_genomes_path}', 'w', newline='') as f:
      writer = csv.writer(f)

      # Header
      writer.writerow([
        'distance',
        'genome.description',
        'genome.taxon.name',
        'genome.taxon.rank',
        'genome.taxon.threshold',
        'matched.name',
        'matched.rank',
        'matched.distance_threshold',
      ])

      for match in item['closest_genomes']:
        genome = match['genome']
        genome_taxon = genome['taxonomy'][0]
        match_taxon = match['matched_taxon']

        writer.writerow([
          fmt_dist(match['distance']),
          genome['description'],
          genome_taxon['name'],
          genome_taxon['rank'],
          fmt_dist(genome_taxon['distance_threshold']),
          '' if match_taxon is None else match_taxon['name'],
          '' if match_taxon is None else match_taxon['rank'],
          fmt_dist(0 if match_taxon is None else match_taxon['distance_threshold']),
        ])
    EOF
  >>>
  output {
    String gambit_version = read_string("GAMBIT_VERSION")
    String docker_image = docker
    String pipeline_date = read_string("DATE")
    File report_file = report_path
    File closest_genomes_file = closest_genomes_path
    Float closest_distance = read_float("CLOSEST_DISTANCE")
    String predicted_taxon = read_string("PREDICTED_TAXON")
    String predicted_rank = read_string("PREDICTED_RANK")
    String predicted_threshold = read_string("PREDICTED_THRESHOLD")
    String next_taxon = read_string("NEXT_TAXON")
    String next_rank = read_string("NEXT_RANK")
    String next_threshold = read_string("NEXT_THRESHOLD")
  }
  runtime {
    docker: "~{docker}"
    memory: "16 GB"
    cpu: 8
    disks: "local-disk 100 SSD"
    preemptible: 0
  }
}
