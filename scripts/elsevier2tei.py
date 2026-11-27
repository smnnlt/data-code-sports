#!/usr/bin/env python3
"""
elsevier2tei.py - convert Elsevier full-text XML (from the Elsevier Article
Retrieval API, Accept: text/xml) into GROBID-style TEI XML.

Usage:
    python elsevier2tei.py data/articles/elsevier tei/
    python elsevier2tei.py one_article.xml tei/

"""

import os
import re
import sys
import xml.etree.ElementTree as ET

XML_ID = "{http://www.w3.org/XML/1998/namespace}id"
XLINK_HREF = "{http://www.w3.org/1999/xlink}href"

# elements whose content is not running text
SKIP_INLINE = {"footnote", "float-anchor", "display", "figure", "table",
               "bib-reference", "label", "section-title", "anchor"}
# abstracts that are not the main abstract
SKIP_ABSTRACTS = {"graphical", "author-highlights", "editor-highlights",
                  "teaser", "highlights"}


# ---------------------------------------------------------------- helpers ---

def ln(el):
    """local name of an element (namespace stripped)"""
    return el.tag.rsplit("}", 1)[-1] if isinstance(el.tag, str) else ""


def kids(el, *names):
    return [c for c in el if ln(c) in names]


def first(el, *path):
    """follow a path of local names, returning the first match or None"""
    for name in path:
        if el is None:
            return None
        el = next((c for c in el if ln(c) == name), None)
    return el


def find_all(el, name):
    return [e for e in el.iter() if ln(e) == name]


def find1(el, name):
    return next((e for e in el.iter() if ln(e) == name), None)


def squish(s):
    return re.sub(r"\s+", " ", s or "").strip()


def text_of(el):
    """plain text of an element, ignoring footnotes/floats"""
    if el is None:
        return ""
    tmp = ET.Element("tmp")
    add_inline(el, tmp, {})
    return squish("".join(tmp.itertext()))


def append_text(dst, s):
    if not s:
        return
    if len(dst):
        dst[-1].tail = (dst[-1].tail or "") + s
    else:
        dst.text = (dst.text or "") + s


def sub(parent, tag, text=None, **attrs):
    el = ET.SubElement(parent, tag, {k: v for k, v in attrs.items() if v is not None})
    if text:
        el.text = text
    return el


# --------------------------------------------------------- inline content ---

def add_inline(src, dst, idmap):
    """copy the mixed content of an Elsevier element into a TEI element,
    turning cross-references into <ref> elements"""
    append_text(dst, src.text)
    for c in src:
        name = ln(c)
        if name in ("cross-ref", "cross-refs"):
            add_xref(c, dst, idmap)
        elif name == "inter-ref":
            href = c.get(XLINK_HREF) or c.get("href") or ""
            r = sub(dst, "ref", type="url", target=href)
            r.text = squish("".join(c.itertext())) or href
        elif name in SKIP_INLINE:
            pass
        elif name in ("hsp", "vsp"):
            append_text(dst, " ")
        else:  # italic, bold, sup, inf, small-caps, formula, list, ...
            add_inline(c, dst, idmap)
        append_text(dst, c.tail)


def add_xref(c, dst, idmap):
    targets = [t for t in (c.get("refid") or "").split() if t in idmap]
    txt = "".join(c.itertext())
    if not targets:
        append_text(dst, txt)
        return
    parts = None
    if len(targets) > 1:
        for sep in (";", ","):
            p = re.split(r"(?<=%s)" % sep, txt)
            if len(p) == len(targets):
                parts = p
                break
    for i, t in enumerate(targets):
        typ, new_id = idmap[t]
        r = sub(dst, "ref", type=typ, target="#" + new_id)
        if parts:
            r.text = parts[i]
        elif i == 0:
            r.text = txt
        # otherwise: an empty <ref> keeps the link, text stays with the first


