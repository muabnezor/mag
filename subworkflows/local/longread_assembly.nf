/*
* LONGREAD_ASSEMBLY: Assembly of long reads
*/

include { FLYE         } from '../../modules/nf-core/flye/main'
include { METAMDBG_ASM } from '../../modules/nf-core/metamdbg/asm/main'

workflow LONGREAD_ASSEMBLY {
    take:
    ch_long_reads            // [ [meta] , fastq] (mandatory)

    main:
    ch_assembled_contigs = Channel.empty()
    ch_versions = Channel.empty()

    if ("flye" in params.longread_assemblers){

        FLYE (
            ch_long_reads,
            params.flye_mode
        )

        ch_flye_assemblies = FLYE.out.fasta.map { meta, assembly ->
                def meta_new = meta + [assembler: "FLYE"]
                [meta_new, assembly]
            }
        ch_assembled_contigs = ch_assembled_contigs.mix(ch_flye_assemblies)
        ch_versions = ch_versions.mix(FLYE.out.versions.first())
    }

    if ("metamdbg" in params.longread_assemblers){

        METAMDBG_ASM (
            ch_long_reads,
            params.longread_sequencing_technology
        )

        ch_metamdbg_assemblies = METAMDBG_ASM.out.contigs.map { meta, assembly ->
                def meta_new = meta + [assembler: "METAMDBG"]
                [meta_new, assembly]
            }
        ch_assembled_contigs = ch_assembled_contigs.mix(ch_metamdbg_assemblies)
        ch_versions = ch_versions.mix( METAMDBG_ASM.out.versions.first() )
    }

    emit:
    assemblies = ch_assemblies
    versions = ch_versions

}