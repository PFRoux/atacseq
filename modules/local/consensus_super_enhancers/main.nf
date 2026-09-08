process CONSENSUS_SUPER_ENHANCERS {
    tag "$meta.id"
    label 'process_low'

    conda "conda-forge::python=3.8.3"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.8.3' :
        'biocontainers/python:3.8.3' }"

    input:
    tuple val(meta), path(tables, stageAs: "rose_super_enhancers/*")

    output:
    tuple val(meta), path("consensus_super_enhancers.bed"), emit: bed
    tuple val(meta), path("consensus_super_enhancers.saf"), emit: saf
    path "versions.yml"                                  , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    python - <<'PY'
    import csv
    import re
    from pathlib import Path

    def normalise(value):
        return re.sub(r"[^A-Z0-9]", "", value.upper())

    def parse_int(value):
        value = str(value).replace(",", "").strip()
        if not re.match(r"^-?[0-9]+(\\.0+)?\$", value):
            return None
        return int(float(value))

    def parse_region_id(value):
        text = str(value).strip()
        match = re.match(r"^(.+):(\\d+)-(\\d+)\$", text)
        if match:
            return match.group(1), int(match.group(2)), int(match.group(3))
        match = re.match(r"^(.+?)[_-](\\d+)[_-](\\d+)\$", text)
        if match:
            return match.group(1), int(match.group(2)), int(match.group(3))
        return None

    intervals = []
    for table in sorted(Path("rose_super_enhancers").glob("*")):
        if not table.is_file() or table.stat().st_size == 0:
            continue
        with table.open(newline="") as handle:
            reader = csv.reader(handle, delimiter="\\t")
            header = None
            columns = {}
            for row in reader:
                if not row or row[0].startswith("#"):
                    continue
                if header is None:
                    names = [normalise(x) for x in row]
                    if {"CHROM", "START"}.intersection(names) or "REGIONID" in names:
                        header = names
                        columns = {name: idx for idx, name in enumerate(names)}
                        continue
                    header = []

                chrom = start = end = None
                if columns:
                    chrom_idx = next((columns[x] for x in ("CHROM", "CHR", "CHROMOSOME") if x in columns), None)
                    start_idx = next((columns[x] for x in ("START", "TXSTART") if x in columns), None)
                    end_idx = next((columns[x] for x in ("STOP", "END", "TXEND") if x in columns), None)
                    region_idx = columns.get("REGIONID")
                    super_idx = next((columns[x] for x in ("ISSUPER", "ISSUPERENHANCER", "SUPERENHANCER") if x in columns), None)

                    if super_idx is not None and super_idx < len(row):
                        status = row[super_idx].strip().upper()
                        if status not in {"1", "TRUE", "YES", "Y"}:
                            continue

                    if chrom_idx is not None and start_idx is not None and end_idx is not None:
                        chrom = row[chrom_idx].strip()
                        start = parse_int(row[start_idx])
                        end = parse_int(row[end_idx])
                    elif region_idx is not None and region_idx < len(row):
                        parsed = parse_region_id(row[region_idx])
                        if parsed:
                            chrom, start, end = parsed
                elif len(row) >= 3:
                    start = parse_int(row[1])
                    end = parse_int(row[2])
                    if start is not None and end is not None:
                        chrom = row[0].strip()
                    elif row:
                        parsed = parse_region_id(row[0])
                        if parsed:
                            chrom, start, end = parsed

                if chrom and start is not None and end is not None and end > start:
                    intervals.append((chrom, max(0, start), end))

    intervals.sort(key=lambda x: (x[0], x[1], x[2]))
    merged = []
    for chrom, start, end in intervals:
        if merged and merged[-1][0] == chrom and start <= merged[-1][2]:
            merged[-1] = (chrom, merged[-1][1], max(merged[-1][2], end))
        else:
            merged.append((chrom, start, end))

    with open("consensus_super_enhancers.bed", "w") as bed:
        for chrom, start, end in merged:
            bed.write(f"{chrom}\\t{start}\\t{end}\\n")

    with open("consensus_super_enhancers.saf", "w") as saf:
        saf.write("GeneID\\tChr\\tStart\\tEnd\\tStrand\\n")
        for chrom, start, end in merged:
            saf.write(f"{chrom}:{start}-{end}\\t{chrom}\\t{start + 1}\\t{end}\\t.\\n")

    if not merged:
        print("No consensus super-enhancer intervals were extracted from ROSE SuperStitched tables.")
    PY

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version 2>&1 | sed 's/Python //')
    END_VERSIONS
    """

    stub:
    """
    printf "chr1\\t100\\t200\\n" > consensus_super_enhancers.bed
    printf "GeneID\\tChr\\tStart\\tEnd\\tStrand\\nchr1:100-200\\tchr1\\t101\\t200\\t.\\n" > consensus_super_enhancers.saf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: 3.8.3
    END_VERSIONS
    """
}
