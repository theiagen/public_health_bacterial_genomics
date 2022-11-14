version 1.0

task pasty {
    input {
        File  assembly
        String  samplename
        String docker = "quay.io/biocontainers/pasty:1.0.0--hdfd78af_0"
    }
    command <<<
        # date and version control
        date | tee DATE
        pasty --version > VERSION && sed -i -e 's/pasty\, version //' VERSION

        pasty \
        --assembly ~{assembly}

        awk 'FNR==2' "~{samplename}.tsv" | cut -d$'\t' -f2 > SEROGROUP
        awk 'FNR==2' "~{samplename}.tsv" | cut -d$'\t' -f3 > COVERAGE
        awk 'FNR==2' "~{samplename}.tsv" | cut -d$'\t' -f4 > FRAGMENTS
    >>>
    output {
        String pasty_serogroup = read_string("SEROGROUP")
        String pasty_serogroup_coverage = read_string("COVERAGE")
        String pasty_serogroup_fragments = read_string("FRAGMENTS")
        File pasty_blast_hits = "~{samplename}.blastn.tsv"
        File pasty_all_serogroups = "~{samplename}.details.tsv"
        String pasty_version = read_string("VERSION")
        String pasty_pipeline_date = read_string("DATE")
    }
    runtime {
        docker: "~{docker}"
        memory: "8 GB"
        cpu: 4
        disks: "local-disk 100 SSD"
        preemptible:  0
    }
}