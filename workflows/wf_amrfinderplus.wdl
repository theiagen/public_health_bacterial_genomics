version 1.0

import "../gene_typing/task_amrfinderplus.wdl" as amrfindertask
import "../tasks/task_versioning.wdl" as versioning

workflow amrfinderplus_wf {
  input {
      File assembly
      String samplename
    }
  call amrfindertask.amrfinderplus {
    input:
      assembly = assembly,
      samplename = samplename
    }
  call versioning.version_capture{
    input:
  }
  output {
    String amrfinderplus_version = amrfinderplus.amrfinderplus_version
    String amrfinderplus_wf_version = version_capture.phbg_version
    String amrfinderplus_wf_analysis_date = version_capture.date
    File amrfinderplus_all_report = amrfinderplus.amrfinderplus_all_report
    File amrfinderplus_amr_report = amrfinderplus.amrfinderplus_amr_report
    File amrfinderplus_stress_report = amrfinderplus.amrfinderplus_stress_report
    File amrfinderplus_virulence_report = amrfinderplus.amrfinderplus_virulence_report
    }
 }
