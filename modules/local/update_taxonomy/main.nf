process UPDATE_TAXONOMY{
    container (workflow.containerEngine ? "pypy:3" : null)
    tag "Update Taxonomy"

    input:
        tuple path(names), path(nodes)
        path("extra_genomes.map")

    output:
        tuple path("new_names.dmp"), path("new_nodes.dmp"), emit: taxonomy
        path("updated_map.map")                           , emit: filemap

    script:
        """
        update_names_nodes_map.py ${names} ${nodes} extra_genomes.map
        """
}