def paragraphs(container, div, idmap):
    """add a <p> for every paragraph-like child"""
    for c in container:
        if ln(c) in ("para", "simple-para"):
            p = sub(div, "p")
            add_inline(c, p, idmap)
            if not squish("".join(p.itertext())):
                div.remove(p)


# -------------------------------------------------------------- sections ---

def add_sections(container, parent, idmap, default_head=None):
    """flat <div>s in document order (GROBID does not nest sections)"""
    div = None
    pending_paras = [c for c in container if ln(c) in ("para", "simple-para")]
    if pending_paras:
        div = sub(parent, "div")
        if default_head:
            sub(div, "head", default_head)
        paragraphs(container, div, idmap)
    for sec in kids(container, "section"):
        add_section(sec, parent, idmap)


def add_section(sec, parent, idmap):
    div = sub(parent, "div")
    label = squish(text_of(first(sec, "label")))
    title = text_of(first(sec, "section-title"))
    if title or label:
        sub(div, "head", title or label, n=label or None)
    paragraphs(sec, div, idmap)
    if not len(div):
        parent.remove(div)
    for s in kids(sec, "section"):
        add_section(s, parent, idmap)


# ----------------------------------------------------------- back matter ---

# Elsevier back-matter element -> (default TEI div type, default heading)
BACK_ELEMENTS = {
    "data-availability": ("availability", "Data availability"),
    "acknowledgment": ("acknowledgement", "Acknowledgements"),
    "conflict-of-interest": ("conflict", "Declaration of competing interest"),
    "appendices": ("annex", "Appendix"),
}
# a sub-section's own title decides its type (e.g. "Availability of data and
# materials" nested inside <ce:acknowledgment>)
TITLE_TYPES = [
    (r"availab|data\s+(and|&)\s+(code|materials?)|data\s+sharing|code\s+sharing", "availability"),
    (r"compet|conflict|declaration\s+of\s+interest", "conflict"),
    (r"fund", "funding"),
    (r"acknowledg", "acknowledgement"),
]


def back_units(el, default_head):
    """(heading, element) pairs: the element's own paragraphs plus every
    nested section, flattened in document order"""
    units = []
    if kids(el, "para", "simple-para"):
        units.append((text_of(first(el, "section-title")) or default_head, el))
    for sec in kids(el, "section"):
        units.extend(back_units(sec, text_of(first(sec, "section-title")) or default_head))
    return units


def add_back(el, back, outers, idmap, default_type, default_head):
    for head, src in back_units(el, default_head):
        typ = next((t for pat, t in TITLE_TYPES if re.search(pat, head, re.I)), default_type)
        div = ET.Element("div")
        sub(div, "head", head)
        paragraphs(src, div, idmap)
        if len(div) < 2:  # heading only, no text
            continue
        if typ not in outers:
            outers[typ] = sub(back, "div", type=typ)
        outers[typ].append(div)


# ------------------------------------------------------ figures & tables ---

def add_figure(fig, body, new_id, idmap):
    f = sub(body, "figure")
    f.set(XML_ID, new_id)
    label = text_of(first(fig, "label"))
    sub(f, "head", label or None)
    if label:
        sub(f, "label", re.sub(r"^\D+", "", label) or label)
    d = sub(f, "figDesc")
    cap = first(fig, "caption")
    if cap is not None:
        for para in kids(cap, "simple-para", "para"):
            if len(d) or d.text:
                append_text(d, " ")
            add_inline(para, d, idmap)


