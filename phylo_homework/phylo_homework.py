#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
ДЗ: Построение и анализ филогенетических деревьев (phylo_hm.pdf).

Автоматизируемая часть из задания:
1.3 Переименование заголовков в FASTA-файле с ортологами.

Формат:
  Было:  >NP_061820.1 CYCS [organism=Homo sapiens] [GeneID=54205]
  Стало: >Homo_sapiens_NP_061820.1

Скрипт читает входной FASTA (обычно белковые последовательности NCBI),
переименовывает заголовки и сохраняет:
- task1_3_renamed.fasta
- task1_3_rename_command.txt (команда/запуск, который вы использовали)

Остальные пункты (MSA/MEGA/скриншоты/анализ) выполняются вручную и
файлы для сдачи можно просто положить в work_dir.
"""

from __future__ import annotations

import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, Iterator, Optional, Tuple


ORG_RE = re.compile(r"\[organism=([^\]]+)\]")


def load_config() -> dict:
    config_path = Path(__file__).parent / "config.json"
    if not config_path.exists():
        return {"work_dir": "./bioinf"}
    with open(config_path, encoding="utf-8") as f:
        return json.load(f)


def ensure_work_dir(work_dir: str) -> Path:
    base = Path(__file__).parent
    p = (base / work_dir).resolve()
    p.mkdir(parents=True, exist_ok=True)
    return p


@dataclass(frozen=True)
class FastaRecord:
    header: str  # without leading '>'
    seq: str


def iter_fasta(path: Path) -> Iterator[FastaRecord]:
    header: Optional[str] = None
    seq_parts: list[str] = []
    with open(path, "r", encoding="utf-8", errors="replace") as f:
        for raw in f:
            line = raw.rstrip("\n")
            if not line:
                continue
            if line.startswith(">"):
                if header is not None:
                    yield FastaRecord(header=header, seq="".join(seq_parts))
                header = line[1:].strip()
                seq_parts = []
            else:
                seq_parts.append(line.strip())
    if header is not None:
        yield FastaRecord(header=header, seq="".join(seq_parts))


def parse_accession(header: str) -> str:
    # accession is the first token up to whitespace
    return header.split(None, 1)[0].strip()


def parse_organism(header: str) -> Optional[str]:
    m = ORG_RE.search(header)
    if not m:
        return None
    name = m.group(1).strip()
    name = re.sub(r"\s+", " ", name)
    return name


def sanitize_organism_to_id(organism: str) -> str:
    # "Homo sapiens" -> "Homo_sapiens"; also strip problematic characters
    s = organism.strip()
    s = re.sub(r"\s+", "_", s)
    s = re.sub(r"[^A-Za-z0-9_]+", "", s)
    return s


def rename_header(header: str) -> Tuple[str, Optional[str]]:
    acc = parse_accession(header)
    org = parse_organism(header)
    if org is None:
        return acc, None
    org_id = sanitize_organism_to_id(org)
    return f"{org_id}_{acc}", org


def write_fasta(records: Iterable[FastaRecord], out_path: Path, wrap: int = 80) -> None:
    with open(out_path, "w", encoding="utf-8") as f:
        for r in records:
            f.write(f">{r.header}\n")
            seq = r.seq.strip()
            if wrap and wrap > 0:
                for i in range(0, len(seq), wrap):
                    f.write(seq[i : i + wrap] + "\n")
            else:
                f.write(seq + "\n")


def run_task1_3(out_dir: Path, in_fasta: Path) -> None:
    if not in_fasta.exists():
        raise FileNotFoundError(f"Input FASTA not found: {in_fasta}")

    renamed: list[FastaRecord] = []
    missing_org = 0
    total = 0
    for rec in iter_fasta(in_fasta):
        new_header, org = rename_header(rec.header)
        if org is None:
            missing_org += 1
        renamed.append(FastaRecord(header=new_header, seq=rec.seq))
        total += 1

    out_fasta = out_dir / "task1_3_renamed.fasta"
    write_fasta(renamed, out_fasta)

    cmd_txt = out_dir / "task1_3_rename_command.txt"
    cmd_txt.write_text(
        "\n".join(
            [
                "Команда для переименования FASTA (phylo task 1.3):",
                f"python {Path(__file__).name} --task 1.3 --in \"{in_fasta}\"",
                "",
                f"Вход:  {in_fasta}",
                f"Выход: {out_fasta}",
                f"Записей: {total}",
                f"Без [organism=...] в заголовке: {missing_org}",
            ]
        )
        + "\n",
        encoding="utf-8",
    )

    print(f"[phylo 1.3] OK: {total} records -> {out_fasta}")
    if missing_org:
        print(f"[phylo 1.3] WARNING: {missing_org} headers without [organism=...]")


def main(argv: list[str]) -> int:
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("--task", required=True, help="Task id, e.g. 1.3")
    parser.add_argument(
        "--in",
        dest="in_fasta",
        help="Input FASTA with ortholog protein sequences (NCBI style headers).",
    )
    args = parser.parse_args(argv)

    cfg = load_config()
    out_dir = ensure_work_dir(cfg.get("work_dir", "./bioinf"))

    if str(args.task) == "1.3":
        if not args.in_fasta:
            print("Для --task 1.3 нужен --in <path_to_fasta>.")
            return 2
        run_task1_3(out_dir, Path(args.in_fasta))
        return 0

    print(f"Неизвестное задание: {args.task}")
    return 2


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))

