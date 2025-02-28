process PARSE_TAXONOMY{
    container (workflow.containerEngine ? "pypy:3" : null)
    label 'local'
    label "process_low"

    input:
    tuple path(names), path(nodes)
    path("extra_genomes.map")

    output:
    path("taxonomy.json"), emit: json
    path "versions.yml"  , emit: versions

    script:
    """
    parse_taxonomy.py ${nodes} ${names} extra_genomes.map > taxonomy.json

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pypy: \$(pypy3 --version | tail -1 | cut -d ' ' -f2)
    END_VERSIONS
    """
}