def add_table(tab, body, new_id, idmap, n):
    f = sub(body, "figure", type="table")
    f.set(XML_ID, new_id)
    label = text_of(first(tab, "label")) or "Table %d" % n
    sub(f, "head", label)
    sub(f, "label", re.sub(r"^\D+", "", label) or label)
    d = sub(f, "figDesc")
    cap = first(tab, "caption")
    if cap is not None:
        for para in kids(cap, "simple-para", "para"):
            if len(d) or d.text:
                append_text(d, " ")
            add_inline(para, d, idmap)
    t = sub(f, "table")
    for row in find_all(tab, "row"):
        r = sub(t, "row")
        for entry in kids(row, "entry"):
            cell = sub(r, "cell", text_of(entry))
            start, end = entry.get("namest"), entry.get("nameend")
            m1 = re.search(r"\d+", start or "")
            m2 = re.search(r"\d+", end or "")
            if m1 and m2 and int(m2.group()) > int(m1.group()):
                cell.set("cols", str(int(m2.group()) - int(m1.group()) + 1))
    legend = [text_of(x) for x in find_all(tab, "table-footnote") + find_all(tab, "legend")]
    if any(legend):
        sub(f, "note", " ".join(x for x in legend if x))


# ----------------------------------------------------------- references ---

def person(el, parent, tag):
    a = sub(parent, tag)
    pn = sub(a, "persName")
    given = text_of(first(el, "given-name"))
    surname = text_of(first(el, "surname"))
    if given:
        sub(pn, "forename", given, type="first")
    if surname:
        sub(pn, "surname", surname)
    return a


def year_of(s):
    m = re.search(r"\b(1[6-9]|20)\d{2}[a-z]?\b", s or "")
    return m.group() if m else None


def add_bib(bibref, listbibl, new_id):
    bs = sub(listbibl, "biblStruct")
    bs.set(XML_ID, new_id)
    ref = first(bibref, "reference")
    raw = text_of(find1(bibref, "source-text")) or text_of(find1(bibref, "textref"))
    if ref is None:  # unstructured reference
        raw = raw or text_of(bibref)
        m = sub(bs, "monogr")
        imp = sub(m, "imprint")
        y = year_of(raw)
        if y:
            sub(imp, "date", y, type="published", when=y[:4])
        sub(bs, "note", raw, type="raw_reference")
        return

    contrib = first(ref, "contribution")
    host = first(ref, "host")
    title = text_of(first(contrib, "title", "maintitle")) if contrib is not None else ""
    authors = find_all(first(contrib, "authors"), "author") if contrib is not None and first(contrib, "authors") is not None else []
    doi = text_of(find1(ref, "doi"))

    issue = first(host, "issue") if host is not None else None
    book = None
    if host is not None:
        book = first(host, "edited-book")
        if book is None:
            book = first(host, "book")
    journal = text_of(first(issue, "series", "title", "maintitle")) if issue is not None else ""
    volume = text_of(first(issue, "series", "volume-nr")) if issue is not None else ""
    issue_nr = text_of(first(issue, "issue-nr")) if issue is not None else ""
    date = text_of(find1(host, "date")) if host is not None else ""
    pages = first(host, "pages") if host is not None else None
    fpage = text_of(first(pages, "first-page")) if pages is not None else ""
    lpage = text_of(first(pages, "last-page")) if pages is not None else ""
    artno = text_of(first(host, "article-number")) if host is not None else ""
    booktitle = text_of(first(book, "title", "maintitle")) if book is not None else ""
    publisher = text_of(find1(book, "publisher")) if book is not None else ""
    if publisher:
        publisher = text_of(first(find1(book, "publisher"), "name")) or publisher
    editors = find_all(first(book, "editors"), "editor") if book is not None and first(book, "editors") is not None else []

    if title:
        a = sub(bs, "analytic")
        for au in authors:
            person(au, a, "author")
        sub(a, "title", title, level="a", type="main")
        if doi:
            sub(a, "idno", doi, type="DOI")
    m = sub(bs, "monogr")
    if journal:
        sub(m, "title", journal, level="j")
    elif booktitle:
        sub(m, "title", booktitle, level="m")
    if not title:  # a whole book: authors belong to the monograph
        for au in authors:
            person(au, m, "author")
        if doi:
            sub(m, "idno", doi, type="DOI")
    for ed in editors:
        person(ed, m, "editor")
    imp = sub(m, "imprint")
    if publisher:
        sub(imp, "publisher", publisher)
    if volume:
        sub(imp, "biblScope", volume, unit="volume")
    if issue_nr:
        sub(imp, "biblScope", issue_nr, unit="issue")
    if fpage:
        bsc = sub(imp, "biblScope", unit="page", **{"from": fpage})
        if lpage:
            bsc.set("to", lpage)
    elif artno:
        sub(imp, "biblScope", artno, unit="page")
    y = year_of(date) or year_of(text_of(ref))
    if y:
        sub(imp, "date", y, type="published", when=y[:4])

    if not raw:
        names = ", ".join(squish("%s %s" % (text_of(first(a, "surname")), text_of(first(a, "given-name"))))
                          for a in authors)
        bits = [names, "(%s)" % y if y else "", title, journal or booktitle,
                volume, "-".join(x for x in (fpage, lpage) if x) or artno, doi]
        raw = squish(". ".join(b for b in bits if b))
    sub(bs, "note", raw, type="raw_reference")


