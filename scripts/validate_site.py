#!/usr/bin/env python3
"""Minimal dependency-free validation for the Electric NOM México static site."""

from __future__ import annotations

from html.parser import HTMLParser
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
INDEX = ROOT / "index.html"
LEGACY_ENTRY = ROOT / "inicio"


class SiteParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.ids: list[str] = []
        self.fragment_links: list[str] = []
        self.onclick_values: list[str] = []
        self.has_viewport = False
        self.in_title = False
        self.title_parts: list[str] = []
        self.inline_scripts: list[str] = []
        self._current_script: list[str] | None = None

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        attributes = dict(attrs)

        element_id = attributes.get("id")
        if element_id:
            self.ids.append(element_id)

        href = attributes.get("href")
        if href and href.startswith("#") and len(href) > 1:
            self.fragment_links.append(href[1:])

        onclick = attributes.get("onclick")
        if onclick:
            self.onclick_values.append(onclick)

        if tag == "meta" and attributes.get("name", "").lower() == "viewport":
            self.has_viewport = bool(attributes.get("content"))

        if tag == "title":
            self.in_title = True

        if tag == "script" and not attributes.get("src"):
            self._current_script = []

    def handle_endtag(self, tag: str) -> None:
        if tag == "title":
            self.in_title = False
        if tag == "script" and self._current_script is not None:
            self.inline_scripts.append("".join(self._current_script))
            self._current_script = None

    def handle_data(self, data: str) -> None:
        if self.in_title:
            self.title_parts.append(data)
        if self._current_script is not None:
            self._current_script.append(data)


def fail(errors: list[str]) -> None:
    print("Static site validation failed:")
    for error in errors:
        print(f"- {error}")
    raise SystemExit(1)


def check_javascript(scripts: list[str], errors: list[str]) -> None:
    node = shutil.which("node")
    if node is None:
        errors.append("Node.js is required to syntax-check inline JavaScript")
        return

    for index, script in enumerate(scripts, start=1):
        if not script.strip():
            continue
        with tempfile.NamedTemporaryFile("w", suffix=".js", encoding="utf-8", delete=False) as temp:
            temp.write(script)
            temp_path = Path(temp.name)
        try:
            result = subprocess.run(
                [node, "--check", str(temp_path)],
                capture_output=True,
                text=True,
                check=False,
            )
            if result.returncode != 0:
                detail = (result.stderr or result.stdout).strip()
                errors.append(f"inline script #{index} has invalid JavaScript: {detail}")
        finally:
            temp_path.unlink(missing_ok=True)


def main() -> int:
    errors: list[str] = []

    if not INDEX.is_file():
        fail(["index.html does not exist"])
    if INDEX.stat().st_size == 0:
        fail(["index.html is empty"])
    if LEGACY_ENTRY.exists():
        errors.append("legacy entry file 'inicio' must not be restored")

    source = INDEX.read_text(encoding="utf-8")
    if not re.match(r"\s*<!DOCTYPE\s+html", source, flags=re.IGNORECASE):
        errors.append("index.html must begin with an HTML doctype")

    parser = SiteParser()
    try:
        parser.feed(source)
        parser.close()
    except Exception as exc:  # HTMLParser errors are uncommon but should block CI.
        errors.append(f"HTML parser error: {exc}")

    title = "".join(parser.title_parts).strip()
    if not title:
        errors.append("document title is missing or empty")
    if not parser.has_viewport:
        errors.append("viewport meta tag is missing")

    duplicate_ids = sorted({element_id for element_id in parser.ids if parser.ids.count(element_id) > 1})
    if duplicate_ids:
        errors.append(f"duplicate HTML ids: {', '.join(duplicate_ids)}")

    known_ids = set(parser.ids)
    missing_fragments = sorted({target for target in parser.fragment_links if target not in known_ids})
    if missing_fragments:
        errors.append(f"fragment links point to missing ids: {', '.join(missing_fragments)}")

    section_names: set[str] = set()
    for onclick in parser.onclick_values:
        section_names.update(re.findall(r"showSection\(['\"]([^'\"]+)['\"]\)", onclick))
    missing_sections = sorted(name for name in section_names if f"sec-{name}" not in known_ids)
    if missing_sections:
        errors.append(f"showSection targets do not exist: {', '.join(missing_sections)}")

    required_sections = {"sec-home", "sec-funciones", "sec-calculadoras", "sec-soporte", "sec-privacidad", "sec-terminos"}
    missing_required = sorted(required_sections - known_ids)
    if missing_required:
        errors.append(f"required site sections are missing: {', '.join(missing_required)}")

    check_javascript(parser.inline_scripts, errors)

    if errors:
        fail(errors)

    print("Static site validation passed")
    print(f"- title: {title}")
    print(f"- ids: {len(parser.ids)}")
    print(f"- internal fragment links: {len(parser.fragment_links)}")
    print(f"- inline scripts checked: {len([s for s in parser.inline_scripts if s.strip()])}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
