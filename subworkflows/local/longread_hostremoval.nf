
//
// Remove host reads via alignment and export off-target reads
//

include { MINIMAP2_INDEX as MINIMAP2_HOST_INDEX                 } from '../../modules/nf-core/minimap2/index/main'
include { MINIMAP2_ALIGN as MINIMAP2_HOST_ALIGN                 } from '../../modules/nf-core/minimap2/align/main'
include { SAMTOOLS_VIEW as SAMTOOLS_HOSTREMOVED_VIEW            } from '../../modules/nf-core/samtools/view/main'
include { SAMTOOLS_LONGREAD_FASTQ as SAMTOOLS_HOSTREMOVED_FASTQ } from '../../modules/local/samtools/fastq_longread/main'
include { SAMTOOLS_INDEX as SAMTOOLS_HOSTREMOVED_INDEX          } from '../../modules/nf-core/samtools/index/main'
include { SAMTOOLS_STATS as SAMTOOLS_HOSTREMOVED_STATS          } from '../../modules/nf-core/samtools/stats/main'

workflow LONGREAD_HOSTREMOVAL {
    take:
    reads     // [ [ meta ], [ reads ] ]
    reference // /path/to/fasta

    main:
    ch_versions       = Channel.empty()
    ch_multiqc_files  = Channel.empty()


    ch_minimap2_index = MINIMAP2_HOST_INDEX ( [ [], reference ] ).index
    ch_versions       = ch_versions.mix( MINIMAP2_HOST_INDEX.out.versions )

    MINIMAP2_HOST_ALIGN ( reads, ch_minimap2_index, true, 'bai', false, false )
    ch_versions        = ch_versions.mix( MINIMAP2_HOST_ALIGN.out.versions.first() )
    ch_minimap2_mapped = MINIMAP2_HOST_ALIGN.out.bam
        .map {
            meta, reads ->
                [ meta, reads, [] ]
        }

    // Generate unmapped reads FASTQ for downstream taxprofiling
    SAMTOOLS_HOSTREMOVED_VIEW ( ch_minimap2_mapped , [[],[]], [] )
    ch_versions      = ch_versions.mix( SAMTOOLS_HOSTREMOVED_VIEW.out.versions.first() )

    SAMTOOLS_HOSTREMOVED_FASTQ ( SAMTOOLS_HOSTREMOVED_VIEW.out.bam, false )
    ch_versions      = ch_versions.mix( SAMTOOLS_HOSTREMOVED_FASTQ.out.versions.first() )

    // Indexing whole BAM for host removal statistics
    SAMTOOLS_INDEX ( MINIMAP2_HOST_ALIGN.out.bam )
    ch_versions      = ch_versions.mix( SAMTOOLS_HOSTREMOVED_INDEX.out.versions.first() )

    bam_bai = MINIMAP2_HOST_ALIGN.out.bam
        .join(SAMTOOLS_HOSTREMOVED_INDEX.out.bai)

    SAMTOOLS_HOSTREMOVED_STATS ( bam_bai, [[],reference] )
    ch_versions = ch_versions.mix(SAMTOOLS_HOSTREMOVED_STATS.out.versions.first())
    ch_multiqc_files = ch_multiqc_files.mix( SAMTOOLS_HOSTREMOVED_STATS.out.stats )

    emit:
    stats              = SAMTOOLS_HOSTREMOVED_STATS.out.stats     //channel: [val(meta), [reads  ] ]
    reads              = SAMTOOLS_HOSTREMOVED_FASTQ.out.other   // channel: [ val(meta), [ reads ] ]
    versions           = ch_versions                 // channel: [ versions.yml ]
    multiqc_files      = ch_multiqc_files
}