# ------------------------------------------------------------- document ---

def unwrap(root):
    """return (article element, API coredata or None)"""
    coredata = None
    if ln(root) == "full-text-retrieval-response":
        coredata = first(root, "coredata")
        ot = first(root, "originalText")
        if ot is not None:
            for item in ot.iter():
                if ln(item) in ("serial-item", "nonserial-item") and len(item):
                    return item[0], coredata
        return None, coredata
    return root, None


def convert(in_path, out_path):
    root = ET.parse(in_path).getroot()
    art, core = unwrap(root)
    if art is None:
        raise ValueError("no article full text in file (abstract-only response?)")

    head = first(art, "head")
    body_src = first(art, "body")

    def core_text(name):
        if core is None:
            return ""
        return text_of(first(core, name))

    # id map for cross-references: Elsevier id -> (TEI ref type, new id)
    idmap = {}
    bibrefs = [b for b in art.iter() if ln(b) == "bib-reference"]
    for i, b in enumerate(bibrefs):
        if b.get("id"):
            idmap[b.get("id")] = ("bibr", "b%d" % i)
    in_head = set(head.iter()) if head is not None else set()
    figures = [f for f in art.iter() if ln(f) == "figure" and f not in in_head]
    tables = [t for t in art.iter() if ln(t) == "table"]
    for i, f in enumerate(figures):
        if f.get("id"):
            idmap[f.get("id")] = ("figure", "fig_%d" % i)
    for i, t in enumerate(tables):
        if t.get("id"):
            idmap[t.get("id")] = ("table", "tab_%d" % i)
    footnotes = [n for n in body_src.iter() if ln(n) == "footnote"] if body_src is not None else []
    for i, n in enumerate(footnotes):
        if n.get("id"):
            idmap[n.get("id")] = ("foot", "foot_%d" % i)

    # ---- header
    tei = ET.Element("TEI", {"xmlns": "http://www.tei-c.org/ns/1.0"})
    th = sub(tei, "teiHeader")
    fd = sub(th, "fileDesc")
    title = text_of(first(head, "title")) if head is not None else ""
    title = title or core_text("title")
    sub(sub(fd, "titleStmt"), "title", title, level="a", type="main")
    pub = sub(fd, "publicationStmt")
    sub(pub, "publisher", core_text("publisher") or "Elsevier")
    doi = text_of(find1(first(art, "item-info"), "doi")) if first(art, "item-info") is not None else ""
    doi = doi or core_text("doi")
    src = sub(sub(fd, "sourceDesc"), "biblStruct")
    an = sub(src, "analytic")

    if head is not None:
        affs = {a.get("id"): text_of(first(a, "textfn")) or text_of(a)
                for a in find_all(head, "affiliation")}
        for grp in find_all(head, "author-group"):
            grp_affs = [text_of(first(a, "textfn")) or text_of(a) for a in kids(grp, "affiliation")]
            for au in kids(grp, "author"):
                a = person(au, an, "author")
                email = next((text_of(e) for e in kids(au, "e-address")
                              if e.get("type", "email") == "email"), "")
                if email:
                    sub(a, "email", email)
                linked = [affs.get(x.get("refid")) for x in find_all(au, "cross-ref")
                          if x.get("refid") in affs]
                aff = (linked or grp_affs or [None])[0]
                if aff:
                    sub(sub(a, "affiliation"), "orgName", aff)
                if au.get("orcid"):
                    sub(a, "idno", au.get("orcid"), type="ORCID")
    sub(an, "title", title, level="a", type="main")
    if doi:
        sub(an, "idno", doi, type="DOI")
    mono = sub(src, "monogr")
    sub(mono, "title", core_text("publicationName"), level="j")
    imp = sub(mono, "imprint")
    cover = core_text("coverDate")
    if cover:
        sub(imp, "date", cover, type="published", when=cover)

    sub(sub(sub(th, "encodingDesc"), "appInfo"), "application",
        ident="elsevier2tei", version="1.0")

    prof = sub(th, "profileDesc")
    if head is not None:
        terms = [text_of(k) for k in find_all(head, "keyword")]
        if terms:
            kw = sub(sub(prof, "textClass"), "keywords")
            for t in terms:
                sub(kw, "term", t)
        abstracts = find_all(head, "abstract")
        main = [a for a in abstracts if a.get("class") not in SKIP_ABSTRACTS] or abstracts
        if main:
            absel = sub(prof, "abstract")
            for a in main:
                for sec in find_all(a, "abstract-sec") or [a]:
                    div = sub(absel, "div")
                    st = text_of(first(sec, "section-title"))
                    if st:
                        sub(div, "head", st)
                    paragraphs(sec, div, idmap)

    # ---- body
    text = sub(tei, "text")
    body = sub(text, "body")
    if body_src is not None:
        for c in body_src:
            if ln(c) == "sections":
                add_sections(c, body, idmap)
            elif ln(c) == "section":
                add_section(c, body, idmap)
        loose = ET.Element("x")
        loose.extend(kids(body_src, "para", "simple-para"))
        if len(loose):
            div = ET.Element("div")
            paragraphs(loose, div, idmap)
            body.insert(0, div)
    for i, f in enumerate(figures):
        add_figure(f, body, "fig_%d" % i, idmap)
    for i, t in enumerate(tables):
        add_table(t, body, "tab_%d" % i, idmap, i + 1)
    for i, n in enumerate(footnotes):
        note = sub(body, "note", place="foot", n=text_of(first(n, "label")) or None)
        note.set(XML_ID, "foot_%d" % i)
        for para in kids(n, "note-para", "para", "simple-para"):
            add_inline(para, note, idmap)

    # ---- back matter
    back = sub(text, "back")
    outers = {}
    for name in BACK_ELEMENTS:
        for el in find_all(art, name):
            add_back(el, back, outers, idmap, *BACK_ELEMENTS[name])
    refs = sub(back, "div", type="references")
    lb = sub(refs, "listBibl")
    for i, b in enumerate(bibrefs):
        add_bib(b, lb, "b%d" % i)

    if body_src is None:
        print("  note: %s has no body (abstract-only?)" % os.path.basename(in_path))

    ET.ElementTree(tei).write(out_path, encoding="utf-8", xml_declaration=True)


def main(argv):
    if len(argv) != 3:
        print(__doc__)
        return 1
    src, out_dir = argv[1], argv[2]
    os.makedirs(out_dir, exist_ok=True)
    files = ([os.path.join(src, f) for f in sorted(os.listdir(src)) if f.lower().endswith(".xml")]
             if os.path.isdir(src) else [src])
    ok = 0
    for f in files:
        out = os.path.join(out_dir, os.path.basename(f))
        try:
            convert(f, out)
            ok += 1
        except Exception as e:  # keep going on bad files
            print("FAILED %s: %s" % (os.path.basename(f), e))
    print("Converted %d of %d files into %s" % (ok, len(files), out_dir))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))